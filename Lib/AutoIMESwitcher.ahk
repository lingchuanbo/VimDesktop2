/*
AutoIMESwitcher - 自动输入法切换库
功能：为任何应用程序提供智能的输入法自动切换功能
作者：BoBO
版本：1.0

使用方法：
1. #Include Lib/AutoIMESwitcher.ahk
2. 调用 AutoIMESwitcher.Setup(processName, options) 来设置自动切换
3. 在 PluginName_Before() 函数中调用 AutoIMESwitcher.HandleBeforeAction(processName)

示例：
AutoIMESwitcher.Setup("AfterFX.exe", {
    enableDebug: false,
    checkInterval: 500,
    enableMouseClick: true,
    inputControlPatterns: ["Edit", "Edit2", "Edit3"],
    cursorTypes: ["IBeam", "Unknown"]
})
*/

class AutoIMESwitcher {
    ; 静态变量存储各个应用的状态
    static appStates := Map()
    static globalMouseMonitorSetup := false
    static timeoutTimers := Map()  ; 存储各个应用的超时定时器

    /*
    设置自动IME切换
    参数：
    - processName: 进程名称，如 "AfterFX.exe"
    - options: 配置选项对象
      - enableDebug: 是否启用调试信息 (默认: false)
      - checkInterval: 检查间隔毫秒 (默认: 500)
      - enableMouseClick: 是否启用鼠标点击监听 (默认: true)
      - inputControlPatterns: 输入控件匹配模式数组 (默认: ["Edit"])
      - cursorTypes: 输入状态光标类型数组 (默认: ["IBeam", "Unknown"])
    */
    static Setup(processName, options := {}) {
        ; 合并用户选项和默认选项
        finalOptions := {
            enableDebug: options.HasProp("enableDebug") ? options.enableDebug : false,
            checkInterval: options.HasProp("checkInterval") ? options.checkInterval : 500,
            enableMouseClick: options.HasProp("enableMouseClick") ? options.enableMouseClick : true,
            inputControlPatterns: options.HasProp("inputControlPatterns") ? options.inputControlPatterns : ["Edit"],
            cursorTypes: options.HasProp("cursorTypes") ? options.cursorTypes : ["IBeam", "Unknown"],
            maxRetries: options.HasProp("maxRetries") ? options.maxRetries : 3,
            autoSwitchTimeout: options.HasProp("autoSwitchTimeout") ? options.autoSwitchTimeout : 5000  ; 5秒超时
        }

        ; 初始化应用状态
        this.appStates[processName] := {
            options: finalOptions,
            lastActiveWindow: "",
            lastFocusedControl: "",
            wasInInputState: false,
            lastCursorType: "",
            debugCount: 0,
            lastInputTime: 0  ; 最后一次输入状态的时间
        }

        ; 设置定时检查
        timerFunc := () => this.CheckWindowState(processName)
        SetTimer(timerFunc, finalOptions.checkInterval)

        ; 设置鼠标点击监听（全局只设置一次）
        if (finalOptions.enableMouseClick && !this.globalMouseMonitorSetup) {
            this.SetupMouseClickMonitor()
            this.globalMouseMonitorSetup := true
        }
    }

    /*
    在 PluginName_Before() 函数中调用此方法
    参数：
    - processName: 进程名称
    - currentControl: 当前焦点控件（可选，如果不提供会自动获取）
    返回：true 表示在输入状态，应该使用普通模式；false 表示不在输入状态，可以使用VIM模式
    */
    static HandleBeforeAction(processName, currentControl := "") {
        if (!this.appStates.Has(processName)) {
            return false
        }

        state := this.appStates[processName]
        options := state.options

        ; 获取当前控件（如果没有提供）
        if (currentControl == "") {
            try {
                currentControl := ControlGetClassNN(ControlGetFocus(""), "ahk_exe " . processName)
            } catch {
                currentControl := ""
            }
        }

        ; 检查是否在输入控件中
        isInInputControl := false
        for pattern in options.inputControlPatterns {
            if (RegExMatch(currentControl, pattern)) {
                isInInputControl := true
                break
            }
        }

        ; 检查光标类型
        currentCursor := A_Cursor
        isInputCursor := false
        for cursorType in options.cursorTypes {
            if (currentCursor == cursorType) {
                isInputCursor := true
                break
            }
        }

        ; 如果在输入状态，返回true（使用普通模式）
        if (isInInputControl || isInputCursor) {
            ; 更新最后输入时间，重置超时计时
            if (this.appStates.Has(processName)) {
                this.appStates[processName].lastInputTime := A_TickCount
            }
            return true
        }

        ; 不在输入状态，切换到英文并返回false（使用VIM模式）
        this.SwitchToEnglish(processName, "VIM模式按键", options.enableDebug)
        return false
    }

    /*
    检查窗口状态并自动切换输入法
    */
    static CheckWindowState(processName) {
        if (!this.appStates.Has(processName)) {
            return
        }

        state := this.appStates[processName]
        options := state.options

        ; 获取当前活动窗口
        try {
            currentWindow := WinGetProcessName("A")
        } catch {
            currentWindow := ""
        }

        ; 只在目标应用窗口中进行检测
        if (currentWindow = processName) {
            ; 获取当前焦点控件
            try {
                currentControl := ControlGetClassNN(ControlGetFocus(""), "ahk_exe " . processName)
            } catch {
                currentControl := ""
            }

            ; 获取当前鼠标光标类型
            currentCursor := A_Cursor

            ; 检测是否在输入状态
            isInInputState := false

            ; 检查输入控件
            for pattern in options.inputControlPatterns {
                if (RegExMatch(currentControl, pattern)) {
                    isInInputState := true
                    break
                }
            }

            ; 检查光标类型
            if (!isInInputState) {
                for cursorType in options.cursorTypes {
                    if (currentCursor == cursorType) {
                        isInInputState := true
                        break
                    }
                }
            }

            ; 调试信息
            if (options.enableDebug) {
                state.debugCount++
                if (state.debugCount >= 10) {
                    state.debugCount := 0
                    MouseGetPos(&mouseX, &mouseY)
                    debugInfo := "状态检查 [" . processName . "]:`n"
                    debugInfo .= "控件: " . currentControl . "`n"
                    debugInfo .= "光标: " . currentCursor . "`n"
                    debugInfo .= "输入状态: " . (isInInputState ? "是" : "否") . "`n"
                    debugInfo .= "上次输入状态: " . (state.wasInInputState ? "是" : "否")
                    ToolTip(debugInfo, mouseX + 100, mouseY + 100)
                    SetTimer(() => ToolTip(), -2000)
                }
            }

            ; 情况1：窗口刚激活
            if (state.lastActiveWindow != processName) {
                this.SwitchToEnglish(processName, "窗口激活", options.enableDebug)
            }
            ; 情况2：从输入状态退出到非输入状态
            else if (state.wasInInputState && !isInInputState) {
                this.SwitchToEnglish(processName, "从输入状态退出", options.enableDebug)
            }
            ; 情况3：光标状态变化
            else if (state.lastCursorType == "IBeam" && currentCursor != "IBeam" && currentCursor != "") {
                this.SwitchToEnglish(processName, "光标状态变化", options.enableDebug)
            }
            ; 情况4：焦点控件发生变化且当前不在输入状态
            else if (currentControl != state.lastFocusedControl && !isInInputState && currentControl != "" && state.lastFocusedControl !=
                "") {
                this.SwitchToEnglish(processName, "焦点控件变化", options.enableDebug)
            }

            ; 处理超时自动切换逻辑
            currentTime := A_TickCount
            
            if (isInInputState) {
                ; 如果当前在输入状态，更新最后输入时间
                state.lastInputTime := currentTime
                
                ; 启动或重置超时定时器
                this.SetTimeoutTimer(processName, options.autoSwitchTimeout)
            } else {
                ; 如果不在输入状态，清除超时定时器
                this.ClearTimeoutTimer(processName)
            }
            
            ; 更新状态
            state.lastFocusedControl := currentControl
            state.wasInInputState := isInInputState
            state.lastCursorType := currentCursor
        }

        state.lastActiveWindow := currentWindow
    }
    
    /*
    设置超时定时器
    */
    static SetTimeoutTimer(processName, timeout) {
        ; 先清除现有定时器
        this.ClearTimeoutTimer(processName)
        
        ; 创建新的定时器函数
        timerFunc := () => this.CheckInputTimeout(processName)
        SetTimer(timerFunc, timeout)
        
        ; 存储定时器函数
        this.timeoutTimers[processName] := timerFunc
    }
    
    /*
    清除超时定时器
    */
    static ClearTimeoutTimer(processName) {
        if (this.timeoutTimers.Has(processName)) {
            SetTimer(this.timeoutTimers[processName], 0)
            this.timeoutTimers.Delete(processName)
        }
    }
    
    /*
    检查输入超时并自动切换
    */
    static CheckInputTimeout(processName) {
        if (!this.appStates.Has(processName)) {
            return
        }
        
        state := this.appStates[processName]
        options := state.options
        
        try {
            ; 检查当前是否还在目标应用中
            currentWindow := WinGetProcessName("A")
            if (currentWindow != processName) {
                ; 不在目标应用中，清除定时器
                this.ClearTimeoutTimer(processName)
                return
            }
            
            ; 检查当前是否还在输入状态
            currentMode := IME.GetInputMode()
            if (currentMode == 0) {
                ; 已经是英文状态，清除定时器
                this.ClearTimeoutTimer(processName)
                return
            }
            
            ; 检查是否真的超时了（防止定时器延迟问题）
            currentTime := A_TickCount
            if (currentTime - state.lastInputTime >= options.autoSwitchTimeout) {
                ; 超时了，执行自动切换
                this.SwitchToEnglish(processName, "输入超时(" . Round(options.autoSwitchTimeout/1000) . "秒)", options.enableDebug)
                
                ; 清除定时器
                this.ClearTimeoutTimer(processName)
            }
        } catch Error as e {
            ; 出错时清除定时器
            this.ClearTimeoutTimer(processName)
        }
    }

    /*
    IME切换的统一函数
    */
    static SwitchToEnglish(processName, reason, enableDebug := false) {
        try {
            DetectHiddenWindows 1
            SetStoreCapsLockMode 0

            ; 首先检查当前是否已经是英文状态
            currentMode := IME.GetInputMode()
            if (currentMode == 0) {
                ; 已经是英文状态，无需切换
                if (enableDebug) {
                    MouseGetPos(&mouseX, &mouseY)
                    ToolTip(reason . "：已是英文状态，跳过切换", mouseX + 10, mouseY + 10)
                    SetTimer(() => ToolTip(), -800)
                }
                return true
            }

            ; 调试信息
            if (enableDebug) {
                MouseGetPos(&mouseX, &mouseY)
                ToolTip("检测到" . reason . "，切换到英文", mouseX + 10, mouseY + 10)
                SetTimer(() => ToolTip(), -1000)
            }

            ; 尝试切换到英文
            switchSuccess := false
            startTime := A_TickCount

            ; 使用简化的切换函数
            try {
                switchSuccess := switch_EN()
                elapsedTime := A_TickCount - startTime

                if (enableDebug) {
                    MouseGetPos(&mouseX, &mouseY)
                    statusText := switchSuccess ? "成功" : "失败"
                    ToolTip(reason . "：切换 - " . statusText . " (" . elapsedTime . "ms)", mouseX + 10, mouseY + 30)
                    SetTimer(() => ToolTip(), -1000)  ; 减少显示时间
                }
            } catch Error as e {
                if (enableDebug) {
                    MouseGetPos(&mouseX, &mouseY)
                    ToolTip(reason . "：切换出错 - " . e.Message, mouseX + 10, mouseY + 30)
                    SetTimer(() => ToolTip(), -1000)  ; 减少显示时间
                }
            }

            ; 如果switch_EN()失败，尝试备用方法
            if (!switchSuccess) {
                try {
                    IME.SetInputMode(0)  ; 0 = 英文
                    Sleep(100)
                    ; 验证切换结果
                    if (IME.GetInputMode() == 0) {
                        switchSuccess := true
                    }
                    if (enableDebug) {
                        MouseGetPos(&mouseX, &mouseY)
                        statusText := switchSuccess ? "成功" : "失败"
                        ToolTip(reason . "：使用IME.SetInputMode()切换 - " . statusText, mouseX + 10, mouseY + 50)
                        SetTimer(() => ToolTip(), -1500)
                    }
                } catch {
                    ; 使用原生方法切换输入法
                    try {
                        PostMessage(0x283, 0, 0x0409, , "A")  ; 切换到英文键盘布局
                        Sleep(100)
                        if (enableDebug) {
                            MouseGetPos(&mouseX, &mouseY)
                            ToolTip(reason . "：使用PostMessage()切换", mouseX + 10, mouseY + 50)
                            SetTimer(() => ToolTip(), -1500)
                        }
                    } catch {
                        if (enableDebug) {
                            MouseGetPos(&mouseX, &mouseY)
                            ToolTip(reason . "：所有切换方法都失败", mouseX + 10, mouseY + 50)
                            SetTimer(() => ToolTip(), -2000)
                        }
                    }
                }
            }
        } catch Error as e {
            if (enableDebug) {
                MouseGetPos(&mouseX, &mouseY)
                ToolTip(reason . "IME切换错误: " . e.Message, mouseX + 10, mouseY + 10)
                SetTimer(() => ToolTip(), -2000)
            }
        }
    }

    /*
    设置鼠标点击监听
    */
    static SetupMouseClickMonitor() {
        ; 监听鼠标左键点击
        OnMessage(0x0201, (wParam, lParam, msg, hwnd) => this.OnMouseClick(wParam, lParam, msg, hwnd))  ; WM_LBUTTONDOWN
        ; 监听鼠标右键点击
        OnMessage(0x0204, (wParam, lParam, msg, hwnd) => this.OnMouseClick(wParam, lParam, msg, hwnd))  ; WM_RBUTTONDOWN
    }

    /*
    鼠标点击事件处理
    */
    static OnMouseClick(wParam, lParam, msg, hwnd) {
        ; 检查是否在已注册的应用窗口中
        try {
            windowProcess := WinGetProcessName("ahk_id " . hwnd)
            if (this.appStates.Has(windowProcess)) {
                ; 延迟一点时间让焦点变化完成
                SetTimer(() => this.CheckInputStateOnClick(windowProcess), -50)
            }
        } catch {
            ; 忽略错误
        }
    }

    /*
    点击后检查输入状态
    */
    static CheckInputStateOnClick(processName) {
        if (!this.appStates.Has(processName)) {
            return
        }

        state := this.appStates[processName]
        options := state.options

        try {
            ; 检查当前是否在目标应用窗口中
            currentWindow := WinGetProcessName("A")
            if (currentWindow != processName) {
                return
            }

            ; 获取当前焦点控件
            try {
                currentControl := ControlGetClassNN(ControlGetFocus(""), "ahk_exe " . processName)
            } catch {
                currentControl := ""
            }

            ; 获取当前鼠标光标类型
            currentCursor := A_Cursor

            ; 检测是否在输入状态
            isInInputState := false

            ; 检查输入控件
            for pattern in options.inputControlPatterns {
                if (RegExMatch(currentControl, pattern)) {
                    isInInputState := true
                    break
                }
            }

            ; 检查光标类型
            if (!isInInputState) {
                for cursorType in options.cursorTypes {
                    if (currentCursor == cursorType) {
                        isInInputState := true
                        break
                    }
                }
            }

            ; 如果不在输入状态，切换到英文
            if (!isInInputState) {
                this.SwitchToEnglish(processName, "鼠标点击非输入区域", options.enableDebug)
            }
        } catch Error as e {
            ; 静默处理错误
        }
    }
}
