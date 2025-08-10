#Requires AutoHotkey v2.0
;@Ahk2Exe-SetVersion 1.0
;@Ahk2Exe-SetName QuickSwitchMuEx
;@Ahk2Exe-SetDescription 快捷切换打开过的程序
;@Ahk2Exe-SetCopyright BoBO

/*
QuickSwitchMuEx - 快捷切换打开过的程序
By: BoBO
功能：
1. 显示最近打开过的程序，排序向上排序
2. 可以设置置顶显示程序
3. 定义菜单条目快捷键
4. 可以设置排除程序
5. 可以快捷关闭程序(Ctrl+右键)
6. 设置快捷键只切换最近2个程序
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
global g_MenuItems := []      ; 菜单项数组
global g_LastTwoWindows := [] ; 最近两个窗口

global g_MenuActive := false

; 初始化配置
InitializeConfig()

; 注册热键
RegisterHotkeys()

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

    ; 如果配置文件不存在，创建默认配置
    if (!FileExist(g_Config.IniFile)) {
        CreateDefaultIniFile()
    }

    ; 加载配置
    LoadConfiguration()
}

CreateDefaultIniFile() {
    try {
        ; 基本设置
        IniWrite("^q", g_Config.IniFile, "Settings", "ShowMenuHotkey")
        IniWrite("^Tab", g_Config.IniFile, "Settings", "QuickSwitchHotkey")
        IniWrite("10", g_Config.IniFile, "Settings", "MaxHistoryCount")
        IniWrite("1", g_Config.IniFile, "Settings", "EnableQuickAccess")
        IniWrite("123456789abcdefghijklmnopqrstuvwxyz", g_Config.IniFile, "Settings", "QuickAccessKeys")

        ; 显示设置
        IniWrite("Default", g_Config.IniFile, "Display", "MenuColor")
        IniWrite("16", g_Config.IniFile, "Display", "IconSize")
        IniWrite("100", g_Config.IniFile, "Display", "MenuPosX")
        IniWrite("100", g_Config.IniFile, "Display", "MenuPosY")
        IniWrite("1", g_Config.IniFile, "Display", "ShowWindowTitle")
        IniWrite("1", g_Config.IniFile, "Display", "ShowProcessName")

        ; 排除的程序
        IniWrite("explorer.exe", g_Config.IniFile, "ExcludedApps", "App1")
        IniWrite("dwm.exe", g_Config.IniFile, "ExcludedApps", "App2")
        IniWrite("winlogon.exe", g_Config.IniFile, "ExcludedApps", "App3")
        IniWrite("csrss.exe", g_Config.IniFile, "ExcludedApps", "App4")

        ; 置顶程序示例
        IniWrite("notepad.exe", g_Config.IniFile, "PinnedApps", "App1")
        IniWrite("chrome.exe", g_Config.IniFile, "PinnedApps", "App2")

        ; 添加配置文件注释
        configComment := "; QuickSwitchMuEx 配置文件`n"
            . "; 快捷切换打开过的程序 - By BoBO`n"
            . "; ShowMenuHotkey: 显示菜单的快捷键`n"
            . "; QuickSwitchHotkey: 快速切换最近两个程序的快捷键`n"
            . "; MaxHistoryCount: 最大历史记录数量`n"
            . "; ExcludedApps: 排除的程序列表`n"
            . "; PinnedApps: 置顶显示的程序列表`n`n"

        ; 读取现有内容并在前面添加注释
        existingContent := FileRead(g_Config.IniFile, "UTF-8")
        FileDelete(g_Config.IniFile)
        FileAppend(configComment . existingContent, g_Config.IniFile, "UTF-8")

    } catch as e {
        MsgBox("创建配置文件失败: " . e.message, "错误", "T5")
    }
}

LoadConfiguration() {
    ; 加载基本设置
    g_Config.ShowMenuHotkey := IniRead(g_Config.IniFile, "Settings", "ShowMenuHotkey", "^q")
    g_Config.QuickSwitchHotkey := IniRead(g_Config.IniFile, "Settings", "QuickSwitchHotkey", "^Tab")
    g_Config.MaxHistoryCount := Integer(IniRead(g_Config.IniFile, "Settings", "MaxHistoryCount", "10"))
    g_Config.EnableQuickAccess := IniRead(g_Config.IniFile, "Settings", "EnableQuickAccess", "1")
    g_Config.QuickAccessKeys := IniRead(g_Config.IniFile, "Settings", "QuickAccessKeys",
        "123456789abcdefghijklmnopqrstuvwxyz")

    ; 加载显示设置
    g_Config.MenuColor := IniRead(g_Config.IniFile, "Display", "MenuColor", "Default")
    g_Config.IconSize := Integer(IniRead(g_Config.IniFile, "Display", "IconSize", "16"))
    g_Config.MenuPosX := Integer(IniRead(g_Config.IniFile, "Display", "MenuPosX", "100"))
    g_Config.MenuPosY := Integer(IniRead(g_Config.IniFile, "Display", "MenuPosY", "100"))
    g_Config.ShowWindowTitle := IniRead(g_Config.IniFile, "Display", "ShowWindowTitle", "1")
    g_Config.ShowProcessName := IniRead(g_Config.IniFile, "Display", "ShowProcessName", "1")

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

; ============================================================================
; 初始化当前窗口
; ============================================================================

InitializeCurrentWindows() {
    try {
        ; 获取所有可见窗口
        allWindows := WinGetList()

        ; 临时存储窗口信息，用于按Z-order排序
        windowsInfo := []

        for winID in allWindows {
            try {
                ; 检查窗口是否可见且不是最小化
                if (!WinExist("ahk_id " . winID)) {
                    continue
                }

                ; 获取窗口信息
                winTitle := WinGetTitle("ahk_id " . winID)
                processName := WinGetProcessName("ahk_id " . winID)

                ; 检查是否应该排除此窗口
                if (ShouldExcludeWindow(processName, winTitle)) {
                    continue
                }

                ; 检查窗口是否可见（不是隐藏窗口）
                if (!IsWindowVisible(winID)) {
                    continue
                }

                ; 添加到临时列表
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

        ; 按Z-order顺序添加到历史记录（最前面的窗口排在前面）
        ; 反向添加，这样最前面的窗口会在历史记录的开头
        loop windowsInfo.Length {
            windowInfo := windowsInfo[windowsInfo.Length - A_Index + 1]

            ; 添加到历史记录
            g_WindowHistory.Push(windowInfo)

            ; 限制历史记录数量
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

IsWindowVisible(winID) {
    try {
        ; 检查窗口是否可见
        if (!WinExist("ahk_id " . winID)) {
            return false
        }

        ; 检查窗口样式
        style := WinGetStyle("ahk_id " . winID)
        exStyle := WinGetExStyle("ahk_id " . winID)

        ; WS_VISIBLE = 0x10000000
        if (!(style & 0x10000000)) {
            return false
        }

        ; 排除工具窗口和其他特殊窗口
        ; WS_EX_TOOLWINDOW = 0x80, WS_EX_NOACTIVATE = 0x8000000
        if (exStyle & 0x80) {
            return false
        }

        ; 检查窗口大小（排除太小的窗口）
        WinGetPos(, , &width, &height, "ahk_id " . winID)
        if (width < 50 || height < 50) {
            return false
        }

        return true

    } catch {
        return false
    }
}

; ============================================================================
; 热键注册
; ============================================================================

RegisterHotkeys() {
    try {
        ; 注册显示菜单热键
        Hotkey(g_Config.ShowMenuHotkey, ShowWindowMenu, "On")

        ; 注册快速切换热键
        Hotkey(g_Config.QuickSwitchHotkey, QuickSwitchLastTwo, "On")

    } catch as e {
        MsgBox("注册热键失败: " . e.message . "`n使用默认热键 Ctrl+Q 和 Ctrl+Tab", "警告", "T5")
        try {
            Hotkey("^q", ShowWindowMenu, "On")
            Hotkey("^Tab", QuickSwitchLastTwo, "On")
        }
    }
}

; ============================================================================
; 窗口监控
; ============================================================================

StartWindowMonitoring() {
    ; 设置窗口事件钩子
    SetTimer(MonitorActiveWindow, 500)
}

MonitorActiveWindow() {
    static lastActiveWindow := ""

    try {
        currentWindow := WinExist("A")
        if (!currentWindow || currentWindow = lastActiveWindow) {
            return
        }

        ; 获取窗口信息
        winTitle := WinGetTitle("ahk_id " . currentWindow)
        processName := WinGetProcessName("ahk_id " . currentWindow)

        ; 检查是否应该排除此窗口
        if (ShouldExcludeWindow(processName, winTitle)) {
            return
        }

        ; 更新窗口历史
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

UpdateWindowHistory(winID, winTitle, processName) {
    ; 创建窗口信息对象
    windowInfo := {
        ID: winID,
        Title: winTitle,
        ProcessName: processName,
        Timestamp: A_Now
    }

    ; 检查是否已存在于历史中
    for i, existingWindow in g_WindowHistory {
        if (existingWindow.ID = winID) {
            ; 移除旧记录
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
    ; 如果是第一个窗口
    if (g_LastTwoWindows.Length = 0) {
        g_LastTwoWindows.Push(currentWindow)
        return
    }

    ; 如果是相同窗口，不更新
    if (g_LastTwoWindows[1].ID = currentWindow.ID) {
        return
    }

    ; 如果已有两个窗口，移除最旧的
    if (g_LastTwoWindows.Length >= 2) {
        g_LastTwoWindows.RemoveAt(2)
    }

    ; 添加当前窗口到开头
    g_LastTwoWindows.InsertAt(1, currentWindow)
}

; ============================================================================
; 菜单显示
; ============================================================================

ShowWindowMenu(*) {
    global g_MenuItems, g_MenuActive

    ; 设置菜单为活动状态
    g_MenuActive := true
    g_MenuItems := []

    ; 创建上下文菜单
    contextMenu := Menu()
    contextMenu.Add("QuickSwitchMuEx - 程序切换", (*) => "")
    contextMenu.Default := "QuickSwitchMuEx - 程序切换"
    contextMenu.Disable("QuickSwitchMuEx - 程序切换")

    hasMenuItems := false

    ; 添加置顶程序（带特殊背景色）
    hasMenuItems := AddPinnedWindowsWithColor(contextMenu) || hasMenuItems

    ; 添加分隔符
    if (hasMenuItems) {
        contextMenu.Add()  ; 分隔符
    }

    ; 添加历史窗口
    hasMenuItems := AddHistoryWindows(contextMenu) || hasMenuItems

    ; 添加操作子菜单
    contextMenu.Add()  ; 分隔符
    AddActionMenus(contextMenu)

    ; 添加设置菜单
    contextMenu.Add()  ; 分隔符
    AddSettingsMenu(contextMenu)

    ; 配置菜单外观
    if (g_Config.MenuColor != "Default") {
        contextMenu.Color := g_Config.MenuColor
    }

    ; 快速访问键由 Windows 菜单系统自动处理（通过 & 符号）

    ; 获取鼠标位置并显示菜单
    MouseGetPos(&mouseX, &mouseY)
    try {
        contextMenu.Show(mouseX, mouseY)
    } catch {
        contextMenu.Show(100, 100)
    }

    ; 设置菜单为非活动状态
    SetTimer(() => g_MenuActive := false, -100)
}

AddPinnedWindows(contextMenu) {
    added := false

    ; 遍历所有窗口，查找置顶程序
    allWindows := WinGetList()

    for winID in allWindows {
        try {
            processName := WinGetProcessName("ahk_id " . winID)
            winTitle := WinGetTitle("ahk_id " . winID)

            ; 检查是否为置顶程序
            if (IsPinnedApp(processName) && !ShouldExcludeWindow(processName, winTitle)) {
                displayText := CreateDisplayText(winTitle, processName)

                ; 添加到菜单（带快速访问键，标记为置顶程序）
                AddMenuItemWithQuickAccess(contextMenu, displayText, WindowChoiceHandler.Bind(winID), processName, true
                )
                added := true
            }
        } catch {
            continue
        }
    }

    return added
}

AddPinnedWindowsWithColor(contextMenu) {
    added := false

    ; 遍历所有窗口，查找置顶程序
    allWindows := WinGetList()

    for winID in allWindows {
        try {
            processName := WinGetProcessName("ahk_id " . winID)
            winTitle := WinGetTitle("ahk_id " . winID)

            ; 检查是否为置顶程序
            if (IsPinnedApp(processName) && !ShouldExcludeWindow(processName, winTitle)) {
                displayText := CreateDisplayText(winTitle, processName)

                ; 直接添加到主菜单（带快速访问键，标记为置顶程序）
                AddMenuItemWithQuickAccess(contextMenu, displayText, WindowChoiceHandler.Bind(winID), processName, true
                )
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
            ; 检查窗口是否仍然存在
            if (!WinExist("ahk_id " . windowInfo.ID)) {
                continue
            }

            ; 跳过置顶程序（已在上面显示）
            if (IsPinnedApp(windowInfo.ProcessName)) {
                continue
            }

            displayText := CreateDisplayText(windowInfo.Title, windowInfo.ProcessName)

            ; 使用快速访问键添加菜单项
            AddMenuItemWithQuickAccess(contextMenu, displayText, WindowChoiceHandler.Bind(windowInfo.ID),
            windowInfo.ProcessName)

            added := true

        } catch {
            continue
        }
    }

    return added
}

AddActionMenus(contextMenu) {
    ; 创建关闭程序子菜单
    closeMenu := Menu()
    closeMenuAdded := false

    ; 创建置顶程序子菜单
    pinnedMenu := Menu()
    pinnedMenuAdded := false

    ; 遍历历史窗口，添加到相应的子菜单
    for windowInfo in g_WindowHistory {
        try {
            ; 检查窗口是否仍然存在
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
            }

        } catch {
            continue
        }
    }

    ; 添加子菜单到主菜单
    if (closeMenuAdded) {
        contextMenu.Add("关闭程序", closeMenu)
    }

    if (pinnedMenuAdded) {
        contextMenu.Add("添加置顶", pinnedMenu)
    }

    ; 不需要额外的操作菜单项，MaxHistoryCount 已经自动管理历史记录数量
}

AddSettingsMenu(contextMenu) {
    ; 添加设置相关菜单项
    settingsMenu := Menu()
    settingsMenu.Add("编辑配置文件", EditConfigFile)
    settingsMenu.Add("重新加载配置", ReloadConfig)
    settingsMenu.Add("关于程序", ShowAbout)

    contextMenu.Add("设置", settingsMenu)
}

; ============================================================================
; 辅助函数
; ============================================================================

AddMenuItemWithQuickAccess(contextMenu, displayText, handler, processName, isPinned := false) {
    ; 添加到快速访问列表
    g_MenuItems.Push({ Handler: handler, Text: displayText })

    ; 创建带快速访问键的显示文本
    finalDisplayText := displayText
    if (g_Config.EnableQuickAccess = "1" && g_MenuItems.Length <= StrLen(g_Config.QuickAccessKeys)) {
        shortcutKey := SubStr(g_Config.QuickAccessKeys, g_MenuItems.Length, 1)
        finalDisplayText := "[" "&" . shortcutKey . "] " . displayText
    }

    ; 为置顶程序添加特殊标识和颜色
    if (isPinned) {
        finalDisplayText := finalDisplayText " 📌"
    }

    ; 添加菜单项
    contextMenu.Add(finalDisplayText, handler)

    ; 设置图标
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

    ; 根据配置决定显示内容
    if (g_Config.ShowWindowTitle = "1" && g_Config.ShowProcessName = "1") {
        ; 限制标题长度
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
    ; 尝试获取进程图标
    try {
        ; 首先尝试从进程路径获取
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

    ; 默认返回通用应用程序图标
    return "shell32.dll"
}

GetModuleFileName(pid) {
    ; 获取进程的完整路径
    try {
        hProcess := DllCall("OpenProcess", "UInt", 0x1000, "Int", false, "UInt", pid, "Ptr")
        if (hProcess) {
            VarSetStrCapacity(&exePath, 260 * 2)
            if (DllCall("psapi\GetModuleFileNameEx", "Ptr", hProcess, "Ptr", 0, "Str", exePath, "UInt", 260)) {
                DllCall("CloseHandle", "Ptr", hProcess)
                return exePath
            }
            DllCall("CloseHandle", "Ptr", hProcess)
        }
    }
    return ""
}

; ============================================================================
; 事件处理
; ============================================================================

WindowChoiceHandler(winID, *) {
    try {
        ; 激活选中的窗口
        WinActivate("ahk_id " . winID)
        WinShow("ahk_id " . winID)

        ; 如果窗口最小化，恢复它
        if (WinGetMinMax("ahk_id " . winID) = -1) {
            WinRestore("ahk_id " . winID)
        }

    } catch as e {
        MsgBox("无法激活窗口: " . e.message, "错误", "T3")
    }
}

QuickSwitchLastTwo(*) {
    ; 快速切换最近两个窗口
    if (g_LastTwoWindows.Length < 2) {
        return
    }

    try {
        ; 获取当前活动窗口
        currentWindow := WinExist("A")

        ; 如果当前窗口是最近的窗口，切换到第二个
        if (currentWindow = g_LastTwoWindows[1].ID) {
            targetWindow := g_LastTwoWindows[2]
        } else {
            targetWindow := g_LastTwoWindows[1]
        }

        ; 激活目标窗口
        WinActivate("ahk_id " . targetWindow.ID)
        WinShow("ahk_id " . targetWindow.ID)

        if (WinGetMinMax("ahk_id " . targetWindow.ID) = -1) {
            WinRestore("ahk_id " . targetWindow.ID)
        }

    } catch {
        ; 如果切换失败，显示菜单
        ShowWindowMenu()
    }
}

CloseAppHandler(processName, winID, *) {
    try {
        ; 关闭程序
        WinClose("ahk_id " . winID)

        MsgBox("程序已关闭: " . processName, "信息", "T2")

    } catch as e {
        MsgBox("关闭程序失败: " . e.message, "错误", "T3")
    }
}

RemoveFromHistoryHandler(winID, *) {
    try {
        ; 从历史记录中移除
        for i, windowInfo in g_WindowHistory {
            if (windowInfo.ID = winID) {
                g_WindowHistory.RemoveAt(i)
                break
            }
        }

        ; 从最近两个窗口记录中移除
        for i, windowInfo in g_LastTwoWindows {
            if (windowInfo.ID = winID) {
                g_LastTwoWindows.RemoveAt(i)
                break
            }
        }

        MsgBox("已从历史记录中移除", "信息", "T2")

    } catch as e {
        MsgBox("移除失败: " . e.message, "错误", "T3")
    }
}

AddToPinnedHandler(processName, *) {
    try {
        ; 检查是否已经在置顶列表中
        if (IsPinnedApp(processName)) {
            MsgBox("程序已在置顶列表中: " . processName, "信息", "T2")
            return
        }

        ; 添加到置顶列表
        g_PinnedWindows.Push(StrLower(processName))

        ; 保存到配置文件
        SavePinnedAppToIni(processName)

        MsgBox("已添加到置顶列表: " . processName, "信息", "T2")

    } catch as e {
        MsgBox("添加到置顶失败: " . e.message, "错误", "T3")
    }
}

SavePinnedAppToIni(processName) {
    try {
        ; 查找空的配置项位置
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
        try Hotkey(g_Config.ShowMenuHotkey, "Off")
        try Hotkey(g_Config.QuickSwitchHotkey, "Off")

        RegisterHotkeys()

        MsgBox("配置已重新加载", "信息", "T2")
    } catch as e {
        MsgBox("重新加载配置失败: " . e.message, "错误", "T3")
    }
}

ShowAbout(*) {
    aboutText := "QuickSwitchMuEx v1.0`n"
        . "快捷切换打开过的程序`n"
        . "作者: BoBO`n`n"
        . "功能特性:`n"
        . "• 显示最近打开的程序`n"
        . "• 置顶显示重要程序`n"
        . "• 快捷键访问菜单项`n"
        . "• 排除不需要的程序`n"
        . "• 快速切换最近两个程序`n`n"
        . "热键:`n"
        . "• " . g_Config.ShowMenuHotkey . " - 显示程序菜单`n"
        . "• " . g_Config.QuickSwitchHotkey . " - 快速切换最近两个程序"

    MsgBox(aboutText, "关于 QuickSwitchMuEx", "T10")
}

; ============================================================================
; 主循环
; ============================================================================

MainLoop() {
    ; 主事件循环
    loop {
        Sleep(100)
    }
}
