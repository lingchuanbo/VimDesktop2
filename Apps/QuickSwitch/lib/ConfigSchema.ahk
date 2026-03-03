;===========================================================
; ConfigSchema.ahk - Shared config defaults
;===========================================================

GetConfigDefaults() {
    static defaults := Map(
        "Settings", Map(
            "MainHotkey", "^q",
            "QuickSwitchHotkey", "^Tab",
            "GetWindowsFolderActivePathKey", "!w",
            "EnableGetWindowsFolderActivePath", "0",
            "MenuCooldownMs", "150",
            "MaxHistoryCount", "10",
            "EnableQuickAccess", "1",
            "QuickAccessKeys", "123456789abcdefghijklmnopqrstuvwxyz",
            "RunMode", "0",
            "EnableLog", "0",
            "LogRetentionDays", "7"
        ),
        "Display", Map(
            "MenuColor", "C0C59C",
            "IconSize", "16",
            "ShowWindowTitle", "1",
            "ShowProcessName", "1"
        ),
        "WindowSwitchMenu", Map(
            "Position", "mouse",
            "FixedPosX", "100",
            "FixedPosY", "100"
        ),
        "PathSwitchMenu", Map(
            "Position", "fixed",
            "FixedPosX", "100",
            "FixedPosY", "100"
        ),
        "FileManagers", Map(
            "TotalCommander", "1",
            "Explorer", "1",
            "XYplorer", "1",
            "DirectoryOpus", "1"
        ),
        "CustomPaths", Map(
            "EnableCustomPaths", "1",
            "MenuTitle", "收藏路径",
            "ShowCustomName", "0"
        ),
        "RecentPaths", Map(
            "EnableRecentPaths", "1",
            "MenuTitle", "最近打开",
            "MaxRecentPaths", "10"
        ),
        "QuickLaunchApps", Map(
            "EnableQuickLaunchApps", "1",
            "MaxDisplayCount", "3"
        ),
        "TotalCommander", Map(
            "CopySrcPath", "2029",
            "CopyTrgPath", "2030"
        ),
        "Theme", Map(
            "DarkMode", "0"
        ),
        "FileDialog", Map(
            "DefaultAction", "manual"
        )
    )
    return defaults
}

GetConfigDefault(section, key, fallback := "") {
    defaults := GetConfigDefaults()
    if (defaults.Has(section) && defaults[section].Has(key)) {
        return defaults[section][key]
    }
    return fallback
}
