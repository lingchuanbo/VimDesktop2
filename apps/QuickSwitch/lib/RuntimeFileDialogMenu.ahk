class RuntimeFileDialogMenu {
    static Render(fileManagerWindows, &stageTick, startTick) {
        contextMenu := Menu()
        contextMenu.Add("QuickSwitch - 路径切换", (*) => "")
        contextMenu.Default := "QuickSwitch - 路径切换"
        contextMenu.Disable("QuickSwitch - 路径切换")

        hasMenuItems := false

        if g_Config.SupportTC = "1" {
            hasMenuItems := this.AddTotalCommanderFolders(contextMenu, fileManagerWindows) || hasMenuItems
            RuntimeLog.LogMenuStageElapsed("FileDialog", "scan_tc", &stageTick, startTick, g_MenuItems.Length)
        }
        if g_Config.SupportExplorer = "1" {
            hasMenuItems := this.AddExplorerFolders(contextMenu, fileManagerWindows) || hasMenuItems
            RuntimeLog.LogMenuStageElapsed("FileDialog", "scan_explorer", &stageTick, startTick, g_MenuItems.Length)
        }
        if g_Config.SupportXY = "1" {
            hasMenuItems := this.AddXYplorerFolders(contextMenu, fileManagerWindows) || hasMenuItems
            RuntimeLog.LogMenuStageElapsed("FileDialog", "scan_xyplorer", &stageTick, startTick, g_MenuItems.Length)
        }
        if g_Config.SupportOpus = "1" {
            hasMenuItems := this.AddOpusFolders(contextMenu, fileManagerWindows) || hasMenuItems
            RuntimeLog.LogMenuStageElapsed("FileDialog", "scan_opus", &stageTick, startTick, g_MenuItems.Length)
        }

        if g_Config.EnableCustomPaths = "1" {
            hasMenuItems := this.AddCustomPaths(contextMenu) || hasMenuItems
            RuntimeLog.LogMenuStageElapsed("FileDialog", "add_custom_paths", &stageTick, startTick, g_MenuItems.Length)
        }

        if g_Config.EnableRecentPaths = "1" {
            hasMenuItems := this.AddRecentPaths(contextMenu) || hasMenuItems
            RuntimeLog.LogMenuStageElapsed("FileDialog", "add_recent_paths", &stageTick, startTick, g_MenuItems.Length)
        }

        this.AddSendToFileManagerMenu(contextMenu)
        RuntimeLog.LogMenuStageElapsed("FileDialog", "add_send_to", &stageTick, startTick, g_MenuItems.Length)

        this.AddFileDialogSettingsMenu(contextMenu)
        RuntimeLog.LogMenuStageElapsed("FileDialog", "add_settings", &stageTick, startTick, g_MenuItems.Length)

        contextMenu.Color := g_Config.MenuColor
        return contextMenu
    }

    static AddCustomPaths(contextMenu) {
        added := false
        customPathsMenu := Menu()
        pinnedPaths := g_CustomPathsCache.pinnedPaths
        normalPaths := g_CustomPathsCache.normalPaths

        if (pinnedPaths.Length > 0 || normalPaths.Length > 0) {
            contextMenu.Add()
            added := true
        }

        if (pinnedPaths.Length > 0) {
            for pathInfo in pinnedPaths {
                displayText := "📌 " . pathInfo.display
                contextMenu.Add(displayText, FolderChoiceHandler.Bind(pathInfo.path))
                try contextMenu.SetIcon(displayText, "shell32.dll", 4, g_Config.IconSize)
            }
        }

        if (normalPaths.Length > 0) {
            for pathInfo in normalPaths {
                customPathsMenu.Add(pathInfo.display, FolderChoiceHandler.Bind(pathInfo.path))
                try customPathsMenu.SetIcon(pathInfo.display, "shell32.dll", 4, g_Config.IconSize)
            }

            contextMenu.Add(g_Config.CustomPathsTitle, customPathsMenu)
            try contextMenu.SetIcon(g_Config.CustomPathsTitle, "shell32.dll", 43, g_Config.IconSize)
        }

        return added
    }

    static AddRecentPaths(contextMenu) {
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

    static AddSendToFileManagerMenu(contextMenu) {
        currentPath := this.GetCurrentDialogPath()

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

    static AddFileDialogSettingsMenu(contextMenu) {
        contextMenu.Add()
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

    static AddTotalCommanderFolders(contextMenu, allWindows := "") {
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

                    clipSaved := ClipboardAll()
                    A_Clipboard := ""

                    SendMessage(1075, g_Config.TC_CopySrcPath, 0, , "ahk_id " . winID)
                    Sleep(50)
                    if (A_Clipboard != "" && IsValidFolder(A_Clipboard)) {
                        folderPath := A_Clipboard
                        this.AddFileDialogMenuItemWithQuickAccess(contextMenu, folderPath, tcExe, 0)
                        added := true
                    }

                    SendMessage(1075, g_Config.TC_CopyTrgPath, 0, , "ahk_id " . winID)
                    Sleep(50)
                    if (A_Clipboard != "" && IsValidFolder(A_Clipboard)) {
                        folderPath := A_Clipboard
                        this.AddFileDialogMenuItemWithQuickAccess(contextMenu, folderPath, tcExe, 0)
                        added := true
                    }

                    A_Clipboard := clipSaved
                }
            }
        }

        return added
    }

    static AddExplorerFolders(contextMenu, allWindows := "") {
        added := false
        if !IsObject(allWindows) {
            allWindows := WinGetList()
        }

        for winID in allWindows {
            try {
                winClass := WinGetClass("ahk_id " . winID)
                if (winClass = "CabinetWClass") {
                    explorerPath := GetExplorerPathEnhanced(winID)
                    if IsValidFolder(explorerPath) {
                        this.AddFileDialogMenuItemWithQuickAccess(contextMenu, explorerPath, "shell32.dll", 5)
                        added := true
                    }
                }
            } catch {
                continue
            }
        }

        return added
    }

    static AddXYplorerFolders(contextMenu, allWindows := "") {
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

                    SendXYplorerMessage(winID, "::copytext get('path', a);")
                    if IsValidFolder(A_Clipboard) {
                        folderPath := A_Clipboard
                        this.AddFileDialogMenuItemWithQuickAccess(contextMenu, folderPath, xyExe, 0)
                        added := true
                    }

                    SendXYplorerMessage(winID, "::copytext get('path', i);")
                    if IsValidFolder(A_Clipboard) {
                        folderPath := A_Clipboard
                        this.AddFileDialogMenuItemWithQuickAccess(contextMenu, folderPath, xyExe, 0)
                        added := true
                    }

                    A_Clipboard := clipSaved
                }
            }
        }

        return added
    }

    static AddOpusFolders(contextMenu, allWindows := "") {
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

                    RunWait('"' . dopusExe . '\..\dopusrt.exe" /info "' . g_Config.TempFile . '",paths', , , &dummy)
                    Sleep(100)

                    try {
                        opusInfo := FileRead(g_Config.TempFile)
                        FileDelete(g_Config.TempFile)

                        if RegExMatch(opusInfo, 'lister="' . winID . '".*tab_state="1".*>(.*)</path>', &match) {
                            folderPath := match[1]
                            if IsValidFolder(folderPath) {
                                this.AddFileDialogMenuItemWithQuickAccess(contextMenu, folderPath, dopusExe, 0)
                                added := true
                            }
                        }

                        if RegExMatch(opusInfo, 'lister="' . winID . '".*tab_state="2".*>(.*)</path>', &match) {
                            folderPath := match[1]
                            if IsValidFolder(folderPath) {
                                this.AddFileDialogMenuItemWithQuickAccess(contextMenu, folderPath, dopusExe, 0)
                                added := true
                            }
                        }
                    }
                }
            }
        }

        return added
    }

    static AddFileDialogMenuItemWithQuickAccess(contextMenu, folderPath, iconPath := "", iconIndex := 0) {
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

    static GetCurrentDialogPath() {
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
        }

        return ""
    }
}
