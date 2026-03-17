class RuntimeFileDialog {
    static MonitorDialogs() {
        static lastDialogID := ""
        static dialogProcessed := false

        if (g_MenuActive || RuntimeMenu.IsRequestThrottled()) {
            return
        }

        currentWinID := WinExist("A")
        if (!currentWinID) {
            return
        }

        dialogType := GetFileDialogType(currentWinID)
        if (dialogType != "") {
            if (currentWinID != lastDialogID || !dialogProcessed) {
                lastDialogID := currentWinID
                dialogProcessed := true

                if (this.Sync(currentWinID)) {
                    this.ProcessCurrentDialog()
                }
            }
        } else if (currentWinID != lastDialogID) {
            lastDialogID := ""
            dialogProcessed := false
            this.Clear()
        }
    }

    static Sync(winID) {
        global g_CurrentDialog

        g_CurrentDialog.WinID := winID
        g_CurrentDialog.Type := GetFileDialogType(winID)
        if (!g_CurrentDialog.Type) {
            g_CurrentDialog.FingerPrint := ""
            g_CurrentDialog.Action := ""
            return false
        }

        g_CurrentDialog.FingerPrint := this.BuildFingerPrint(winID)
        g_CurrentDialog.Action := this.ReadStoredAction()
        return true
    }

    static EnsureCurrent(winID) {
        global g_CurrentDialog

        if (!winID) {
            return false
        }

        if (winID != g_CurrentDialog.WinID || g_CurrentDialog.Type = "") {
            return this.Sync(winID)
        }

        if (g_CurrentDialog.FingerPrint = "") {
            g_CurrentDialog.FingerPrint := this.BuildFingerPrint(winID)
        }

        return g_CurrentDialog.Type != ""
    }

    static BuildFingerPrint(winID) {
        ahkExe := WinGetProcessName("ahk_id " . winID)
        windowTitle := WinGetTitle("ahk_id " . winID)
        return ahkExe . "___" . windowTitle
    }

    static ReadStoredAction() {
        global g_Config, g_CurrentDialog

        if (g_CurrentDialog.FingerPrint = "") {
            return ""
        }
        return UTF8IniRead(g_Config.IniFile, "Dialogs", g_CurrentDialog.FingerPrint, "")
    }

    static ResolveAction() {
        global g_Config, g_CurrentDialog

        if (g_CurrentDialog.Action != "") {
            return g_CurrentDialog.Action
        }

        switch g_Config.FileDialogDefaultAction {
            case "auto_switch":
                return "1"
            case "never":
                return "0"
            case "auto_menu":
                return "2"
            default:
                return ""
        }
    }

    static ResolveAndStoreAction() {
        global g_CurrentDialog

        g_CurrentDialog.Action := this.ResolveAction()
        return g_CurrentDialog.Action
    }

    static ProcessCurrentDialog() {
        this.ResolveAndStoreAction()

        if (g_CurrentDialog.Action = "1") {
            folderPath := GetActiveFileManagerFolder(g_CurrentDialog.WinID)
            if IsValidFolder(folderPath) {
                RecordRecentPath(folderPath)
                FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
            }
        } else if (g_CurrentDialog.Action = "2") {
            SetTimer(ObjBindMethod(this, "ShowDelayedMenu", g_CurrentDialog.WinID), -200)
        }
    }

    static SetAction(action) {
        global g_Config, g_CurrentDialog

        if (g_CurrentDialog.FingerPrint = "") {
            g_CurrentDialog.Action := action
            return
        }

        if (action = "") {
            try UTF8IniDelete(g_Config.IniFile, "Dialogs", g_CurrentDialog.FingerPrint)
        } else {
            UTF8IniWrite(action, g_Config.IniFile, "Dialogs", g_CurrentDialog.FingerPrint)
        }

        g_CurrentDialog.Action := action
    }

    static Clear(resetMenuItems := true) {
        global g_CurrentDialog, g_MenuItems

        g_CurrentDialog.WinID := ""
        g_CurrentDialog.Type := ""
        g_CurrentDialog.FingerPrint := ""
        g_CurrentDialog.Action := ""

        if (resetMenuItems) {
            g_MenuItems := []
        }

        RuntimeMenu.Release()
    }

    static CanShowDelayed(expectedWinID) {
        global g_CurrentDialog

        return expectedWinID = g_CurrentDialog.WinID
            && g_CurrentDialog.WinID != ""
            && WinExist("ahk_id " . g_CurrentDialog.WinID)
    }

    static ShowDelayedMenu(expectedWinID) {
        if (this.CanShowDelayed(expectedWinID)) {
            ShowFileDialogMenuInternal()
        }
    }
}
