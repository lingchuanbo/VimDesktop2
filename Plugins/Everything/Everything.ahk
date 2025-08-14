/*
[PluginInfo]
PluginName=Everything
Author= BoBO
Version=1.0
Comment=Everything搜索工具
*/

; 引入 UIA.ahk 库用于UI自动化检测

; 全局变量声明和初始化
global EverythingConfig := {
    everything_path: "",
    enable_double_click: true,
    show_debug_info: false
}

; 读取Everything配置
ReadEverythingConfig() {
    global EverythingConfig

    ; 配置文件路径
    configFile := A_ScriptDir . "\Plugins\Everything\everything.ini"

    ; 重置为默认配置
    EverythingConfig.everything_path := ""
    EverythingConfig.enable_double_click := true
    EverythingConfig.show_debug_info := false

    ; 读取配置文件
    if FileExist(configFile) {
        try {
            ; 读取Everything路径
            path := IniRead(configFile, "Everything", "everything_path", "")
            if (path != "") {
                EverythingConfig.everything_path := path
            }

            ; 读取双击启动开关
            enableDoubleClick := IniRead(configFile, "Everything", "enable_double_click", "true")
            EverythingConfig.enable_double_click := (enableDoubleClick = "true")

            ; 读取调试信息开关
            showDebugInfo := IniRead(configFile, "Everything", "show_debug_info", "false")
            EverythingConfig.show_debug_info := (showDebugInfo = "true")

        } catch as e {
            ; 配置文件读取失败，使用默认值
            MsgBox("读取Everything配置文件失败: " . e.message . "`n使用默认配置", "配置警告")
        }
    }

    return EverythingConfig
}

; 初始化配置
EverythingConfig := ReadEverythingConfig()

; 保存配置到文件
SaveEverythingConfig() {
    configFile := A_ScriptDir . "\Plugins\Everything\everything.ini"

    try {
        ; 写入配置
        IniWrite(EverythingConfig.everything_path, configFile, "Everything", "everything_path")
        IniWrite(EverythingConfig.enable_double_click ? "true" : "false", configFile, "Everything",
            "enable_double_click")
        IniWrite(EverythingConfig.show_debug_info ? "true" : "false", configFile, "Everything", "show_debug_info")

        return true
    } catch as e {
        MsgBox("保存Everything配置文件失败: " . e.message, "配置错误")
        return false
    }
}

; 切换双击启动功能
ToggleDoubleClickFeature() {
    EverythingConfig.enable_double_click := !EverythingConfig.enable_double_click
    if (SaveEverythingConfig()) {
        status := EverythingConfig.enable_double_click ? "启用" : "禁用"
        MsgBox("桌面双击启动Everything功能已" . status, "配置更新")
    }
}

; 切换调试信息显示
ToggleDebugInfo() {
    EverythingConfig.show_debug_info := !EverythingConfig.show_debug_info
    if (SaveEverythingConfig()) {
        status := EverythingConfig.show_debug_info ? "启用" : "禁用"
        MsgBox("调试信息显示已" . status, "配置更新")
    }
}

Everything() {
    ; 热键映射数组
    KeyArray := Array()

    ; 模式切换
    KeyArray.push({ Key: "<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】" })
    KeyArray.push({ Key: "<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】" })
    KeyArray.push({ Key: "<esc>", Mode: "VIM模式", Group: "模式", Func: "VIMD_清除输入键", Param: "", Comment: "清除输入键及提示" })
    KeyArray.push({ Key: "<capslock>", Mode: "VIM模式", Group: "模式", Func: "VIMD_清除输入键", Param: "", Comment: "清除输入键及提示" })

    ; 帮助
    ; KeyArray.push({ Key: ":?", Mode: "VIM模式", Group: "帮助", Func: "VIMD_ShowKeyHelpWithGui", Param: "Everything",
    ;     Comment: "显示所有按键(GUI)" })
    KeyArray.push({ Key: "i", Mode: "VIM模式", Group: "帮助", Func: "VIMD_ShowKeyHelpMD", Param: "Everything|VIM模式",
        Comment: "显示按键(Markdown)" })

    ; 测试
    ; KeyArray.push({ Key: "1", Mode: "VIM模式", Group: "搜索", Func: "SingleDoubleFullHandlers", Param: "1|Everything_1|Everything_2|Everything_3",
    ;     Comment: "单击/双击/长按" })
    ; KeyArray.push({ Key: "2", Mode: "VIM模式", Group: "搜索", Func: "SingleDoubleFullHandlers", Param: "2|Everything_1|Everything_2",
    ;     Comment: "单击/双击" })
    ; KeyArray.push({ Key: "<c-1>", Mode: "VIM模式", Group: "搜索", Func: "SingleDoubleFullHandlers", Param: "3",
    ;     Comment: "单击" })
    KeyArray.push({ Key: "/d", Mode: "VIM模式", Group: "网站", Func: "run", Param: "http://www.deepseek.com",
        Comment: "打开deepseek" })
    KeyArray.push({ Key: "/g", Mode: "VIM模式", Group: "网站", Func: "run", Param: "http://www.google.com",
        Comment: "打开google" })

    ; 注册窗体
    vim.SetWin("Everything", "EVERYTHING", "Everything.exe")

    ; 设置超时
    vim.SetTimeOut(300, "Everything")

    ; 注册热键
    RegisterPluginKeys(KeyArray, "Everything")
}

; 对符合条件的控件使用【normal模式】，而不是【Vim模式】
Everything_Before() {
    ctrl := ControlGetClassNN(ControlGetFocus("ahk_class EVERYTHING"), "ahk_exe Everything.exe")
    if RegExMatch(ctrl, "Edit") || RegExMatch(ctrl, "Edit1")
        return true
    return false
}

; 运行Everything
Run_Everything(*) {
    ; 优先从everything.ini配置文件获取路径
    everythingPath := EverythingConfig.everything_path

    ; 如果配置文件中没有路径，尝试从其他配置源读取
    if (!everythingPath) {
        try {
            ; 从插件独立配置文件读取
            if (PluginConfigs.HasOwnProp("Everything") && PluginConfigs.Everything.HasOwnProp("Everything")) {
                everythingPath := PluginConfigs.Everything.Everything.everything_path
            }
            ; 如果插件配置不存在，尝试从主配置文件读取（向后兼容）
            else if (INIObject.HasOwnProp("Everything")) {
                everythingPath := INIObject.Everything.everything_path
            }
        } catch {
            ; 配置读取失败，使用默认路径
        }
    }

    ; 如果配置中没有路径，尝试默认路径
    if (!everythingPath) {
        defaultPaths := [
            "C:\Program Files\Everything\Everything.exe",
            "C:\Program Files (x86)\Everything\Everything.exe",
            "D:\WorkFlow\tools\TotalCMD\Tools\Everything\Everything.exe"
        ]

        for path in defaultPaths {
            if FileExist(path) {
                everythingPath := path
                break
            }
        }
    }

    ; 如果找到了Everything路径，运行它
    if (everythingPath && FileExist(everythingPath)) {
        ; 使用修改后的 LaunchOrShow 函数，现在可以安全地省略第三个参数
        LaunchOrShow(everythingPath, "EVERYTHING")
    } else {
        MsgBox("未找到Everything程序，请检查插件配置文件或在主配置文件中设置正确的路径。", "错误", "Icon!")
    }
}

; 打开Everything搜索对话框
Everything_Search(*) {
    ; 先确保Everything已运行
    if !WinExist("ahk_exe Everything.exe") {
        Run_Everything()
        WinWait("ahk_exe Everything.exe", , 3)
    }

    ; 激活Everything窗口并聚焦到搜索框
    if WinExist("ahk_exe Everything.exe") {
        WinActivate
        Send "^f"  ; 聚焦到搜索框
    }
}

Everything_1() {
    MsgBox("1")
}
Everything_2() {
    MsgBox("2")
}
Everything_3() {
    MsgBox("3")
}

; 全局变量用于双击检测
LTickCount := 0
RTickCount := 0
DblClickTime := DllCall("GetDoubleClickTime", "UInt") ; 从系统获取双击时间间隔

; 获取资源管理器背景颜色作为基准
GetExplorerBackgroundColor(WinID) {
    ; 尝试获取资源管理器窗口的背景颜色
    ; 在窗口的多个空白区域采样
    try {
        WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " . WinID)

        ; 获取客户区域（排除标题栏等）
        clientRect := Buffer(16, 0)
        DllCall("GetClientRect", "Ptr", WinID, "Ptr", clientRect)
        clientW := NumGet(clientRect, 8, "Int")
        clientH := NumGet(clientRect, 12, "Int")

        ; 将客户区坐标转换为屏幕坐标
        clientPoint := Buffer(8, 0)
        NumPut("Int", 0, clientPoint, 0)
        NumPut("Int", 0, clientPoint, 4)
        DllCall("ClientToScreen", "Ptr", WinID, "Ptr", clientPoint)
        clientX := NumGet(clientPoint, 0, "Int")
        clientY := NumGet(clientPoint, 4, "Int")

        ; 在客户区域的多个位置采样背景颜色（避开可能有文件的区域）
        samplePoints := [{ x: clientX + clientW - 30, y: clientY + clientH - 30 }],   ; 右下角
        { x: clientX + clientW - 60, y: clientY + clientH - 60 },   ; 右下角偏上
        { x: clientX + clientW - 30, y: clientY + clientH - 100 },  ; 右边中下
        { x: clientX + clientW - 100, y: clientY + clientH - 30 },  ; 下边中右
        { x: clientX + clientW * 0.9, y: clientY + clientH * 0.9 }  ; 右下区域中心]

        colors := []
        validColors := []

        for point in samplePoints {
            if (point.x > clientX && point.y > clientY &&
                point.x < clientX + clientW && point.y < clientY + clientH) {
                color := PixelGetColor(point.x, point.y)
                colors.Push(color)

                ; 过滤掉明显不是背景色的颜色（太暗或太亮的边界色）
                r := (color >> 16) & 0xFF
                g := (color >> 8) & 0xFF
                b := color & 0xFF
                brightness := (r + g + b) / 3

                ; 背景色通常是中等亮度的白色或灰色
                if (brightness > 200 || (brightness > 150 && r = g && g = b)) {
                    validColors.Push(color)
                }
            }
        }

        ; 优先返回有效的背景色，否则返回第一个采样色
        if (validColors.Length > 0) {
            return validColors[1]
        } else if (colors.Length > 0) {
            return colors[1]
        }
    }

    ; 如果获取失败，返回常见的资源管理器背景色
    return 0xFFFFFF  ; 白色
}

; 使用 UIA 检测鼠标位置的元素（统一处理桌面、任务栏、资源管理器）
DetectBlankAreaByUIA(x, y, WinID, WinClass) {
    try {
        ; 使用 UIA 获取鼠标位置的元素
        element := UIA.ElementFromPoint(x, y)

        if (!element) {
            ; 如果没有获取到元素，认为是空白区域
            if (EverythingConfig.show_debug_info) {
                ToolTip("UIA检测: 未获取到元素，判断为空白区域", x + 10, y + 50)
                SetTimer(() => ToolTip(), -3000)
            }
            return true
        }

        ; 获取元素的名称和类型
        elementName := ""
        elementType := ""

        try {
            elementName := element.Name
        }
        try {
            elementType := UIA.Type[element.Type]
        }

        ; 根据不同窗口类型和实际测试结果判断
        isBlankArea := false

        if (WinClass = "Progman" || WinClass = "WorkerW") {
            ; 桌面：选中状态元素类型为 ListItem，空白区域为 List
            if (elementType = "List") {
                isBlankArea := true
            } else if (elementType = "ListItem") {
                isBlankArea := false
            } else {
                ; 其他情况根据名称判断
                if (elementName = "桌面" || elementName = "Desktop" || elementName = "" ||
                    InStr(elementName, "桌面") || InStr(elementName, "Desktop")) {
                    isBlankArea := true
                }
            }
        } else if (WinClass = "Shell_TrayWnd") {
            ; 任务栏：选中状态元素类型为 Pane，空白区域为 TitleBar
            if (elementType = "TitleBar") {
                isBlankArea := true
            } else if (elementType = "Pane") {
                isBlankArea := false
            } else {
                ; 其他情况根据名称判断
                if (elementName = "" || elementName = "任务栏" || elementName = "Taskbar" ||
                    InStr(elementName, "任务栏") || InStr(elementName, "Taskbar")) {
                    isBlankArea := true
                }
            }
        } else if (WinClass = "CabinetWClass" || WinClass = "ExploreWClass") {
            ; 资源管理器：选中文件元素类型为 Edit，空白区域为 List 且名称为 "项目视图"
            if (elementType = "List" && elementName = "项目视图") {
                isBlankArea := true
            } else if (elementType = "Edit" && elementName != "" && elementName != "项目视图") {
                isBlankArea := false
            } else {
                ; 其他情况根据元素类型判断
                if (elementType = "List" || elementType = "Pane" || elementName = "项目视图") {
                    isBlankArea := true
                } else {
                    isBlankArea := false
                }
            }
        }

        ; 调试信息
        if (EverythingConfig.show_debug_info) {
            debugText := "UIA检测:`n"
            debugText .= "窗口类: " . WinClass . "`n"
            debugText .= "元素名称: '" . elementName . "'`n"
            debugText .= "元素类型: '" . elementType . "'`n"
            debugText .= "是空白区域: " . (isBlankArea ? "是" : "否") . "`n"
            debugText .= "应启动Everything: " . (isBlankArea ? "是" : "否")

            ToolTip(debugText, x + 10, y + 50)
            SetTimer(() => ToolTip(), -5000)
        }

        ; 返回 true 表示应该启动 Everything（即是空白区域）
        return isBlankArea

    } catch as e {
        ; UIA 检测失败，回退到颜色检测（仅资源管理器）
        if (EverythingConfig.show_debug_info) {
            ToolTip("UIA检测失败: " . e.message, x + 10, y + 50)
            SetTimer(() => ToolTip(), -3000)
        }
    }
}

; 桌面双击启动Everything - 使用UIA检测空白区域
~LButton::
{
    ; 确保EverythingConfig已初始化并且有必要的属性
    try {
        if (!IsObject(EverythingConfig) || !EverythingConfig.HasOwnProp("enable_double_click")) {
            return
        }
        
        ; 检查是否启用了双击功能
        if (!EverythingConfig.enable_double_click) {
            return
        }
    } catch {
        ; 如果访问EverythingConfig出错，直接返回
        return
    }

    global LTickCount, RTickCount, DblClickTime
    static LastClickTime := 0
    static LastClickPos := ""

    MouseGetPos(&x, &y, &WinID, &Control)
    WinClass := WinGetClass("ahk_id " . WinID)

    ; 获取当前时间和位置
    CurrentTime := A_TickCount
    CurrentPos := x . "," . y

    ; 更严格的双击检测：时间间隔、位置相近、且是连续的LButton事件
    IsDoubleClick := (A_PriorHotKey = "~LButton" &&
        A_TimeSincePriorHotkey < DblClickTime &&
        A_TimeSincePriorHotkey > 50 &&  ; 避免过快的重复触发
        CurrentPos = LastClickPos)      ; 位置必须相同

    ; 更新记录
    LastClickTime := CurrentTime
    LastClickPos := CurrentPos
    LTickCount := CurrentTime

    ; 详细的调试信息（如果启用）
    if (EverythingConfig.show_debug_info) {
        debugInfo := "双击检测调试:`n"
        debugInfo .= "窗口类: " . WinClass . "`n"
        debugInfo .= "控件: " . Control . "`n"
        debugInfo .= "位置: " . x . "," . y . "`n"
        debugInfo .= "是双击: " . (IsDoubleClick ? "是" : "否") . "`n"
        debugInfo .= "时间间隔: " . A_TimeSincePriorHotkey . "ms`n"
        debugInfo .= "双击时间限制: " . DblClickTime . "ms`n"
        debugInfo .= "前一个热键: " . A_PriorHotKey . "`n"

        ToolTip(debugInfo, x + 10, y - 100)
        SetTimer(() => ToolTip(), -2000)
    }

    ; 只有真正的双击才处理
    if (IsDoubleClick && LTickCount > RTickCount) {
        ShouldLaunch := false

        ; 使用统一的 UIA 检测所有目标窗口类型
        if (WinClass = "Progman" || WinClass = "WorkerW") {
            ; 桌面：使用 UIA 检测
            ShouldLaunch := DetectBlankAreaByUIA(x, y, WinID, WinClass)
        }
        else if (WinClass = "Shell_TrayWnd") {
            ; 任务栏：排除系统托盘和时钟区域，使用 UIA 检测
            if (!InStr(Control, "TrayNotifyWnd") && !InStr(Control, "TrayClockWClass")) {
                ShouldLaunch := DetectBlankAreaByUIA(x, y, WinID, WinClass)
            }
        }
        else if (WinClass = "CabinetWClass" || WinClass = "ExploreWClass") {
            ; 资源管理器：使用 UIA 检测是否点击了空白区域
            if (InStr(Control, "DirectUIHWND") || InStr(Control, "SHELLDLL_DefView")) {
                ShouldLaunch := DetectBlankAreaByUIA(x, y, WinID, WinClass)
            }
        }

        ; 最终调试信息（根据配置显示）
        if (EverythingConfig.show_debug_info) {
            finalDebug := "最终检测结果:`n"
            finalDebug .= "窗口类: " . WinClass . "`n"
            finalDebug .= "控件: " . Control . "`n"
            finalDebug .= "应启动: " . (ShouldLaunch ? "是" : "否") . "`n"
            finalDebug .= "实际启动: " . (ShouldLaunch ? "是" : "否")

            ToolTip(finalDebug, x + 10, y + 10)
            SetTimer(() => ToolTip(), -4000)
        }

        ; 启动Everything
        if (ShouldLaunch) {
            Run_Everything()
        }
    }

    ; 更新点击时间
    LTickCount := A_TickCount
}
