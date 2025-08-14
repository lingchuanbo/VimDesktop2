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
        ; 使用多种方法检测输入法状态，提高准确性
        return this.GetInputModeRobust(hwnd)
    }

    /**
     * 修复的输入法状态检测方法
     * 针对小狼毫输入法的特殊逻辑
     * @param hwnd 窗口句柄
     * @returns {1 | 0} 1:中文，0:英文
     */
    static GetInputModeRobust(hwnd := this.GetFocusedWindow()) {
        try {
            ; 获取基本状态
            openStatus := this.GetOpenStatus(hwnd)
            conversionMode := this.GetConversionMode(hwnd)
            
            ; 对于小狼毫输入法，可能需要特殊处理
            ; 如果转换模式是144或145，使用精确匹配
            if (conversionMode == 144) {
                return 0  ; 144 = 英文
            } else if (conversionMode == 145) {
                return 1  ; 145 = 中文
            }
            
            ; 对于其他情况，使用传统检测
            if (!openStatus) {
                return 0  ; 输入法未开启，肯定是英文
            }
            
            ; 检查位0，但可能需要反转逻辑
            return conversionMode & 1
        } catch {
            ; 如果出错，返回英文状态
            return 0
        }
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
    ; 处理大写锁定
    if (GetKeyState("CapsLock", "T")) {
        SendInput("{CapsLock}")
    }
    Sleep(50)
    
    ; 优先使用有效的方法，减少等待时间提高响应速度
    ; 方法1: 使用Shift键切换（小狼毫的有效方法）
    try {
        SendInput("{Shift}")
        Sleep(150)  ; 减少等待时间
        
        if (IME.GetInputMode() == 0) {
            return true
        }
    } catch {
        ; 忽略错误
    }
    
    ; 方法2: 直接设置转换模式为144（小狼毫英文模式）
    try {
        IME.SetConversionMode(144)
        Sleep(100)  ; 进一步减少等待时间
        
        if (IME.GetInputMode() == 0) {
            return true
        }
    } catch {
        ; 忽略错误
    }
    
    ; 备用方法: 传统的SetInputMode（为其他输入法保留）
    try {
        IME.SetInputMode(0)
        Sleep(100)
        
        if (IME.GetInputMode() == 0) {
            return true
        }
    } catch {
        ; 忽略错误
    }
    
    return false
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

/**
 * 测试IME切换功能
 * 显示当前输入法状态并尝试切换
 */
TestIMESwitch() {
    ; 获取当前状态
    currentMode := IME.GetInputMode()
    currentStatus := currentMode ? "中文" : "英文"

    ; 显示当前状态
    MsgBox("当前输入法状态: " . currentStatus . "`n点击确定后将尝试切换到英文", "IME测试", "T3")

    ; 尝试切换到英文
    result := switch_EN()

    ; 等待一下让切换生效
    Sleep(200)

    ; 检查切换后的状态
    newMode := IME.GetInputMode()
    newStatus := newMode ? "中文" : "英文"

    ; 显示结果
    resultText := "切换结果: " . (result ? "成功" : "失败") . "`n"
    resultText .= "切换前: " . currentStatus . "`n"
    resultText .= "切换后: " . newStatus . "`n"

    if (result && newMode == 0) {
        resultText .= "`n✓ 切换成功！"
    } else if (!result) {
        resultText .= "`n✗ 切换函数返回失败"
    } else {
        resultText .= "`n✗ 切换后状态验证失败"
    }

    MsgBox(resultText, "IME切换测试结果", "T5")
}

/**
 * 获取详细的IME状态信息
 */
GetIMEStatusInfo() {
    try {
        hwnd := IME.GetFocusedWindow()
        inputMode := IME.GetInputMode(hwnd)
        openStatus := IME.GetOpenStatus(hwnd)
        conversionMode := IME.GetConversionMode(hwnd)
        keyboardLayout := IME.GetKeyboardLayout(hwnd)

        info := "=== IME状态详情 ===`n"
        info .= "窗口句柄: " . hwnd . "`n"
        info .= "输入模式: " . (inputMode ? "中文" : "英文") . " (" . inputMode . ")`n"
        info .= "开启状态: " . openStatus . "`n"
        info .= "转换模式: " . conversionMode . "`n"
        info .= "键盘布局: 0x" . Format("{:08X}", keyboardLayout) . "`n"

        return info
    } catch Error as e {
        return "获取IME状态时出错: " . e.Message
    }
}
/**
 * 获取详细的IME状态信息（增强版）
 */
GetIMEStatusInfoEnhanced() {
    try {
        hwnd := IME.GetFocusedWindow()
        inputMode := IME.GetInputMode(hwnd)
        openStatus := IME.GetOpenStatus(hwnd)
        conversionMode := IME.GetConversionMode(hwnd)
        keyboardLayout := IME.GetKeyboardLayout(hwnd)

        ; 获取当前线程的键盘布局
        threadId := DllCall("GetWindowThreadProcessId", "ptr", hwnd, "ptr", 0, "uint")
        currentLayout := DllCall("GetKeyboardLayout", "uint", threadId, "ptr")

        info := "=== IME状态详情 ===`n"
        info .= "窗口句柄: " . hwnd . "`n"
        info .= "线程ID: " . threadId . "`n"
        info .= "输入模式: " . (inputMode ? "中文" : "英文") . " (" . inputMode . ")`n"
        info .= "开启状态: " . openStatus . "`n"
        info .= "转换模式: " . conversionMode . " (二进制: " . Format("{:08b}", conversionMode) . ")`n"
        info .= "键盘布局: 0x" . Format("{:08X}", keyboardLayout) . "`n"
        info .= "当前布局: 0x" . Format("{:08X}", currentLayout) . "`n"
        info .= "布局低位: 0x" . Format("{:04X}", currentLayout & 0xFFFF) . "`n"
        info .= "布局高位: 0x" . Format("{:04X}", (currentLayout >> 16) & 0xFFFF) . "`n"

        ; 分析转换模式各位的含义
        info .= "`n=== 转换模式分析 ===`n"
        info .= "位0 (中文/英文): " . (conversionMode & 1 ? "中文" : "英文") . "`n"
        info .= "位1 (全角/半角): " . (conversionMode & 2 ? "全角" : "半角") . "`n"
        info .= "位3 (片假名): " . (conversionMode & 8 ? "是" : "否") . "`n"
        info .= "位4 (平假名): " . (conversionMode & 16 ? "是" : "否") . "`n"

        ; 判断输入法类型
        info .= "`n=== 输入法类型判断 ===`n"
        layoutLow := currentLayout & 0xFFFF
        if (layoutLow == 0x0804) {
            info .= "输入法类型: 简体中文 (中国)`n"
        } else if (layoutLow == 0x0404) {
            info .= "输入法类型: 繁体中文 (台湾)`n"
        } else if (layoutLow == 0x1004) {
            info .= "输入法类型: 繁体中文 (新加坡)`n"
        } else if (layoutLow == 0x0C04) {
            info .= "输入法类型: 繁体中文 (香港)`n"
        } else if (layoutLow == 0x0409) {
            info .= "输入法类型: 英文 (美国)`n"
        } else {
            info .= "输入法类型: 其他 (0x" . Format("{:04X}", layoutLow) . ")`n"
        }

        return info
    } catch Error as e {
        return "获取IME状态时出错: " . e.Message
    }
}

/**
 * 专门针对小狼毫输入法的英文切换函数（增强版）
 * 增加重试机制和更好的时序控制
 * @param maxRetries 最大重试次数，默认3次
 * @returns {Boolean} 切换是否成功
 */
switch_EN_Rime(maxRetries := 3) {
    ; 处理大写锁定
    if (GetKeyState("CapsLock", "T")) {
        SendInput("{CapsLock}")
        Sleep(50)
    }

    ; 定义切换方法数组
    switchMethods := [{ name: "SetConversionMode", func: () => IME.SetConversionMode(144) }, { name: "SetInputMode",
        func: () => IME.SetInputMode(0) }, { name: "SetOpenStatus", func: () => IME.SetOpenStatus(false) }, { name: "ShiftKey",
            func: () => SendInput("{Shift}") }, { name: "CtrlSpace", func: () => SendInput("^{Space}") }, { name: "PostMessage",
                func: () => PostMessage(0x283, 0, 0x0409, , "A") }
    ]

    ; 对每种方法进行重试
    for method in switchMethods {
        loop maxRetries {
            retry := A_Index
            try {
                ; 执行切换方法
                method.func.Call()

                ; 等待切换生效，根据重试次数调整等待时间
                waitTime := 100 + (retry - 1) * 50
                Sleep(waitTime)

                ; 验证是否切换成功
                if (IME.GetInputMode() == 0) {
                    return true
                }

                ; 如果不是最后一次重试，稍等再试
                if (retry < maxRetries) {
                    Sleep(50)
                }
            } catch {
                ; 忽略错误，继续下一次重试
                Sleep(50)
            }
        }
    }

    ; 如果所有方法和重试都失败，返回false
    return false
}

/**
 * 强健的英文切换函数（通用版）
 * 增加重试机制和更好的错误处理
 * @param maxRetries 最大重试次数，默认3次
 * @returns {Boolean} 切换是否成功
 */
switch_EN_Robust(maxRetries := 3) {
    ; 处理大写锁定
    if (GetKeyState("CapsLock", "T")) {
        SendInput("{CapsLock}")
        Sleep(50)
    }

    ; 首先尝试小狼毫专用方法
    if (switch_EN_Rime(maxRetries)) {
        return true
    }

    ; 如果小狼毫方法失败，尝试通用方法
    loop maxRetries {
        retry := A_Index
        try {
            ; 方法1: 使用IME.SetInputMode
            IME.SetInputMode(0)
            waitTime := 100 + (retry - 1) * 50
            Sleep(waitTime)

            if (IME.GetInputMode() == 0) {
                return true
            }
        } catch {
            ; 忽略错误
        }

        try {
            ; 方法2: 设置开启状态
            IME.SetOpenStatus(false)
            Sleep(waitTime)

            if (IME.GetInputMode() == 0) {
                return true
            }
        } catch {
            ; 忽略错误
        }

        try {
            ; 方法3: 使用PostMessage
            PostMessage(0x283, 0, 0x0409, , "A")
            Sleep(waitTime)

            if (IME.GetInputMode() == 0) {
                return true
            }
        } catch {
            ; 忽略错误
        }

        ; 如果不是最后一次重试，等待更长时间
        if (retry < maxRetries) {
            Sleep(100)
        }
    }

    return false
}
