/*
类: ToolTipInfoManager
作用: 管理按键提示信息的显示和隐藏，支持配置的自动隐藏规则
作者: Kiro
版本: 1.0
AHK版本: 2.0.18
*/
class ToolTipInfoManager {
    static isShowing := false
    static hideTimer := 0
    static mouseHook := 0
    static windowHook := 0
    static lastActiveWindow := 0
    static tooltipRect := { x: 0, y: 0, w: 0, h: 0 }
    static configCache := 0
    
    ; 全局窗口监控（独立于提示显示状态）
    static globalWindowHook := 0
    static globalLastActiveWindow := 0
    static globalWindowMonitorEnabled := false

    ; 显示提示信息并启动监控
    static Show(text, x := "", y := "", whichToolTip := 1) {
        this._LoadConfigCache()
        ; 先显示提示
        ToolTipManager.Show(text, x, y, whichToolTip)
        this.isShowing := true

        ; 记录提示框位置（用于鼠标检测）
        this._UpdateTooltipRect(x, y, text)

        ; 根据配置启动相应的监控
        this._StartMonitoring()
    }

    ; 隐藏提示信息
    static Hide() {
        if (!this.isShowing)
            return

        ; 检查配置是否允许自动隐藏
        if (!this._IsConfigEnabled("tooltip_auto_hide", true))
            return

        this._DoHide()
    }

    ; 强制隐藏（忽略配置）
    static ForceHide() {
        this._DoHide()
    }

    ; 执行实际的隐藏操作
    static _DoHide() {
        if (!this.isShowing)
            return

        ToolTipManager.Hide()
        this.isShowing := false
        this._StopMonitoring()
        
        ; 清除按键缓存，避免后续按键继续执行组合功能
        this._ClearKeyCache()
    }
    
    ; 清除按键缓存
    static _ClearKeyCache(reason := "自动隐藏") {
        try {
            ; 检查配置是否启用按键缓存清除
            if (!this._IsConfigEnabled("tooltip_clear_key_cache_on_hide", true))
                return
            
            ; 获取当前窗口和对象
            global vim
            winName := vim.CheckWin()
            winObj := vim.GetWin(winName)
            
            ; 清除按键缓存
            if (winObj && winObj.KeyTemp != "") {
                oldKeyTemp := winObj.KeyTemp
                winObj.KeyTemp := ""
                winObj.Count := 0
                
                ; 如果启用调试，记录清除操作
                try {
                    if (this._IsConfigEnabled("enable_debug", false)) {
                        vim._Debug.Add(reason "时清除按键缓存: " winName " (原缓存: " oldKeyTemp ")")
                    }
                } catch {
                    ; 忽略调试记录错误
                }
            }
        } catch as e {
            VimD_LogOnce("WARN", "TTI_CLEAR_KEYCACHE_FAIL", "清除按键缓存失败", e)
        }
    }

    ; 启动监控
    static _StartMonitoring() {
        ; 启动超时定时器
        timeoutMs := this._GetCachedConfig("tooltip_hide_timeout", 5000)
        if (timeoutMs > 0) {
            this._SetHideTimer(timeoutMs)
        }

        ; 启动鼠标监控
        if (this._IsConfigEnabled("tooltip_hide_on_mouse_leave", false) || this._IsConfigEnabled("tooltip_hide_on_click_outside", false)) {
            this._StartMouseMonitoring()
        }

        ; 启动窗口监控
        if (this._IsConfigEnabled("tooltip_hide_on_window_change", false)) {
            this._StartWindowMonitoring()
        }
    }

    static _SetHideTimer(timeoutMs) {
        if (timeoutMs <= 0)
            return
        this.hideTimer := SetTimer(() => ToolTipInfoManager._OnTimeout(), -timeoutMs)
    }

    static _IsConfigEnabled(key, defaultValue := true) {
        return this._GetCachedConfig(key, defaultValue)
    }

    static _LoadConfigCache() {
        this.configCache := Map()
        this.configCache["tooltip_auto_hide"] := this._GetConfigValue("tooltip_auto_hide", true)
        this.configCache["tooltip_hide_timeout"] := this._GetConfigValue("tooltip_hide_timeout", 5000)
        this.configCache["tooltip_hide_on_mouse_leave"] := this._GetConfigValue("tooltip_hide_on_mouse_leave", false)
        this.configCache["tooltip_hide_on_click_outside"] := this._GetConfigValue("tooltip_hide_on_click_outside", false)
        this.configCache["tooltip_hide_on_window_change"] := this._GetConfigValue("tooltip_hide_on_window_change", false)
        this.configCache["tooltip_global_window_monitor"] := this._GetConfigValue("tooltip_global_window_monitor", true)
        this.configCache["tooltip_clear_key_cache_on_hide"] := this._GetConfigValue("tooltip_clear_key_cache_on_hide", true)
        this.configCache["enable_debug"] := this._GetConfigValue("enable_debug", false)
    }

    static _GetCachedConfig(key, defaultValue) {
        if (IsObject(this.configCache) && this.configCache.Has(key))
            return this.configCache[key]
        return this._GetConfigValue(key, defaultValue)
    }

    static _GetConfigValue(key, defaultValue) {
        try {
            return INIObject.config.%key%
        } catch {
            return defaultValue
        }
    }

    ; 停止监控
    static _StopMonitoring() {
        ; 停止定时器
        if (this.hideTimer) {
            SetTimer(this.hideTimer, 0)
            this.hideTimer := 0
        }

        ; 停止鼠标监控
        this._StopMouseMonitoring()

        ; 停止窗口监控
        this._StopWindowMonitoring()
    }

    ; 启动鼠标监控
    static _StartMouseMonitoring() {
        if (this.mouseHook)
            return

        ; 使用低级鼠标钩子监控鼠标事件
        this.mouseHook := SetTimer(() => ToolTipInfoManager._CheckMouse(), 100)
    }

    ; 停止鼠标监控
    static _StopMouseMonitoring() {
        this._StopTimerHook("mouseHook")
    }

    ; 启动窗口监控
    static _StartWindowMonitoring() {
        if (this.windowHook)
            return

        this.lastActiveWindow := WinGetID("A")
        this.windowHook := SetTimer(() => ToolTipInfoManager._CheckWindow(), 200)
    }

    ; 停止窗口监控
    static _StopWindowMonitoring() {
        this._StopTimerHook("windowHook")
    }

    ; 检查鼠标状态
    static _CheckMouse() {
        if (!this.isShowing)
            return

        try {
            ; 获取鼠标位置
            MouseGetPos(&mouseX, &mouseY)

            ; 检查是否点击了鼠标（左键或右键）
            if (this._IsConfigEnabled("tooltip_hide_on_click_outside", false)) {
                if (GetKeyState("LButton", "P") || GetKeyState("RButton", "P")) {
                    ; 检查点击是否在提示框外
                    if (this._HideIfMouseOutside(mouseX, mouseY)) {
                        return
                    }
                }
            }

            ; 检查鼠标是否离开提示区域
            if (this._IsConfigEnabled("tooltip_hide_on_mouse_leave", false)) {
                if (!this._IsMouseInTooltip(mouseX, mouseY)) {
                    ; 给一个小的延迟，避免鼠标快速移动时误触发
                    SetTimer(() => ToolTipInfoManager._DelayedHideCheck(), -500)
                }
            }
        } catch as e {
            VimD_LogOnce("WARN", "TTI_MOUSE_CHECK_FAIL", "鼠标检测失败", e)
        }
    }

    ; 检查窗口状态
    static _CheckWindow() {
        if (!this.isShowing)
            return

        try {
            currentWindow := WinGetID("A")
            if (currentWindow != this.lastActiveWindow) {
                this.Hide()
            }
        } catch as e {
            VimD_LogOnce("WARN", "TTI_WINDOW_CHECK_FAIL", "窗口检测失败", e)
        }
    }

    ; 超时回调
    static _OnTimeout() {
        this.Hide()
    }

    ; 延迟隐藏检查
    static _DelayedHideCheck() {
        if (this.isShowing) {
            MouseGetPos(&newX, &newY)
            this._HideIfMouseOutside(newX, newY)
        }
    }

    ; 更新提示框矩形区域
    static _UpdateTooltipRect(x, y, text) {
        ; 如果没有指定位置，使用默认位置（鼠标附近）
        if (x = "" || y = "") {
            MouseGetPos(&mouseX, &mouseY)
            this.tooltipRect.x := (x = "") ? mouseX + 10 : x
            this.tooltipRect.y := (y = "") ? mouseY + 10 : y
        } else {
            this.tooltipRect.x := x
            this.tooltipRect.y := y
        }

        ; 估算提示框大小（基于文本长度）
        lines := StrSplit(text, "`n")
        maxLineLength := 0
        for line in lines {
            if (StrLen(line) > maxLineLength)
                maxLineLength := StrLen(line)
        }

        ; 估算尺寸（每个字符约8像素宽，每行约20像素高）
        this.tooltipRect.w := maxLineLength * 8 + 20
        this.tooltipRect.h := lines.Length * 20 + 10
    }

    ; 检查鼠标是否在提示框区域内
    static _IsMouseInTooltip(mouseX, mouseY) {
        ; 添加一些边距，让检测区域稍大一些
        margin := 20
        return (mouseX >= this.tooltipRect.x - margin &&
            mouseX <= this.tooltipRect.x + this.tooltipRect.w + margin &&
            mouseY >= this.tooltipRect.y - margin &&
            mouseY <= this.tooltipRect.y + this.tooltipRect.h + margin)
    }

    static _HideIfMouseOutside(mouseX, mouseY) {
        if (!this._IsMouseInTooltip(mouseX, mouseY)) {
            this.Hide()
            return true
        }
        return false
    }
    
    ; 启动全局窗口监控
    static StartGlobalWindowMonitor() {
        this._LoadConfigCache()
        ; 检查配置是否启用全局窗口监控与按键缓存清除
        if (!this._IsConfigEnabled("tooltip_global_window_monitor", true))
            return
        if (!this._IsConfigEnabled("tooltip_clear_key_cache_on_hide", true))
            return
        
        if (this.globalWindowHook)
            return
            
        this.globalLastActiveWindow := WinGetID("A")
        this.globalWindowHook := SetTimer(() => ToolTipInfoManager._CheckGlobalWindow(), 200)
        this.globalWindowMonitorEnabled := true
    }
    
    ; 停止全局窗口监控
    static StopGlobalWindowMonitor() {
        this._StopTimerHook("globalWindowHook")
        this.globalWindowMonitorEnabled := false
    }

    static _StopTimerHook(hookField) {
        hookId := this.%hookField%
        if (hookId) {
            SetTimer(hookId, 0)
            this.%hookField% := 0
        }
    }
    
    ; 检查全局窗口状态
    static _CheckGlobalWindow() {
        try {
            currentWindow := WinGetID("A")
            if (currentWindow != this.globalLastActiveWindow) {
                ; 窗口切换了，清除按键缓存
                this._ClearKeyCache("窗口切换")
                this.globalLastActiveWindow := currentWindow
            }
        } catch as e {
            VimD_LogOnce("WARN", "TTI_GLOBAL_WINDOW_CHECK_FAIL", "全局窗口检测失败", e)
        }
    }
}
