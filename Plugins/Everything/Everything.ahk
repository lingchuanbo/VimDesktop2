/*
[PluginInfo]
PluginName=Everything
Author= BoBO
Version=1.0
Comment=Everything搜索工具
*/

; 引入 SingleDoubleLongPress.ahk 库
; 引入 Acc.ahk 库用于辅助功能检测 主要判断能否获取acname，还有常规的检测方式，前后颜色变化，如果发生改变则点了图标 没变化就是空白区域
#Include <Acc>

; 读取Everything配置
ReadEverythingConfig() {
    global EverythingConfig := {}

    ; 配置文件路径
    configFile := A_ScriptDir . "\Plugins\Everything\everything.ini"

    ; 默认配置
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

    ; 配置管理
    KeyArray.push({ Key: "cd", Mode: "VIM模式", Group: "配置", Func: "ToggleDoubleClickFeature", Param: "",
        Comment: "切换桌面双击启动功能" })
    KeyArray.push({ Key: "ci", Mode: "VIM模式", Group: "配置", Func: "ToggleDebugInfo", Param: "",
        Comment: "切换调试信息显示" })

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

; 检查是否在空白区域的辅助函数
IsBlankArea(WinClass, Control, WinID) {
    ; 桌面空白区域检测
    if (WinClass = "Progman" || WinClass = "WorkerW") {
        ; 进一步检查是否真的在空白处，而不是桌面图标上
        try {
            ; 获取鼠标下的控件信息
            MouseGetPos(&x, &y, , &ControlUnderMouse, 2)
            ; 如果没有特定控件或者是桌面背景，则认为是空白区域
            if (ControlUnderMouse = "" || ControlUnderMouse = "SysListView321") {
                return true
            }
        }
        return false
    }

    ; 任务栏空白区域检测
    if (WinClass = "Shell_TrayWnd") {
        ; 检查是否在任务栏的空白区域，而不是在按钮上
        if (Control = "MSTaskSwWClass1" || Control = "ReBarWindow321") {
            try {
                ; 获取鼠标位置下的具体控件
                MouseGetPos(&x, &y, , &ControlUnderMouse, 2)
                ; 如果不是按钮控件，则认为是空白区域
                if (!InStr(ControlUnderMouse, "Button") && !InStr(ControlUnderMouse, "ToolbarWindow32")) {
                    return true
                }
            }
        }
        return false
    }

    ; 资源管理器空白区域检测
    if (WinClass = "CabinetWClass" || WinClass = "ExploreWClass") {
        ; 检查是否在文件列表的空白区域
        if (Control = "DirectUIHWND2" || Control = "SHELLDLL_DefView1") {
            try {
                ; 使用更精确的方法检测是否点击在文件/文件夹上
                MouseGetPos(&x, &y, , &ControlUnderMouse, 2)

                ; 发送消息检查鼠标位置是否有项目
                hWnd := WinExist("ahk_id " . WinID)
                if (hWnd) {
                    ; 尝试获取ListView控件
                    try {
                        lvControl := ControlGetHwnd("SysListView321", "ahk_id " . hWnd)
                        if (lvControl) {
                            ; 检查鼠标位置是否有列表项
                            result := DllCall("SendMessage", "Ptr", lvControl, "UInt", 0x1012, "Ptr", 0, "Int64", (y <<
                                32) | (x & 0xFFFFFFFF), "Ptr")
                            if (result = -1) {  ; -1 表示没有项目在该位置
                                return true
                            }
                        }
                    }
                }

                ; 备用检测：如果上述方法失败，使用简单的控件名检测
                if (ControlUnderMouse = "DirectUIHWND2" || ControlUnderMouse = "SHELLDLL_DefView1") {
                    return true
                }
            }
        }
        return false
    }

    return false
}

; 全局变量用于双击检测
LTickCount := 0
RTickCount := 0
DblClickTime := DllCall("GetDoubleClickTime", "UInt") ; 从系统获取双击时间间隔

; 使用Accessibility API获取鼠标下的对象名称
AccUnderMouse(WinID, &child) {
    static h := 0
    if (!h)
        h := DllCall("LoadLibrary", "Str", "oleacc", "Ptr")

    pt := 0
    DllCall("GetCursorPos", "Int64*", &pt)
    pacc := 0
    varChild := Buffer(8 + 2 * A_PtrSize, 0)

    if (DllCall("oleacc\AccessibleObjectFromPoint", "Int64", pt, "Ptr*", &pacc, "Ptr", varChild.ptr) = 0) {
        try {
            ; 在AutoHotkey v2中使用ComValue包装IDispatch接口
            Acc := ComValue(9, pacc, 1)
            if (IsObject(Acc)) {
                child := NumGet(varChild, 8, "UInt")
                return Acc
            }
        } catch {
            ; 如果ComValue失败，尝试使用ComObjActive的替代方法
            try {
                Acc := ComObjActive(pacc)
                if (IsObject(Acc)) {
                    child := NumGet(varChild, 8, "UInt")
                    return Acc
                }
            }
        }
    }
    return ""
}

; 桌面双击启动Everything - 使用Accessibility API检测空白区域
~LButton::
{
    ; 检查是否启用了双击功能
    if (!EverythingConfig.enable_double_click) {
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

    ; 只有真正的双击才处理
    if (IsDoubleClick && LTickCount > RTickCount) {
        ShouldLaunch := false
        AccName := ""

        ; 只在目标窗口类型中检测
        if (WinClass = "Progman" || WinClass = "WorkerW") {
            ; 桌面：使用Accessibility API获取对象名称
            child := 0
            try {
                Acc := AccUnderMouse(WinID, &child)
                if (IsObject(Acc)) {
                    AccName := Acc.accName(child)
                    ; 在桌面空白处，accName通常返回"桌面"或空值
                    ; 如果返回具体文件名，说明点击了图标
                    if (AccName = "桌面" || AccName = "Desktop" || AccName = "" ||
                        InStr(AccName, "桌面") || InStr(AccName, "Desktop") || InStr(AccName, "运行中的应用程序")) {
                        ShouldLaunch := true
                    }
                }
            }
        }
        else if (WinClass = "Shell_TrayWnd") {
            ; 任务栏：排除系统托盘和时钟区域
            if (!InStr(Control, "TrayNotifyWnd") && !InStr(Control, "TrayClockWClass")) {
                child := 0
                try {
                    Acc := AccUnderMouse(WinID, &child)
                    if (IsObject(Acc)) {
                        AccName := Acc.accName(child)
                        ; 任务栏空白处通常返回"任务栏"或相关名称，或者为空
                        if (AccName = "" || AccName = "任务栏" || AccName = "Taskbar" ||
                            InStr(AccName, "运行中的应用程序") || InStr(AccName, "Taskbar")) {
                            ShouldLaunch := true
                        }
                    }
                }
            }
        }
        else if (WinClass = "CabinetWClass" || WinClass = "ExploreWClass") {
            ; 资源管理器：检查是否在文件列表区域
            if (InStr(Control, "DirectUIHWND") || InStr(Control, "SHELLDLL_DefView")) {
                child := 0
                try {
                    Acc := AccUnderMouse(WinID, &child)
                    if (IsObject(Acc)) {
                        AccName := Acc.accName(child)
                        ; 在空白区域时，accName通常为空或返回通用名称
                        ; 如果返回具体文件名（包含扩展名），说明点击了文件
                        if (AccName = "" || InStr(AccName, "项目视图")) {
                            ; (!InStr(AccName, ".") && !RegExMatch(AccName, "\.(txt|doc|pdf|jpg|png|exe|zip|rar)$", "i")||InStr(AccName, "项目视图"))
                            ShouldLaunch := true
                        }
                    }
                }
            }
        }

        ; 调试信息（根据配置显示）
        if (EverythingConfig.show_debug_info) {
            ToolTip("Class: " . WinClass . "`nControl: " . Control .
                "`nAccName: '" . AccName . "'" .
                "`nShouldLaunch: " . ShouldLaunch, x + 10, y + 10)
            SetTimer(() => ToolTip(), -3000)
        }

        ; 启动Everything
        if (ShouldLaunch) {
            Run_Everything()
        }
    }

    ; 更新点击时间
    LTickCount := A_TickCount
}
