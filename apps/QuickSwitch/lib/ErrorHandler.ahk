;===========================================================
; ErrorHandler.ahk - 统一错误处理模块
;===========================================================
; 功能：
; 1. 统一的错误日志记录
; 2. 分级错误处理 (DEBUG, INFO, WARNING, ERROR, CRITICAL)
; 3. 安全执行包装器
; 4. 错误提示统一管理
;===========================================================

class ErrorHandler {
    ; 静态配置
    static logFile := ""
    static logEnabled := false
    static logLevel := "INFO"
    static showErrors := true
    
    ; 日志级别定义
    static levels := Map(
        "DEBUG", 0,
        "INFO", 1,
        "WARNING", 2,
        "ERROR", 3,
        "CRITICAL", 4
    )
    
    ; 初始化错误处理器
    static Init(logFile := "", logLevel := "INFO", showErrors := true) {
        if (logFile != "")
            this.logFile := logFile
        else
            this.logFile := A_ScriptDir "\QuickSwitch.log"
        
        this.logLevel := logLevel
        this.showErrors := showErrors
        
        ; 从配置读取日志设置
        try {
            if (IsSet(g_Config) && g_Config.HasOwnProp("IniFile")) {
                enabled := UTF8IniRead(g_Config.IniFile, "Settings", "EnableLog", "0")
                this.logEnabled := (enabled = "1")
                
                level := UTF8IniRead(g_Config.IniFile, "Settings", "LogLevel", "INFO")
                if (this.levels.Has(level))
                    this.logLevel := level
            }
        } catch {
            ; 配置读取失败，使用默认值
        }
    }
    
    ; 判断是否应该记录日志
    static ShouldLog(level) {
        if (!this.logEnabled)
            return false
        
        if (!this.levels.Has(level))
            return false
        
        return this.levels[level] >= this.levels[this.logLevel]
    }
    
    ; 记录日志
    static Log(message, level := "INFO", context := "") {
        if (!this.ShouldLog(level))
            return
        
        try {
            timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
            logEntry := timestamp " [" level "] " message
            
            if (context != "")
                logEntry .= " (" context ")"
            
            FileAppend(logEntry "`n", this.logFile, "UTF-8")
        } catch as e {
            ; 日志写入失败，避免无限循环
            if (this.showErrors && level = "CRITICAL") {
                MsgBox("严重错误，无法写入日志: " e.message, "错误", "Icon! T3")
            }
        }
    }
    
    ; 记录调试信息
    static Debug(message, context := "") {
        this.Log(message, "DEBUG", context)
    }
    
    ; 记录一般信息
    static Info(message, context := "") {
        this.Log(message, "INFO", context)
    }
    
    ; 记录警告
    static Warning(message, context := "") {
        this.Log(message, "WARNING", context)
    }
    
    ; 记录错误
    static Error(message, context := "") {
        this.Log(message, "ERROR", context)
    }
    
    ; 记录严重错误
    static Critical(message, context := "") {
        this.Log(message, "CRITICAL", context)
    }
    
    ; 安全执行包装器 - 自动捕获异常
    ; 返回对象: {success: true/false, result: 结果值, error: 错误信息}
    static SafeCall(func, args*) {
        try {
            result := func(args*)
            return {success: true, result: result, error: ""}
        } catch as e {
            this.Error(e.message, e.what)
            return {success: false, result: "", error: e.message}
        }
    }
    
    ; 安全执行 - 显示错误消息
    ; 使用方式: SafeCallWithMsg(func, arg1, arg2) 或 SafeCallWithMsgEx(func, errorMsg, arg1, arg2)
    static SafeCallWithMsg(func, args*) {
        try {
            return func(args*)
        } catch as e {
            this.Error(e.message, e.what)
            
            if (this.showErrors) {
                msg := "操作失败"
                msg .= "`n`n错误详情: " e.message
                
                if (e.what != "")
                    msg .= "`n位置: " e.what
                
                MsgBox(msg, "错误", "Icon! T5")
            }
            
            return ""
        }
    }
    
    ; 安全执行 - 显示自定义错误消息
    static SafeCallWithMsgEx(func, errorMsg, args*) {
        try {
            return func(args*)
        } catch as e {
            this.Error(e.message, e.what)
            
            if (this.showErrors) {
                msg := (errorMsg != "") ? errorMsg : "操作失败"
                msg .= "`n`n错误详情: " e.message
                
                if (e.what != "")
                    msg .= "`n位置: " e.what
                
                MsgBox(msg, "错误", "Icon! T5")
            }
            
            return ""
        }
    }
    
    ; 显示错误消息
    static ShowError(message, title := "错误", timeout := 5) {
        this.Error(message)
        
        if (this.showErrors) {
            MsgBox(message, title, "Icon! T" timeout)
        }
    }
    
    ; 显示警告消息
    static ShowWarning(message, title := "警告", timeout := 3) {
        this.Warning(message)
        
        if (this.showErrors) {
            MsgBox(message, title, "Icon? T" timeout)
        }
    }
    
    ; 显示信息消息
    static ShowInfo(message, title := "信息", timeout := 2) {
        this.Info(message)
        
        if (this.showErrors) {
            MsgBox(message, title, "T" timeout)
        }
    }
    
    ; 异常处理包装器 - 用于包装可能失败的代码块
    static TryCatch(codeBlock, errorHandler := "", finallyBlock := "") {
        try {
            result := codeBlock()
            return {success: true, result: result}
        } catch as e {
            this.Error(e.message, e.what)
            
            if (errorHandler != "") {
                try {
                    errorHandler(e)
                } catch as eh {
                    this.Error("错误处理器失败: " eh.message, "ErrorHandler")
                }
            }
            
            return {success: false, error: e}
        } finally {
            if (finallyBlock != "") {
                try {
                    finallyBlock()
                } catch as ef {
                    this.Error("清理代码失败: " ef.message, "FinallyBlock")
                }
            }
        }
    }
    
    ; 性能监控 - 记录函数执行时间
    static Profile(name, func, args*) {
        startTime := A_TickCount
        
        try {
            result := func(args*)
            elapsed := A_TickCount - startTime
            
            this.Debug(name " 执行成功，耗时: " elapsed "ms", "Performance")
            
            return result
        } catch as e {
            elapsed := A_TickCount - startTime
            
            this.Error(name " 执行失败 (耗时: " elapsed "ms): " e.message, e.what)
            
            throw e
        }
    }
    
    ; 条件检查 - 用于前置条件验证
    static Assert(condition, message := "断言失败") {
        if (!condition) {
            this.Critical(message, "Assertion")
            
            if (this.showErrors) {
                MsgBox(message, "断言失败", "Icon! T5")
            }
            
            throw Error(message)
        }
    }
    
    ; 清理日志文件 - 删除过期日志
    static CleanOldLogs(daysToKeep := 7) {
        if (!FileExist(this.logFile))
            return
        
        try {
            ; 读取日志文件
            logContent := FileRead(this.logFile, "UTF-8")
            lines := StrSplit(logContent, "`n", "`r")
            
            ; 计算截止日期
            cutoffTime := DateAdd(A_Now, -daysToKeep, "Days")
            cutoffStr := FormatTime(cutoffTime, "yyyy-MM-dd")
            
            ; 过滤日志行
            newLines := []
            for line in lines {
                if (line = "")
                    continue
                
                ; 提取日志行的时间戳
                if (RegExMatch(line, "^(\d{4}-\d{2}-\d{2})", &match)) {
                    logDate := match[1]
                    
                    ; 保留最近的日志
                    if (StrCompare(logDate, cutoffStr) >= 0) {
                        newLines.Push(line)
                    }
                } else {
                    ; 没有时间戳的行也保留
                    newLines.Push(line)
                }
            }
            
            ; 写回文件
            FileDelete(this.logFile)
            for line in newLines {
                FileAppend(line "`n", this.logFile, "UTF-8")
            }
            
            this.Info("已清理 " (lines.Length - newLines.Length) " 条过期日志", "LogClean")
        } catch as e {
            this.Error("清理日志失败: " e.message, "LogClean")
        }
    }
}

; 全局错误处理函数 - 便于快速调用
LogError(message, context := "") {
    ErrorHandler.Error(message, context)
}

LogWarning(message, context := "") {
    ErrorHandler.Warning(message, context)
}

LogInfo(message, context := "") {
    ErrorHandler.Info(message, context)
}

LogDebug(message, context := "") {
    ErrorHandler.Debug(message, context)
}

SafeCall(func, args*) {
    return ErrorHandler.SafeCall(func, args*)
}
