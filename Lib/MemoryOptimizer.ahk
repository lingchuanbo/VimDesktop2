#Requires AutoHotkey v2.0

/*
内存优化器 - 定期清理程序内存
作者: BoBO
版本: 1.0
用途: 解决ToolTip和其他组件的内存累积问题
*/

class MemoryOptimizer {
    static cleanupInterval := 300000  ; 5分钟清理一次
    static _isEnabled := false
    static _cleanupTimer := 0
    static _lastCleanupTime := 0

    static isEnabled {
        get => this._isEnabled
        set => this._isEnabled := value
    }

    static cleanupTimer {
        get => this._cleanupTimer
        set => this._cleanupTimer := value
    }

    static lastCleanupTime {
        get => this._lastCleanupTime
        set => this._lastCleanupTime := value
    }

    /*
    启用内存优化器
    @param interval 清理间隔(毫秒)，默认5分钟
    */
    static Enable(interval := 300000) {
        if (this.isEnabled)
            return

        this.cleanupInterval := interval
        this.isEnabled := true

        ; 设置定期清理定时器
        this.cleanupTimer := () => this.PerformCleanup()
        SetTimer(this.cleanupTimer, this.cleanupInterval)

        ; 立即执行一次清理
        this.PerformCleanup()
    }

    /*
    禁用内存优化器
    */
    static Disable() {
        if (!this.isEnabled)
            return

        this.isEnabled := false

        if (this.cleanupTimer) {
            SetTimer(this.cleanupTimer, 0)
            this.cleanupTimer := 0
        }
    }

    /*
    执行内存清理
    */
    static PerformCleanup() {
        try {
            ; 记录清理时间
            this.lastCleanupTime := A_TickCount

            ; 清理ToolTip相关内存
            this.CleanupToolTips()

            ; 清理GDI+资源
            this.CleanupGDIPlus()

            ; 强制垃圾回收
            this.ForceGarbageCollection()

            ; 调用Windows API清理工作集
            this.CleanupWorkingSet()

        } catch as e {
            ; 忽略清理过程中的错误，避免影响主程序
        }
    }

    /*
    清理ToolTip相关内存
    */
    static CleanupToolTips() {
        try {
            ; 隐藏所有ToolTip
            loop 20 {
                ToolTip("", , , A_Index)
            }

            ; 清理ToolTipManager缓存
            global ToolTipManager
            if (IsSet(ToolTipManager)) {
                try {
                    ToolTipManager.Reset()
                } catch {
                    ; 忽略重置错误
                }
            }

        } catch {
            ; 忽略ToolTip清理错误
        }
    }

    /*
    清理GDI+资源
    */
    static CleanupGDIPlus() {
        try {
            ; 如果BTT存在，尝试清理其资源
            global BTT
            if (IsSet(BTT)) {
                ; 清理BTT的缓存
                try {
                    if (BTT.HasOwnProp("_cachedDPI")) {
                        BTT._cachedDPI.Clear()
                    }
                } catch {
                    ; 忽略清理错误
                }
            }

        } catch {
            ; 忽略GDI+清理错误
        }
    }

    /*
    强制垃圾回收
    */
    static ForceGarbageCollection() {
        try {
            ; AutoHotkey v2没有直接的垃圾回收API
            ; 但我们可以通过清空一些全局变量来帮助释放内存

            ; 清空一些可能的缓存变量
            global VimDesktop_Global
            if (IsSet(VimDesktop_Global)) {
                ; 清理一些可能累积的状态
                VimDesktop_Global.showToolTipStatus := 0
            }

        } catch {
            ; 忽略垃圾回收错误
        }
    }

    /*
    清理工作集内存
    */
    static CleanupWorkingSet() {
        try {
            ; 调用Windows API强制内存清理
            DllCall("kernel32.dll\SetProcessWorkingSetSize", "ptr", -1, "uptr", -1, "uptr", -1)

            ; 额外的内存清理
            DllCall("kernel32.dll\EmptyWorkingSet", "ptr", -1)

            ; 清理堆内存
            DllCall("kernel32.dll\HeapCompact", "ptr", DllCall("kernel32.dll\GetProcessHeap", "ptr"), "uint", 0)

        } catch {
            ; 忽略API调用错误
        }
    }

    /*
    手动触发清理
    */
    static ManualCleanup() {
        this.PerformCleanup()
    }

    /*
    获取上次清理时间
    */
    static GetLastCleanupTime() {
        return this.lastCleanupTime
    }

    /*
    获取清理状态
    */
    static IsEnabled() {
        return this.isEnabled
    }
}
