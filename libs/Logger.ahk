; log := new Logger("test.log")
; log.Debug("test")

class Logger
{
    __New(filename)
    {
        this.filename := filename
    }

    Write(level, msg)
    {
        try {
            timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            FileAppend timestamp . " [" . level . "] " . msg . "`n", this.filename, "UTF-8"
        }
    }

    Debug(msg)
    {
        this.Write("DEBUG", msg)
    }

    Info(msg)
    {
        this.Write("INFO", msg)
    }

    Warn(msg)
    {
        this.Write("WARN", msg)
    }

    Error(msg)
    {
        this.Write("ERROR", msg)
    }
}

VimD_Log(level, code, message, err := "")
{
    static fallbackLogger := ""
    logger := ""
    if (!IsObject(fallbackLogger)) {
        try {
            fallbackLogger := Logger(PathResolver.RootPath("debug.log"))
        } catch {
            fallbackLogger := ""
        }
    }

    if (IsObject(fallbackLogger))
        logger := fallbackLogger
    try {
        global logObject
        if (IsSet(logObject) && IsObject(logObject))
            logger := logObject
    }
    if (!IsObject(logger))
        return

    logLine := "[" code "] " message
    if IsObject(err) {
        if (Type(err) = "Error")
            logLine .= " | " err.Message
        else
            logLine .= " | " Type(err)
    } else if (err != "") {
        logLine .= " | " err
    }

    switch StrUpper(level) {
        case "ERROR":
            logger.Error(logLine)
        case "WARN":
            logger.Warn(logLine)
        case "INFO":
            logger.Info(logLine)
        default:
            logger.Debug(logLine)
    }
}

; 统一错误入口：总是记录日志，仅在调试模式下弹窗
VimD_Error(code, message, err := "", showAlways := false) {
    VimD_Log("ERROR", code, message, err)
    try {
        global INIObject
        if (showAlways || (IsSet(INIObject) && INIObject.HasOwnProp("config") && INIObject.config.enable_debug = 1)) {
            errMsg := message
            if IsObject(err) && Type(err) = "Error"
                errMsg .= "`n" err.Message
            else if (err != "")
                errMsg .= "`n" err
            MsgBox(errMsg, "VimDesktop 错误", "OK Icon!")
        }
    }
}

VimD_LogOnce(level, code, message, err := "")
{
    static logged := Map()
    key := StrUpper(level) "|" code
    if (logged.Has(key))
        return
    logged[key] := true
    VimD_Log(level, code, message, err)
}
