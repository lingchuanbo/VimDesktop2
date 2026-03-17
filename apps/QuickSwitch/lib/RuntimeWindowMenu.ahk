class RuntimeWindowMenu {
    static Render(windowSnapshot, &stageTick, startTick) {
        contextMenu := Menu()
        contextMenu.Add("QuickSwitch - 程序切换", (*) => "")
        contextMenu.Default := "QuickSwitch - 程序切换"
        contextMenu.Disable("QuickSwitch - 程序切换")

        hasMenuItems := false
        pinnedMenuItems := RuntimeWindowState.CollectPinnedWindowMenuItems(windowSnapshot)
        historyMenuItems := RuntimeWindowState.CollectHistoryWindowMenuItems()

        hasMenuItems := this.AddPinnedWindows(contextMenu, pinnedMenuItems, windowSnapshot.AllWindowIds) || hasMenuItems
        RuntimeLog.LogMenuStageElapsed("WindowSwitch", "add_pinned", &stageTick, startTick, g_MenuItems.Length)

        if (hasMenuItems) {
            contextMenu.Add()
        }

        hasMenuItems := this.AddHistoryWindows(contextMenu, historyMenuItems, windowSnapshot.AllWindowIds) || hasMenuItems
        RuntimeLog.LogMenuStageElapsed("WindowSwitch", "add_history", &stageTick, startTick, g_MenuItems.Length)

        if (hasMenuItems) {
            contextMenu.Add()
        }

        quickLaunchAdded := AddQuickLaunchApps(contextMenu)
        RuntimeLog.LogMenuStageElapsed("WindowSwitch", "add_quick_launch", &stageTick, startTick, g_MenuItems.Length)

        if (quickLaunchAdded) {
            contextMenu.Add()
        }

        settingsMenuData := this.CollectWindowSettingsMenuData(windowSnapshot.AllWindowIds)
        this.AddWindowSettingsMenu(contextMenu, settingsMenuData, windowSnapshot.AllWindowIds)
        RuntimeLog.LogMenuStageElapsed("WindowSwitch", "add_settings", &stageTick, startTick, g_MenuItems.Length)

        contextMenu.Color := g_Config.MenuColor
        return contextMenu
    }

    static CollectWindowSettingsMenuData(allWindows := "") {
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

    static AddPinnedWindows(contextMenu, pinnedMenuItems, allWindows := "") {
        added := false

        for item in pinnedMenuItems {
            try {
                this.AddWindowMenuItemWithQuickAccess(
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

    static AddHistoryWindows(contextMenu, historyMenuItems, allWindows := "") {
        added := false

        for item in historyMenuItems {
            try {
                this.AddWindowMenuItemWithQuickAccess(
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

    static AddWindowSettingsMenu(contextMenu, settingsMenuData, allWindows := "") {
        settingsMenu := Menu()
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

        if (g_DarkMode) {
            settingsMenu.Check("切换主题")
        }

        if (g_Config.EnableGetWindowsFolderActivePath = "1") {
            settingsMenu.Check("GetWindowsFolderActivePath功能")
        }

        contextMenu.Add("设置", settingsMenu)
    }

    static AddWindowMenuItemWithQuickAccess(contextMenu, displayText, handler, processName, isPinned := false, allWindows := "") {
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
}
