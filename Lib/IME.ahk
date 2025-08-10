; IME Library - Extracted from InputTip project
; 用于获取和切换输入法状态的函数库

/**
 * IME 输入法管理类
 * 提供获取输入法状态和切换输入法的功能
 */
class IME {
    ; 默认超时时间(毫秒)
    static checkTimeout := 500
    ; 默认基础状态 (0: 英文, 1: 中文)
    static baseStatus := 0
    ; 模式规则数组
    static modeRules := []
    ; 模式 (1: 简单模式, 0: 自定义模式)
    static mode := 1

    /**
     * 获取当前输入法输入模式
     * @param hwnd 窗口句柄，默认为当前焦点窗口
     * @returns {1 | 0} 1:中文，0:英文
     */
    static GetInputMode(hwnd := this.GetFocusedWindow()) {
        if (this.mode = 1) {
            if (!this.GetOpenStatus(hwnd)) {
                return 0
            }
            return this.GetConversionMode(hwnd) & 1
        }

        ; 存储默认状态，如果都不匹配，就返回预先指定的默认状态
        status := this.baseStatus

        ; 系统返回的状态码
        statusMode := this.GetOpenStatus(hwnd)
        ; 系统返回的切换码
        conversionMode := this.GetConversionMode(hwnd)

        for v in this.modeRules {
            r := StrSplit(v, "*")

            ; 状态码规则
            sm := r[1]
            ; 切换码规则
            cm := r[2]
            ; 匹配状态
            s := r[3]

            if (this.matchRule(statusMode, sm) && this.matchRule(conversionMode, cm)) {
                ; 匹配成功
                status := s
                break
            }
        }

        return status
    }

    /**
     * 匹配规则
     * @param value 系统返回的状态值
     * @param ruleValue 规则定义的状态值
     * @returns {1 | 0} 是否匹配成功
     */
    static matchRule(value, ruleValue) {
        ; 规则为空，默认匹配成功
        if (ruleValue == "") {
            return 1
        }

        if (ruleValue == "evenNum") { ; 如果值是偶数
            isMatch := !(value & 1)
        } else if (ruleValue == "oddNum") { ; 如果值是奇数
            isMatch := value & 1
        } else {
            isMatch := InStr("/" ruleValue "/", "/" value "/")
        }
        return isMatch
    }

    /**
     * 系统返回的状态码和切换码
     * @param hwnd 窗口句柄
     * @returns {Object} 系统返回的状态码和切换码
     */
    static CheckInputMode(hwnd := this.GetFocusedWindow()) {
        return {
            statusMode: this.GetOpenStatus(hwnd),
            conversionMode: this.GetConversionMode(hwnd)
        }
    }

    /**
     * 切换到指定的输入法状态
     * @param mode 要切换的指定输入法状态(1:中文，0:英文)
     * @param hwnd 窗口句柄
     */
    static SetInputMode(mode, hwnd := this.GetFocusedWindow()) {
        if mode {
            this.SetOpenStatus(true, hwnd)
            switch this.GetKeyboardLayout(hwnd) {
                case 0x08040804:
                    this.SetConversionMode(1025, hwnd)
                case 0x04110411:
                    this.SetConversionMode(9, hwnd)
            }
        }
        else {
            this.SetOpenStatus(false, hwnd)
        }
    }

    /**
     * 切换输入法状态
     * @param hwnd 窗口句柄
     */
    static ToggleInputMode(hwnd := this.GetFocusedWindow()) {
        this.SetInputMode(!this.GetInputMode(hwnd), hwnd)
    }

    /**
     * 获取输入法开启状态
     * @param hwnd 窗口句柄
     * @returns {Integer} 输入法开启状态
     */
    static GetOpenStatus(hwnd := this.GetFocusedWindow()) {
        try {
            DllCall("SendMessageTimeoutW", "ptr", DllCall("imm32\ImmGetDefaultIMEWnd", "ptr", hwnd, "ptr"), "uint",
            0x283, "ptr", 0x5, "ptr", 0, "uint", 0, "uint", this.checkTimeout, "ptr*", &status := 0)
            return status
        } catch {
            return 0
        }
    }

    /**
     * 设置输入法开启状态
     * @param status 要设置的状态
     * @param hwnd 窗口句柄
     */
    static SetOpenStatus(status, hwnd := this.GetFocusedWindow()) {
        try {
            DllCall("SendMessageTimeoutW", "ptr", DllCall("imm32\ImmGetDefaultIMEWnd", "ptr", hwnd, "ptr"), "uint",
            0x283, "ptr", 0x6, "ptr", status, "uint", 0, "uint", this.checkTimeout, "ptr*", 0)
        }
    }

    /**
     * 获取输入法转换模式
     * @param hwnd 窗口句柄
     * @returns {Integer} 转换模式
     */
    static GetConversionMode(hwnd := this.GetFocusedWindow()) {
        try {
            DllCall("SendMessageTimeoutW", "ptr", DllCall("imm32\ImmGetDefaultIMEWnd", "ptr", hwnd, "ptr"), "uint",
            0x283, "ptr", 0x1, "ptr", 0, "uint", 0, "uint", this.checkTimeout, "ptr*", &mode := 0)
            return mode
        } catch {
            return 0
        }
    }

    /**
     * 设置输入法转换模式
     * @param mode 要设置的转换模式
     * @param hwnd 窗口句柄
     */
    static SetConversionMode(mode, hwnd := this.GetFocusedWindow()) {
        try {
            DllCall("SendMessageTimeoutW", "ptr", DllCall("imm32\ImmGetDefaultIMEWnd", "ptr", hwnd, "ptr"), "uint",
            0x283, "ptr", 0x2, "ptr", mode, "uint", 0, "uint", this.checkTimeout, "ptr*", 0)
        }
    }

    /**
     * 获取键盘布局
     * @param hwnd 窗口句柄
     * @returns {Integer} 键盘布局标识符
     */
    static GetKeyboardLayout(hwnd := this.GetFocusedWindow()) {
        return DllCall("GetKeyboardLayout", "uint", DllCall("GetWindowThreadProcessId", "ptr", hwnd, "ptr", 0, "uint"),
        "ptr")
    }

    /**
     * 设置键盘布局
     * @param hkl 键盘布局句柄
     * @param hwnd 窗口句柄
     */
    static SetKeyboardLayout(hkl, hwnd := this.GetFocusedWindow()) {
        SendMessage(0x50, 1, hkl, hwnd)
    }

    /**
     * 获取键盘布局列表
     * @returns {Array} 键盘布局列表
     */
    static GetKeyboardLayoutList() {
        if cnt := DllCall("GetKeyboardLayoutList", "int", 0, "ptr", 0) {
            list := []
            buf := Buffer(cnt * A_PtrSize)
            loop DllCall("GetKeyboardLayoutList", "int", cnt, "ptr", buf) {
                list.Push(NumGet(buf, (A_Index - 1) * A_PtrSize, "ptr"))
            }
            return list
        }
    }

    /**
     * 加载键盘布局
     * @param hkl 键盘布局标识符
     * @returns {Integer} 键盘布局句柄
     */
    static LoadKeyboardLayout(hkl) {
        return DllCall("LoadKeyboardLayoutW", "str", Format("{:08x}", hkl), "uint", 0x101)
    }

    /**
     * 卸载键盘布局
     * @param hkl 键盘布局句柄
     * @returns {Integer} 操作结果
     */
    static UnloadKeyboardLayout(hkl) {
        return DllCall("UnloadKeyboardLayout", "ptr", hkl)
    }

    /**
     * 获取当前焦点窗口
     * @returns {Integer} 窗口句柄
     */
    static GetFocusedWindow() {
        if foreHwnd := WinExist("A") {
            guiThreadInfo := Buffer(A_PtrSize == 8 ? 72 : 48)
            NumPut("uint", guiThreadInfo.Size, guiThreadInfo)
            DllCall("GetGUIThreadInfo", "uint", DllCall("GetWindowThreadProcessId", "ptr", foreHwnd, "ptr", 0, "uint"),
            "ptr", guiThreadInfo)
            if focusedHwnd := NumGet(guiThreadInfo, A_PtrSize == 8 ? 16 : 12, "ptr") {
                return focusedHwnd
            }
            return foreHwnd
        }
        return 0
    }
}

/**
 * 判断当前输入法状态是否为中文
 * @returns {1 | 0} 输入法是否为中文
 * @example
 * DetectHiddenWindows 1 ; 前置条件(不为1，可能判断有误)
 * MsgBox isCN()
 */
isCN() {
    return IME.GetInputMode()
}

/**
 * 将输入法状态切换为中文
 * @example
 * SetStoreCapsLockMode 0 ; 前置条件，确保大写锁定可切换
 * switch_CN()
 */
switch_CN() {
    if (GetKeyState("CapsLock", "T")) {
        SendInput("{CapsLock}")
    }
    Sleep(50)
    IME.SetInputMode(1)
}

/**
 * 将输入法状态切换为英文
 * @example
 * SetStoreCapsLockMode 0 ; 前置条件，确保大写锁定可切换
 * switch_EN()
 */
switch_EN() {
    if (GetKeyState("CapsLock", "T")) {
        SendInput("{CapsLock}")
    }
    Sleep(50)
    IME.SetInputMode(0)
}

/**
 * 切换输入法状态
 */
IME_Toggle() {
    IME.ToggleInputMode()
}

/**
 * 获取输入法状态信息
 * @returns {Object} 包含状态码和转换码的对象
 */
getIMEStatus() {
    return IME.CheckInputMode()
}
