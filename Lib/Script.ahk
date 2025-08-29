#Requires AutoHotkey v2.0
; ################ Adobe After Effect运行函数 ######################

; -----------------------------------------------------------------
;	运行方式
;	1.Script_AfterEffects("脚本名字.jsx")
;	2.Script_AfterEffects("目录\脚本名字.jsx")
;   3.Script_AfterEffects("D:\目录\脚本名字.jsx")

Script_AfterEffects(path) {
    ; 定义After Effects窗口组，包含多个版本
    GroupAdd("AEWindows", "ahk_class AE_CApplication_11.0")  ; AE CS6
    GroupAdd("AEWindows", "ahk_class AE_CApplication_12.0")  ; AE CC
    GroupAdd("AEWindows", "ahk_class AE_CApplication_13.0")  ; AE CC 2014
    GroupAdd("AEWindows", "ahk_class AE_CApplication_14.0")  ; AE CC 2015
    GroupAdd("AEWindows", "ahk_class AE_CApplication_15.0")  ; AE CC 2017
    GroupAdd("AEWindows", "ahk_class AE_CApplication_16.0")  ; AE CC 2018
    GroupAdd("AEWindows", "ahk_class AE_CApplication_17.0")  ; AE CC 2019
    GroupAdd("AEWindows", "ahk_class AE_CApplication_18.0")  ; AE 2020
    GroupAdd("AEWindows", "ahk_class AE_CApplication_19.0")  ; AE 2021
    GroupAdd("AEWindows", "ahk_class AE_CApplication_20.0")  ; AE 2022
    GroupAdd("AEWindows", "ahk_class AE_CApplication_21.0")  ; AE 2023
    GroupAdd("AEWindows", "ahk_class AE_CApplication_22.0")  ; AE 2024
    GroupAdd("AEWindows", "ahk_class AE_CApplication_23.0")  ; AE 2025 (future-proofing)

    ; 查找进程中的"AfterFX.exe" 获得所在路径
    AeExePath := GetProcessPath("AfterFX.exe")

    if RegExMatch(path, ".*\.(jsx|jsxbin)$") {
        CommandsFile := A_ScriptDir "\plugins\AfterEffects\Script\Commands\" path
        AeScriptFile := A_ScriptDir "\plugins\AfterEffects\Script\" path
        runAEScriptFile := A_ScriptDir "\plugins\AfterEffects\Script\runAEScript.jsx"

        ; 判断Commands 目录下文件是否存在，存在执行 不存在提示
        if FileExist(CommandsFile) {
            ; 检查是否是任何版本的After Effects窗口
            if WinActive("ahk_group AEWindows") {
                Run AeExePath " -r " CommandsFile, , "Hide"
                return
            } else {
                runAeScriptFiles(CommandsFile)
                Send "^+!{d}"
                Sleep 200
                ; 只在文件存在时才删除
                if FileExist(runAEScriptFile)
                    FileDelete runAEScriptFile
                return
            }
        }

        ; 判断Script 目录下文件是否存在，存在执行 不存在提示
        if FileExist(AeScriptFile) {
            ; 检查是否是任何版本的After Effects窗口
            if WinActive("ahk_group AEWindows") {
                Run AeExePath " -r " AeScriptFile, , "Hide"
                return
            } else {
                runAeScriptFiles(AeScriptFile)
                Send "^+!{d}"
                Sleep 200
                ; 只在文件存在时才删除
                if FileExist(runAEScriptFile)
                    FileDelete runAEScriptFile
                return
            }
        }

        ; 绝对路径
        if FileExist(path) {
            ; 检查是否是任何版本的After Effects窗口
            if WinActive("ahk_group AEWindows") {
                Run AeExePath " -r " path, , "Hide"
                return
            } else {
                runAeScriptFiles(path)
                Send "^+!{d}"
                Sleep 200
                ; 只在文件存在时才删除
                if FileExist(runAEScriptFile)
                    FileDelete runAEScriptFile
                return
            }
        } else {
            MsgBox Format("{1}`n{2}`n{3}文件不存在！", CommandsFile, AeScriptFile, path)
            return
        }
    }
}

runAeScriptFiles(path) {
    scriptDir := A_ScriptDir "\plugins\AfterEffects\Script"
    setPreset := scriptDir "\runAEScript.jsx"

    ; 确保Script目录存在
    if !DirExist(scriptDir)
        DirCreate scriptDir

    ; 确保Commands目录存在
    commandsDir := scriptDir "\Commands"
    if !DirExist(commandsDir)
        DirCreate commandsDir

    ; 使用V2的文件操作方式
    try {
        ; 创建或清空文件
        FileObj := FileOpen(setPreset, "w", "UTF-8")
        if !FileObj {
            MsgBox Format("无法创建文件: {1}", setPreset)
            return
        }

        ; 替换路径中的反斜杠
        paths := StrReplace(path, "\", "\\")

        ; 构建JavaScript代码
        jsCode := "var scriptpath = `"" . paths . "`";" . "`n"
        jsCode .= "var scriptpaths = scriptpath.replace(/\\\\/g, '/');" . "`n"
        jsCode .= "$.evalFile(scriptpaths);"

        ; 写入文件内容
        FileObj.Write(jsCode)
        FileObj.Close()
    } catch Error as e {
        MsgBox Format("写入文件时出错: {1}", e.Message)
    }
}

; =============================================================================
; After Effects 初始化相关配置和常量
; =============================================================================

; 日志记录类
class AfterEffects_Logger {
    static Write(level, message) {
        try {
            ; 检查日志级别
            if !this.ShouldLog(level)
                return

            ; 获取当前时间
            currentTime := FormatTime(, "yyyy-MM-dd HH:mm:ss")

            ; 格式化日志消息
            logMessage := Format("[{1}] [{2}] {3}`n", currentTime, level, message)

            ; 写入日志文件
            FileAppend logMessage, AfterEffects_InitConfig.LOG_FILE, "UTF-8"

        } catch Error as e {
            ; 记录日志失败时不处理，避免无限循环
        }
    }

    static ShouldLog(level) {
        ; 日志级别优先级定义
        static priorities := Map("DEBUG", 1, "INFO", 2, "WARN", 3, "ERROR", 4)

        logLevel := AfterEffects_InitConfig.LOG_LEVEL
        return priorities.Has(level) && priorities.Has(logLevel) && priorities[level] >= priorities[logLevel]
    }

    static Info(message) => this.Write("INFO", message)
    static Warn(message) => this.Write("WARN", message)
    static Error(message) => this.Write("ERROR", message)
    static Debug(message) => this.Write("DEBUG", message)
}

; =============================================================================

class AfterEffects_InitConfig {
    ; 初始化相关常量配置
    static INIT_TIMEOUT := 3000         ; 初始化超时时间(ms)
    static CLEANUP_DELAY := 200         ; 清理延迟(ms)
    static SCRIPT_PREFIX := "runAEScript"  ; 临时脚本文件前缀
    static SUCCESS_SUFFIX := "init_success" ; 成功标记文件后缀
    static LOG_LEVEL := "INFO"          ; 日志级别 (DEBUG, INFO, WARN, ERROR)
    static LOG_FILE := A_ScriptDir "\plugins\AfterEffects\init_log.txt" ; 日志文件路径

    ; 错误消息模板
    static ERRORS := Map(
        "PROCESS_NOT_FOUND", "After Effects未运行，请先启动After Effects。",
        "PATH_NOT_FOUND", "无法获取After Effects路径，请确保After Effects正在运行。",
        "FILE_CREATE_FAILED", "无法创建文件: {1}",
        "SCRIPT_EXEC_FAILED", "运行脚本时出错: {1}",
        "WRITE_FAILED", "写入文件时出错: {1}"
    )

    ; 成功消息
    static MESSAGES := Map(
        "INIT_SUCCESS", "After Effects初始化成功！",
        "INIT_INCOMPLETE", "初始化可能未完成，请再次尝试或检查After Effects是否响应。"
    )
}

; =============================================================================
; 初始化脚本路径 - 重构后的优化版本
; =============================================================================
AfterEffects_Initialization() {
    AfterEffects_Logger.Info("=== 开始After Effects初始化过程 ===")

    try {
        ; 步骤1: 环境检查
        AfterEffects_Logger.Debug("步骤1: 验证环境...")
        if !AfterEffects_ValidateEnvironment()
            return

        ; 步骤2: 获取配置
        AfterEffects_Logger.Debug("步骤2: 获取初始化配置...")
        config := AfterEffects_GetInitConfig()

        ; 步骤3: 准备目录结构
        AfterEffects_Logger.Debug("步骤3: 确保目录结构存在...")
        if !AfterEffects_EnsureDirectories(config)
            return

        ; 步骤4: 生成并执行脚本
        AfterEffects_Logger.Debug("步骤4: 生成并执行初始化脚本...")
        if !AfterEffects_ExecuteInitScript(config)
            return

        ; 步骤5: 清理临时文件
        AfterEffects_Logger.Debug("步骤5: 清理临时文件...")
        AfterEffects_Cleanup(config)

        AfterEffects_Logger.Info("=== After Effects初始化完成 ===")

    } catch Error as e {
        AfterEffects_Logger.Error("初始化过程中发生异常: " e.Message)
        MsgBox Format("初始化过程中发生错误: {1}", e.Message), "初始化失败", "Icon!"
    }
}

; 环境验证函数
AfterEffects_ValidateEnvironment() {
    ; 检查After Effects是否正在运行
    if !ProcessExist("AfterFX.exe") {
        AfterEffects_Logger.Error("AfterFX.exe进程未找到")
        MsgBox AfterEffects_InitConfig.ERRORS["PROCESS_NOT_FOUND"], "初始化失败", "Icon!"
        return false
    }

    AfterEffects_Logger.Info("AfterFX.exe进程验证通过")

    ; 获取After Effects路径
    AeExePath := GetProcessPath("AfterFX.exe")
    if !AeExePath {
        AfterEffects_Logger.Error("无法获取After Effects可执行文件路径")
        MsgBox AfterEffects_InitConfig.ERRORS["PATH_NOT_FOUND"], "初始化失败", "Icon!"
        return false
    }

    AfterEffects_Logger.Info("After Effects路径获取成功: " AeExePath)
    return true
}

; 获取初始化配置
AfterEffects_GetInitConfig() {
    baseDir := A_ScriptDir "\plugins\AfterEffects\Script"

    return {
        scriptDir: baseDir,
        tempScript: baseDir "\" AfterEffects_InitConfig.SCRIPT_PREFIX ".jsx",
        successFile: baseDir "\" AfterEffects_InitConfig.SUCCESS_SUFFIX ".txt",
        exePath: GetProcessPath("AfterFX.exe"),
        commandsDir: baseDir "\Commands"
    }
}

; 确保必要的目录存在
AfterEffects_EnsureDirectories(config) {
    try {
        ; 创建脚本目录
        if !DirExist(config.scriptDir)
            DirCreate config.scriptDir

        ; 创建命令目录
        if !DirExist(config.commandsDir)
            DirCreate config.commandsDir

        ; 清理旧的临时文件
        if FileExist(config.tempScript)
            FileDelete config.tempScript
        if FileExist(config.successFile)
            FileDelete config.successFile

        return true
    } catch Error as e {
        MsgBox Format("创建目录失败: {1}", e.Message), "初始化失败", "Icon!"
        return false
    }
}

; 生成并执行初始化脚本
AfterEffects_ExecuteInitScript(config) {
    try {
        ; 生成JSX脚本内容
        jsCode := AfterEffects_GenerateInitScript(config)

        ; 写入临时脚本文件
        if !AfterEffects_WriteScriptFile(config.tempScript, jsCode)
            return false

        ; 执行脚本并等待结果
        return AfterEffects_RunAndWaitScript(config)

    } catch Error as e {
        MsgBox Format(AfterEffects_InitConfig.ERRORS["SCRIPT_EXEC_FAILED"], e.Message), "初始化失败", "Icon!"
        return false
    }
}

; 生成初始化JSX脚本
AfterEffects_GenerateInitScript(config) {
    ; 构建JSX脚本内容
    jsCode := "try {`n"
    jsCode .= "    // 确保脚本在After Effects中正确执行`n"
    jsCode .= "    var scriptpath = `"执行初始化`";`n"
    jsCode .= "    alert(scriptpath);`n"
    jsCode .= "`n"
    jsCode .= "    // 写入一个标记文件表示成功`n"
    jsCode := jsCode "    var successFile = new File(`"" StrReplace(config.successFile, "\", "\\") "`");`n"
    jsCode .= "    successFile.open('w');`n"
    jsCode .= "    successFile.write('初始化成功: ' + new Date().toString());`n"
    jsCode .= "    successFile.close();`n"
    jsCode .= "`n"
    jsCode .= "} catch(e) {`n"
    jsCode .= "    alert('初始化出错: ' + e.toString());`n"
    jsCode .= "}`n"

    return jsCode
}

; 写入脚本文件
AfterEffects_WriteScriptFile(filePath, content) {
    try {
        AfterEffects_Logger.Debug("创建脚本文件: " filePath)
        FileObj := FileOpen(filePath, "w", "UTF-8")
        if !FileObj {
            AfterEffects_Logger.Error("无法创建文件: " filePath)
            MsgBox Format(AfterEffects_InitConfig.ERRORS["FILE_CREATE_FAILED"], filePath), "初始化失败", "Icon!"
            return false
        }

        contentSize := StrLen(content)
        FileObj.Write(content)
        FileObj.Close()

        AfterEffects_Logger.Info("脚本文件写入成功，大小: " contentSize " 字符")
        return true

    } catch Error as e {
        AfterEffects_Logger.Error("写入文件时出错: " e.Message " (文件: " filePath ")")
        MsgBox Format(AfterEffects_InitConfig.ERRORS["WRITE_FAILED"], e.Message), "初始化失败", "Icon!"
        return false
    }
}

; 运行脚本并等待结果
AfterEffects_RunAndWaitScript(config) {
    try {
        ; 运行脚本
        AfterEffects_Logger.Info("启动After Effects脚本执行...")
        Run config.exePath " -r " config.tempScript, , "Hide"

        ; 等待脚本执行完成
        AfterEffects_Logger.Debug("等待脚本执行完成，最多 " AfterEffects_InitConfig.INIT_TIMEOUT " ms")
        startTime := A_TickCount
        loop {
            Sleep 100
            if FileExist(config.successFile) {
                execTime := A_TickCount - startTime
                AfterEffects_Logger.Info("脚本执行成功，耗时: " execTime " ms")
                MsgBox AfterEffects_InitConfig.MESSAGES["INIT_SUCCESS"], "初始化成功", "Icon!"
                return true
            }

            ; 超时检查
            if (A_TickCount - startTime > AfterEffects_InitConfig.INIT_TIMEOUT) {
                AfterEffects_Logger.Warn("脚本执行超时 (超过 " AfterEffects_InitConfig.INIT_TIMEOUT " ms)")
                MsgBox AfterEffects_InitConfig.MESSAGES["INIT_INCOMPLETE"], "初始化提示", "Icon!"
                return false
            }
        }

    } catch Error as e {
        AfterEffects_Logger.Error("脚本执行异常: " e.Message)
        MsgBox Format(AfterEffects_InitConfig.ERRORS["SCRIPT_EXEC_FAILED"], e.Message), "初始化失败", "Icon!"
        return false
    }
}

; 清理临时文件
AfterEffects_Cleanup(config) {
    Sleep AfterEffects_InitConfig.CLEANUP_DELAY

    try {
        if FileExist(config.tempScript)
            FileDelete config.tempScript
        if FileExist(config.successFile)
            FileDelete config.successFile
    } catch Error as e {
        ; 清理失败时不显示错误，因为程序已经初始化成功
    }
}

; 获取进程路径的辅助函数 - 简化版本
GetProcessPath(ProcessName) {
    ; 使用WMI查询获取进程路径
    try {
        for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process where Name = '" ProcessName "'") {
            return process.ExecutablePath
        }
    } catch {
        ; 如果出错，返回空字符串
    }
    return ""
}

/**
 * 运行Max3D脚本命令
 * 
 * 三种用法:
 * 1. Script_Max3D("脚本名字.ms") - 运行指定的脚本文件
 * 2. Script_Max3D("startObjectCreation box") - 直接运行Max命令
 * 3. Script_Max3D("id12345") - 通过ID执行动作
 * 
 * @param {String} Path - 脚本路径、命令或ID
 * @return {Void}
 */
Script_3DsMax(Path) {
    ; 检查是否为脚本文件 (.ms|.mse|.py)
    if RegExMatch(Path, "i).*\.(ms|mse|py)$") {
        ; 检查是否为完整文件路径
        if FileExist(Path) {
            ; 直接运行完整路径的文件
            Run A_ScriptDir . "\plugins\Max3D\Script\MXSPyCOM.exe -f " . Path
            return
        }

        ; 检查相对路径
        FilePath1 := A_ScriptDir . "\plugins\Max3D\Script\commands\" . Path
        FilePath2 := A_ScriptDir . "\plugins\Max3D\Script\" . Path

        ; 检查文件是否存在并运行
        if FileExist(FilePath2) {
            Run A_ScriptDir . "\plugins\Max3D\Script\MXSPyCOM.exe -f " . FilePath2
            return
        }

        if FileExist(FilePath1) {
            Run A_ScriptDir . "\plugins\Max3D\Script\MXSPyCOM.exe -f " . FilePath1
            return
        } else {
            ; fileIn "d:\\BoBO\\VimDesktop2\\Plugins\\Max3D\\Script\\commands\\hideByCategoryGUI.ms"
            ; MXSPATH := "fileIn " Path
            ; ControlFocus "MXS_Scintilla2"
            ; ControlSetText MXSPATH, "MXS_Scintilla2"
            ; Send "+{Enter}"
            ; Click
            ; return
            MsgBox "文件不存在: " . Path, "错误", 16
            return
        }

    }

    ; 检查是否为ID模式 (id12345)

    if RegExMatch(Path, "^id\d+$") {
        ; 提取ID数字部分
        IdNumber := SubStr(Path, 3)
        cmd := 'actionMan.executeAction 0 "' . IdNumber . '"'

        ; 发送命令到Max3D
        ControlFocus "MXS_Scintilla2"
        ControlSetText cmd, "MXS_Scintilla2"
        Send "+{Enter}"
        Click
        return
    }
    ; 默认为直接Max命令模式
    ControlFocus "MXS_Scintilla2"
    ControlSetText Path, "MXS_Scintilla2"
    Send "+{Enter}"
    Click
    return
}
