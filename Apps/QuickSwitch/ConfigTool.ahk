;===========================================================
; QuickSwitch 配置工具 - AHK v2
;===========================================================
#Requires AutoHotkey v2.0
#SingleInstance Force

global IniFile := A_ScriptDir "\QuickSwitch.ini"
global MyGui := ""
global Data := Map()

#Include lib\UTF8Ini.ahk

Main()

Main() {
    ReadAllConfig()
    CreateGUI()
}

ReadAllConfig() {
    global Data
    Data["MainHotkey"] := UTF8IniRead(IniFile, "Settings", "MainHotkey", "^q")
    Data["QuickSwitchHotkey"] := UTF8IniRead(IniFile, "Settings", "QuickSwitchHotkey", "^Tab")
    Data["GetWindowsFolderActivePathKey"] := UTF8IniRead(IniFile, "Settings", "GetWindowsFolderActivePathKey", "!w")
    Data["EnableGetWindowsFolderActivePath"] := UTF8IniRead(IniFile, "Settings", "EnableGetWindowsFolderActivePath", "0")
    Data["MaxHistoryCount"] := UTF8IniRead(IniFile, "Settings", "MaxHistoryCount", "10")
    Data["EnableQuickAccess"] := UTF8IniRead(IniFile, "Settings", "EnableQuickAccess", "1")
    Data["QuickAccessKeys"] := UTF8IniRead(IniFile, "Settings", "QuickAccessKeys", "123456789abcdefghijklmnopqrstuvwxyz")
    Data["RunMode"] := UTF8IniRead(IniFile, "Settings", "RunMode", "0")
    Data["MenuColor"] := UTF8IniRead(IniFile, "Display", "MenuColor", "C0C59C")
    Data["IconSize"] := UTF8IniRead(IniFile, "Display", "IconSize", "16")
    Data["ShowWindowTitle"] := UTF8IniRead(IniFile, "Display", "ShowWindowTitle", "1")
    Data["ShowProcessName"] := UTF8IniRead(IniFile, "Display", "ShowProcessName", "1")
    Data["WindowSwitchPosition"] := UTF8IniRead(IniFile, "WindowSwitchMenu", "Position", "mouse")
    Data["WindowSwitchFixedPosX"] := UTF8IniRead(IniFile, "WindowSwitchMenu", "FixedPosX", "100")
    Data["WindowSwitchFixedPosY"] := UTF8IniRead(IniFile, "WindowSwitchMenu", "FixedPosY", "100")
    Data["PathSwitchPosition"] := UTF8IniRead(IniFile, "PathSwitchMenu", "Position", "fixed")
    Data["PathSwitchFixedPosX"] := UTF8IniRead(IniFile, "PathSwitchMenu", "FixedPosX", "100")
    Data["PathSwitchFixedPosY"] := UTF8IniRead(IniFile, "PathSwitchMenu", "FixedPosY", "100")
    Data["TotalCommander"] := UTF8IniRead(IniFile, "FileManagers", "TotalCommander", "1")
    Data["Explorer"] := UTF8IniRead(IniFile, "FileManagers", "Explorer", "1")
    Data["XYplorer"] := UTF8IniRead(IniFile, "FileManagers", "XYplorer", "1")
    Data["DirectoryOpus"] := UTF8IniRead(IniFile, "FileManagers", "DirectoryOpus", "1")
    Data["EnableCustomPaths"] := UTF8IniRead(IniFile, "CustomPaths", "EnableCustomPaths", "1")
    Data["CustomPathsMenuTitle"] := UTF8IniRead(IniFile, "CustomPaths", "MenuTitle", "收藏路径")
    Data["ShowCustomName"] := UTF8IniRead(IniFile, "CustomPaths", "ShowCustomName", "0")
    Data["EnableRecentPaths"] := UTF8IniRead(IniFile, "RecentPaths", "EnableRecentPaths", "1")
    Data["RecentPathsMenuTitle"] := UTF8IniRead(IniFile, "RecentPaths", "MenuTitle", "最近打开")
    Data["MaxRecentPaths"] := UTF8IniRead(IniFile, "RecentPaths", "MaxRecentPaths", "10")
    Data["EnableQuickLaunchApps"] := UTF8IniRead(IniFile, "QuickLaunchApps", "EnableQuickLaunchApps", "1")
    Data["MaxDisplayCount"] := UTF8IniRead(IniFile, "QuickLaunchApps", "MaxDisplayCount", "3")
    
    ; [Theme]
    Data["DarkMode"] := UTF8IniRead(IniFile, "Theme", "DarkMode", "0")
}

CreateGUI() {
    global MyGui, Data
    MyGui := Gui("+Resize", "QuickSwitch 配置工具")
    MyGui.OnEvent("Close", (*) => ExitApp())
    Tab := MyGui.Add("Tab3", "x10 y10 w760 h540", ["基本设置", "显示设置", "路径管理", "程序管理", "快速启动", "文件管理器"])
    CreateBasicTab(Tab)
    CreateDisplayTab(Tab)
    CreatePathTab(Tab)
    CreateAppTab(Tab)
    CreateLaunchTab(Tab)
    CreateFileManagerTab(Tab)
    Tab.UseTab()
    MyGui.Add("Button", "x280 y560 w80 h30", "保存配置").OnEvent("Click", SaveAllConfig)
    MyGui.Add("Button", "x370 y560 w80 h30", "重新加载").OnEvent("Click", (*) => Reload())
    MyGui.Add("Button", "x460 y560 w80 h30", "关闭").OnEvent("Click", (*) => ExitApp())
    MyGui.Show("w780 h600")
}

CreateBasicTab(Tab) {
    global Data
    Tab.UseTab("基本设置")
    MyGui.Add("GroupBox", "x20 y40 w360 h180", "快捷键设置")
    MyGui.Add("Text", "x30 y65", "主快捷键:")
    Data["MainHotkeyCtrl"] := MyGui.Add("Hotkey", "x30 y85 w330", Data["MainHotkey"])
    MyGui.Add("Text", "x30 y115", "快速切换:")
    Data["QuickSwitchHotkeyCtrl"] := MyGui.Add("Hotkey", "x30 y135 w330", Data["QuickSwitchHotkey"])
    MyGui.Add("Text", "x30 y165", "获取路径:")
    Data["GetPathKeyCtrl"] := MyGui.Add("Hotkey", "x30 y185 w330", Data["GetWindowsFolderActivePathKey"])
    MyGui.Add("GroupBox", "x390 y40 w360 h180", "功能设置")
    Data["EnableGetPathCtrl"] := MyGui.Add("Checkbox", "x400 y65 Checked" Data["EnableGetWindowsFolderActivePath"], "启用获取文件管理器路径")
    Data["EnableQuickAccessCtrl"] := MyGui.Add("Checkbox", "x400 y95 Checked" Data["EnableQuickAccess"], "启用快速访问键")
    MyGui.Add("Text", "x400 y125", "运行模式:")
    Data["RunModeCtrl"] := MyGui.Add("DropDownList", "x400 y145 w330 Choose" (Integer(Data["RunMode"]) + 1), ["全部运行(智能判断)", "只运行路径跳转", "只运行程序切换"])
    MyGui.Add("Text", "x400 y180", "最大历史记录数:")
    Data["MaxHistoryCountCtrl"] := MyGui.Add("Edit", "x550 y175 w80", Data["MaxHistoryCount"])
    MyGui.Add("UpDown", "Range1-50", Data["MaxHistoryCount"])
    
    ; 主题设置
    MyGui.Add("GroupBox", "x390 y230 w360 h80", "主题设置")
    Data["DarkModeCtrl"] := MyGui.Add("Checkbox", "x400 y255 Checked" Data["DarkMode"], "启用深色主题")
    MyGui.Add("Text", "x400 y280", "(需要重启程序生效)")
    MyGui.Add("GroupBox", "x20 y230 w730 h80", "快速访问键")
    MyGui.Add("Text", "x30 y255", "快速访问键序列:")
    Data["QuickAccessKeysCtrl"] := MyGui.Add("Edit", "x30 y275 w710", Data["QuickAccessKeys"])
    MyGui.Add("GroupBox", "x20 y320 w730 h100", "最近路径设置")
    Data["EnableRecentPathsCtrl"] := MyGui.Add("Checkbox", "x30 y345 Checked" Data["EnableRecentPaths"], "启用最近路径")
    MyGui.Add("Text", "x30 y370", "菜单标题:")
    Data["RecentMenuTitleCtrl"] := MyGui.Add("Edit", "x120 y367 w200", Data["RecentPathsMenuTitle"])
    MyGui.Add("Text", "x350 y370", "最大路径数:")
    Data["MaxRecentPathsCtrl"] := MyGui.Add("Edit", "x450 y367 w80", Data["MaxRecentPaths"])
    MyGui.Add("UpDown", "Range1-50", Data["MaxRecentPaths"])
    MyGui.Add("Button", "x30 y395 w150", "清除最近路径").OnEvent("Click", ClearRecentPaths)
}

CreateDisplayTab(Tab) {
    global Data
    Tab.UseTab("显示设置")
    MyGui.Add("GroupBox", "x20 y40 w360 h200", "外观设置")
    MyGui.Add("Text", "x30 y65", "菜单颜色:")
    Data["MenuColorCtrl"] := MyGui.Add("Edit", "x30 y85 w120", Data["MenuColor"])
    MyGui.Add("Button", "x160 y83 w80", "选择颜色").OnEvent("Click", PickColor)
    MyGui.Add("Text", "x30 y120", "图标大小:")
    Data["IconSizeCtrl"] := MyGui.Add("Edit", "x30 y140 w120", Data["IconSize"])
    MyGui.Add("UpDown", "Range8-64", Data["IconSize"])
    Data["ShowWindowTitleCtrl"] := MyGui.Add("Checkbox", "x30 y175 Checked" Data["ShowWindowTitle"], "显示窗口标题")
    Data["ShowProcessNameCtrl"] := MyGui.Add("Checkbox", "x30 y200 Checked" Data["ShowProcessName"], "显示进程名称")
    MyGui.Add("GroupBox", "x390 y40 w360 h200", "窗口切换菜单位置")
    Data["WinPos1Ctrl"] := MyGui.Add("Radio", "x400 y65 Group", "鼠标位置")
    Data["WinPos2Ctrl"] := MyGui.Add("Radio", "x400 y90", "固定位置")
    if (Data["WindowSwitchPosition"] = "mouse")
        Data["WinPos1Ctrl"].Value := 1
    else
        Data["WinPos2Ctrl"].Value := 1
    Data["WinPos1Ctrl"].OnEvent("Click", (*) => UpdateWinPosControls())
    Data["WinPos2Ctrl"].OnEvent("Click", (*) => UpdateWinPosControls())
    MyGui.Add("Text", "x400 y120", "X 坐标:")
    Data["WinPosXCtrl"] := MyGui.Add("Edit", "x460 y117 w100", Data["WindowSwitchFixedPosX"])
    MyGui.Add("Text", "x400 y150", "Y 坐标:")
    Data["WinPosYCtrl"] := MyGui.Add("Edit", "x460 y147 w100", Data["WindowSwitchFixedPosY"])
    UpdateWinPosControls()
    MyGui.Add("GroupBox", "x20 y250 w360 h170", "路径切换菜单位置")
    Data["PathPos1Ctrl"] := MyGui.Add("Radio", "x30 y275 Group", "鼠标位置")
    Data["PathPos2Ctrl"] := MyGui.Add("Radio", "x30 y300", "固定位置")
    if (Data["PathSwitchPosition"] = "mouse")
        Data["PathPos1Ctrl"].Value := 1
    else
        Data["PathPos2Ctrl"].Value := 1
    Data["PathPos1Ctrl"].OnEvent("Click", (*) => UpdatePathPosControls())
    Data["PathPos2Ctrl"].OnEvent("Click", (*) => UpdatePathPosControls())
    MyGui.Add("Text", "x30 y330", "X 坐标:")
    Data["PathPosXCtrl"] := MyGui.Add("Edit", "x90 y327 w100", Data["PathSwitchFixedPosX"])
    MyGui.Add("Text", "x30 y360", "Y 坐标:")
    Data["PathPosYCtrl"] := MyGui.Add("Edit", "x90 y357 w100", Data["PathSwitchFixedPosY"])
    UpdatePathPosControls()
}

CreatePathTab(Tab) {
    global Data
    Tab.UseTab("路径管理")
    MyGui.Add("GroupBox", "x20 y40 w730 h140", "自定义路径设置")
    Data["EnableCustomPathsCtrl"] := MyGui.Add("Checkbox", "x30 y65 Checked" Data["EnableCustomPaths"], "启用自定义路径")
    MyGui.Add("Text", "x30 y90", "菜单标题:")
    Data["CustomMenuTitleCtrl"] := MyGui.Add("Edit", "x120 y87 w200", Data["CustomPathsMenuTitle"])
    Data["ShowCustomNameCtrl"] := MyGui.Add("Checkbox", "x350 y90 Checked" Data["ShowCustomName"], "显示自定义名称")
    MyGui.Add("Text", "x30 y120", "格式: 显示名称|路径|置顶标记(1=置顶)")
    MyGui.Add("GroupBox", "x20 y190 w730 h230", "自定义路径列表")
    Data["PathListCtrl"] := MyGui.Add("ListView", "x30 y210 w630 h200 Grid", ["序号", "显示名称", "路径", "置顶"])
    Data["PathListCtrl"].ModifyCol(1, 50)
    Data["PathListCtrl"].ModifyCol(2, 150)
    Data["PathListCtrl"].ModifyCol(3, 350)
    Data["PathListCtrl"].ModifyCol(4, 50)
    LoadCustomPaths()
    MyGui.Add("Button", "x670 y210 w70", "添加").OnEvent("Click", AddPath)
    MyGui.Add("Button", "x670 y245 w70", "编辑").OnEvent("Click", EditPath)
    MyGui.Add("Button", "x670 y280 w70", "删除").OnEvent("Click", DeletePath)
    MyGui.Add("Button", "x670 y315 w70", "上移").OnEvent("Click", MoveUpPath)
    MyGui.Add("Button", "x670 y350 w70", "下移").OnEvent("Click", MoveDownPath)
}

CreateAppTab(Tab) {
    global Data
    Tab.UseTab("程序管理")
    MyGui.Add("GroupBox", "x20 y40 w360 h380", "排除的程序列表")
    Data["ExcludedListCtrl"] := MyGui.Add("ListView", "x30 y60 w270 h350 Grid", ["序号", "程序名称"])
    Data["ExcludedListCtrl"].ModifyCol(1, 50)
    Data["ExcludedListCtrl"].ModifyCol(2, 200)
    LoadExcludedApps()
    MyGui.Add("Button", "x310 y60 w60", "添加").OnEvent("Click", AddExcluded)
    MyGui.Add("Button", "x310 y95 w60", "删除").OnEvent("Click", DeleteExcluded)
    MyGui.Add("GroupBox", "x390 y40 w360 h380", "置顶的程序列表")
    Data["PinnedListCtrl"] := MyGui.Add("ListView", "x400 y60 w270 h350 Grid", ["序号", "程序名称"])
    Data["PinnedListCtrl"].ModifyCol(1, 50)
    Data["PinnedListCtrl"].ModifyCol(2, 200)
    LoadPinnedApps()
    MyGui.Add("Button", "x680 y60 w60", "添加").OnEvent("Click", AddPinned)
    MyGui.Add("Button", "x680 y95 w60", "删除").OnEvent("Click", DeletePinned)
    MyGui.Add("Button", "x680 y130 w60", "上移").OnEvent("Click", MoveUpPinned)
    MyGui.Add("Button", "x680 y165 w60", "下移").OnEvent("Click", MoveDownPinned)
}

CreateLaunchTab(Tab) {
    global Data
    Tab.UseTab("快速启动")
    MyGui.Add("GroupBox", "x20 y40 w730 h100", "快速启动设置")
    Data["EnableLaunchCtrl"] := MyGui.Add("Checkbox", "x30 y65 Checked" Data["EnableQuickLaunchApps"], "启用快速启动应用程序")
    MyGui.Add("Text", "x30 y95", "主菜单最大显示数量:")
    Data["MaxDisplayCountCtrl"] := MyGui.Add("Edit", "x180 y92 w80", Data["MaxDisplayCount"])
    MyGui.Add("UpDown", "Range1-20", Data["MaxDisplayCount"])
    MyGui.Add("Text", "x280 y95", "(超出部分放入'更多'子菜单)")
    MyGui.Add("GroupBox", "x20 y150 w730 h270", "快速启动应用列表")
    MyGui.Add("Text", "x30 y170", "格式: 显示名称|进程名|路径(可选)|快捷键(可选)")
    Data["LaunchListCtrl"] := MyGui.Add("ListView", "x30 y190 w630 h220 Grid", ["序号", "显示名称", "进程名", "路径", "快捷键"])
    Data["LaunchListCtrl"].ModifyCol(1, 50)
    Data["LaunchListCtrl"].ModifyCol(2, 120)
    Data["LaunchListCtrl"].ModifyCol(3, 100)
    Data["LaunchListCtrl"].ModifyCol(4, 250)
    Data["LaunchListCtrl"].ModifyCol(5, 80)
    LoadLaunchApps()
    MyGui.Add("Button", "x670 y190 w70", "添加").OnEvent("Click", AddLaunch)
    MyGui.Add("Button", "x670 y225 w70", "编辑").OnEvent("Click", EditLaunch)
    MyGui.Add("Button", "x670 y260 w70", "删除").OnEvent("Click", DeleteLaunch)
    MyGui.Add("Button", "x670 y295 w70", "上移").OnEvent("Click", MoveUpLaunch)
    MyGui.Add("Button", "x670 y330 w70", "下移").OnEvent("Click", MoveDownLaunch)
}

CreateFileManagerTab(Tab) {
    global Data
    Tab.UseTab("文件管理器")
    MyGui.Add("GroupBox", "x20 y40 w730 h200", "支持的文件管理器")
    MyGui.Add("Text", "x30 y65", "选择需要支持的文件管理器:")
    Data["TCCtrl"] := MyGui.Add("Checkbox", "x30 y95 Checked" Data["TotalCommander"], "Total Commander")
    Data["ExplorerCtrl"] := MyGui.Add("Checkbox", "x30 y125 Checked" Data["Explorer"], "Windows 资源管理器")
    Data["XYCtrl"] := MyGui.Add("Checkbox", "x30 y155 Checked" Data["XYplorer"], "XYplorer")
    Data["DOpusCtrl"] := MyGui.Add("Checkbox", "x30 y185 Checked" Data["DirectoryOpus"], "Directory Opus")
}

#Include lib\ConfigFunctions.ahk
