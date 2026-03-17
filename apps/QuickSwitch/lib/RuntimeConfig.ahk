class RuntimeConfig {
    static ReadConfigValue(section, key, fallback := "") {
        global g_Config
        defaultValue := GetConfigDefault(section, key, fallback)
        return UTF8IniRead(g_Config.IniFile, section, key, defaultValue)
    }

    static Load() {
        global g_Config, g_DarkMode, g_LogEnabled, g_LogRetentionDays
        global g_ExcludedApps, g_PinnedWindows

        g_Config.MainHotkey := this.ReadConfigValue("Settings", "MainHotkey")
        g_Config.QuickSwitchHotkey := this.ReadConfigValue("Settings", "QuickSwitchHotkey")
        g_Config.GetWindowsFolderActivePathKey := this.ReadConfigValue("Settings", "GetWindowsFolderActivePathKey")
        g_Config.EnableGetWindowsFolderActivePath := this.ReadConfigValue("Settings", "EnableGetWindowsFolderActivePath")
        g_Config.MaxHistoryCount := Integer(this.ReadConfigValue("Settings", "MaxHistoryCount"))
        g_Config.EnableQuickAccess := this.ReadConfigValue("Settings", "EnableQuickAccess")
        g_Config.QuickAccessKeys := this.ReadConfigValue("Settings", "QuickAccessKeys")
        g_Config.RunMode := Integer(this.ReadConfigValue("Settings", "RunMode"))
        try {
            g_Config.MenuCooldownMs := Integer(this.ReadConfigValue("Settings", "MenuCooldownMs"))
        } catch {
            g_Config.MenuCooldownMs := Integer(GetConfigDefault("Settings", "MenuCooldownMs", "150"))
        }

        g_Config.MenuColor := this.ReadConfigValue("Display", "MenuColor")
        g_Config.IconSize := Integer(this.ReadConfigValue("Display", "IconSize"))
        g_Config.ShowWindowTitle := this.ReadConfigValue("Display", "ShowWindowTitle")
        g_Config.ShowProcessName := this.ReadConfigValue("Display", "ShowProcessName")

        g_Config.WindowSwitchPosition := this.ReadConfigValue("WindowSwitchMenu", "Position")
        g_Config.WindowSwitchPosX := Integer(this.ReadConfigValue("WindowSwitchMenu", "FixedPosX"))
        g_Config.WindowSwitchPosY := Integer(this.ReadConfigValue("WindowSwitchMenu", "FixedPosY"))

        g_Config.PathSwitchPosition := this.ReadConfigValue("PathSwitchMenu", "Position")
        g_Config.PathSwitchPosX := Integer(this.ReadConfigValue("PathSwitchMenu", "FixedPosX"))
        g_Config.PathSwitchPosY := Integer(this.ReadConfigValue("PathSwitchMenu", "FixedPosY"))

        g_Config.SupportTC := this.ReadConfigValue("FileManagers", "TotalCommander")
        g_Config.SupportExplorer := this.ReadConfigValue("FileManagers", "Explorer")
        g_Config.SupportXY := this.ReadConfigValue("FileManagers", "XYplorer")
        g_Config.SupportOpus := this.ReadConfigValue("FileManagers", "DirectoryOpus")

        g_Config.EnableCustomPaths := this.ReadConfigValue("CustomPaths", "EnableCustomPaths")
        g_Config.CustomPathsTitle := this.ReadConfigValue("CustomPaths", "MenuTitle")
        g_Config.ShowCustomName := this.ReadConfigValue("CustomPaths", "ShowCustomName")

        g_Config.EnableRecentPaths := this.ReadConfigValue("RecentPaths", "EnableRecentPaths")
        g_Config.RecentPathsTitle := this.ReadConfigValue("RecentPaths", "MenuTitle")
        g_Config.MaxRecentPaths := this.ReadConfigValue("RecentPaths", "MaxRecentPaths")

        g_Config.TC_CopySrcPath := Integer(this.ReadConfigValue("TotalCommander", "CopySrcPath"))
        g_Config.TC_CopyTrgPath := Integer(this.ReadConfigValue("TotalCommander", "CopyTrgPath"))

        g_DarkMode := this.ReadConfigValue("Theme", "DarkMode") = "1"
        g_Config.FileDialogDefaultAction := this.ReadConfigValue("FileDialog", "DefaultAction")

        g_Config.EnableLog := this.ReadConfigValue("Settings", "EnableLog")
        g_LogEnabled := g_Config.EnableLog = "1"
        try {
            g_Config.LogRetentionDays := Integer(this.ReadConfigValue("Settings", "LogRetentionDays"))
        } catch {
            g_Config.LogRetentionDays := Integer(GetConfigDefault("Settings", "LogRetentionDays", "7"))
        }

        WindowsTheme.SetAppMode(g_DarkMode)

        g_ExcludedApps.Length := 0
        loop 50 {
            appKey := "App" . A_Index
            appValue := UTF8IniRead(g_Config.IniFile, "ExcludedApps", appKey, "")
            if (appValue != "") {
                g_ExcludedApps.Push(StrLower(appValue))
            }
        }

        g_PinnedWindows.Length := 0
        loop 20 {
            appKey := "App" . A_Index
            appValue := UTF8IniRead(g_Config.IniFile, "PinnedApps", appKey, "")
            if (appValue != "") {
                g_PinnedWindows.Push(StrLower(appValue))
            }
        }

        this.Validate()
        g_LogRetentionDays := g_Config.LogRetentionDays
        this.ResetRuntimeLookupCaches()
        this.RefreshMenuCaches()
    }

    static Validate() {
        global g_Config, g_MenuCooldownMs, g_LogRetentionDays

        configErrors := []

        if (g_Config.MainHotkey = "") {
            configErrors.Push("主快捷键配置缺失")
        }

        if (g_Config.QuickSwitchHotkey = "") {
            configErrors.Push("快速切换热键配置缺失")
        }

        if (g_Config.GetWindowsFolderActivePathKey = "") {
            configErrors.Push("GetWindowsFolderActivePath热键配置缺失")
        }

        if (g_Config.MaxHistoryCount <= 0) {
            configErrors.Push("历史记录数量配置错误")
            g_Config.MaxHistoryCount := 10
        }

        if (g_Config.IconSize <= 0) {
            configErrors.Push("图标大小配置错误")
            g_Config.IconSize := 16
        }

        if (g_Config.MenuCooldownMs < 50 || g_Config.MenuCooldownMs > 1000) {
            configErrors.Push("MenuCooldownMs配置错误（允许范围: 50-1000）")
            g_Config.MenuCooldownMs := Integer(GetConfigDefault("Settings", "MenuCooldownMs", "150"))
        }

        if (g_Config.LogRetentionDays < 1 || g_Config.LogRetentionDays > 365) {
            configErrors.Push("LogRetentionDays配置错误（允许范围: 1-365）")
            g_Config.LogRetentionDays := Integer(GetConfigDefault("Settings", "LogRetentionDays", "7"))
        }

        if (g_Config.EnableGetWindowsFolderActivePath != "0" && g_Config.EnableGetWindowsFolderActivePath != "1") {
            configErrors.Push("EnableGetWindowsFolderActivePath开关配置错误")
            g_Config.EnableGetWindowsFolderActivePath := GetConfigDefault("Settings", "EnableGetWindowsFolderActivePath", "0")
        }

        if (configErrors.Length > 0) {
            errorMsg := "发现配置错误：`n"
            for errorItem in configErrors {
                errorMsg .= "- " . errorItem . "`n"
            }
            errorMsg .= "`n已使用默认值修复。建议检查配置文件。"
            MsgBox(errorMsg, "配置验证警告", "Icon! T10")
        }

        g_MenuCooldownMs := g_Config.MenuCooldownMs
        g_LogRetentionDays := g_Config.LogRetentionDays
    }

    static RefreshMenuCaches() {
        this.LoadQuickLaunchCache()
        this.LoadCustomPathsCache()
        this.LoadRecentPathsCache()
    }

    static ResetRuntimeLookupCaches() {
        global g_AppExecutableCache, g_ProcessIconCache, g_RuntimeLookupMissCache

        g_AppExecutableCache := Map()
        g_ProcessIconCache := Map()
        g_RuntimeLookupMissCache := { appExe: Map(), processIcon: Map() }
    }

    static LoadQuickLaunchCache() {
        global g_Config, g_QuickLaunchCache

        section := "QuickLaunchApps"
        enabled := true
        maxDisplayCount := 2
        appList := []

        try {
            enabled := Integer(UTF8IniRead(g_Config.IniFile, section, "EnableQuickLaunchApps", "1")) = 1
        } catch {
            enabled := true
        }

        try {
            maxDisplayCount := Integer(UTF8IniRead(g_Config.IniFile, section, "MaxDisplayCount", "2"))
        } catch {
            maxDisplayCount := 2
        }
        if (maxDisplayCount < 0) {
            maxDisplayCount := 0
        }

        loop {
            appIndex := A_Index
            appConfig := UTF8IniRead(g_Config.IniFile, section, "App" . appIndex, "")
            if (appConfig = "") {
                break
            }

            parts := StrSplit(appConfig, "|")
            if (parts.Length >= 2) {
                appList.Push({
                    displayName: parts[1],
                    processName: parts[2],
                    exePath: parts.Length >= 3 ? parts[3] : "",
                    hotkey: parts.Length >= 4 ? parts[4] : ""
                })
            }
        }

        g_QuickLaunchCache := {
            enabled: enabled,
            maxDisplayCount: maxDisplayCount,
            apps: appList
        }
    }

    static LoadCustomPathsCache() {
        global g_Config, g_CustomPathsCache

        showCustomName := g_Config.ShowCustomName = "1"
        pinnedPaths := []
        normalPaths := []

        loop 20 {
            pathKey := "Path" . A_Index
            pathValue := UTF8IniRead(g_Config.IniFile, "CustomPaths", pathKey, "")
            if (pathValue = "") {
                continue
            }

            displayName := ""
            actualPath := ""
            isPinned := false

            if InStr(pathValue, "|") {
                parts := StrSplit(pathValue, "|", " `t")
                if (parts.Length >= 2) {
                    displayName := parts[1]
                    actualPath := parts[2]
                    if (parts.Length >= 3 && Trim(parts[3]) = "1") {
                        isPinned := true
                    }
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
            if !IsValidFolder(expandedPath) {
                continue
            }

            finalDisplayText := showCustomName ? displayName : expandedPath
            pathObj := { display: finalDisplayText, path: expandedPath, isPinned: isPinned }

            if (isPinned) {
                pinnedPaths.Push(pathObj)
            } else {
                normalPaths.Push(pathObj)
            }
        }

        g_CustomPathsCache := {
            pinnedPaths: pinnedPaths,
            normalPaths: normalPaths
        }
    }

    static LoadRecentPathsCache() {
        global g_Config, g_RecentPathsCache

        recentPaths := []
        maxPaths := Integer(g_Config.MaxRecentPaths)
        if (maxPaths <= 0) {
            maxPaths := 1
        }

        loop maxPaths {
            recentValue := UTF8IniRead(g_Config.IniFile, "RecentPaths", "Recent" . A_Index, "")
            if (recentValue = "") {
                continue
            }

            if InStr(recentValue, "|") {
                parts := StrSplit(recentValue, "|", " `t")
                pathValue := parts.Length >= 2 ? parts[2] : recentValue
            } else {
                pathValue := recentValue
            }

            if IsValidFolder(pathValue) {
                recentPaths.Push(pathValue)
            }
        }

        g_RecentPathsCache := recentPaths
    }
}
