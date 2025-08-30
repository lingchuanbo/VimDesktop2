#Requires AutoHotkey v2.0
#Include <class_EasyIni>
; ################ Adobe After Effect运行函数 ######################

; -----------------------------------------------------------------
;	运行方式
;	1.Script_AfterEffects("脚本名字.jsx")
;	2.Script_AfterEffects("目录\脚本名字.jsx")
;   3.Script_AfterEffects("D:\目录\脚本名字.jsx")

; 静态类用于管理AE窗口组（避免重复GroupAdd）
class AEWindowsManager {
    static initialized := false
    static groupName := "AEWindows"
    
    static Init() {
        if this.initialized
            return
            
        ; 定义After Effects窗口组，包含多个版本（CS6到未来版本）
        versions := [11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30]
        for version in versions {
            GroupAdd(this.groupName, "ahk_class AE_CApplication_" . version . ".0")
            ; 支持小版本号格式
            GroupAdd(this.groupName, "ahk_class AE_CApplication_" . version . ".*")
        }
        
        this.initialized := true
    }
    
    static IsAEWindowActive() {
        this.Init()
        return WinActive("ahk_group " . this.groupName)
    }
}

; 优化后的 Script_AfterEffects 函数
Script_AfterEffects(path) {
    ; 确保配置已加载
    AfterEffects_InitConfig.LoadConfig()
    
    ; 参数验证
    if !path || path = "" {
        MsgBox("错误：未提供脚本路径", "参数错误", "Icon!")
        return false
    }
    
    ; 检查文件扩展名
    if !RegExMatch(path, "i).*\.(jsx|jsxbin)$") {
        MsgBox("错误：文件必须是 .jsx 或 .jsxbin 格式`n提供的文件：" . path, "文件格式错误", "Icon!")
        return false
    }
    
    ; 获取AE进程路径
    AeExePath := GetProcessPath("AfterFX.exe")
    if !AeExePath {
        MsgBox("错误：After Effects 未运行或无法获取程序路径`n请先启动 After Effects", "进程错误", "Icon!")
        return false
    }
    
    ; 构建可能的脚本路径列表（按优先级排序）
    scriptPaths := BuildScriptPaths(path)
    
    ; 查找存在的脚本文件
    existingScript := ""
    for scriptPath in scriptPaths {
        if FileExist(scriptPath) {
            existingScript := scriptPath
            break
        }
    }
    
    ; 如果没有找到文件，显示详细错误信息
    if !existingScript {
        errorMsg := "无法找到脚本文件：" . path . "`n`n已检查以下位置：`n"
        for index, scriptPath in scriptPaths {
            errorMsg .= index . ". " . scriptPath . "`n"
        }
        MsgBox(errorMsg, "文件不存在", "Icon!")
        return false
    }
    
    ; 执行脚本
    return ExecuteAEScript(existingScript, AeExePath)
}

; 构建可能的脚本路径列表
BuildScriptPaths(path) {
    paths := []
    baseDir := A_ScriptDir . "\plugins\AfterEffects\Script"
    
    ; 如果是绝对路径，直接添加
    if InStr(path, ":") || SubStr(path, 1, 2) = "\\" {
        paths.Push(path)
    } else {
        ; 添加相对路径的可能位置
        paths.Push(baseDir . "\Commands\" . path)  ; Commands目录
        paths.Push(baseDir . "\" . path)           ; Script根目录
        paths.Push(path)                           ; 当前目录
    }
    
    return paths
}

; 执行AE脚本
ExecuteAEScript(scriptPath, AeExePath) {
    try {
        ; 检查AE窗口是否激活
        if AEWindowsManager.IsAEWindowActive() {
            ; 直接通过命令行执行
            Run(AeExePath . " -r " . Chr(34) . scriptPath . Chr(34), , "Hide")
            AfterEffects_Logger.Info("直接执行脚本: " . scriptPath)
            return true
        } else {
            ; 使用快捷键方式执行
            return ExecuteViaHotkey(scriptPath)
        }
    } catch Error as e {
        MsgBox("执行脚本时发生错误：" . e.Message, "执行错误", "Icon!")
        AfterEffects_Logger.Error("脚本执行失败: " . scriptPath . " - " . e.Message)
        return false
    }
}

; 通过快捷键方式执行脚本
ExecuteViaHotkey(scriptPath) {
    runAEScriptFile := A_ScriptDir . "\plugins\AfterEffects\Script\runAEScript.jsx"
    
    try {
        ; 创建临时执行脚本
        if !CreateTempRunScript(scriptPath, runAEScriptFile) {
            return false
        }
        
        ; 发送快捷键执行
        Send("^+!{d}")
        Sleep(200)
        
        ; 清理临时文件
        AE_CleanupTempFile(runAEScriptFile)
        
        AfterEffects_Logger.Info("通过快捷键执行脚本: " . scriptPath)
        return true
        
    } catch Error as e {
        ; 确保清理临时文件
        AE_CleanupTempFile(runAEScriptFile)
        AfterEffects_Logger.Error("快捷键执行失败: " . e.Message)
        throw e
    }
}

; 创建临时运行脚本
CreateTempRunScript(scriptPath, tempFile) {
    try {
        ; 确保目录存在
        SplitPath(tempFile, , &dir)
        if !DirExist(dir) {
            DirCreate(dir)
        }
        
        ; 删除已存在的临时文件
        AE_CleanupTempFile(tempFile)
        
        ; 生成脚本内容
        jsCode := GenerateRunScriptCode(scriptPath)
        
        ; 写入文件
        FileObj := FileOpen(tempFile, "w", "UTF-8")
        if !FileObj {
            MsgBox("无法创建临时脚本文件: " . tempFile, "文件错误", "Icon!")
            return false
        }
        
        FileObj.Write(jsCode)
        FileObj.Close()
        
        return true
        
    } catch Error as e {
        MsgBox("创建临时脚本时出错: " . e.Message, "错误", "Icon!")
        return false
    }
}

; 生成运行脚本代码
GenerateRunScriptCode(scriptPath) {
    ; 转换路径格式（反斜杠转为正斜杠）
    normalizedPath := StrReplace(scriptPath, "\", "/")
    
    ; 生成JSX代码
    jsCode := "try {`n"
    jsCode .= "    var scriptpath = `"" . normalizedPath . "`";`n"
    jsCode .= "    $.evalFile(scriptpath);`n"
    jsCode .= "} catch(e) {`n"
    jsCode .= "    alert('执行脚本出错: ' + e.toString());`n"
    jsCode .= "}`n"
    
    return jsCode
}

; 清理临时文件（AE专用）
AE_CleanupTempFile(filePath) {
    try {
        if FileExist(filePath) {
            FileDelete(filePath)
        }
    } catch {
        ; 忽略删除错误
    }
}

; 优化后的 runAeScriptFiles 函数（保留以兼容旧代码）
runAeScriptFiles(path) {
    ; 使用新的创建临时脚本函数
    tempFile := A_ScriptDir . "\plugins\AfterEffects\Script\runAEScript.jsx"
    
    try {
        ; 调用优化后的创建临时脚本函数
        if CreateTempRunScript(path, tempFile) {
            AfterEffects_Logger.Info("兼容模式：创建临时脚本成功 - " . path)
            return true
        } else {
            AfterEffects_Logger.Error("兼容模式：创建临时脚本失败 - " . path)
            return false
        }
    } catch Error as e {
        AfterEffects_Logger.Error("兼容模式出错: " . e.Message)
        MsgBox(Format("写入文件时出错: {1}", e.Message))
        return false
    }
}

; =============================================================================
; After Effects 初始化相关配置和常量
; =============================================================================

; 日志记录类
class AfterEffects_Logger {
    static Write(level, message) {
        try {
            ; 检查日志开关
            if !AfterEffects_InitConfig.ENABLE_LOGGING
                return
                
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
    static ENABLE_LOGGING := true       ; 日志记录开关
    
    ; 读取配置文件
    static __New() {
        this.LoadConfig()
    }
    
    static LoadConfig() {
        configFile := A_ScriptDir "\plugins\AfterEffects\AfterEffects.ini"
        
        if FileExist(configFile) {
            try {
                ini := EasyIni(configFile)
                
                ; 读取日志开关
                if ini.HasOwnProp("Config") && ini.Config.HasOwnProp("EnableLogging") {
                    ; 明确检查 true 和 false
                    value := StrLower(Trim(ini.Config.EnableLogging))
                    if (value = "false" || value = "0" || value = "no" || value = "off") {
                        this.ENABLE_LOGGING := false
                    } else if (value = "true" || value = "1" || value = "yes" || value = "on") {
                        this.ENABLE_LOGGING := true
                    }
                    ; 如果值不是预期的，保持默认值
                }
                
                ; 读取日志级别
                if ini.HasOwnProp("Config") && ini.Config.HasOwnProp("LogLevel") {
                    logLevel := ini.Config.LogLevel
                    if InStr("DEBUG,INFO,WARN,ERROR", logLevel) {
                        this.LOG_LEVEL := logLevel
                    }
                }
                
                ; 读取日志文件路径
                if ini.HasOwnProp("Config") && ini.Config.HasOwnProp("LogFile") {
                    this.LOG_FILE := A_ScriptDir "\plugins\AfterEffects\" ini.Config.LogFile
                }
                
            } catch {
                ; 配置文件读取失败，使用默认值
            }
        }
    }

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
    ; 确保配置已加载
    AfterEffects_InitConfig.LoadConfig()
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
 * 运行Max3D脚本命令 - 优化版本，提高健壮性
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
    ; 验证3Ds Max是否正在运行
    if !WinExist("ahk_exe 3dsmax.exe") {
        MsgBox "3Ds Max 未运行，请先启动 3Ds Max", "错误", 16
        return
    }

    ; 检查是否为脚本文件 (.ms|.mse|.py)
    if RegExMatch(Path, "i).*\.(ms|mse|py)$") {
        ; 验证MXSPyCOM.exe是否存在
        mxsComPath := A_ScriptDir . "\plugins\Max3D\Script\MXSPyCOM.exe"
        if !FileExist(mxsComPath) {
            MsgBox "MXSPyCOM.exe 未找到，无法执行脚本文件", "错误", 16
            return
        }

        ; 检查是否为完整文件路径
        if FileExist(Path) {
            try {
                ; 直接运行完整路径的文件
                Run mxsComPath . " -f " . Chr(34) . Path . Chr(34), , "Hide"
                return
            } catch Error as e {
                MsgBox "执行脚本失败: " . e.Message, "错误", 16
                return
            }
        }

        ; 检查相对路径
        FilePath1 := A_ScriptDir . "\plugins\Max3D\Script\commands\" . Path
        FilePath2 := A_ScriptDir . "\plugins\Max3D\Script\" . Path

        ; 检查文件是否存在并运行
        if FileExist(FilePath2) {
            try {
                Run mxsComPath . " -f " . Chr(34) . FilePath2 . Chr(34), , "Hide"
                return
            } catch Error as e {
                MsgBox "执行脚本失败: " . e.Message, "错误", 16
                return
            }
        }

        if FileExist(FilePath1) {
            try {
                Run mxsComPath . " -f " . Chr(34) . FilePath1 . Chr(34), , "Hide"
                return
            } catch Error as e {
                MsgBox "执行脚本失败: " . e.Message, "错误", 16
                return
            }
        } else {
            MsgBox "文件不存在: " . Path, "错误", 16
            return
        }
    }

    ; 检查是否为ID模式 (id12345)
    if RegExMatch(Path, "^id\d+$") {
        ; 验证控制台控件是否存在
        if !ControlGetHwnd("MXS_Scintilla2", "ahk_exe 3dsmax.exe") {
            MsgBox "无法找到 3Ds Max 的控制台控件", "错误", 16
            return
        }

        ; 提取ID数字部分
        IdNumber := SubStr(Path, 3)
        cmd := 'actionMan.executeAction 0 "' . IdNumber . '"'

        try {
            ; 发送命令到Max3D
            ControlSend cmd . "{Enter}", "MXS_Scintilla2", "ahk_exe 3dsmax.exe"
            Sleep(100)  ; 小延迟确保执行
            return
        } catch Error as e {
            MsgBox "发送ID命令失败: " . e.Message, "错误", 16
            return
        }
    }

    ; 默认为直接Max命令模式
    ; 验证控制台控件是否存在
    if !ControlGetHwnd("MXS_Scintilla2", "ahk_exe 3dsmax.exe") {
        MsgBox "无法找到 3Ds Max 的控制台控件", "错误", 16
        return
    }

    try {
        ControlSend Path . "{Enter}", "MXS_Scintilla2", "ahk_exe 3dsmax.exe"
        Sleep(100)  ; 小延迟确保执行
        return
    } catch Error as e {
        MsgBox "发送命令失败: " . e.Message, "错误", 16
        return
    }
}
/**
 * 运行Blender脚本文件 - 基于vimd框架的Python函数实现
 *
 * 多种用法:
 * 1. run_BlenderScript("script_name.py") - 运行指定的Python脚本文件
 * 2. run_BlenderScript("commands/render_scene.py") - 运行指定路径的脚本
 * 3. run_BlenderScript("D:\path\to\script.py") - 运行绝对路径的脚本
 *; 示例调用
run_BlenderScript("D:\BlenderScripts\test.py")
 * @param {String} Path - Python脚本路径
 * @return {Boolean} 执行是否成功
 */
run_BlenderScript(filePath) {
    ; 检查是否为脚本文件 (.py)
    if !RegExMatch(filePath, "i).*\.py$") {
        MsgBox "仅支持Python脚本文件 (.py)", "错误", 16
        return
    }

    ; 检查是否为完整文件路径
    if FileExist(filePath) {
        ; 直接运行完整路径的文件
        RunBlenderScriptWithPath(filePath)
        return
    }

    ; 检查相对路径
    FilePath1 := A_ScriptDir . "\Plugins\Blender\Script\commands\" . filePath
    FilePath2 := A_ScriptDir . "\Plugins\Blender\Script\models\" . filePath
    FilePath3 := A_ScriptDir . "\Plugins\Blender\Script\materials\" . filePath
    FilePath4 := A_ScriptDir . "\Plugins\Blender\Script\geometrynode\" . filePath
    FilePath5 := A_ScriptDir . "\Plugins\Blender\Script\" . filePath

    ; 检查文件是否存在并运行
    if FileExist(FilePath1) {
        RunBlenderScriptWithPath(FilePath1)
        return
    }
    if FileExist(FilePath2) {
        RunBlenderScriptWithPath(FilePath2)
        return
    }
    if FileExist(FilePath3) {
        RunBlenderScriptWithPath(FilePath3)
        return
    }
    if FileExist(FilePath4) {
        RunBlenderScriptWithPath(FilePath4)
        return
    }
    if FileExist(FilePath5) {
        RunBlenderScriptWithPath(FilePath5)
        return
    }

    MsgBox "文件不存在: " . filePath, "错误", 16
    return
}

/**
 * 使用指定路径运行Blender脚本
 * @param {String} scriptPath - 完整的脚本文件路径
 */
RunBlenderScriptWithPath(scriptPath) {
    ; 读取Blender配置
    configFile := A_ScriptDir "\Plugins\Blender\Blender.ini"
    if FileExist(configFile) {
        try {
            pyExe := IniRead(configFile, "Blender", "python_path", "")
        } catch as e {
            MsgBox "读取Blender配置文件失败: " . e.Message . "`n使用默认Python路径", "配置警告"
            pyExe := "C:\Program Files\Blender Foundation\Blender 4.5\4.5\python\bin\python.exe"
        }
    } else {
        pyExe := "C:\Program Files\Blender Foundation\Blender 4.5\4.5\python\bin\python.exe"
    }
    
    pyClient := A_ScriptDir "\Plugins\Blender\Send_to_Blender.py" ; 客户端脚本路径

    try {
        cmd := '"' pyExe '" "' pyClient '" "' scriptPath '"'
        RunWait cmd,, "Hide"
    } catch as e {
        MsgBox "无法调用 Python 客户端，请确认路径正确。`nError: " e.Message
    }
}
