#Requires AutoHotkey v2.0
;@Ahk2Exe-SetName QuickSwitch
;@Ahk2Exe-SetDescription 快速切换工具 - 程序窗口切换 + 文件对话框路径切换
;@Ahk2Exe-SetCopyright BoBO

; 包含WindowsTheme库
#Include "Lib/WindowsTheme.ahk"
#Include "Lib/TrayIcon.ahk"
#Include "Lib/UTF8Ini.ahk"
#Include "Lib/ConfigSchema.ahk"
#Include "Lib/RuntimeConfig.ahk"
#Include "Lib/RuntimeLog.ahk"
#Include "Lib/RuntimeMenu.ahk"
#Include "Lib/RuntimeFileDialog.ahk"
#Include "Lib/RuntimeWindowState.ahk"
; 引入 UIA.ahk 库用于UI自动化检测
#Include "Lib/UIA.ahk"

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
global g_MenuLockToken := 0
global g_MenuLockOwner := ""
global g_LastMenuOpenTick := 0
global g_MenuCooldownMs := 150
global g_LastMenuLockRejectTick := 0
global g_LastMenuLockRejectReason := ""
global g_QuickLaunchCache := { enabled: true, maxDisplayCount: 2, apps: [] }
global g_CustomPathsCache := { pinnedPaths: [], normalPaths: [] }
global g_RecentPathsCache := []
global g_AppExecutableCache := Map()
global g_ProcessIconCache := Map()
global g_RuntimeLookupMissCache := { appExe: Map(), processIcon: Map() }
global g_RuntimeLookupMissCooldownMs := 5000
global g_MenuPerfStats := Map()
global g_MenuPerfLastSummaryTick := 0
global g_MenuPerfSummaryIntervalMs := 120000
global g_MenuPerfTopN := 5
global g_MenuPerfMinSamples := 3
global g_LogRetentionDays := 7
global g_LastLogCleanupDate := ""
global g_DarkMode := false    ; 主题状态
global g_LogEnabled := false  ; 日志开关

; 文件对话框相关变量
global g_CurrentDialog := {
    WinID: "",
    Type: "",
    FingerPrint: "",
    Action: ""
}

; 双击检测相关变量
global LTickCount := 0
global RTickCount := 0
global DblClickTime := DllCall("GetDoubleClickTime", "UInt") ; 从系统获取双击时间间隔

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

; 使用 UIA 检测文件对话框中的空白区域
DetectFileDialogBlankAreaByUIA(x, y, WinID, WinClass) {
    try {
        ; 使用 UIA 获取鼠标位置的元素
        element := UIA.ElementFromPoint(x, y)

        if (!element) {
            ; 如果没有获取到元素，认为是空白区域
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

        ; 根据不同窗口类型判断是否为空白区域
        isBlankArea := false

        if (WinClass = "#32770") {
            ; 标准文件对话框：选中文件元素类型为 Edit，空白区域为 List 且名称为 "项目视图"
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
        } else if (WinClass = "GHOST_WindowClass") {
            ; Blender文件视图：根据元素类型和名称判断
            if (elementType = "List" || elementName = "项目视图" || elementName = "") {
                isBlankArea := true
            } else {
                isBlankArea := false
            }
        } else {
            ; 其他文件对话框类型的通用判断
            if (elementType = "List" || elementType = "Pane" || elementName = "项目视图" || elementName = "应用程序控件") {
                isBlankArea := true
            } else {
                isBlankArea := false
            }
        }

        ; 返回 true 表示应该启动功能（即是空白区域）
        return isBlankArea

    } catch as e {
        ; UIA 检测失败，默认返回 false（不启动）
        return false
    }
}

IsActiveRecognizedFileDialog() {
    return GetFileDialogType(WinExist("A")) != ""
}

; 当文件对话框激活时，允许双击触发路径跳转辅助逻辑
#HotIf IsActiveRecognizedFileDialog()
{

    ; 添加双击直接执行 GetWindowsFolderActivePath 函数
    ~LButton:: {
        MouseGetPos(&x, &y) ; 获取鼠标位置信息
        color := PixelGetColor(x, y) ; 获取鼠标位置处的颜色信息
        ; 如果鼠双击同时双击位置处的颜色为白色,则触发后续操作
        if (A_PriorHotKey = "~LButton" && A_TimeSincePriorHotkey < 400) && (color = "0xFFFFFF") {
            GetWindowsFolderActivePath() ; 调用处理函数
        }
        return
    }
}
; ============================================================================
; 配置管理
; ============================================================================
InitializeConfig() {
    ; 获取脚本名称用于配置文件
    SplitPath(A_ScriptFullPath, , , , &name_no_ext)
    g_Config.IniFile := A_ScriptDir . "\" . name_no_ext . ".ini"
    g_Config.TempFile := EnvGet("TEMP") . "\dopusinfo.xml"

    ; 如果配置文件不存在，创建默认配置
    if (!FileExist(g_Config.IniFile)) {
        CreateDefaultIniFile()
    }

    ; 加载配置
    RuntimeConfig.Load()

    ; 清理临时文件
    try FileDelete(g_Config.TempFile)
}

CreateDefaultIniFile() {
    try {
        d := (section, key) => GetConfigDefault(section, key)

        ; 直接创建完整的配置文件内容
        configContent := "; QuickSwitch 配置文件`n"
            . "; 快速切换工具 - By BoBO`n"
            . "; MainHotkey: 主快捷键，在普通窗口显示程序切换菜单，在文件对话框显示路径切换菜单`n"
            . "; QuickSwitchHotkey: 快速切换最近两个程序的快捷键`n"
            . "; GetWindowsFolderActivePathKey: 直接载入文件管理器路径的快捷键`n"
            . "; EnableGetWindowsFolderActivePath: 是否启用GetWindowsFolderActivePath功能 - 1=开启, 0=关闭`n"
            . "; MenuCooldownMs: 菜单触发节流窗口（毫秒）`n"
            . "; LogRetentionDays: 日志保留天数（自动清理logs目录中过期日志）`n"
            . "; MaxHistoryCount: 最大历史记录数量`n"
            . "; RunMode: 运行模式 - 0=全部运行(智能判断), 1=只运行路径跳转, 2=只运行程序切换`n"
            . "; ExcludedApps: 排除的程序列表`n"
            . "; PinnedApps: 置顶显示的程序列表`n"
            . "; DefaultAction: 文件对话框默认行为 - manual=手动按键, auto_menu=自动弹出菜单, auto_switch=自动切换, never=从不显示`n`n"
            . "; CustomPaths 格式说明: 显示名称|路径|置顶标记`n"
            . "; 置顶标记: 1=置顶，空或其他=不置顶`n"
            . "; ShowCustomName: 0=显示完整路径(默认), 1=显示自定义名称`n"
            . "; 置顶路径将与收藏路径同层级显示，普通路径在子菜单中`n"
            . "; 示例: Path1=桌面|%USERPROFILE%\\Desktop|1 (置顶路径)`n"
            . "; 示例: Path2=文档|%USERPROFILE%\\Documents (普通路径)`n`n"
            . "; Position: mouse鼠标  fixed固定`n`n"
            . "[Settings]`n"
            . "MainHotkey=" . d("Settings", "MainHotkey") . "`n"
            . "QuickSwitchHotkey=" . d("Settings", "QuickSwitchHotkey") . "`n"
            . "GetWindowsFolderActivePathKey=" . d("Settings", "GetWindowsFolderActivePathKey") . "`n"
            . "EnableGetWindowsFolderActivePath=" . d("Settings", "EnableGetWindowsFolderActivePath") . "`n"
            . "MenuCooldownMs=" . d("Settings", "MenuCooldownMs") . "`n"
            . "MaxHistoryCount=" . d("Settings", "MaxHistoryCount") . "`n"
            . "EnableQuickAccess=" . d("Settings", "EnableQuickAccess") . "`n"
            . "QuickAccessKeys=" . d("Settings", "QuickAccessKeys") . "`n"
            . "RunMode=" . d("Settings", "RunMode") . "`n"
            . "EnableLog=" . d("Settings", "EnableLog") . "`n"
            . "LogRetentionDays=" . d("Settings", "LogRetentionDays") . "`n`n"
            . "[Display]`n"
            . "MenuColor=" . d("Display", "MenuColor") . "`n"
            . "IconSize=" . d("Display", "IconSize") . "`n"
            . "ShowWindowTitle=" . d("Display", "ShowWindowTitle") . "`n"
            . "ShowProcessName=" . d("Display", "ShowProcessName") . "`n`n"
            . "[WindowSwitchMenu]`n"
            . "Position=" . d("WindowSwitchMenu", "Position") . "`n"
            . "FixedPosX=" . d("WindowSwitchMenu", "FixedPosX") . "`n"
            . "FixedPosY=" . d("WindowSwitchMenu", "FixedPosY") . "`n`n"
            . "[PathSwitchMenu]`n"
            . "Position=" . d("PathSwitchMenu", "Position") . "`n"
            . "FixedPosX=" . d("PathSwitchMenu", "FixedPosX") . "`n"
            . "FixedPosY=" . d("PathSwitchMenu", "FixedPosY") . "`n`n"
            . "[FileManagers]`n"
            . "TotalCommander=" . d("FileManagers", "TotalCommander") . "`n"
            . "Explorer=" . d("FileManagers", "Explorer") . "`n"
            . "XYplorer=" . d("FileManagers", "XYplorer") . "`n"
            . "DirectoryOpus=" . d("FileManagers", "DirectoryOpus") . "`n`n"
            . "[CustomPaths]`n"
            . "EnableCustomPaths=" . d("CustomPaths", "EnableCustomPaths") . "`n"
            . "MenuTitle=" . d("CustomPaths", "MenuTitle") . "`n"
            . "ShowCustomName=" . d("CustomPaths", "ShowCustomName") . "`n"
            . "Path1=桌面|%USERPROFILE%\\Desktop|1`n"
            . "Path2=文档|%USERPROFILE%\\Documents`n"
            . "Path3=下载|%USERPROFILE%\\Downloads`n`n"
            . "[RecentPaths]`n"
            . "EnableRecentPaths=" . d("RecentPaths", "EnableRecentPaths") . "`n"
            . "MenuTitle=" . d("RecentPaths", "MenuTitle") . "`n"
            . "MaxRecentPaths=" . d("RecentPaths", "MaxRecentPaths") . "`n`n"
            . "[ExcludedApps]`n"
            . "App1=explorer.exe`n"
            . "App2=dwm.exe`n"
            . "App3=winlogon.exe`n"
            . "App4=csrss.exe`n`n"
            . "[PinnedApps]`n"
            . "App1=notepad.exe`n"
            . "App2=chrome.exe`n`n"
            . "[QuickLaunchApps]`n"
            . "EnableQuickLaunchApps=" . d("QuickLaunchApps", "EnableQuickLaunchApps") . "`n"
            . "MaxDisplayCount=" . d("QuickLaunchApps", "MaxDisplayCount") . "`n`n"
            . "[TotalCommander]`n"
            . "CopySrcPath=" . d("TotalCommander", "CopySrcPath") . "`n"
            . "CopyTrgPath=" . d("TotalCommander", "CopyTrgPath") . "`n`n"
            . "[Theme]`n"
            . "DarkMode=" . d("Theme", "DarkMode") . "`n`n"
            . "[FileDialog]`n"
            . "DefaultAction=" . d("FileDialog", "DefaultAction") . "`n"

        ; 删除现有文件并写入新内容
        if FileExist(g_Config.IniFile) {
            FileDelete(g_Config.IniFile)
        }

        ; 使用UTF-8编码写入文件
        FileAppend(configContent, g_Config.IniFile, "UTF-8")

    } catch as e {
        MsgBox("创建配置文件失败: " . e.message, "错误", "T5")
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

        ; 根据开关决定是否注册GetWindowsFolderActivePath热键
        if (g_Config.EnableGetWindowsFolderActivePath = "1") {
            Hotkey(g_Config.GetWindowsFolderActivePathKey, GetWindowsFolderActivePath, "On")
        }

        ; 注册微信快捷键 Ctrl+Alt+W
        Hotkey("^!w", ActivateWeChatHotkey, "On")

    } catch as e {
        MsgBox("注册热键失败: " . e.message . "`n使用默认热键 Ctrl+Q 和 Ctrl+Tab", "警告", "T5")
        try {
            Hotkey("^q", ShowSmartMenu, "On")
            Hotkey("^Tab", QuickSwitchLastTwo, "On")
            ; 根据开关决定是否注册默认GetWindowsFolderActivePath热键
            if (g_Config.EnableGetWindowsFolderActivePath = "1") {
                Hotkey("!w", GetWindowsFolderActivePath, "On")
            }
            ; 注册微信快捷键 Ctrl+Alt+W
            Hotkey("^!w", ActivateWeChatHotkey, "On")
        }
    }
}

ActivateWeChatHotkey(*) {
    ; 微信快捷键处理函数
    ActivateWeChat("")  ; 传递空字符串表示没有配置快捷键
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

    ; 添加程序名称和版本号（灰色、禁用）
    ; A_TrayMenu.Add("QuickSwitch v1.0", (*) => "")
    ; A_TrayMenu.Disable("QuickSwitch v1.0")
    ; A_TrayMenu.Add()  ; 分隔符

    ; 添加主要功能菜单项
    A_TrayMenu.Add("设置", OpenConfigFile)
    A_TrayMenu.Add()
    A_TrayMenu.Add("输出性能摘要", DumpMenuPerfSummaryFromTray)
    A_TrayMenu.Add("清空性能统计", ResetMenuPerfStatsFromTray)
    A_TrayMenu.Add()
    A_TrayMenu.Add("关于", ShowAboutFromTray)
    A_TrayMenu.Add("重启", RestartApplication)
    A_TrayMenu.Add("退出", ExitApplication)

    ; 设置默认菜单项（双击任务栏图标时执行）
    A_TrayMenu.Default := "设置"
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

UpdateTrayMenuGetWindowsFolderActivePathStatus() {
    ; 更新GetWindowsFolderActivePath功能菜单项的显示文本
    functionText := (g_Config.EnableGetWindowsFolderActivePath = "1") ? "GetWindowsFolderActivePath功能 (当前: 开启)" :
        "GetWindowsFolderActivePath功能 (当前: 关闭)"
    try {
        A_TrayMenu.Rename("GetWindowsFolderActivePath功能", functionText)
    } catch {
        ; 如果重命名失败，忽略错误
    }
}

UpdateTrayMenuRunModeStatus() {
    ; 更新运行模式菜单项的选中状态
    try {
        runModeMenu := A_TrayMenu.Handle("运行模式")
        runModeMenu.Uncheck("全部运行")
        runModeMenu.Uncheck("只运行路径跳转")
        runModeMenu.Uncheck("只运行程序切换")

        switch g_Config.RunMode {
            case 0:
                runModeMenu.Check("全部运行")
            case 1:
                runModeMenu.Check("只运行路径跳转")
            case 2:
                runModeMenu.Check("只运行程序切换")
        }
    } catch {
        ; 如果更新失败，忽略错误
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

ToggleGetWindowsFolderActivePathFromTray(*) {
    ToggleGetWindowsFolderActivePath()
    ; 更新任务栏菜单显示
    UpdateTrayMenuGetWindowsFolderActivePathStatus()
}

SetRunModeFromTray(mode, *) {
    SetRunMode(mode)
    ; 更新任务栏菜单显示
    UpdateTrayMenuRunModeStatus()
}

ShowAboutFromTray(*) {
    ShowAbout()
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

DumpMenuPerfSummaryFromTray(*) {
    global g_MenuPerfMinSamples, g_MenuPerfTopN, g_LogEnabled
    summary := RuntimeLog.BuildMenuPerfSummaryText(g_MenuPerfMinSamples, g_MenuPerfTopN)
    if (summary = "") {
        MsgBox("暂无性能统计样本。请先触发几次菜单后再查看。", "性能统计", "T3")
        return
    }

    if (g_LogEnabled) {
        RuntimeLog.LogPerfSummary(summary, "INFO")
    }
    MsgBox(summary, "菜单性能摘要", "T8")
}

ResetMenuPerfStatsFromTray(*) {
    global g_LogEnabled
    RuntimeLog.ResetMenuPerfStats()
    if (g_LogEnabled) {
        RuntimeLog.LogMessage("菜单性能统计已手动清空", "INFO")
    }
    MsgBox("菜单性能统计已清空。", "性能统计", "T2")
}

; ============================================================================
; 智能菜单显示
; ============================================================================

ShowSmartMenu(*) {
    ; 如果菜单已经激活，则不重复显示
    if (g_MenuActive || RuntimeMenu.IsRequestThrottled()) {
        return
    }

    ; 获取当前活动窗口
    currentWinID := WinExist("A")

    ; 根据运行模式决定显示哪个菜单
    switch g_Config.RunMode {
        case 0:  ; 全部运行 - 智能判断
            ; 检查是否为文件对话框
            if (IsFileDialog(currentWinID)) {
                ; 统一使用 ShowFileDialogMenu 处理所有文件对话框情况
                ShowFileDialogMenu(currentWinID)
            } else {
                ; 显示程序窗口切换菜单
                ShowWindowSwitchMenu()
            }
        case 1:  ; 只运行路径跳转
            if (IsFileDialog(currentWinID)) {
                ShowFileDialogMenu(currentWinID)
            } else {
                ; 如果不是文件对话框，不显示任何菜单
                return
            }
        case 2:  ; 只运行程序切换
            if (!IsFileDialog(currentWinID)) {
                ShowWindowSwitchMenu()
            } else {
                ; 如果是文件对话框，不显示任何菜单
                return
            }
        default: ; 默认为全部运行
            ; 检查是否为文件对话框
            if (IsFileDialog(currentWinID)) {
                ShowFileDialogMenu(currentWinID)
            } else {
                ; 显示程序窗口切换菜单
                ShowWindowSwitchMenu()
            }
    }
}

GetFileDialogType(winID) {
    if (!winID) {
        return ""
    }

    try {
        dialogType := DetectFileDialog(winID)
        return dialogType ? dialogType : ""
    } catch {
        return ""
    }
}

IsFileDialog(winID) {
    return GetFileDialogType(winID) != ""
}

; ============================================================================
; 程序窗口切换功能
; ============================================================================

InitializeCurrentWindows() {
    RuntimeWindowState.InitializeCurrentWindows()
}

CollectWindowSnapshot() {
    return RuntimeWindowState.CollectWindowSnapshot()
}

StartWindowMonitoring() {
    SetTimer(MonitorActiveWindow, 500)
}

MonitorActiveWindow() {
    RuntimeWindowState.MonitorActiveWindow()
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
    RuntimeWindowState.UpdateWindowHistory(winID, winTitle, processName)
}

UpdateLastTwoWindows(currentWindow) {
    RuntimeWindowState.UpdateLastTwoWindows(currentWindow)
}

ShowWindowSwitchMenu(*) {
    global g_MenuItems
    lockToken := RuntimeMenu.TryAcquire("WindowSwitch")
    if (!lockToken) {
        return
    }
    g_MenuItems := []
    startTick := A_TickCount
    stageTick := startTick

    try {
        windowSnapshot := CollectWindowSnapshot()
        RuntimeLog.LogMenuStageElapsed("WindowSwitch", "collect_windows", &stageTick, startTick, g_MenuItems.Length)
        PrewarmProcessIconCacheFromWindows(windowSnapshot.AllWindowIds)
        RuntimeLog.LogMenuStageElapsed("WindowSwitch", "prewarm_icon_cache", &stageTick, startTick, g_MenuItems.Length)
        contextMenu := RenderWindowSwitchMenu(windowSnapshot, &stageTick, startTick)
        RuntimeLog.LogMenuStageElapsed("WindowSwitch", "render_menu", &stageTick, startTick, g_MenuItems.Length)

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
        RuntimeLog.LogMenuStageElapsed("WindowSwitch", "menu_show", &stageTick, startTick, g_MenuItems.Length)
    } finally {
        RuntimeLog.LogMenuBuildElapsed("WindowSwitch", startTick, g_MenuItems.Length)
        RuntimeMenu.ScheduleUnlock(lockToken, 150)
    }
}

RenderWindowSwitchMenu(windowSnapshot, &stageTick, startTick) {
    contextMenu := Menu()
    contextMenu.Add("QuickSwitch - 程序切换", (*) => "")
    contextMenu.Default := "QuickSwitch - 程序切换"
    contextMenu.Disable("QuickSwitch - 程序切换")

    hasMenuItems := false
    pinnedMenuItems := CollectPinnedWindowMenuItems(windowSnapshot)
    historyMenuItems := CollectHistoryWindowMenuItems()

    hasMenuItems := AddPinnedWindows(contextMenu, pinnedMenuItems, windowSnapshot.AllWindowIds) || hasMenuItems
    RuntimeLog.LogMenuStageElapsed("WindowSwitch", "add_pinned", &stageTick, startTick, g_MenuItems.Length)

    if (hasMenuItems) {
        contextMenu.Add()
    }

    hasMenuItems := AddHistoryWindows(contextMenu, historyMenuItems, windowSnapshot.AllWindowIds) || hasMenuItems
    RuntimeLog.LogMenuStageElapsed("WindowSwitch", "add_history", &stageTick, startTick, g_MenuItems.Length)

    if (hasMenuItems) {
        contextMenu.Add()
    }

    quickLaunchAdded := AddQuickLaunchApps(contextMenu)
    RuntimeLog.LogMenuStageElapsed("WindowSwitch", "add_quick_launch", &stageTick, startTick, g_MenuItems.Length)

    if (quickLaunchAdded) {
        contextMenu.Add()
    }
    settingsMenuData := CollectWindowSettingsMenuData(windowSnapshot.AllWindowIds)
    AddWindowSettingsMenu(contextMenu, settingsMenuData, windowSnapshot.AllWindowIds)
    RuntimeLog.LogMenuStageElapsed("WindowSwitch", "add_settings", &stageTick, startTick, g_MenuItems.Length)

    contextMenu.Color := g_Config.MenuColor
    return contextMenu
}

CollectPinnedWindowMenuItems(windowSnapshot := "") {
    return RuntimeWindowState.CollectPinnedWindowMenuItems(windowSnapshot)
}

CollectHistoryWindowMenuItems() {
    return RuntimeWindowState.CollectHistoryWindowMenuItems()
}

CollectWindowSettingsMenuData(allWindows := "") {
    if !IsObject(allWindows) {
        allWindows := WinGetList()
    }

    settingsMenuData := {
        CloseItems: [],
        PinItems: [],
        UnpinItems: []
    }

    ; TODO: If the settings menu keeps growing, split each submenu collector into its own function.
    for windowInfo in g_WindowHistory {
        try {
            if (!WinExist("ahk_id " . windowInfo.ID)) {
                continue
            }

            settingsMenuData.CloseItems.Push({
                DisplayText: CreateDisplayText(windowInfo.Title, windowInfo.ProcessName),
                ProcessName: windowInfo.ProcessName,
                WindowId: windowInfo.ID
            })

            if (!IsPinnedApp(windowInfo.ProcessName)) {
                settingsMenuData.PinItems.Push({
                    DisplayText: CreateDisplayText(windowInfo.Title, windowInfo.ProcessName),
                    ProcessName: windowInfo.ProcessName
                })
            }
        } catch {
            continue
        }
    }

    for winID in allWindows {
        try {
            if (!WinExist("ahk_id " . winID)) {
                continue
            }

            processName := WinGetProcessName("ahk_id " . winID)
            winTitle := WinGetTitle("ahk_id " . winID)
            if (IsPinnedApp(processName) && !ShouldExcludeWindow(processName, winTitle)) {
                settingsMenuData.UnpinItems.Push({
                    DisplayText: CreateDisplayText(winTitle, processName),
                    ProcessName: processName
                })
            }
        } catch {
            continue
        }
    }

    return settingsMenuData
}

AddQuickLaunchApps(contextMenu) {
    added := false
    cache := g_QuickLaunchCache

    if (!cache.enabled) {
        return false
    }

    appList := cache.apps
    if (appList.Length = 0) {
        return false
    }

    maxDisplayCount := cache.maxDisplayCount
    displayCount := Min(appList.Length, maxDisplayCount)

    ; 分级显示应用程序
    loop displayCount {
        app := appList[A_Index]
        if (AddQuickLaunchApp(contextMenu, app.displayName, app.processName, app.exePath, app.hotkey)) {
            added := true
        }
    }

    ; 如果还有更多应用程序，添加到"更多"子菜单
    if (appList.Length > displayCount) {
        moreMenu := Menu()
        loop (appList.Length - displayCount) {
            app := appList[displayCount + A_Index]
            AddQuickLaunchApp(moreMenu, app.displayName, app.processName, app.exePath, app.hotkey)
        }
        contextMenu.Add("更多", moreMenu)
        added := true
    }

    return added
}

AddQuickLaunchApp(contextMenu, displayName, processName, exePath := "", hotkey := "") {
    ; 检查应用程序是否在运行
    appRunning := ProcessExist(processName)

    ; 设置不同的显示文本
    if (appRunning) {
        displayText := "📱 " . displayName . " (已运行)"
    } else {
        displayText := "📱 " . displayName . "*"
    }

    ; 添加菜单项
    contextMenu.Add(displayText, QuickLaunchAppHandler.Bind(processName, exePath, hotkey))

    ; 尝试设置应用程序图标
    try {
        ; 如果提供了路径，使用提供的路径
        if (exePath != "") {
            contextMenu.SetIcon(displayText, exePath, 0, g_Config.IconSize)
        } else {
            ; 自动查找可执行文件路径
            foundPath := FindAppExecutable(processName)
            if (foundPath != "") {
                contextMenu.SetIcon(displayText, foundPath, 0, g_Config.IconSize)
            } else {
                ; 使用默认图标
                contextMenu.SetIcon(displayText, "shell32.dll", 15, g_Config.IconSize) ; 使用消息图标
            }
        }
    } catch {
        ; 如果设置图标失败，忽略错误
    }

    return true
}

QuickLaunchAppHandler(processName, exePath, hotkey, *) {
    ; 快速启动应用程序按钮点击处理函数

    ; 检查应用程序是否在运行
    if (ProcessExist(processName)) {
        ; 应用程序已运行，尝试激活窗口

        ; 特殊处理微信（Weixin.exe）
        if (processName = "Weixin.exe") {
            ActivateWeChat(hotkey)
        } else {
            ; 其他应用程序使用标准托盘图标点击
            try {
                TrayIcon_Button(processName, "L", false, 1)
            } catch as e {
                MsgBox("激活" . processName . "失败: " . e.message, "错误", "T2")
            }
        }
    } else {
        ; 应用程序未运行，启动应用程序
        try {
            ; 如果提供了路径，使用提供的路径
            if (exePath != "") {
                if (FileExist(exePath)) {
                    Run(exePath)
                } else {
                    MsgBox("指定的路径不存在: " . exePath, "错误", "T3")
                }
            } else {
                ; 自动查找可执行文件路径
                foundPath := FindAppExecutable(processName)
                if (foundPath != "") {
                    Run(foundPath)
                } else {
                    MsgBox("未找到" . processName . "程序，请确保已安装", "错误", "T3")
                }
            }
        } catch as e {
            MsgBox("启动" . processName . "失败: " . e.message, "错误", "T3")
        }
    }
}

ActivateWeChat(hotkey := "") {
    ; 特殊处理微信激活
    weixinProcessName := "Weixin.exe"

    ; 如果配置了快捷键，优先使用快捷键激活
    if (hotkey != "") {
        try {
            Send(hotkey)
            Sleep(200)

            ; 检查微信窗口是否被激活
            if (IsWeChatActive()) {
                return  ; 成功激活，直接返回
            }
        } catch {
            ; 快捷键失败，继续尝试其他方法
        }
    }

    ; 方法1：首先尝试使用TrayIcon_Button点击托盘图标
    try {
        TrayIcon_Button(weixinProcessName, "L", false, 1)
        ; 等待一下看看是否成功激活
        Sleep(200)

        ; 检查微信窗口是否被激活
        if (IsWeChatActive()) {
            return  ; 成功激活，直接返回
        }
    } catch {
        ; TrayIcon_Button失败，继续尝试其他方法
    }

    ; 方法2：尝试使用快捷键Ctrl+Alt+W（如果没有配置快捷键）
    if (hotkey = "") {
        try {
            Send("^!w")  ; Ctrl+Alt+W
            Sleep(200)

            ; 检查微信窗口是否被激活
            if (IsWeChatActive()) {
                return  ; 成功激活
            }
        } catch {
            ; 快捷键失败，继续尝试其他方法
        }
    }

    ; 方法3：尝试直接激活微信窗口
    try {
        ; 查找微信主窗口
        weixinWinID := WinExist("ahk_exe " . weixinProcessName)
        if (weixinWinID) {
            WinActivate("ahk_id " . weixinWinID)
            WinShow("ahk_id " . weixinWinID)

            ; 如果窗口最小化，恢复窗口
            if (WinGetMinMax("ahk_id " . weixinWinID) = -1) {
                WinRestore("ahk_id " . weixinWinID)
            }

            Sleep(200)
            if (IsWeChatActive()) {
                return  ; 成功激活
            }
        }
    } catch as e {
        ; 窗口激活失败
    }

    ; 所有方法都失败，显示错误信息
    MsgBox("激活微信失败，请确保微信已安装并运行", "错误", "T2")
}

IsWeChatActive() {
    ; 检查微信窗口是否处于激活状态
    weixinProcessName := "Weixin.exe"

    ; 获取当前激活窗口的进程名
    try {
        activeWinID := WinExist("A")  ; 获取当前激活窗口
        activeProcessName := WinGetProcessName("ahk_id " . activeWinID)

        ; 如果当前激活窗口是微信，返回true
        if (activeProcessName = weixinProcessName) {
            return true
        }
    } catch {
        ; 获取窗口信息失败
    }

    return false
}

FindAppExecutable(processName) {
    global g_AppExecutableCache, g_RuntimeLookupMissCache, g_RuntimeLookupMissCooldownMs

    ; 根据进程名查找可执行文件路径
    processKey := StrLower(Trim(processName))
    if (processKey = "") {
        return ""
    }

    appMissCache := g_RuntimeLookupMissCache.appExe
    if (appMissCache.Has(processKey)) {
        if ((A_TickCount - appMissCache[processKey]) < g_RuntimeLookupMissCooldownMs) {
            return ""
        }
        appMissCache.Delete(processKey)
    }

    if (g_AppExecutableCache.Has(processKey)) {
        cachedPath := g_AppExecutableCache[processKey]
        if (cachedPath != "" && FileExist(cachedPath)) {
            return cachedPath
        }
        g_AppExecutableCache.Delete(processKey)
    }

    ; 首先尝试通过进程列表查找
    try {
        for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where Name='" . processKey . "'") {
            exePath := process.ExecutablePath
            if (exePath != "" && FileExist(exePath)) {
                g_AppExecutableCache[processKey] := exePath
                if (appMissCache.Has(processKey)) {
                    appMissCache.Delete(processKey)
                }
                return exePath
            }
        }
    } catch {
        ; 如果WMI查询失败，使用其他方法
    }

    ; 常见应用程序的默认路径查找
    appPaths := GetCommonAppPaths(processName)

    for path in appPaths {
        if (FileExist(path)) {
            g_AppExecutableCache[processKey] := path
            if (appMissCache.Has(processKey)) {
                appMissCache.Delete(processKey)
            }
            return path
        }
    }

    ; 尝试通过注册表查找
    registryPaths := GetRegistryAppPaths(processName)

    for regPath in registryPaths {
        try {
            appPath := RegRead(regPath[1], regPath[2])
            if (appPath != "") {
                if (FileExist(appPath)) {
                    g_AppExecutableCache[processKey] := appPath
                    if (appMissCache.Has(processKey)) {
                        appMissCache.Delete(processKey)
                    }
                    return appPath
                }
            }
        } catch {
            ; 注册表查找失败
        }
    }

    appMissCache[processKey] := A_TickCount
    return ""
}

GetCommonAppPaths(processName) {
    ; 返回常见应用程序的默认安装路径
    paths := []
    processKey := StrLower(Trim(processName))

    ; 微信相关路径
    if (processKey = "wechat.exe" || processKey = "weixin.exe") {
        paths.Push(A_ProgramFiles "\\Tencent\\WeChat\\WeChat.exe")
        paths.Push(A_ProgramFiles " (x86)\\Tencent\\WeChat\\WeChat.exe")
        paths.Push(EnvGet("LOCALAPPDATA") "\\Programs\\Tencent\\WeChat\\WeChat.exe")
        paths.Push(EnvGet("APPDATA") "\\Tencent\\WeChat\\WeChat.exe")
    }

    ; Tim相关路径
    if (processKey = "tim.exe") {
        paths.Push(A_ProgramFiles "\\Tencent\\Tim\\Bin\\Tim.exe")
        paths.Push(A_ProgramFiles " (x86)\\Tencent\\Tim\\Bin\\Tim.exe")
        paths.Push(EnvGet("LOCALAPPDATA") "\\Programs\\Tencent\\Tim\\Bin\\Tim.exe")
    }

    ; QQ相关路径
    if (processKey = "qq.exe") {
        paths.Push(A_ProgramFiles "\\Tencent\\QQ\\Bin\\QQ.exe")
        paths.Push(A_ProgramFiles " (x86)\\Tencent\\QQ\\Bin\\QQ.exe")
    }

    ; 钉钉相关路径
    if (processKey = "dingtalk.exe") {
        paths.Push(A_ProgramFiles "\\DingDing\\DingTalkLauncher.exe")
        paths.Push(A_ProgramFiles " (x86)\\DingDing\\DingTalkLauncher.exe")
        paths.Push(EnvGet("LOCALAPPDATA") "\\Programs\\DingTalk\\DingTalk.exe")
    }

    ; 企业微信相关路径
    if (processKey = "wxwork.exe") {
        paths.Push(A_ProgramFiles "\\WXWork\\WXWork.exe")
        paths.Push(A_ProgramFiles " (x86)\\WXWork\\WXWork.exe")
    }

    ; 添加更多常见应用程序路径...

    return paths
}

GetRegistryAppPaths(processName) {
    ; 返回注册表查找路径
    registryPaths := []
    processKey := StrLower(Trim(processName))

    ; 微信注册表路径
    if (processKey = "wechat.exe" || processKey = "weixin.exe") {
        registryPaths.Push(["HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Tencent\\WeChat", "InstallPath"])
        registryPaths.Push(["HKEY_CURRENT_USER\\SOFTWARE\\Tencent\\WeChat", "InstallPath"])
    }

    ; Tim注册表路径
    if (processKey = "tim.exe") {
        registryPaths.Push(["HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Tencent\\Tim", "InstallPath"])
        registryPaths.Push(["HKEY_CURRENT_USER\\SOFTWARE\\Tencent\\Tim", "InstallPath"])
    }

    ; QQ注册表路径
    if (processKey = "qq.exe") {
        registryPaths.Push(["HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Tencent\\QQ", "InstallPath"])
        registryPaths.Push(["HKEY_CURRENT_USER\\SOFTWARE\\Tencent\\QQ", "InstallPath"])
    }

    ; 钉钉注册表路径
    if (processKey = "dingtalk.exe") {
        registryPaths.Push(["HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\DingTalk", "InstallPath"])
        registryPaths.Push(["HKEY_CURRENT_USER\\SOFTWARE\\DingTalk", "InstallPath"])
    }

    ; 企业微信注册表路径
    if (processKey = "wxwork.exe") {
        registryPaths.Push(["HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Tencent\\WXWork", "InstallPath"])
        registryPaths.Push(["HKEY_CURRENT_USER\\SOFTWARE\\Tencent\\WXWork", "InstallPath"])
    }

    return registryPaths
}

AddPinnedWindows(contextMenu, pinnedMenuItems, allWindows := "") {
    added := false

    for item in pinnedMenuItems {
        try {
            AddWindowMenuItemWithQuickAccess(
                contextMenu,
                item.DisplayText,
                WindowChoiceHandler.Bind(item.WindowId),
                item.ProcessName,
                true,
                allWindows
            )
            added := true
        } catch {
            continue
        }
    }

    return added
}

AddHistoryWindows(contextMenu, historyMenuItems, allWindows := "") {
    added := false

    for item in historyMenuItems {
        try {
            AddWindowMenuItemWithQuickAccess(
                contextMenu,
                item.DisplayText,
                WindowChoiceHandler.Bind(item.WindowId),
                item.ProcessName,
                false,
                allWindows
            )
            added := true

        } catch {
            continue
        }
    }

    return added
}

AddWindowSettingsMenu(contextMenu, settingsMenuData, allWindows := "") {
    settingsMenu := Menu()

    ; 添加运行模式子菜单
    ; runModeMenu := Menu()
    ; runModeMenu.Add("全部运行", SetRunMode.Bind(0))
    ; runModeMenu.Add("只运行路径跳转", SetRunMode.Bind(1))
    ; runModeMenu.Add("只运行程序切换", SetRunMode.Bind(2))

    ; ; 根据当前运行模式设置选中状态
    ; switch g_Config.RunMode {
    ;     case 0:
    ;         runModeMenu.Check("全部运行")
    ;     case 1:
    ;         runModeMenu.Check("只运行路径跳转")
    ;     case 2:
    ;         runModeMenu.Check("只运行程序切换")
    ; }

    ; settingsMenu.Add("运行模式", runModeMenu)
    ; settingsMenu.Add("切换主题", ToggleTheme)
    ; settingsMenu.Add("GetWindowsFolderActivePath功能", ToggleGetWindowsFolderActivePath)
    ; settingsMenu.Add()

    closeMenu := Menu()
    pinnedMenu := Menu()
    unpinnedMenu := Menu()

    closeMenuAdded := false
    for item in settingsMenuData.CloseItems {
        try {
            closeMenu.Add(item.DisplayText, CloseAppHandler.Bind(item.ProcessName, item.WindowId))
            try {
                closeMenu.SetIcon(item.DisplayText, GetProcessIcon(item.ProcessName, allWindows), , g_Config.IconSize)
            }
            closeMenuAdded := true
        } catch {
            continue
        }
    }

    pinnedMenuAdded := false
    for item in settingsMenuData.PinItems {
        try {
            pinnedMenu.Add(item.DisplayText, AddToPinnedHandler.Bind(item.ProcessName))
            try {
                pinnedMenu.SetIcon(item.DisplayText, GetProcessIcon(item.ProcessName, allWindows), , g_Config.IconSize)
            }
            pinnedMenuAdded := true
        } catch {
            continue
        }
    }

    unpinnedMenuAdded := false
    for item in settingsMenuData.UnpinItems {
        try {
            unpinnedMenu.Add(item.DisplayText, RemoveFromPinnedHandler.Bind(item.ProcessName))
            try {
                unpinnedMenu.SetIcon(item.DisplayText, GetProcessIcon(item.ProcessName, allWindows), , g_Config.IconSize)
            }
            unpinnedMenuAdded := true
        } catch {
            continue
        }
    }

    if (closeMenuAdded) {
        settingsMenu.Add("关闭程序", closeMenu)
    }

    if (pinnedMenuAdded) {
        settingsMenu.Add("添加置顶", pinnedMenu)
    }

    if (unpinnedMenuAdded) {
        settingsMenu.Add("取消置顶", unpinnedMenu)
    }

    ; settingsMenu.Add()
    ; settingsMenu.Add("编辑配置文件", EditConfigFile)
    ; settingsMenu.Add("重新加载配置", ReloadConfig)
    ; settingsMenu.Add("关于程序", ShowAbout)

    ; 根据当前主题状态设置菜单项显示
    if (g_DarkMode) {
        settingsMenu.Check("切换主题")
    }

    ; 根据当前GetWindowsFolderActivePath功能状态设置菜单项显示
    if (g_Config.EnableGetWindowsFolderActivePath = "1") {
        settingsMenu.Check("GetWindowsFolderActivePath功能")
    }

    contextMenu.Add("设置", settingsMenu)
}

AddWindowMenuItemWithQuickAccess(contextMenu, displayText, handler, processName, isPinned := false, allWindows := "") {
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
        iconPath := GetProcessIcon(processName, allWindows)
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

PrewarmProcessIconCacheFromWindows(allWindows) {
    global g_ProcessIconCache

    if !IsObject(allWindows) {
        return
    }

    for winID in allWindows {
        try {
            processName := WinGetProcessName("ahk_id " . winID)
            processKey := StrLower(Trim(processName))
            if (processKey = "" || g_ProcessIconCache.Has(processKey)) {
                continue
            }

            pid := WinGetPID("ahk_id " . winID)
            iconPath := GetModuleFileName(pid)
            if (iconPath != "" && FileExist(iconPath)) {
                g_ProcessIconCache[processKey] := iconPath
            }
        } catch {
            continue
        }
    }
}

GetProcessIcon(processName, allWindows := "") {
    global g_ProcessIconCache, g_RuntimeLookupMissCache, g_RuntimeLookupMissCooldownMs

    processKey := StrLower(Trim(processName))
    if (processKey = "") {
        return "shell32.dll"
    }

    iconMissCache := g_RuntimeLookupMissCache.processIcon
    if (iconMissCache.Has(processKey)) {
        if ((A_TickCount - iconMissCache[processKey]) < g_RuntimeLookupMissCooldownMs) {
            return "shell32.dll"
        }
        iconMissCache.Delete(processKey)
    }

    if (processKey != "" && g_ProcessIconCache.Has(processKey)) {
        cachedIconPath := g_ProcessIconCache[processKey]
        if (cachedIconPath != "" && FileExist(cachedIconPath)) {
            return cachedIconPath
        }
        g_ProcessIconCache.Delete(processKey)
    }

    windowsToScan := allWindows
    if !IsObject(windowsToScan) {
        windowsToScan := WinGetList()
    }

    try {
        for winID in windowsToScan {
            try {
                if (StrLower(WinGetProcessName("ahk_id " . winID)) = processKey) {
                    pid := WinGetPID("ahk_id " . winID)
                    iconPath := GetModuleFileName(pid)
                    if (processKey != "" && iconPath != "" && FileExist(iconPath)) {
                        g_ProcessIconCache[processKey] := iconPath
                        if (iconMissCache.Has(processKey)) {
                            iconMissCache.Delete(processKey)
                        }
                    }
                    return iconPath
                }
            }
        }
    }

    iconMissCache[processKey] := A_TickCount
    return "shell32.dll"
}

QuickSwitchLastTwo(*) {
    RuntimeWindowState.QuickSwitchLastTwo()
}

WindowChoiceHandler(winID, *) {
    RuntimeMenu.Release()

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
    RuntimeMenu.Release()

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
            existingValue := UTF8IniRead(g_Config.IniFile, "PinnedApps", appKey, "")
            if (existingValue = "") {
                UTF8IniWrite(processName, g_Config.IniFile, "PinnedApps", appKey)
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
            existingValue := UTF8IniRead(g_Config.IniFile, "PinnedApps", appKey, "")
            if (existingValue != "" && StrLower(existingValue) = StrLower(processName)) {
                UTF8IniDelete(g_Config.IniFile, "PinnedApps", appKey)

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
            appValue := UTF8IniRead(g_Config.IniFile, "PinnedApps", appKey, "")
            if (appValue != "") {
                existingApps.Push(appValue)
            }
            ; 清除现有条目
            UTF8IniDelete(g_Config.IniFile, "PinnedApps", appKey)
        }

        ; 重新写入，确保连续编号
        for i, appValue in existingApps {
            appKey := "App" . i
            UTF8IniWrite(appValue, g_Config.IniFile, "PinnedApps", appKey)
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

    ; 如果菜单已经激活，则不重复显示
    if (g_MenuActive) {
        return
    }

    ; 如果不是当前监控的对话框，需要重新设置信息
    if (winID != g_CurrentDialog.WinID) {
        if (!RuntimeFileDialog.Sync(winID)) {
            ; 如果不是有效的文件对话框，显示程序切换菜单
            ShowWindowSwitchMenu()
            return
        }
    }

    ; 当用户手动按快捷键时，总是显示菜单（不执行自动切换）
    ; 显示文件对话框菜单
    ShowFileDialogMenuInternal()
}

ShowFileDialogMenuInternal() {
    global g_MenuItems

    ; 双重检查：如果菜单已经激活，则不重复显示
    if (g_MenuActive) {
        return
    }

    lockToken := RuntimeMenu.TryAcquire("FileDialog")
    if (!lockToken) {
        return
    }
    g_MenuItems := []
    startTick := A_TickCount
    stageTick := startTick

    try {
        fileManagerWindows := WinGetList()
        RuntimeLog.LogMenuStageElapsed("FileDialog", "snapshot", &stageTick, startTick, g_MenuItems.Length)

        contextMenu := Menu()
        contextMenu.Add("QuickSwitch - 路径切换", (*) => "")
        contextMenu.Default := "QuickSwitch - 路径切换"
        contextMenu.Disable("QuickSwitch - 路径切换")

        hasMenuItems := false

        ; 扫描文件管理器窗口
        if g_Config.SupportTC = "1" {
            hasMenuItems := AddTotalCommanderFolders(contextMenu, fileManagerWindows) || hasMenuItems
            RuntimeLog.LogMenuStageElapsed("FileDialog", "scan_tc", &stageTick, startTick, g_MenuItems.Length)
        }
        if g_Config.SupportExplorer = "1" {
            hasMenuItems := AddExplorerFolders(contextMenu, fileManagerWindows) || hasMenuItems
            RuntimeLog.LogMenuStageElapsed("FileDialog", "scan_explorer", &stageTick, startTick, g_MenuItems.Length)
        }
        if g_Config.SupportXY = "1" {
            hasMenuItems := AddXYplorerFolders(contextMenu, fileManagerWindows) || hasMenuItems
            RuntimeLog.LogMenuStageElapsed("FileDialog", "scan_xyplorer", &stageTick, startTick, g_MenuItems.Length)
        }
        if g_Config.SupportOpus = "1" {
            hasMenuItems := AddOpusFolders(contextMenu, fileManagerWindows) || hasMenuItems
            RuntimeLog.LogMenuStageElapsed("FileDialog", "scan_opus", &stageTick, startTick, g_MenuItems.Length)
        }

        ; 添加自定义路径
        if g_Config.EnableCustomPaths = "1" {
            hasMenuItems := AddCustomPaths(contextMenu) || hasMenuItems
            RuntimeLog.LogMenuStageElapsed("FileDialog", "add_custom_paths", &stageTick, startTick, g_MenuItems.Length)
        }

        ; 添加最近路径
        if g_Config.EnableRecentPaths = "1" {
            hasMenuItems := AddRecentPaths(contextMenu) || hasMenuItems
            RuntimeLog.LogMenuStageElapsed("FileDialog", "add_recent_paths", &stageTick, startTick, g_MenuItems.Length)
        }

        ; 添加发送到文件管理器选项
        AddSendToFileManagerMenu(contextMenu)
        RuntimeLog.LogMenuStageElapsed("FileDialog", "add_send_to", &stageTick, startTick, g_MenuItems.Length)

        ; 添加设置菜单
        AddFileDialogSettingsMenu(contextMenu)
        RuntimeLog.LogMenuStageElapsed("FileDialog", "add_settings", &stageTick, startTick, g_MenuItems.Length)

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
        RuntimeLog.LogMenuStageElapsed("FileDialog", "menu_show", &stageTick, startTick, g_MenuItems.Length)
    } finally {
        RuntimeLog.LogMenuBuildElapsed("FileDialog", startTick, g_MenuItems.Length)
        RuntimeMenu.ScheduleUnlock(lockToken, 150)
    }
}

GetFileDialogControlFlags(winID) {
    controlList := WinGetControls("ahk_id " . winID)
    flags := {
        hasSysListView: false,
        hasToolbar: false,
        hasDirectUI: false,
        hasEdit: false
    }

    for control in controlList {
        switch control {
            case "SysListView321":
                flags.hasSysListView := true
            case "ToolbarWindow321":
                flags.hasToolbar := true
            case "DirectUIHWND1":
                flags.hasDirectUI := true
            case "Edit1":
                flags.hasEdit := true
        }
    }

    return flags
}

DetectFileDialog(winID) {
    winClass := WinGetClass("ahk_id " . winID)

    if (winClass = "GHOST_WindowClass") {
        try {
            exeName := WinGetProcessName("ahk_id " . winID)
            winTitle := WinGetTitle("ahk_id " . winID)
            if (exeName = "blender.exe" && InStr(winTitle, "Blender File View")) {
                return "GENERAL"
            }
        } catch {
        }
        return false
    }

    if (winClass != "#32770") {
        return false
    }

    flags := GetFileDialogControlFlags(winID)

    if (!flags.hasEdit || !flags.hasToolbar) {
        return false
    }

    if (flags.hasDirectUI) {
        return "GENERAL"
    }

    if (flags.hasSysListView) {
        return "SYSLISTVIEW"
    }

    return false
}

; ============================================================================
; 增强的Windows API路径获取函数
; ============================================================================

GetExplorerPathByAPI(winID) {
    ; 方法1：使用Windows API获取路径（最稳定）
    try {
        ; 获取窗口的进程ID
        thisPID := WinGetPID("ahk_id " . winID)

        ; 使用IShellWindows接口获取路径
        shell := ComObject("Shell.Application")

        for window in shell.Windows {
            try {
                if (window.hwnd = winID) {
                    ; 方法1A：直接获取路径（最稳定）
                    try {
                        folder := window.Document
                        if (folder) {
                            return folder.Folder.Self.Path
                        }
                    } catch {
                        ; 方法1B：备用方法 - 获取LocationURL
                        try {
                            url := window.LocationURL
                            if (InStr(url, "file:///")) {
                                path := StrReplace(url, "file:///", "")
                                path := StrReplace(path, "/", "\\")
                                return path
                            }
                        }
                    }
                }
            } catch {
                continue
            }
        }
    } catch {
        ; API方法失败
    }

    return ""
}

GetExplorerPathByTitle(winID) {
    ; 方法2：从窗口标题中提取路径（备用方法）
    try {
        title := WinGetTitle("ahk_id " . winID)

        ; 常见资源管理器标题格式
        if (RegExMatch(title, "(.+)\\s*-\\s*文件资源管理器", &match)) {
            potentialPath := Trim(match[1])
            if (IsValidFolder(potentialPath)) {
                return potentialPath
            }
        }

        ; 英文系统格式
        if (RegExMatch(title, "(.+)\\s*-\\s*File Explorer", &match)) {
            potentialPath := Trim(match[1])
            if (IsValidFolder(potentialPath)) {
                return potentialPath
            }
        }

        ; 其他可能的格式
        if (InStr(title, ":\\") && !InStr(title, " - ")) {
            ; 如果标题直接包含路径且没有分隔符
            potentialPath := Trim(title)
            if (IsValidFolder(potentialPath)) {
                return potentialPath
            }
        }
    } catch {
        ; 标题解析失败
    }

    return ""
}

GetExplorerPathEnhanced(winID) {
    ; 增强的路径获取函数，使用多种方法确保稳定性

    ; 方法1：优先使用Windows API（最稳定）
    apiPath := GetExplorerPathByAPI(winID)
    if (apiPath != "" && IsValidFolder(apiPath)) {
        RuntimeLog.LogPathExtraction(winID, "Windows API", apiPath, true)
        return apiPath
    }

    ; 方法2：备用方法 - 从窗口标题提取
    titlePath := GetExplorerPathByTitle(winID)
    if (titlePath != "" && IsValidFolder(titlePath)) {
        RuntimeLog.LogPathExtraction(winID, "窗口标题", titlePath, true)
        return titlePath
    }

    ; 方法3：最后尝试原始COM方法（兼容性）
    try {
        for explorerWindow in ComObject("Shell.Application").Windows {
            try {
                if (explorerWindow.hwnd = winID) {
                    explorerPath := explorerWindow.Document.Folder.Self.Path
                    if (IsValidFolder(explorerPath)) {
                        RuntimeLog.LogPathExtraction(winID, "COM对象", explorerPath, true)
                        return explorerPath
                    }
                }
            } catch {
                continue
            }
        }
    } catch {
        ; COM方法失败
    }

    ; 所有方法都失败
    RuntimeLog.LogPathExtraction(winID, "所有方法", "", false)
    return ""
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
                ; 使用增强的路径获取函数
                explorerPath := GetExplorerPathEnhanced(id)
                if IsValidFolder(explorerPath) {
                    fileManagerCandidates.Push({ id: id, path: explorerPath, type: "Explorer" })
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

    ; 方法1：使用PostMessage + ClipWait (基于V1代码修复)
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

    ; 方法2：尝试目标路径 (右窗格)
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
        ; 忽略错误，继续尝试其他方法
    }

    ; 方法3：备选方案 - 使用SendMessage
    A_Clipboard := ""
    try {
        result := SendMessage(1075, g_Config.TC_CopySrcPath, 0, , "ahk_id " . winID)
        Sleep(100)

        if (result != 0 && A_Clipboard != "") {
            folderPath := A_Clipboard
            A_Clipboard := clipSaved
            return folderPath
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

    ; 方法1：优先尝试直接设置Edit1控件文本
    try {
        ; 确保路径格式正确
        folderWithSlash := RTrim(folderPath, "\") . "\"

        ; 先尝试获取Edit1控件的焦点
        ControlFocus("Edit1", "ahk_id " . winID)
        Sleep(50)

        ; 清空Edit1内容并设置新路径
        ControlSetText("", "Edit1", "ahk_id " . winID)
        Sleep(50)
        ControlSetText(folderWithSlash, "Edit1", "ahk_id " . winID)
        Sleep(100)
        ; 发送Enter键确认路径
        ; ControlSend("Edit1", "{Enter}", "ahk_id " . winID)
        Send("{Enter}")
        return  ; 如果成功，直接返回
    } catch {
        ; 方法1失败，继续尝试方法2
    }

    ; 方法2：使用剪贴板方式（备用方案）
    try {
        oldClipboard := A_Clipboard
        A_Clipboard := folderPath
        ClipWait(1, 0)

        ; 尝试多种焦点获取方式
        try ControlFocus("Edit1", "ahk_id " . winID)
        Sleep(100)

        ; 使用Ctrl+A全选然后粘贴
        ControlSend("Edit1", "^a", "ahk_id " . winID)
        Sleep(50)
        ControlSend("Edit1", "^v", "ahk_id " . winID)
        Sleep(100)
        ControlSend("Edit1", "{Enter}", "ahk_id " . winID)
        Sleep(200)

        A_Clipboard := oldClipboard
        return
    } catch {
        ; 方法2失败，继续尝试方法3
    }

    ; 方法3：使用SendInput直接发送（最后备选）
    try {
        oldClipboard := A_Clipboard
        A_Clipboard := folderPath
        ClipWait(1, 0)

        ; 激活窗口并发送快捷键
        WinActivate("ahk_id " . winID)
        Sleep(100)
        SendInput("^l")  ; Ctrl+L定位到地址栏
        Sleep(200)
        SendInput("^v")  ; Ctrl+V粘贴
        Sleep(100)
        SendInput("{Enter}")  ; 确认
        Sleep(200)

        A_Clipboard := oldClipboard

        ; 最后尝试将焦点设置回Edit1
        try ControlFocus("Edit1", "ahk_id " . winID)
        return
    } catch {
        ; 所有方法都失败，记录错误但不中断程序
        ; MsgBox("路径设置失败，请手动输入路径: " . folderPath, "提示", "T2")
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
}

AddCustomPaths(contextMenu) {
    added := false
    customPathsMenu := Menu()  ; 普通路径的子菜单
    pinnedPaths := g_CustomPathsCache.pinnedPaths
    normalPaths := g_CustomPathsCache.normalPaths

    ; 如果有任何自定义路径，添加分割线
    if (pinnedPaths.Length > 0 || normalPaths.Length > 0) {
        contextMenu.Add()
        added := true
    }

    ; 先添加置顶路径到主菜单（在分割线下面，与收藏路径一起）
    if (pinnedPaths.Length > 0) {
        for pathInfo in pinnedPaths {
            displayText := "📌 " . pathInfo.display
            contextMenu.Add(displayText, FolderChoiceHandler.Bind(pathInfo.path))
            try contextMenu.SetIcon(displayText, "shell32.dll", 4, g_Config.IconSize)
        }
    }

    ; 再添加普通路径到子菜单
    if (normalPaths.Length > 0) {
        for pathInfo in normalPaths {
            customPathsMenu.Add(pathInfo.display, FolderChoiceHandler.Bind(pathInfo.path))
            try customPathsMenu.SetIcon(pathInfo.display, "shell32.dll", 4, g_Config.IconSize)
        }

        ; 只有当有普通路径时才添加子菜单
        contextMenu.Add(g_Config.CustomPathsTitle, customPathsMenu)
        try contextMenu.SetIcon(g_Config.CustomPathsTitle, "shell32.dll", 43, g_Config.IconSize)
    }

    return added
}

AddRecentPaths(contextMenu) {
    added := false
    recentPathsMenu := Menu()
    recentPaths := g_RecentPathsCache

    if (recentPaths.Length > 0) {
        for pathValue in recentPaths {
            recentPathsMenu.Add(pathValue, RecentPathChoiceHandler.Bind(pathValue))
            try recentPathsMenu.SetIcon(pathValue, "shell32.dll", 4, g_Config.IconSize)
        }

        contextMenu.Add()
        contextMenu.Add(g_Config.RecentPathsTitle, recentPathsMenu)
        try contextMenu.SetIcon(g_Config.RecentPathsTitle, "shell32.dll", 269, g_Config.IconSize)
        added := true
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
    ; // 创建设置子菜单
    settingsSubMenu := Menu()
    settingsSubMenu.Add("自动跳转", AutoSwitchHandler)
    settingsSubMenu.Add("自动弹出菜单", AutoMenuHandler)
    settingsSubMenu.Add("手动按键", ManualHandler)
    settingsSubMenu.Add("从不显示", NeverHandler)

    switch g_CurrentDialog.Action {
        case "1":
            settingsSubMenu.Check("自动跳转")
        case "2":
            settingsSubMenu.Check("自动弹出菜单")
        case "0":
            settingsSubMenu.Check("从不显示")
        default:
            settingsSubMenu.Check("手动按键")
    }

    contextMenu.Add("跳转设置", settingsSubMenu)
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
    RuntimeMenu.Release()

    if IsValidFolder(folderPath) && g_CurrentDialog.WinID != "" {
        RecordRecentPath(folderPath)
        FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
    }
}

RecentPathChoiceHandler(folderPath, *) {
    RuntimeMenu.Release()

    if IsValidFolder(folderPath) && g_CurrentDialog.WinID != "" {
        RecordRecentPath(folderPath)
        FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
    }
}

AutoSwitchHandler(*) {
    RuntimeMenu.Release()

    RuntimeFileDialog.SetAction("1")

    folderPath := GetActiveFileManagerFolder(g_CurrentDialog.WinID)

    if IsValidFolder(folderPath) {
        FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
    }
}

GetWindowsFolderActivePath(*) {
    ; 获取当前活动窗口
    currentWinID := WinExist("A")

    ; 检查当前窗口是否为文件对话框
    if (IsFileDialog(currentWinID)) {
        ; 如果是文件对话框，执行路径切换功能

        ; 如果当前对话框信息未设置或已过期，重新设置
        if (!RuntimeFileDialog.EnsureCurrent(currentWinID)) {
            ; 如果检测失败，直接返回
            return
        }

        ; 获取文件管理器的当前路径
        folderPath := GetActiveFileManagerFolder(currentWinID)

        if IsValidFolder(folderPath) {
            ; 记录到最近路径并切换到该路径
            RecordRecentPath(folderPath)
            FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
        } else {
            ; 如果没有找到有效的文件管理器路径，显示路径切换菜单
            ShowFileDialogMenu(currentWinID)
        }
    } else {
        ; 如果不是文件对话框，什么都不做（或者可以显示提示信息）
        ; 可选：显示提示信息
        ; MsgBox("此功能仅在文件对话框中可用", "提示", "T2")
        return
    }
}

NotNowHandler(*) {
    RuntimeMenu.Release()

    RuntimeFileDialog.SetAction("")
}

AutoMenuHandler(*) {
    RuntimeMenu.Release()

    RuntimeFileDialog.SetAction("2")
}

ManualHandler(*) {
    RuntimeMenu.Release()

    RuntimeFileDialog.SetAction("")
}

NeverHandler(*) {
    RuntimeMenu.Release()

    RuntimeFileDialog.SetAction("0")
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
    RuntimeMenu.Release()

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
    RuntimeMenu.Release()

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
        recentValue := UTF8IniRead(g_Config.IniFile, "RecentPaths", recentKey, "")

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

    UTF8IniWrite(newEntry, g_Config.IniFile, "RecentPaths", "Recent1")

    entryIndex := 2
    for existingEntry in existingPaths {
        if (entryIndex > maxPaths) {
            break
        }
        UTF8IniWrite(existingEntry, g_Config.IniFile, "RecentPaths", "Recent" . entryIndex)
        entryIndex++
    }

    while (entryIndex <= maxPaths) {
        try UTF8IniDelete(g_Config.IniFile, "RecentPaths", "Recent" . entryIndex)
        entryIndex++
    }

    RuntimeConfig.LoadRecentPathsCache()
}
; ============================================================================
; 文件对话框菜单功能
; ============================================================================

AddTotalCommanderFolders(contextMenu, allWindows := "") {
    added := false
    if !IsObject(allWindows) {
        allWindows := WinGetList()
    }

    for winID in allWindows {
        try {
            winClass := WinGetClass("ahk_id " . winID)
            if (winClass = "TTOTAL_CMD") {
                thisPID := WinGetPID("ahk_id " . winID)
                tcExe := GetModuleFileName(thisPID)

                ; 获取源路径
                clipSaved := ClipboardAll()
                A_Clipboard := ""

                SendMessage(1075, g_Config.TC_CopySrcPath, 0, , "ahk_id " . winID)
                Sleep(50)
                if (A_Clipboard != "" && IsValidFolder(A_Clipboard)) {
                    folderPath := A_Clipboard
                    AddFileDialogMenuItemWithQuickAccess(contextMenu, folderPath, tcExe, 0)
                    added := true
                }

                ; 获取目标路径
                SendMessage(1075, g_Config.TC_CopyTrgPath, 0, , "ahk_id " . winID)
                Sleep(50)
                if (A_Clipboard != "" && IsValidFolder(A_Clipboard)) {
                    folderPath := A_Clipboard
                    AddFileDialogMenuItemWithQuickAccess(contextMenu, folderPath, tcExe, 0)
                    added := true
                }

                A_Clipboard := clipSaved
            }
        }
    }

    return added
}

AddExplorerFolders(contextMenu, allWindows := "") {
    added := false
    if !IsObject(allWindows) {
        allWindows := WinGetList()
    }

    for winID in allWindows {
        try {
            winClass := WinGetClass("ahk_id " . winID)
            if (winClass = "CabinetWClass") {
                ; 使用增强的路径获取函数
                explorerPath := GetExplorerPathEnhanced(winID)
                if IsValidFolder(explorerPath) {
                    AddFileDialogMenuItemWithQuickAccess(contextMenu, explorerPath, "shell32.dll", 5)
                    added := true
                }
            }
        } catch {
            continue
        }
    }

    return added
}

AddXYplorerFolders(contextMenu, allWindows := "") {
    added := false
    if !IsObject(allWindows) {
        allWindows := WinGetList()
    }

    for winID in allWindows {
        try {
            winClass := WinGetClass("ahk_id " . winID)
            if (winClass = "ThunderRT6FormDC") {
                thisPID := WinGetPID("ahk_id " . winID)
                xyExe := GetModuleFileName(thisPID)

                clipSaved := ClipboardAll()
                A_Clipboard := ""

                ; 获取活动路径
                SendXYplorerMessage(winID, "::copytext get('path', a);")
                if IsValidFolder(A_Clipboard) {
                    folderPath := A_Clipboard
                    AddFileDialogMenuItemWithQuickAccess(contextMenu, folderPath, xyExe, 0)
                    added := true
                }

                ; 获取非活动路径
                SendXYplorerMessage(winID, "::copytext get('path', i);")
                if IsValidFolder(A_Clipboard) {
                    folderPath := A_Clipboard
                    AddFileDialogMenuItemWithQuickAccess(contextMenu, folderPath, xyExe, 0)
                    added := true
                }

                A_Clipboard := clipSaved
            }
        }
    }

    return added
}

AddOpusFolders(contextMenu, allWindows := "") {
    added := false
    if !IsObject(allWindows) {
        allWindows := WinGetList()
    }

    for winID in allWindows {
        try {
            winClass := WinGetClass("ahk_id " . winID)
            if (winClass = "dopus.lister") {
                thisPID := WinGetPID("ahk_id " . winID)
                dopusExe := GetModuleFileName(thisPID)

                ; 获取Opus信息
                RunWait('"' . dopusExe . '\..\dopusrt.exe" /info "' . g_Config.TempFile . '",paths', , , &dummy)
                Sleep(100)

                try {
                    opusInfo := FileRead(g_Config.TempFile)
                    FileDelete(g_Config.TempFile)

                    ; 解析活动和被动路径
                    if RegExMatch(opusInfo, 'lister="' . winID . '".*tab_state="1".*>(.*)</path>', &match) {
                        folderPath := match[1]
                        if IsValidFolder(folderPath) {
                            AddFileDialogMenuItemWithQuickAccess(contextMenu, folderPath, dopusExe, 0)
                            added := true
                        }
                    }

                    if RegExMatch(opusInfo, 'lister="' . winID . '".*tab_state="2".*>(.*)</path>', &match) {
                        folderPath := match[1]
                        if IsValidFolder(folderPath) {
                            AddFileDialogMenuItemWithQuickAccess(contextMenu, folderPath, dopusExe, 0)
                            added := true
                        }
                    }
                }
            }
        }
    }

    return added
}

AddFileDialogMenuItemWithQuickAccess(contextMenu, folderPath, iconPath := "", iconIndex := 0) {
    ; 添加到菜单项数组用于快速访问
    g_MenuItems.Push(folderPath)

    ; 创建带快速访问快捷键的显示文本（如果启用）
    displayText := folderPath
    if g_Config.EnableQuickAccess = "1" && g_MenuItems.Length <= StrLen(g_Config.QuickAccessKeys) {
        shortcutKey := SubStr(g_Config.QuickAccessKeys, g_MenuItems.Length, 1)
        displayText := "[" "&" . shortcutKey . "] " . folderPath
    }

    ; 添加菜单项
    contextMenu.Add(displayText, FolderChoiceHandler.Bind(folderPath))

    ; 设置图标（如果提供）
    if iconPath != "" {
        try contextMenu.SetIcon(displayText, iconPath, iconIndex, g_Config.IconSize)
    }
}

; ============================================================================
; 对话框检测和路径注入
; ============================================================================

; ============================================================================
; 设置功能
; ============================================================================

EditConfigFile(*) {
    try {
        configToolPath := A_ScriptDir "\ConfigTool.ahk"
        if FileExist(configToolPath) {
            Run(configToolPath)
        } else {
            ; 如果ConfigTool不存在，回退到用记事本打开INI文件
            Run("notepad.exe " . g_Config.IniFile)
        }
    } catch {
        MsgBox("无法打开配置工具", "错误", "T3")
    }
}

ReloadConfig(*) {
    try {
        RuntimeConfig.Load()

        ; 重新注册所有热键
        try Hotkey(g_Config.MainHotkey, "Off")
        try Hotkey(g_Config.QuickSwitchHotkey, "Off")
        try Hotkey(g_Config.GetWindowsFolderActivePathKey, "Off")

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
        UTF8IniWrite(mode, g_Config.IniFile, "Settings", "RunMode")

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

ToggleGetWindowsFolderActivePath(*) {
    ; 切换功能状态
    currentState := g_Config.EnableGetWindowsFolderActivePath
    newState := (currentState = "1") ? "0" : "1"

    ; 更新配置
    g_Config.EnableGetWindowsFolderActivePath := newState

    ; 保存到配置文件
    try {
        UTF8IniWrite(newState, g_Config.IniFile, "Settings", "EnableGetWindowsFolderActivePath")
    } catch as e {
        MsgBox("保存配置失败: " . e.message, "错误", "T3")
        return
    }

    ; 注册或注销热键
    try {
        if (newState = "1") {
            ; 开启功能 - 注册热键
            Hotkey(g_Config.GetWindowsFolderActivePathKey, GetWindowsFolderActivePath, "On")
            MsgBox("GetWindowsFolderActivePath功能已开启\n热键: " . g_Config.GetWindowsFolderActivePathKey, "功能切换", "T3")
        } else {
            ; 关闭功能 - 注销热键
            Hotkey(g_Config.GetWindowsFolderActivePathKey, "Off")
            MsgBox("GetWindowsFolderActivePath功能已关闭", "功能切换", "T3")
        }
    } catch as e {
        MsgBox("切换热键失败: " . e.message, "错误", "T3")
    }
}

ShowAbout(*) {
    aboutText := "QuickSwitch v1.3`n"
        . "快速切换【对话框&程序】工具`n"
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
        . "• " . g_Config.GetWindowsFolderActivePathKey . " - 直接载入最近打开的窗口(状态: " . (g_Config.EnableGetWindowsFolderActivePath =
            "1" ? "开启" : "关闭") . ")`n"
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
        UTF8IniWrite(g_DarkMode ? "1" : "0", g_Config.IniFile, "Theme", "DarkMode")

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

    ; 启动文件对话框监控
    SetTimer(MonitorFileDialogs, 200)

    ; 主事件循环
    loop {
        Sleep(100)
    }
}

MonitorFileDialogs() {
    static lastDialogID := ""
    static dialogProcessed := false

    ; 如果菜单正在显示，暂停监控
    if (g_MenuActive || RuntimeMenu.IsRequestThrottled()) {
        return
    }

    ; 获取当前激活窗口
    currentWinID := WinExist("A")

    ; 检查窗口ID是否有效
    if (!currentWinID) {
        return
    }

    dialogType := GetFileDialogType(currentWinID)
    if (dialogType != "") {
        ; 如果是新的对话框或者之前没有处理过
        if (currentWinID != lastDialogID || !dialogProcessed) {
            lastDialogID := currentWinID
            dialogProcessed := true

            ; 设置当前对话框信息
            if (RuntimeFileDialog.Sync(currentWinID)) {
                ProcessFileDialog()
            }
        }
    } else {
        ; 如果不是文件对话框，重置状态
        if (currentWinID != lastDialogID) {
            lastDialogID := ""
            dialogProcessed := false
            CleanupFileDialogGlobals()
        }
    }
}

ProcessFileDialog() {
    RuntimeFileDialog.ResolveAndStoreAction()

    if (g_CurrentDialog.Action = "1") {
        ; 自动切换模式
        folderPath := GetActiveFileManagerFolder(g_CurrentDialog.WinID)

        if IsValidFolder(folderPath) {
            ; 自动切换成功：记录路径并切换到文件夹
            RecordRecentPath(folderPath)
            FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
        }
        ; 注意：自动切换失败时不显示菜单，等待用户手动按快捷键
    } else if (g_CurrentDialog.Action = "0") {
        ; Never here mode - 什么都不做
    } else if (g_CurrentDialog.Action = "2") {
        ; 自动弹出菜单模式
        ; 延迟一点时间确保对话框完全加载
        SetTimer(DelayedShowMenu.Bind(g_CurrentDialog.WinID), -200)
    } else {
        ; Show menu mode - 不自动显示菜单，等待用户按热键
    }
}

DelayedShowMenu(expectedWinID) {
    if (RuntimeFileDialog.CanShowDelayed(expectedWinID)) {
        ShowFileDialogMenuInternal()
    }
}

CleanupFileDialogGlobals() {
    RuntimeFileDialog.Clear()
}

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
