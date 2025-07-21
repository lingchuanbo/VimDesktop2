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
