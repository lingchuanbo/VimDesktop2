#Requires AutoHotkey v2.0
#SingleInstance Force

if A_Args.Length > 0 {
    targetPath := A_Args[1]
    ProcessPath(targetPath)
    ExitApp
}

#o:: {
    selectedPath := GetSelectedPath()
    if !selectedPath {
        MsgBox "娌℃湁閫変腑浠讳綍鏂囦欢鎴栨枃浠跺す!", "閿欒", 16
        return
    }

    ProcessPath(selectedPath)
}

ProcessPath(path) {
    if !path || !FileExist(path) {
        MsgBox "璺緞涓嶅瓨鍦? " path, "閿欒", 16
        return
    }

    if ProcessExist("TOTALCMD.EXE") {
        OpenWithTC(path)
    } else {
        try Run path
        catch Error as e
            MsgBox "鎵撳紑澶辫触: " e.Message, "閿欒", 16
    }
}

GetSelectedPath() {
    A_Clipboard := ""
    Send "^c"
    if !ClipWait(0.5)
        return ""

    path := Trim(A_Clipboard)
    if (path != "") && FileExist(path)
        return path

    return ""
}

OpenWithTC(path) {
    try {
        tcPID := ProcessExist("TOTALCMD.EXE")
        if !tcPID
            return false

        tcExe := ProcessGetPath(tcPID)
        if !tcExe
            return false

        Run '"' . tcExe . '" "' . path . '"'
        return true
    } catch as e {
        return false
    }
}
