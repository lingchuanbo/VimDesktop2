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
            fallbackLogger := Logger(A_ScriptDir "\debug.log")
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

VimD_LogOnce(level, code, message, err := "")
{
    static logged := Map()
    key := StrUpper(level) "|" code
    if (logged.Has(key))
        return
    logged[key] := true
    VimD_Log(level, code, message, err)
}
