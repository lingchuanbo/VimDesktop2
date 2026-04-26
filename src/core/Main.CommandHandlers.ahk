; Main.CommandHandlers.ahk - 命令分发处理
; 负责 VIMD_CMD 命令解析和各类命令的实际执行

VIMD_CMD(Param) {
    global MAIN_CMD_CACHE_MAX
    static cmdCache := Map()

    if (cmdCache.Has(Param)) {
        cmdType := cmdCache[Param]
    } else {
        cmdType := _VIMD_GetCmdType(Param)
        if (cmdCache.Count < MAIN_CMD_CACHE_MAX) {
            cmdCache[Param] := cmdType
        }
    }

    switch cmdType {
        case "run":
            Run SubStr(Param, 5)
        case "key":
            Send SubStr(Param, 5)
        case "dir":
            _HandleDirCommand(SubStr(Param, 5))
        case "tccmd":
            _HandleTCCommand(SubStr(Param, 7))
        case "wshkey":
            _HandleWshKeyCommand(SubStr(Param, 8))
    }
}

_VIMD_GetCmdType(param) {
    if (RegExMatch(param, "i)^(run)\|"))
        return "run"
    if (RegExMatch(param, "i)^(key)\|"))
        return "key"
    if (RegExMatch(param, "i)^(dir)\|"))
        return "dir"
    if (RegExMatch(param, "i)^(tccmd)\|"))
        return "tccmd"
    if (RegExMatch(param, "i)^(wshkey)\|"))
        return "wshkey"
    return ""
}

; 处理目录命令
_HandleDirCommand(path) {
    f := "TC_OpenPath"
    if (Type(%f%) == "Func") {
        %f%(path, false)
    } else {
        Run path
    }
}

; 处理TC命令
_HandleTCCommand(cmd) {
    f := "TC_Run"
    if (Type(%f%) == "Func") {
        %f%(cmd)
    }
}

; 处理WSH按键命令
_HandleWshKeyCommand(keys) {
    static WshShell := 0
    if (!WshShell) {
        WshShell := ComObject("WScript.Shell")
    }
    WshShell.SendKeys(keys)
}

; 日志开关（被热重载流程调用）
_ApplyLogSetting(enableLog) {
    try {
        global logObject
        if (enableLog == 1) {
            if (!IsSet(logObject) || !IsObject(logObject))
                logObject := Logger(PathResolver.RootPath("debug.log"))
        } else {
            if (IsSet(logObject))
                logObject := ""
        }
    } catch Error as e {
        VimD_Log("WARN", "MAIN_LOG_SWITCH", "日志切换失败", e)
    }
}
