class RuntimePathSwitch {
    static GetExplorerPathByAPI(winID) {
        try {
            thisPID := WinGetPID("ahk_id " . winID)
            shell := ComObject("Shell.Application")

            for window in shell.Windows {
                try {
                    if (window.hwnd = winID) {
                        try {
                            folder := window.Document
                            if (folder) {
                                return folder.Folder.Self.Path
                            }
                        } catch {
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
        }

        return ""
    }

    static GetExplorerPathByTitle(winID) {
        try {
            title := WinGetTitle("ahk_id " . winID)

            if (RegExMatch(title, "(.+)\\s*-\\s*文件资源管理器", &match)) {
                potentialPath := Trim(match[1])
                if (IsValidFolder(potentialPath)) {
                    return potentialPath
                }
            }

            if (RegExMatch(title, "(.+)\\s*-\\s*File Explorer", &match)) {
                potentialPath := Trim(match[1])
                if (IsValidFolder(potentialPath)) {
                    return potentialPath
                }
            }

            if (InStr(title, ":\\") && !InStr(title, " - ")) {
                potentialPath := Trim(title)
                if (IsValidFolder(potentialPath)) {
                    return potentialPath
                }
            }
        } catch {
        }

        return ""
    }

    static GetExplorerPathEnhanced(winID) {
        apiPath := this.GetExplorerPathByAPI(winID)
        if (apiPath != "" && IsValidFolder(apiPath)) {
            RuntimeLog.LogPathExtraction(winID, "Windows API", apiPath, true)
            return apiPath
        }

        titlePath := this.GetExplorerPathByTitle(winID)
        if (titlePath != "" && IsValidFolder(titlePath)) {
            RuntimeLog.LogPathExtraction(winID, "窗口标题", titlePath, true)
            return titlePath
        }

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
        }

        RuntimeLog.LogPathExtraction(winID, "所有方法", "", false)
        return ""
    }

    static GetActiveFileManagerFolder(winID) {
        allWindows := WinGetList()
        fileManagerCandidates := []

        for id in allWindows {
            try {
                winClass := WinGetClass("ahk_id " . id)

                if (g_Config.SupportTC = "1" && winClass = "TTOTAL_CMD") {
                    folderPath := this.GetTCActiveFolder(id)
                    if IsValidFolder(folderPath) {
                        fileManagerCandidates.Push({ id: id, path: folderPath, type: "TC" })
                    }
                }
                else if (g_Config.SupportExplorer = "1" && winClass = "CabinetWClass") {
                    explorerPath := this.GetExplorerPathEnhanced(id)
                    if IsValidFolder(explorerPath) {
                        fileManagerCandidates.Push({ id: id, path: explorerPath, type: "Explorer" })
                    }
                }
                else if (g_Config.SupportXY = "1" && winClass = "ThunderRT6FormDC") {
                    folderPath := this.GetXYActiveFolder(id)
                    if IsValidFolder(folderPath) {
                        fileManagerCandidates.Push({ id: id, path: folderPath, type: "XY" })
                    }
                }
                else if (g_Config.SupportOpus = "1" && winClass = "dopus.lister") {
                    folderPath := this.GetOpusActiveFolder(id)
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

    static GetTCActiveFolder(winID) {
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
        }

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
        }

        A_Clipboard := clipSaved
        return ""
    }

    static GetXYActiveFolder(winID) {
        clipSaved := ClipboardAll()
        A_Clipboard := ""

        SendXYplorerMessage(winID, "::copytext get('path', a);")
        ClipWait(0)

        result := A_Clipboard
        A_Clipboard := clipSaved
        return result
    }

    static GetOpusActiveFolder(winID) {
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

    static FeedDialog(winID, folderPath, dialogType) {
        try {
            exeName := WinGetProcessName("ahk_id " . winID)
            winTitle := WinGetTitle("ahk_id " . winID)
            if (exeName = "blender.exe" && InStr(winTitle, "Blender File View")) {
                this.FeedDialogGeneral(winID, folderPath)
                return
            }
        } catch {
        }

        switch dialogType {
            case "GENERAL":
                this.FeedDialogGeneral(winID, folderPath)
            case "SYSLISTVIEW":
                this.FeedDialogSysListView(winID, folderPath)
        }
    }

    static FeedDialogGeneral(winID, folderPath) {
        WinActivate("ahk_id " . winID)
        Sleep(200)

        try {
            folderWithSlash := RTrim(folderPath, "\") . "\"
            ControlFocus("Edit1", "ahk_id " . winID)
            Sleep(50)
            ControlSetText("", "Edit1", "ahk_id " . winID)
            Sleep(50)
            ControlSetText(folderWithSlash, "Edit1", "ahk_id " . winID)
            Sleep(100)
            Send("{Enter}")
            return
        } catch {
        }

        try {
            oldClipboard := A_Clipboard
            A_Clipboard := folderPath
            ClipWait(1, 0)

            try ControlFocus("Edit1", "ahk_id " . winID)
            Sleep(100)
            ControlSend("Edit1", "^a", "ahk_id " . winID)
            Sleep(50)
            ControlSend("Edit1", "^v", "ahk_id " . winID)
            Sleep(100)
            ControlSend("Edit1", "{Enter}", "ahk_id " . winID)
            Sleep(200)

            A_Clipboard := oldClipboard
            return
        } catch {
        }

        try {
            oldClipboard := A_Clipboard
            A_Clipboard := folderPath
            ClipWait(1, 0)
            WinActivate("ahk_id " . winID)
            Sleep(100)
            SendInput("^l")
            Sleep(200)
            SendInput("^v")
            Sleep(100)
            SendInput("{Enter}")
            Sleep(200)

            A_Clipboard := oldClipboard
            try ControlFocus("Edit1", "ahk_id " . winID)
            return
        } catch {
        }
    }

    static FeedDialogSysListView(winID, folderPath) {
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

    static GetWindowsFolderActivePath(*) {
        currentWinID := WinExist("A")

        if (IsFileDialog(currentWinID)) {
            if (!RuntimeFileDialog.EnsureCurrent(currentWinID)) {
                return
            }

            folderPath := this.GetActiveFileManagerFolder(currentWinID)

            if IsValidFolder(folderPath) {
                RecordRecentPath(folderPath)
                this.FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
            } else {
                ShowFileDialogMenu(currentWinID)
            }
        } else {
            return
        }
    }

    static SendToTCHandler(dialogPath, *) {
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

    static SendToExplorerHandler(dialogPath, *) {
        RuntimeMenu.Release()

        try {
            Run("explorer.exe `"" . dialogPath . "`"")
            RecordRecentPath(dialogPath)
        } catch as e {
            MsgBox("发送路径到资源管理器失败: " . e.message, "错误", "T5")
        }
    }
}
