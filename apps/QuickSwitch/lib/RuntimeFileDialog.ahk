class RuntimeFileDialog {
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
}
