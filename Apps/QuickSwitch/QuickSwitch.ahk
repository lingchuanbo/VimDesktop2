#Requires AutoHotkey v2.0
;@Ahk2Exe-SetVersion 1.1
;@Ahk2Exe-SetName QuickSwitch
;@Ahk2Exe-SetDescription 快速切换工具 - 程序窗口切换 + 文件对话框路径切换
;@Ahk2Exe-SetCopyright BoBO

; 包含WindowsTheme库
#Include "../../Lib/WindowsTheme.ahk"

/*
QuickSwitch - 统一的快速切换工具
By: BoBO
功能：
1. 程序窗口切换：显示最近打开的程序，支持置顶显示和快速切换
2. 文件对话框路径切换：在文件对话框中快速切换到文件管理器路径
3. 同一快捷键触发不同菜单：在普通窗口显示程序切换菜单，在文件对话框显示路径切换菜单
4. 性能优化：避免内存泄露，合理管理资源
*/
; ============================================================================
; 初始化
; ============================================================================

#Warn
SendMode("Input")
SetWorkingDir(A_ScriptDir)
#SingleInstance Force

; 全局变量
global g_Config := {}
global g_WindowHistory := []  ; 窗口历史记录
global g_PinnedWindows := []  ; 置顶窗口列表
global g_ExcludedApps := []   ; 排除的应用程序
global g_LastTwoWindows := [] ; 最近两个窗口
global g_MenuItems := []      ; 菜单项数组
global g_MenuActive := false
global g_DarkMode := false    ; 主题状态

; 文件对话框相关变量
global g_CurrentDialog := {
    WinID: "",
    Type: "",
    FingerPrint: "",
    Action: ""
}

; 初始化配置
InitializeConfig()

; 注册热键
RegisterHotkeys()

; 初始化任务栏图标
InitializeTrayIcon()

; 初始化当前打开的程序列表
InitializeCurrentWindows()

; 启动窗口监控
StartWindowMonitoring()

; 主循环
MainLoop()

; ============================================================================
; 配置管理
; ============================================================================

InitializeConfig() {
    ; 获取脚本名称用于配置文件
    SplitPath(A_ScriptFullPath, , , , &name_no_ext)
    g_Config.IniFile := name_no_ext . ".ini"
    g_Config.TempFile := EnvGet("TEMP") . "\dopusinfo.xml"

    ; 如果配置文件不存在，创建默认配置
    if (!FileExist(g_Config.IniFile)) {
        CreateDefaultIniFile()
    }

    ; 加载配置
    LoadConfiguration()

    ; 清理临时文件
    try FileDelete(g_Config.TempFile)
}

CreateDefaultIniFile() {
    try {
        ; 基本设置
        IniWrite("^q", g_Config.IniFile, "Settings", "MainHotkey")
        IniWrite("^Tab", g_Config.IniFile, "Settings", "QuickSwitchHotkey")
        IniWrite("10", g_Config.IniFile, "Settings", "MaxHistoryCount")
        IniWrite("1", g_Config.IniFile, "Settings", "EnableQuickAccess")
        IniWrite("123456789abcdefghijklmnopqrstuvwxyz", g_Config.IniFile, "Settings", "QuickAccessKeys")
        IniWrite("0", g_Config.IniFile, "Settings", "RunMode")

        ; 显示设置
        IniWrite("C0C59C", g_Config.IniFile, "Display", "MenuColor")
        IniWrite("16", g_Config.IniFile, "Display", "IconSize")
        IniWrite("1", g_Config.IniFile, "Display", "ShowWindowTitle")
        IniWrite("1", g_Config.IniFile, "Display", "ShowProcessName")

        ; 程序切换菜单位置设置
        IniWrite("mouse", g_Config.IniFile, "WindowSwitchMenu", "Position")
        IniWrite("100", g_Config.IniFile, "WindowSwitchMenu", "FixedPosX")
        IniWrite("100", g_Config.IniFile, "WindowSwitchMenu", "FixedPosY")

        ; 路径切换菜单位置设置
        IniWrite("mouse", g_Config.IniFile, "PathSwitchMenu", "Position")
        IniWrite("200", g_Config.IniFile, "PathSwitchMenu", "FixedPosX")
        IniWrite("200", g_Config.IniFile, "PathSwitchMenu", "FixedPosY")

        ; 文件管理器设置
        IniWrite("1", g_Config.IniFile, "FileManagers", "TotalCommander")
        IniWrite("1", g_Config.IniFile, "FileManagers", "Explorer")
        IniWrite("1", g_Config.IniFile, "FileManagers", "XYplorer")
        IniWrite("1", g_Config.IniFile, "FileManagers", "DirectoryOpus")

        ; 自定义路径设置
        IniWrite("1", g_Config.IniFile, "CustomPaths", "EnableCustomPaths")
        IniWrite("收藏路径", g_Config.IniFile, "CustomPaths", "MenuTitle")
        IniWrite("桌面|%USERPROFILE%\Desktop", g_Config.IniFile, "CustomPaths", "Path1")
        IniWrite("文档|%USERPROFILE%\Documents", g_Config.IniFile, "CustomPaths", "Path2")
        IniWrite("下载|%USERPROFILE%\Downloads", g_Config.IniFile, "CustomPaths", "Path3")

        ; 最近路径设置
        IniWrite("1", g_Config.IniFile, "RecentPaths", "EnableRecentPaths")
        IniWrite("最近打开", g_Config.IniFile, "RecentPaths", "MenuTitle")
        IniWrite("10", g_Config.IniFile, "RecentPaths", "MaxRecentPaths")

        ; 排除的程序
        IniWrite("explorer.exe", g_Config.IniFile, "ExcludedApps", "App1")
        IniWrite("dwm.exe", g_Config.IniFile, "ExcludedApps", "App2")
        IniWrite("winlogon.exe", g_Config.IniFile, "ExcludedApps", "App3")
        IniWrite("csrss.exe", g_Config.IniFile, "ExcludedApps", "App4")

        ; 置顶程序示例
        IniWrite("notepad.exe", g_Config.IniFile, "PinnedApps", "App1")
        IniWrite("chrome.exe", g_Config.IniFile, "PinnedApps", "App2")

        ; Total Commander 消息代码
        IniWrite("2029", g_Config.IniFile, "TotalCommander", "CopySrcPath")
        IniWrite("2030", g_Config.IniFile, "TotalCommander", "CopyTrgPath")

        ; 主题设置
        IniWrite("0", g_Config.IniFile, "Theme", "DarkMode")

        ; 添加配置文件注释
        configComment := "; QuickSwitch 配置文件`n"
            . "; 快速切换工具 - By BoBO`n"
            . "; MainHotkey: 主快捷键，在普通窗口显示程序切换菜单，在文件对话框显示路径切换菜单`n"
            . "; QuickSwitchHotkey: 快速切换最近两个程序的快捷键`n"
            . "; MaxHistoryCount: 最大历史记录数量`n"
            . "; RunMode: 运行模式 - 0=全部运行(智能判断), 1=只运行路径跳转, 2=只运行程序切换`n"
            . "; ExcludedApps: 排除的程序列表`n"
            . "; PinnedApps: 置顶显示的程序列表`n`n"
            . "; Position: mouse鼠标  fixed固定n"


        ; 读取现有内容并在前面添加注释
        existingContent := FileRead(g_Config.IniFile, "UTF-16")
        FileDelete(g_Config.IniFile)
        FileAppend(configComment . existingContent, g_Config.IniFile, "UTF-16")

    } catch as e {
        MsgBox("创建配置文件失败: " . e.message, "错误", "T5")
    }
}

LoadConfiguration() {
    global g_DarkMode
    ; 加载基本设置
    g_Config.MainHotkey := IniRead(g_Config.IniFile, "Settings", "MainHotkey", "^q")
    g_Config.QuickSwitchHotkey := IniRead(g_Config.IniFile, "Settings", "QuickSwitchHotkey", "^Tab")
    g_Config.MaxHistoryCount := Integer(IniRead(g_Config.IniFile, "Settings", "MaxHistoryCount", "10"))
    g_Config.EnableQuickAccess := IniRead(g_Config.IniFile, "Settings", "EnableQuickAccess", "1")
    g_Config.QuickAccessKeys := IniRead(g_Config.IniFile, "Settings", "QuickAccessKeys",
        "123456789abcdefghijklmnopqrstuvwxyz")
    g_Config.RunMode := Integer(IniRead(g_Config.IniFile, "Settings", "RunMode", "0"))

    ; 加载显示设置
    g_Config.MenuColor := IniRead(g_Config.IniFile, "Display", "MenuColor", "C0C59C")
    g_Config.IconSize := Integer(IniRead(g_Config.IniFile, "Display", "IconSize", "16"))
    g_Config.ShowWindowTitle := IniRead(g_Config.IniFile, "Display", "ShowWindowTitle", "1")
    g_Config.ShowProcessName := IniRead(g_Config.IniFile, "Display", "ShowProcessName", "1")

    ; 加载程序切换菜单位置设置
    g_Config.WindowSwitchPosition := IniRead(g_Config.IniFile, "WindowSwitchMenu", "Position", "mouse")
    g_Config.WindowSwitchPosX := Integer(IniRead(g_Config.IniFile, "WindowSwitchMenu", "FixedPosX", "100"))
    g_Config.WindowSwitchPosY := Integer(IniRead(g_Config.IniFile, "WindowSwitchMenu", "FixedPosY", "100"))

    ; 加载路径切换菜单位置设置
    g_Config.PathSwitchPosition := IniRead(g_Config.IniFile, "PathSwitchMenu", "Position", "fixed")
    g_Config.PathSwitchPosX := Integer(IniRead(g_Config.IniFile, "PathSwitchMenu", "FixedPosX", "200"))
    g_Config.PathSwitchPosY := Integer(IniRead(g_Config.IniFile, "PathSwitchMenu", "FixedPosY", "200"))

    ; 加载文件管理器设置
    g_Config.SupportTC := IniRead(g_Config.IniFile, "FileManagers", "TotalCommander", "1")
    g_Config.SupportExplorer := IniRead(g_Config.IniFile, "FileManagers", "Explorer", "1")
    g_Config.SupportXY := IniRead(g_Config.IniFile, "FileManagers", "XYplorer", "1")
    g_Config.SupportOpus := IniRead(g_Config.IniFile, "FileManagers", "DirectoryOpus", "1")

    ; 加载自定义路径设置
    g_Config.EnableCustomPaths := IniRead(g_Config.IniFile, "CustomPaths", "EnableCustomPaths", "1")
    g_Config.CustomPathsTitle := IniRead(g_Config.IniFile, "CustomPaths", "MenuTitle", "收藏路径")

    ; 加载最近路径设置
    g_Config.EnableRecentPaths := IniRead(g_Config.IniFile, "RecentPaths", "EnableRecentPaths", "1")
    g_Config.RecentPathsTitle := IniRead(g_Config.IniFile, "RecentPaths", "MenuTitle", "最近打开")
    g_Config.MaxRecentPaths := IniRead(g_Config.IniFile, "RecentPaths", "MaxRecentPaths", "10")

    ; Total Commander 消息代码
    g_Config.TC_CopySrcPath := Integer(IniRead(g_Config.IniFile, "TotalCommander", "CopySrcPath", "2029"))
    g_Config.TC_CopyTrgPath := Integer(IniRead(g_Config.IniFile, "TotalCommander", "CopyTrgPath", "2030"))

    ; 加载主题设置
    g_DarkMode := IniRead(g_Config.IniFile, "Theme", "DarkMode", "0") = "1"

    ; 应用主题设置
    WindowsTheme.SetAppMode(g_DarkMode)

    ; 清空并重新加载排除的程序列表
    g_ExcludedApps.Length := 0
    loop 50 {  ; 支持最多50个排除程序
        appKey := "App" . A_Index
        appValue := IniRead(g_Config.IniFile, "ExcludedApps", appKey, "")
        if (appValue != "") {
            g_ExcludedApps.Push(StrLower(appValue))
        }
    }

    ; 清空并重新加载置顶程序列表
    g_PinnedWindows.Length := 0
    loop 20 {  ; 支持最多20个置顶程序
        appKey := "App" . A_Index
        appValue := IniRead(g_Config.IniFile, "PinnedApps", appKey, "")
        if (appValue != "") {
            g_PinnedWindows.Push(StrLower(appValue))
        }
    }
}
;============================================================================
; 热键注册
; ============================================================================

RegisterHotkeys() {
    try {
        ; 注册主快捷键 - 智能菜单显示
        Hotkey(g_Config.MainHotkey, ShowSmartMenu, "On")

        ; 注册快速切换热键
        Hotkey(g_Config.QuickSwitchHotkey, QuickSwitchLastTwo, "On")

    } catch as e {
        MsgBox("注册热键失败: " . e.message . "`n使用默认热键 Ctrl+Q 和 Ctrl+Tab", "警告", "T5")
        try {
            Hotkey("^q", ShowSmartMenu, "On")
            Hotkey("^Tab", QuickSwitchLastTwo, "On")
        }
    }
}

; ============================================================================
; 任务栏图标管理
; ============================================================================

InitializeTrayIcon() {
    ; 设置任务栏图标
    iconPath := A_ScriptDir . "\icon\fast-forward-1.ico"
    if (FileExist(iconPath)) {
        TraySetIcon(iconPath)
    }

    ; 设置任务栏提示文本
    A_IconTip := "QuickSwitch - 快速切换工具"

    ; 创建任务栏右键菜单
    CreateTrayMenu()
}

CreateTrayMenu() {
    ; 清除默认菜单项
    A_TrayMenu.Delete()

    ; 添加自定义菜单项
    A_TrayMenu.Add("设置", OpenConfigFile)
    A_TrayMenu.Add("切换主题", ToggleThemeFromTray)
    A_TrayMenu.Add()  ; 分隔符
    A_TrayMenu.Add("重启", RestartApplication)
    A_TrayMenu.Add("退出", ExitApplication)

    ; 设置默认菜单项（双击任务栏图标时执行）
    A_TrayMenu.Default := "设置"

    ; 根据当前主题状态设置菜单项显示
    UpdateTrayMenuThemeStatus()
}

UpdateTrayMenuThemeStatus() {
    ; 更新主题菜单项的显示文本
    themeText := g_DarkMode ? "切换主题 (当前: 深色)" : "切换主题 (当前: 浅色)"
    try {
        A_TrayMenu.Rename("切换主题", themeText)
    } catch {
        ; 如果重命名失败，忽略错误
    }
}

; 任务栏菜单处理函数
OpenConfigFile(*) {
    EditConfigFile()
}

ToggleThemeFromTray(*) {
    ToggleTheme()
    ; 更新任务栏菜单显示
    UpdateTrayMenuThemeStatus()
}

RestartApplication(*) {
    ; 显示确认对话框
    result := MsgBox("确定要重启 QuickSwitch 吗？", "重启确认", "YesNo Icon?")
    if (result = "Yes") {
        Reload
    }
}

ExitApplication(*) {
    ; 显示确认对话框
    result := MsgBox("确定要退出 QuickSwitch 吗？", "退出确认", "YesNo Icon?")
    if (result = "Yes") {
        ExitApp
    }
}

; ============================================================================
; 智能菜单显示
; ============================================================================

ShowSmartMenu(*) {
    ; 获取当前活动窗口
    currentWinID := WinExist("A")

    ; 根据运行模式决定显示哪个菜单
    switch g_Config.RunMode {
        case 0:  ; 全部运行 - 智能判断
            ; 检查是否为文件对话框
            if (IsFileDialog(currentWinID)) {
                ; 显示文件对话框路径切换菜单
                ShowFileDialogMenu(currentWinID)
            } else {
                ; 显示程序窗口切换菜单
                ShowWindowSwitchMenu()
            }
        case 1:  ; 只运行路径跳转
            ShowFileDialogMenu(currentWinID)
        case 2:  ; 只运行程序切换
            ShowWindowSwitchMenu()
        default: ; 默认为全部运行
            ; 检查是否为文件对话框
            if (IsFileDialog(currentWinID)) {
                ; 显示文件对话框路径切换菜单
                ShowFileDialogMenu(currentWinID)
            } else {
                ; 显示程序窗口切换菜单
                ShowWindowSwitchMenu()
            }
    }
}

IsFileDialog(winID) {
    try {
        winClass := WinGetClass("ahk_id " . winID)
        exeName := WinGetProcessName("ahk_id " . winID)
        winTitle := WinGetTitle("ahk_id " . winID)

        ; 检查是否为标准文件对话框
        if (winClass = "#32770") {
            return true
        }

        ; 检查是否为Blender文件视图窗口
        if (winClass = "GHOST_WindowClass" and exeName = "blender.exe" and InStr(winTitle, "Blender File View")) {
            return true
        }

        return false
    } catch {
        return false
    }
}

; ============================================================================
; 程序窗口切换功能
; ============================================================================

InitializeCurrentWindows() {
    try {
        ; 获取所有可见窗口
        allWindows := WinGetList()
        windowsInfo := []

        for winID in allWindows {
            try {
                if (!WinExist("ahk_id " . winID)) {
                    continue
                }

                winTitle := WinGetTitle("ahk_id " . winID)
                processName := WinGetProcessName("ahk_id " . winID)

                if (ShouldExcludeWindow(processName, winTitle)) {
                    continue
                }

                if (!IsWindowVisible(winID)) {
                    continue
                }

                windowsInfo.Push({
                    ID: winID,
                    Title: winTitle,
                    ProcessName: processName,
                    Timestamp: A_Now
                })

            } catch {
                continue
            }
        }

        ; 按Z-order顺序添加到历史记录
        loop windowsInfo.Length {
            windowInfo := windowsInfo[windowsInfo.Length - A_Index + 1]
            g_WindowHistory.Push(windowInfo)

            if (g_WindowHistory.Length > g_Config.MaxHistoryCount) {
                break
            }
        }

        ; 初始化最近两个窗口
        if (g_WindowHistory.Length >= 1) {
            g_LastTwoWindows.Push(g_WindowHistory[1])
        }
        if (g_WindowHistory.Length >= 2) {
            g_LastTwoWindows.Push(g_WindowHistory[2])
        }

    } catch {
        ; 如果初始化失败，继续运行程序
    }
}

StartWindowMonitoring() {
    SetTimer(MonitorActiveWindow, 500)
}

MonitorActiveWindow() {
    static lastActiveWindow := ""

    try {
        currentWindow := WinExist("A")
        if (!currentWindow || currentWindow = lastActiveWindow) {
            return
        }

        winTitle := WinGetTitle("ahk_id " . currentWindow)
        processName := WinGetProcessName("ahk_id " . currentWindow)

        if (ShouldExcludeWindow(processName, winTitle)) {
            return
        }

        UpdateWindowHistory(currentWindow, winTitle, processName)
        lastActiveWindow := currentWindow

    } catch {
        ; 忽略错误，继续监控
    }
}

ShouldExcludeWindow(processName, winTitle) {
    ; 检查是否在排除列表中
    for excludedApp in g_ExcludedApps {
        if (InStr(StrLower(processName), excludedApp)) {
            return true
        }
    }

    ; 排除没有标题的窗口
    if (winTitle = "") {
        return true
    }

    ; 排除系统窗口
    if (InStr(winTitle, "Program Manager") || InStr(winTitle, "Task Switching")) {
        return true
    }

    return false
}

IsWindowVisible(winID) {
    try {
        if (!WinExist("ahk_id " . winID)) {
            return false
        }

        style := WinGetStyle("ahk_id " . winID)
        exStyle := WinGetExStyle("ahk_id " . winID)

        ; WS_VISIBLE = 0x10000000
        if (!(style & 0x10000000)) {
            return false
        }

        ; 排除工具窗口
        if (exStyle & 0x80) {
            return false
        }

        ; 检查窗口大小
        WinGetPos(, , &width, &height, "ahk_id " . winID)
        if (width < 50 || height < 50) {
            return false
        }

        return true

    } catch {
        return false
    }
}

UpdateWindowHistory(winID, winTitle, processName) {
    windowInfo := {
        ID: winID,
        Title: winTitle,
        ProcessName: processName,
        Timestamp: A_Now
    }

    ; 检查是否已存在于历史中
    for i, existingWindow in g_WindowHistory {
        if (existingWindow.ID = winID) {
            g_WindowHistory.RemoveAt(i)
            break
        }
    }

    ; 添加到历史记录开头
    g_WindowHistory.InsertAt(1, windowInfo)

    ; 限制历史记录数量
    while (g_WindowHistory.Length > g_Config.MaxHistoryCount) {
        g_WindowHistory.Pop()
    }

    ; 更新最近两个窗口记录
    UpdateLastTwoWindows(windowInfo)
}

UpdateLastTwoWindows(currentWindow) {
    if (g_LastTwoWindows.Length = 0) {
        g_LastTwoWindows.Push(currentWindow)
        return
    }

    if (g_LastTwoWindows[1].ID = currentWindow.ID) {
        return
    }

    if (g_LastTwoWindows.Length >= 2) {
        g_LastTwoWindows.RemoveAt(2)
    }

    g_LastTwoWindows.InsertAt(1, currentWindow)
}

ShowWindowSwitchMenu(*) {
    global g_MenuItems, g_MenuActive

    g_MenuActive := true
    g_MenuItems := []

    ; 创建上下文菜单
    contextMenu := Menu()
    contextMenu.Add("QuickSwitch - 程序切换", (*) => "")
    contextMenu.Default := "QuickSwitch - 程序切换"
    contextMenu.Disable("QuickSwitch - 程序切换")

    hasMenuItems := false

    ; 添加置顶程序
    hasMenuItems := AddPinnedWindows(contextMenu) || hasMenuItems

    ; 添加分隔符
    if (hasMenuItems) {
        contextMenu.Add()
    }

    ; 添加历史窗口
    hasMenuItems := AddHistoryWindows(contextMenu) || hasMenuItems

    ; 添加操作子菜单
    contextMenu.Add()
    AddWindowActionMenus(contextMenu)

    ; 添加设置菜单
    contextMenu.Add()
    AddWindowSettingsMenu(contextMenu)

    ; 配置菜单外观
    contextMenu.Color := g_Config.MenuColor

    ; 根据配置显示菜单 - 程序切换菜单
    if (g_Config.WindowSwitchPosition = "mouse") {
        ; 在鼠标位置显示
        MouseGetPos(&mouseX, &mouseY)
        try {
            contextMenu.Show(mouseX, mouseY)
        } catch {
            contextMenu.Show(100, 100)
        }
    } else {
        ; 在固定位置显示
        try {
            contextMenu.Show(g_Config.WindowSwitchPosX, g_Config.WindowSwitchPosY)
        } catch {
            contextMenu.Show(100, 100)
        }
    }

    SetTimer(() => g_MenuActive := false, -100)
}

AddPinnedWindows(contextMenu) {
    added := false
    allWindows := WinGetList()

    for winID in allWindows {
        try {
            processName := WinGetProcessName("ahk_id " . winID)
            winTitle := WinGetTitle("ahk_id " . winID)

            if (IsPinnedApp(processName) && !ShouldExcludeWindow(processName, winTitle)) {
                displayText := CreateDisplayText(winTitle, processName)
                AddWindowMenuItemWithQuickAccess(contextMenu, displayText, WindowChoiceHandler.Bind(winID), processName,
                true)
                added := true
            }
        } catch {
            continue
        }
    }

    return added
}

AddHistoryWindows(contextMenu) {
    added := false

    for windowInfo in g_WindowHistory {
        try {
            if (!WinExist("ahk_id " . windowInfo.ID)) {
                continue
            }

            if (IsPinnedApp(windowInfo.ProcessName)) {
                continue
            }

            displayText := CreateDisplayText(windowInfo.Title, windowInfo.ProcessName)
            AddWindowMenuItemWithQuickAccess(contextMenu, displayText, WindowChoiceHandler.Bind(windowInfo.ID),
            windowInfo.ProcessName)
            added := true

        } catch {
            continue
        }
    }

    return added
}

AddWindowActionMenus(contextMenu) {
    ; 创建关闭程序子菜单
    closeMenu := Menu()
    closeMenuAdded := false

    ; 创建置顶程序子菜单
    pinnedMenu := Menu()
    pinnedMenuAdded := false

    ; 创建取消置顶程序子菜单
    unpinnedMenu := Menu()
    unpinnedMenuAdded := false

    for windowInfo in g_WindowHistory {
        try {
            if (!WinExist("ahk_id " . windowInfo.ID)) {
                continue
            }

            displayText := CreateDisplayText(windowInfo.Title, windowInfo.ProcessName)

            ; 添加到关闭菜单
            closeMenu.Add(displayText, CloseAppHandler.Bind(windowInfo.ProcessName, windowInfo.ID))
            try {
                closeMenu.SetIcon(displayText, GetProcessIcon(windowInfo.ProcessName), , g_Config.IconSize)
            }
            closeMenuAdded := true

            ; 如果不是置顶程序，添加到置顶菜单
            if (!IsPinnedApp(windowInfo.ProcessName)) {
                pinnedMenu.Add(displayText, AddToPinnedHandler.Bind(windowInfo.ProcessName))
                try {
                    pinnedMenu.SetIcon(displayText, GetProcessIcon(windowInfo.ProcessName), , g_Config.IconSize)
                }
                pinnedMenuAdded := true
            } else {
                ; 如果是置顶程序，添加到取消置顶菜单
                unpinnedMenu.Add(displayText, RemoveFromPinnedHandler.Bind(windowInfo.ProcessName))
                try {
                    unpinnedMenu.SetIcon(displayText, GetProcessIcon(windowInfo.ProcessName), , g_Config.IconSize)
                }
                unpinnedMenuAdded := true
            }

        } catch {
            continue
        }
    }

    if (closeMenuAdded) {
        contextMenu.Add("关闭程序", closeMenu)
    }

    if (pinnedMenuAdded) {
        contextMenu.Add("添加置顶", pinnedMenu)
    }

    if (unpinnedMenuAdded) {
        contextMenu.Add("取消置顶", unpinnedMenu)
    }
}

AddWindowSettingsMenu(contextMenu) {
    settingsMenu := Menu()

    ; 添加运行模式子菜单
    runModeMenu := Menu()
    runModeMenu.Add("全部运行", SetRunMode.Bind(0))
    runModeMenu.Add("只运行路径跳转", SetRunMode.Bind(1))
    runModeMenu.Add("只运行程序切换", SetRunMode.Bind(2))

    ; 根据当前运行模式设置选中状态
    switch g_Config.RunMode {
        case 0:
            runModeMenu.Check("全部运行")
        case 1:
            runModeMenu.Check("只运行路径跳转")
        case 2:
            runModeMenu.Check("只运行程序切换")
    }

    settingsMenu.Add("运行模式", runModeMenu)
    settingsMenu.Add("切换主题", ToggleTheme)
    settingsMenu.Add()
    settingsMenu.Add("编辑配置文件", EditConfigFile)
    settingsMenu.Add("重新加载配置", ReloadConfig)
    settingsMenu.Add("关于程序", ShowAbout)

    ; 根据当前主题状态设置菜单项显示
    if (g_DarkMode) {
        settingsMenu.Check("切换主题")
    }

    contextMenu.Add("设置", settingsMenu)
}

AddWindowMenuItemWithQuickAccess(contextMenu, displayText, handler, processName, isPinned := false) {
    g_MenuItems.Push({ Handler: handler, Text: displayText })

    finalDisplayText := displayText
    if (g_Config.EnableQuickAccess = "1" && g_MenuItems.Length <= StrLen(g_Config.QuickAccessKeys)) {
        shortcutKey := SubStr(g_Config.QuickAccessKeys, g_MenuItems.Length, 1)
        finalDisplayText := "[" "&" . shortcutKey . "] " . displayText
    }

    if (isPinned) {
        finalDisplayText := finalDisplayText " 📌"
    }

    contextMenu.Add(finalDisplayText, handler)

    try {
        iconPath := GetProcessIcon(processName)
        contextMenu.SetIcon(finalDisplayText, iconPath, , g_Config.IconSize)
    }
}

IsPinnedApp(processName) {
    for pinnedApp in g_PinnedWindows {
        if (InStr(StrLower(processName), pinnedApp)) {
            return true
        }
    }
    return false
}

CreateDisplayText(winTitle, processName) {
    displayText := ""

    if (g_Config.ShowWindowTitle = "1" && g_Config.ShowProcessName = "1") {
        shortTitle := StrLen(winTitle) > 50 ? SubStr(winTitle, 1, 47) . "..." : winTitle
        displayText := shortTitle . " [" . processName . "]"
    } else if (g_Config.ShowWindowTitle = "1") {
        displayText := StrLen(winTitle) > 60 ? SubStr(winTitle, 1, 57) . "..." : winTitle
    } else if (g_Config.ShowProcessName = "1") {
        displayText := processName
    } else {
        displayText := winTitle
    }

    return displayText
}

GetProcessIcon(processName) {
    try {
        allWindows := WinGetList()
        for winID in allWindows {
            try {
                if (WinGetProcessName("ahk_id " . winID) = processName) {
                    pid := WinGetPID("ahk_id " . winID)
                    return GetModuleFileName(pid)
                }
            }
        }
    }

    return "shell32.dll"
}

QuickSwitchLastTwo(*) {
    if (g_LastTwoWindows.Length < 2) {
        return
    }

    try {
        currentWindow := WinExist("A")

        if (currentWindow = g_LastTwoWindows[1].ID) {
            targetWindow := g_LastTwoWindows[2]
        } else {
            targetWindow := g_LastTwoWindows[1]
        }

        WinActivate("ahk_id " . targetWindow.ID)
        WinShow("ahk_id " . targetWindow.ID)

        if (WinGetMinMax("ahk_id " . targetWindow.ID) = -1) {
            WinRestore("ahk_id " . targetWindow.ID)
        }

    } catch {
        ShowWindowSwitchMenu()
    }
}

WindowChoiceHandler(winID, *) {
    try {
        WinActivate("ahk_id " . winID)
        WinShow("ahk_id " . winID)

        if (WinGetMinMax("ahk_id " . winID) = -1) {
            WinRestore("ahk_id " . winID)
        }

    } catch as e {
        MsgBox("无法激活窗口: " . e.message, "错误", "T3")
    }
}

CloseAppHandler(processName, winID, *) {
    try {
        WinClose("ahk_id " . winID)
        MsgBox("程序已关闭: " . processName, "信息", "T2")
    } catch as e {
        MsgBox("关闭程序失败: " . e.message, "错误", "T3")
    }
}

AddToPinnedHandler(processName, *) {
    try {
        if (IsPinnedApp(processName)) {
            MsgBox("程序已在置顶列表中: " . processName, "信息", "T2")
            return
        }

        g_PinnedWindows.Push(StrLower(processName))
        SavePinnedAppToIni(processName)
        MsgBox("已添加到置顶列表: " . processName, "信息", "T2")

    } catch as e {
        MsgBox("添加到置顶失败: " . e.message, "错误", "T3")
    }
}

SavePinnedAppToIni(processName) {
    try {
        loop 20 {
            appKey := "App" . A_Index
            existingValue := IniRead(g_Config.IniFile, "PinnedApps", appKey, "")
            if (existingValue = "") {
                IniWrite(processName, g_Config.IniFile, "PinnedApps", appKey)
                break
            }
        }
    } catch {
        ; 忽略保存错误
    }
}

RemoveFromPinnedHandler(processName, *) {
    try {
        if (!IsPinnedApp(processName)) {
            MsgBox("程序不在置顶列表中: " . processName, "信息", "T2")
            return
        }

        ; 从内存中的置顶列表移除
        for i, pinnedApp in g_PinnedWindows {
            if (InStr(StrLower(processName), pinnedApp)) {
                g_PinnedWindows.RemoveAt(i)
                break
            }
        }

        ; 从配置文件中移除
        RemovePinnedAppFromIni(processName)
        MsgBox("已从置顶列表移除: " . processName, "信息", "T2")

    } catch as e {
        MsgBox("取消置顶失败: " . e.message, "错误", "T3")
    }
}

RemovePinnedAppFromIni(processName) {
    try {
        ; 查找并删除匹配的置顶程序
        loop 20 {
            appKey := "App" . A_Index
            existingValue := IniRead(g_Config.IniFile, "PinnedApps", appKey, "")
            if (existingValue != "" && StrLower(existingValue) = StrLower(processName)) {
                IniDelete(g_Config.IniFile, "PinnedApps", appKey)

                ; 重新整理配置文件中的置顶程序列表，填补空缺
                ReorganizePinnedAppsInIni()
                break
            }
        }
    } catch {
        ; 忽略保存错误
    }
}

ReorganizePinnedAppsInIni() {
    try {
        ; 读取所有现有的置顶程序
        existingApps := []
        loop 20 {
            appKey := "App" . A_Index
            appValue := IniRead(g_Config.IniFile, "PinnedApps", appKey, "")
            if (appValue != "") {
                existingApps.Push(appValue)
            }
            ; 清除现有条目
            IniDelete(g_Config.IniFile, "PinnedApps", appKey)
        }

        ; 重新写入，确保连续编号
        for i, appValue in existingApps {
            appKey := "App" . i
            IniWrite(appValue, g_Config.IniFile, "PinnedApps", appKey)
        }
    } catch {
        ; 忽略重组错误
    }
}
; ============================================================================
; 文件对话框路径切换功能
; ============================================================================

ShowFileDialogMenu(winID) {
    global g_MenuItems, g_MenuActive

    ; 设置当前对话框信息
    g_CurrentDialog.WinID := winID
    g_CurrentDialog.Type := DetectFileDialog(winID)

    if (!g_CurrentDialog.Type) {
        ; 如果不是有效的文件对话框，显示程序切换菜单
        ShowWindowSwitchMenu()
        return
    }

    ; 获取对话框指纹
    ahk_exe := WinGetProcessName("ahk_id " . winID)
    window_title := WinGetTitle("ahk_id " . winID)
    g_CurrentDialog.FingerPrint := ahk_exe . "___" . window_title
    g_CurrentDialog.Action := IniRead(g_Config.IniFile, "Dialogs", g_CurrentDialog.FingerPrint, "")

    ; 检查是否为自动切换模式
    if (g_CurrentDialog.Action = "1") {
        folderPath := GetActiveFileManagerFolder(winID)
        if IsValidFolder(folderPath) {
            RecordRecentPath(folderPath)
            FeedDialog(winID, folderPath, g_CurrentDialog.Type)
            return
        }
    }

    ; 显示文件对话框菜单
    g_MenuActive := true
    g_MenuItems := []

    contextMenu := Menu()
    contextMenu.Add("QuickSwitch - 路径切换", (*) => "")
    contextMenu.Default := "QuickSwitch - 路径切换"
    contextMenu.Disable("QuickSwitch - 路径切换")

    hasMenuItems := false

    ; 扫描文件管理器窗口
    if g_Config.SupportTC = "1" {
        hasMenuItems := AddTotalCommanderFolders(contextMenu) || hasMenuItems
    }
    if g_Config.SupportExplorer = "1" {
        hasMenuItems := AddExplorerFolders(contextMenu) || hasMenuItems
    }
    if g_Config.SupportXY = "1" {
        hasMenuItems := AddXYplorerFolders(contextMenu) || hasMenuItems
    }
    if g_Config.SupportOpus = "1" {
        hasMenuItems := AddOpusFolders(contextMenu) || hasMenuItems
    }

    ; 添加自定义路径
    if g_Config.EnableCustomPaths = "1" {
        hasMenuItems := AddCustomPaths(contextMenu) || hasMenuItems
    }

    ; 添加最近路径
    if g_Config.EnableRecentPaths = "1" {
        hasMenuItems := AddRecentPaths(contextMenu) || hasMenuItems
    }

    ; 添加发送到文件管理器选项
    AddSendToFileManagerMenu(contextMenu)

    ; 添加设置菜单
    AddFileDialogSettingsMenu(contextMenu)

    ; 配置菜单外观
    contextMenu.Color := g_Config.MenuColor

    ; 根据配置显示菜单 - 路径切换菜单
    if (g_Config.PathSwitchPosition = "mouse") {
        ; 在鼠标位置显示
        MouseGetPos(&mouseX, &mouseY)
        try {
            contextMenu.Show(mouseX, mouseY)
        } catch {
            contextMenu.Show(200, 200)
        }
    } else {
        ; 在固定位置显示
        try {
            contextMenu.Show(g_Config.PathSwitchPosX, g_Config.PathSwitchPosY)
        } catch {
            contextMenu.Show(200, 200)
        }
    }

    SetTimer(() => g_MenuActive := false, -100)
}

DetectFileDialog(winID) {
    winClass := WinGetClass("ahk_id " . winID)

    ; 直接识别Blender窗口
    if (winClass = "GHOST_WindowClass") {
        return "GENERAL"
    }

    controlList := WinGetControls("ahk_id " . winID)

    hasSysListView := false
    hasToolbar := false
    hasDirectUI := false
    hasEdit := false

    for control in controlList {
        switch control {
            case "SysListView321":
                hasSysListView := true
            case "ToolbarWindow321":
                hasToolbar := true
            case "DirectUIHWND1":
                hasDirectUI := true
            case "Edit1":
                hasEdit := true
        }
    }

    if (hasDirectUI && hasToolbar && hasEdit) {
        return "GENERAL"
    } else if (hasSysListView && hasToolbar && hasEdit) {
        return "SYSLISTVIEW"
    }
    return false
}

GetActiveFileManagerFolder(winID) {
    allWindows := WinGetList()
    fileManagerCandidates := []

    for id in allWindows {
        try {
            winClass := WinGetClass("ahk_id " . id)

            if (g_Config.SupportTC = "1" && winClass = "TTOTAL_CMD") {
                folderPath := GetTCActiveFolder(id)
                if IsValidFolder(folderPath) {
                    fileManagerCandidates.Push({ id: id, path: folderPath, type: "TC" })
                }
            }
            else if (g_Config.SupportExplorer = "1" && winClass = "CabinetWClass") {
                for explorerWindow in ComObject("Shell.Application").Windows {
                    try {
                        if (id = explorerWindow.hwnd) {
                            explorerPath := explorerWindow.Document.Folder.Self.Path
                            if IsValidFolder(explorerPath) {
                                fileManagerCandidates.Push({ id: id, path: explorerPath, type: "Explorer" })
                            }
                        }
                    } catch {
                        continue
                    }
                }
            }
            else if (g_Config.SupportXY = "1" && winClass = "ThunderRT6FormDC") {
                folderPath := GetXYActiveFolder(id)
                if IsValidFolder(folderPath) {
                    fileManagerCandidates.Push({ id: id, path: folderPath, type: "XY" })
                }
            }
            else if (g_Config.SupportOpus = "1" && winClass = "dopus.lister") {
                folderPath := GetOpusActiveFolder(id)
                if IsValidFolder(folderPath) {
                    fileManagerCandidates.Push({ id: id, path: folderPath, type: "Opus" })
                }
            }
        } catch {
            continue
        }
    }

    if (fileManagerCandidates.Length = 0) {
        return ""
    }

    if (fileManagerCandidates.Length = 1) {
        return fileManagerCandidates[1].path
    }

    return fileManagerCandidates[1].path
}

GetTCActiveFolder(winID) {
    clipSaved := ClipboardAll()
    A_Clipboard := ""

    try {
        PostMessage(1075, g_Config.TC_CopySrcPath, 0, , "ahk_id " . winID)

        if ClipWait(1) {
            if (A_Clipboard != "") {
                folderPath := A_Clipboard
                A_Clipboard := clipSaved
                return folderPath
            }
        }
    } catch {
        ; 忽略错误，继续尝试其他方法
    }

    A_Clipboard := ""
    try {
        PostMessage(1075, g_Config.TC_CopyTrgPath, 0, , "ahk_id " . winID)

        if ClipWait(1) {
            if (A_Clipboard != "") {
                folderPath := A_Clipboard
                A_Clipboard := clipSaved
                return folderPath
            }
        }
    } catch {
        ; 忽略错误
    }

    A_Clipboard := clipSaved
    return ""
}

GetXYActiveFolder(winID) {
    clipSaved := ClipboardAll()
    A_Clipboard := ""

    SendXYplorerMessage(winID, "::copytext get('path', a);")
    ClipWait(0)

    result := A_Clipboard
    A_Clipboard := clipSaved
    return result
}

GetOpusActiveFolder(winID) {
    thisPID := WinGetPID("ahk_id " . winID)
    dopusExe := GetModuleFileName(thisPID)

    RunWait('"' . dopusExe . '\..\dopusrt.exe" /info "' . g_Config.TempFile . '",paths', , , &dummy)
    Sleep(100)

    try {
        opusInfo := FileRead(g_Config.TempFile)
        FileDelete(g_Config.TempFile)

        if RegExMatch(opusInfo, 'lister="' . winID . '".*tab_state="1".*>(.*)</path>', &match) {
            return match[1]
        }
    }

    return ""
}

FeedDialog(winID, folderPath, dialogType) {
    try {
        exeName := WinGetProcessName("ahk_id " . winID)
        winTitle := WinGetTitle("ahk_id " . winID)
        if (exeName = "blender.exe" && InStr(winTitle, "Blender File View")) {
            FeedDialogGeneral(winID, folderPath)
            return
        }
    } catch {
        ; 如果检测失败，继续使用通用方法
    }

    switch dialogType {
        case "GENERAL":
            FeedDialogGeneral(winID, folderPath)
        case "SYSLISTVIEW":
            FeedDialogSysListView(winID, folderPath)
    }
}

FeedDialogGeneral(winID, folderPath) {
    WinActivate("ahk_id " . winID)
    Sleep(200)

    try {
        oldClipboard := A_Clipboard
        A_Clipboard := folderPath
        ClipWait(1, 0)

        SendInput("^l")
        Sleep(300)
        SendInput("^v")
        Sleep(100)
        SendInput("{Enter}")
        Sleep(500)

        A_Clipboard := oldClipboard

        try ControlFocus("Edit1", "ahk_id " . winID)
        return
    }

    try {
        originalText := ControlGetText("Edit1", "ahk_id " . winID)
        folderWithSlash := RTrim(folderPath, "\") . "\"
        ControlSetText(folderWithSlash, "Edit1", "ahk_id " . winID)
        Sleep(100)
        ControlSend("Edit1", "{Enter}", "ahk_id " . winID)
        Sleep(200)

        if (originalText != "" && !InStr(originalText, "\")) {
            ControlSetText(originalText, "Edit1", "ahk_id " . winID)
        }
        Sleep(200)
    }
}

FeedDialogSysListView(winID, folderPath) {
    WinActivate("ahk_id " . winID)
    Sleep(50)

    try {
        originalText := ControlGetText("Edit1", "ahk_id " . winID)
        folderWithSlash := RTrim(folderPath, "\") . "\"

        ControlSetText(folderWithSlash, "Edit1", "ahk_id " . winID)
        Sleep(100)
        ControlFocus("Edit1", "ahk_id " . winID)
        ControlSend("Edit1", "{Enter}", "ahk_id " . winID)
        Sleep(200)

        if (originalText != "" && !InStr(originalText, "\") && !InStr(originalText, "/")) {
            ControlSetText(originalText, "Edit1", "ahk_id " . winID)
        } else {
            ControlSetText("", "Edit1", "ahk_id " . winID)
        }
    } catch {
        try {
            ControlSetText(folderPath, "Edit1", "ahk_id " . winID)
            ControlSend("Edit1", "{Enter}", "ahk_id " . winID)
        }
    }
    Send("{Enter}")
}

AddTotalCommanderFolders(contextMenu) {
    added := false
    allWindows := WinGetList()

    for winID in allWindows {
        try {
            winClass := WinGetClass("ahk_id " . winID)
            if (winClass = "TTOTAL_CMD") {
                thisPID := WinGetPID("ahk_id " . winID)
                tcExe := GetModuleFileName(thisPID)

                clipSaved := ClipboardAll()
                A_Clipboard := ""

                SendMessage(1075, g_Config.TC_CopySrcPath, 0, , "ahk_id " . winID)
                Sleep(50)
                if (A_Clipboard != "" && IsValidFolder(A_Clipboard)) {
                    folderPath := A_Clipboard
                    AddFileMenuItemWithQuickAccess(contextMenu, folderPath, tcExe, 0)
                    added := true
                }

                SendMessage(1075, g_Config.TC_CopyTrgPath, 0, , "ahk_id " . winID)
                Sleep(50)
                if (A_Clipboard != "" && IsValidFolder(A_Clipboard)) {
                    folderPath := A_Clipboard
                    AddFileMenuItemWithQuickAccess(contextMenu, folderPath, tcExe, 0)
                    added := true
                }

                A_Clipboard := clipSaved
            }
        }
    }

    return added
}

AddExplorerFolders(contextMenu) {
    added := false
    allWindows := WinGetList()

    for winID in allWindows {
        try {
            winClass := WinGetClass("ahk_id " . winID)
            if (winClass = "CabinetWClass") {
                for explorerWindow in ComObject("Shell.Application").Windows {
                    try {
                        if (winID = explorerWindow.hwnd) {
                            explorerPath := explorerWindow.Document.Folder.Self.Path
                            if IsValidFolder(explorerPath) {
                                AddFileMenuItemWithQuickAccess(contextMenu, explorerPath, "shell32.dll", 5)
                                added := true
                            }
                        }
                    }
                }
            }
        }
    }

    return added
}

AddXYplorerFolders(contextMenu) {
    added := false
    allWindows := WinGetList()

    for winID in allWindows {
        try {
            winClass := WinGetClass("ahk_id " . winID)
            if (winClass = "ThunderRT6FormDC") {
                thisPID := WinGetPID("ahk_id " . winID)
                xyExe := GetModuleFileName(thisPID)

                clipSaved := ClipboardAll()
                A_Clipboard := ""

                SendXYplorerMessage(winID, "::copytext get('path', a);")
                if IsValidFolder(A_Clipboard) {
                    folderPath := A_Clipboard
                    AddFileMenuItemWithQuickAccess(contextMenu, folderPath, xyExe, 0)
                    added := true
                }

                SendXYplorerMessage(winID, "::copytext get('path', i);")
                if IsValidFolder(A_Clipboard) {
                    folderPath := A_Clipboard
                    AddFileMenuItemWithQuickAccess(contextMenu, folderPath, xyExe, 0)
                    added := true
                }

                A_Clipboard := clipSaved
            }
        }
    }

    return added
}

AddOpusFolders(contextMenu) {
    added := false
    allWindows := WinGetList()

    for winID in allWindows {
        try {
            winClass := WinGetClass("ahk_id " . winID)
            if (winClass = "dopus.lister") {
                thisPID := WinGetPID("ahk_id " . winID)
                dopusExe := GetModuleFileName(thisPID)

                RunWait('"' . dopusExe . '\..\dopusrt.exe" /info "' . g_Config.TempFile . '",paths', , , &dummy)
                Sleep(100)

                try {
                    opusInfo := FileRead(g_Config.TempFile)
                    FileDelete(g_Config.TempFile)

                    if RegExMatch(opusInfo, 'lister="' . winID . '".*tab_state="1".*>(.*)</path>', &match) {
                        folderPath := match[1]
                        if IsValidFolder(folderPath) {
                            AddFileMenuItemWithQuickAccess(contextMenu, folderPath, dopusExe, 0)
                            added := true
                        }
                    }

                    if RegExMatch(opusInfo, 'lister="' . winID . '".*tab_state="2".*>(.*)</path>', &match) {
                        folderPath := match[1]
                        if IsValidFolder(folderPath) {
                            AddFileMenuItemWithQuickAccess(contextMenu, folderPath, dopusExe, 0)
                            added := true
                        }
                    }
                }
            }
        }
    }

    return added
}

AddCustomPaths(contextMenu) {
    added := false
    customPathsMenu := Menu()
    customPaths := []

    loop 20 {
        pathKey := "Path" . A_Index
        pathValue := IniRead(g_Config.IniFile, "CustomPaths", pathKey, "")

        if (pathValue != "") {
            if InStr(pathValue, "|") {
                parts := StrSplit(pathValue, "|", " `t")
                if (parts.Length >= 2) {
                    displayName := parts[1]
                    actualPath := parts[2]
                } else {
                    displayName := pathValue
                    actualPath := pathValue
                }
            } else {
                SplitPath(pathValue, &folderName)
                displayName := folderName != "" ? folderName : pathValue
                actualPath := pathValue
            }

            expandedPath := ExpandEnvironmentVariables(actualPath)

            if IsValidFolder(expandedPath) {
                customPaths.Push({ display: displayName, path: expandedPath })
                added := true
            }
        }
    }

    if (customPaths.Length > 0) {
        for pathInfo in customPaths {
            customPathsMenu.Add(pathInfo.display, FolderChoiceHandler.Bind(pathInfo.path))
            try customPathsMenu.SetIcon(pathInfo.display, "shell32.dll", 4, g_Config.IconSize)
        }

        contextMenu.Add()
        contextMenu.Add(g_Config.CustomPathsTitle, customPathsMenu)
        try contextMenu.SetIcon(g_Config.CustomPathsTitle, "shell32.dll", 43, g_Config.IconSize)
    }

    return added
}

AddRecentPaths(contextMenu) {
    added := false
    recentPathsMenu := Menu()
    recentPaths := []
    maxPaths := Integer(g_Config.MaxRecentPaths)

    loop maxPaths {
        recentKey := "Recent" . A_Index
        recentValue := IniRead(g_Config.IniFile, "RecentPaths", recentKey, "")

        if (recentValue != "") {
            if InStr(recentValue, "|") {
                parts := StrSplit(recentValue, "|", " `t")
                if (parts.Length >= 2) {
                    pathValue := parts[2]
                } else {
                    pathValue := recentValue
                }
            } else {
                pathValue := recentValue
            }

            if IsValidFolder(pathValue) {
                recentPaths.Push(pathValue)
                added := true
            }
        }
    }

    if (recentPaths.Length > 0) {
        for pathValue in recentPaths {
            recentPathsMenu.Add(pathValue, RecentPathChoiceHandler.Bind(pathValue))
            try recentPathsMenu.SetIcon(pathValue, "shell32.dll", 4, g_Config.IconSize)
        }

        contextMenu.Add()
        contextMenu.Add(g_Config.RecentPathsTitle, recentPathsMenu)
        try contextMenu.SetIcon(g_Config.RecentPathsTitle, "shell32.dll", 269, g_Config.IconSize)
    }

    return added
}

AddSendToFileManagerMenu(contextMenu) {
    currentPath := GetCurrentDialogPath()

    if (currentPath != "") {
        contextMenu.Add()
        contextMenu.Add("发送路径到...", (*) => "")
        contextMenu.Disable("发送路径到...")

        if g_Config.SupportTC = "1" {
            contextMenu.Add("发送到 Total Commander", SendToTCHandler.Bind(currentPath))
            try contextMenu.SetIcon("发送到 Total Commander", "shell32.dll", 5, g_Config.IconSize)
        }

        if g_Config.SupportExplorer = "1" {
            contextMenu.Add("发送到 资源管理器", SendToExplorerHandler.Bind(currentPath))
            try contextMenu.SetIcon("发送到 资源管理器", "shell32.dll", 4, g_Config.IconSize)
        }
    }
}

AddFileDialogSettingsMenu(contextMenu) {
    contextMenu.Add()
    contextMenu.Add("自动跳转", AutoSwitchHandler)
    contextMenu.Add("Not now", NotNowHandler)

    switch g_CurrentDialog.Action {
        case "1":
            contextMenu.Check("自动跳转")
        default:
            contextMenu.Check("Not now")
    }
}

AddFileMenuItemWithQuickAccess(contextMenu, folderPath, iconPath := "", iconIndex := 0) {
    g_MenuItems.Push(folderPath)

    displayText := folderPath
    if g_Config.EnableQuickAccess = "1" && g_MenuItems.Length <= StrLen(g_Config.QuickAccessKeys) {
        shortcutKey := SubStr(g_Config.QuickAccessKeys, g_MenuItems.Length, 1)
        displayText := "[" "&" . shortcutKey . "] " . folderPath
    }

    contextMenu.Add(displayText, FolderChoiceHandler.Bind(folderPath))

    if iconPath != "" {
        try contextMenu.SetIcon(displayText, iconPath, iconIndex, g_Config.IconSize)
    }
}

FolderChoiceHandler(folderPath, *) {
    if IsValidFolder(folderPath) && g_CurrentDialog.WinID != "" {
        RecordRecentPath(folderPath)
        FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
    }
}

RecentPathChoiceHandler(folderPath, *) {
    if IsValidFolder(folderPath) && g_CurrentDialog.WinID != "" {
        RecordRecentPath(folderPath)
        FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
    }
}

AutoSwitchHandler(*) {
    IniWrite("1", g_Config.IniFile, "Dialogs", g_CurrentDialog.FingerPrint)
    g_CurrentDialog.Action := "1"

    folderPath := GetActiveFileManagerFolder(g_CurrentDialog.WinID)

    if IsValidFolder(folderPath) {
        FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
    }
}

NotNowHandler(*) {
    try IniDelete(g_Config.IniFile, "Dialogs", g_CurrentDialog.FingerPrint)
    g_CurrentDialog.Action := ""
}

GetCurrentDialogPath() {
    try {
        winText := WinGetText("ahk_id " . g_CurrentDialog.WinID)
        lines := StrSplit(winText, "`n", "`r")
        for line in lines {
            if RegExMatch(line, "^地址: (.+)", &match) {
                return Trim(match[1])
            }
            if RegExMatch(line, "^Address: (.+)", &match) {
                return Trim(match[1])
            }
            if RegExMatch(line, "^Location: (.+)", &match) {
                return Trim(match[1])
            }
        }

        try {
            editText := ControlGetText("Edit1", "ahk_id " . g_CurrentDialog.WinID)
            if (editText != "" && InStr(editText, "\")) {
                SplitPath(editText, , &dir)
                if IsValidFolder(dir) {
                    return dir
                }
            }
        }

        controlList := WinGetControls("ahk_id " . g_CurrentDialog.WinID)
        for control in controlList {
            if InStr(control, "Edit") {
                try {
                    controlText := ControlGetText(control, "ahk_id " . g_CurrentDialog.WinID)
                    if (controlText != "" && InStr(controlText, "\") && IsValidFolder(controlText)) {
                        return controlText
                    }
                }
            }
        }

    } catch {
        ; 如果所有方法都失败，返回空
    }

    return ""
}

SendToTCHandler(dialogPath, *) {
    try {
        tcWindow := WinExist("ahk_class TTOTAL_CMD")

        if (tcWindow) {
            WinActivate("ahk_class TTOTAL_CMD")
            Sleep(100)

            PostMessage(1075, 3001, 0, , "ahk_class TTOTAL_CMD")
            Sleep(100)

            ControlSetText("cd " . dialogPath, "Edit1", "ahk_class TTOTAL_CMD")
            Sleep(400)
            ControlSend("Edit1", "{Enter}", "ahk_class TTOTAL_CMD")

            RecordRecentPath(dialogPath)
        } else {
            MsgBox("未找到 Total Commander 窗口", "发送路径", "T3")
        }
    } catch as e {
        MsgBox("发送路径到 Total Commander 失败: " . e.message, "错误", "T5")
    }
}

SendToExplorerHandler(dialogPath, *) {
    try {
        Run("explorer.exe `"" . dialogPath . "`"")
        RecordRecentPath(dialogPath)
    } catch as e {
        MsgBox("发送路径到资源管理器失败: " . e.message, "错误", "T5")
    }
}

RecordRecentPath(folderPath) {
    if (!IsValidFolder(folderPath)) {
        return
    }

    maxPaths := Integer(g_Config.MaxRecentPaths)
    currentTime := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    newEntry := currentTime . "|" . folderPath

    existingPaths := []
    loop maxPaths {
        recentKey := "Recent" . A_Index
        recentValue := IniRead(g_Config.IniFile, "RecentPaths", recentKey, "")

        if (recentValue != "") {
            if InStr(recentValue, "|") {
                parts := StrSplit(recentValue, "|", " `t")
                if (parts.Length >= 2) {
                    existingPath := parts[2]
                } else {
                    existingPath := recentValue
                }
            } else {
                existingPath := recentValue
            }

            if (existingPath != folderPath && IsValidFolder(existingPath)) {
                existingPaths.Push(recentValue)
            }
        }
    }

    IniWrite(newEntry, g_Config.IniFile, "RecentPaths", "Recent1")

    entryIndex := 2
    for existingEntry in existingPaths {
        if (entryIndex > maxPaths) {
            break
        }
        IniWrite(existingEntry, g_Config.IniFile, "RecentPaths", "Recent" . entryIndex)
        entryIndex++
    }

    while (entryIndex <= maxPaths) {
        try IniDelete(g_Config.IniFile, "RecentPaths", "Recent" . entryIndex)
        entryIndex++
    }
}
; ============================================================================
; 设置功能
; ============================================================================

EditConfigFile(*) {
    try {
        Run("notepad.exe " . g_Config.IniFile)
    } catch {
        MsgBox("无法打开配置文件", "错误", "T3")
    }
}

ReloadConfig(*) {
    try {
        LoadConfiguration()

        ; 重新注册热键
        try Hotkey(g_Config.MainHotkey, "Off")
        try Hotkey(g_Config.QuickSwitchHotkey, "Off")

        RegisterHotkeys()

        MsgBox("配置已重新加载", "信息", "T2")
    } catch as e {
        MsgBox("重新加载配置失败: " . e.message, "错误", "T3")
    }
}

SetRunMode(mode, *) {
    try {
        ; 更新配置
        g_Config.RunMode := mode

        ; 保存到配置文件
        IniWrite(mode, g_Config.IniFile, "Settings", "RunMode")

        ; 显示提示信息
        modeText := ""
        switch mode {
            case 0:
                modeText := "全部运行 - 智能判断显示菜单"
            case 1:
                modeText := "只运行路径跳转 - 仅显示路径切换菜单"
            case 2:
                modeText := "只运行程序切换 - 仅显示程序切换菜单"
        }

        MsgBox("运行模式已切换到: " . modeText, "运行模式切换", "T3")

    } catch as e {
        MsgBox("切换运行模式失败: " . e.message, "错误", "T3")
    }
}

ShowAbout(*) {
    aboutText := "QuickSwitch v1.1`n"
        . "统一的快速切换工具`n"
        . "作者: BoBO`n`n"
        . "功能特性:`n"
        . "• 程序窗口切换：显示最近打开的程序`n"
        . "• 文件对话框路径切换：快速切换到文件管理器路径`n"
        . "• 智能菜单：同一快捷键触发不同菜单`n"
        . "• 置顶显示重要程序`n"
        . "• 快捷键访问菜单项`n"
        . "• 排除不需要的程序`n"
        . "• 快速切换最近两个程序`n`n"
        . "热键:`n"
        . "• " . g_Config.MainHotkey . " - 智能菜单显示`n"
        . "• " . g_Config.QuickSwitchHotkey . " - 快速切换最近两个程序"

    MsgBox(aboutText, "关于 QuickSwitch", "T10")
}

ToggleTheme(*) {
    global g_DarkMode
    ; 切换主题状态
    g_DarkMode := !g_DarkMode

    ; 应用新主题
    WindowsTheme.SetAppMode(g_DarkMode)

    ; 保存到配置文件
    try {
        IniWrite(g_DarkMode ? "1" : "0", g_Config.IniFile, "Theme", "DarkMode")

        ; 更新任务栏菜单显示
        UpdateTrayMenuThemeStatus()

        ; 显示提示信息
        themeText := g_DarkMode ? "深色主题" : "浅色主题"
        MsgBox("已切换到" . themeText, "主题切换", "T2")
    } catch as e {
        MsgBox("保存主题设置失败: " . e.message, "错误", "T3")
    }
}

; ============================================================================
; 工具函数
; ============================================================================

IsOSSupported() {
    unsupportedOS := ["WIN_VISTA", "WIN_2003", "WIN_XP", "WIN_2000"]
    return !HasValue(unsupportedOS, A_OSVersion)
}

IsValidFolder(path) {
    return (path != "" && StrLen(path) < 259 && InStr(FileExist(path), "D"))
}

ExpandEnvironmentVariables(path) {
    try {
        size := DllCall("ExpandEnvironmentStrings", "Str", path, "Ptr", 0, "UInt", 0)
        if (size > 0) {
            pathBuffer := Buffer(size * 2)
            result := DllCall("ExpandEnvironmentStrings", "Str", path, "Ptr", pathBuffer, "UInt", size)
            if (result > 0) {
                return StrGet(pathBuffer)
            }
        }
    } catch {
        ; 如果扩展失败，返回原始路径
    }
    return path
}

GetModuleFileName(pid) {
    hProcess := DllCall("OpenProcess", "uint", 0x10 | 0x400, "int", false, "uint", pid)
    if (!hProcess) {
        return ""
    }

    nameSize := 255
    name := Buffer(nameSize * 2)

    result := DllCall("psapi.dll\GetModuleFileNameExW", "uint", hProcess, "uint", 0, "ptr", name, "uint", nameSize)
    DllCall("CloseHandle", "ptr", hProcess)

    return result ? StrGet(name) : ""
}

SendXYplorerMessage(xyHwnd, message) {
    size := StrLen(message)
    data := Buffer(size * 2)
    StrPut(message, data, "UTF-16")

    copyData := Buffer(A_PtrSize * 3)
    NumPut("Ptr", 4194305, copyData, 0)
    NumPut("UInt", size * 2, copyData, A_PtrSize)
    NumPut("Ptr", data.Ptr, copyData, A_PtrSize * 2)

    DllCall("User32.dll\SendMessageW", "Ptr", xyHwnd, "UInt", 74, "Ptr", 0, "Ptr", copyData, "Ptr")
}

HasValue(haystack, needle) {
    for value in haystack {
        if (value = needle) {
            return true
        }
    }
    return false
}

; ============================================================================
; 主循环
; ============================================================================

MainLoop() {
    ; 检查操作系统兼容性
    if !IsOSSupported() {
        MsgBox(A_OSVersion . " is not supported.")
        ExitApp()
    }

    ; 主事件循环
    loop {
        Sleep(100)
    }
}
