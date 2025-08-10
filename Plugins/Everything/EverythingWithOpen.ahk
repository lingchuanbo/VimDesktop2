#Requires AutoHotkey v2.0
#SingleInstance Force

; 检查命令行参数，如果有参数则直接处理
if A_Args.Length > 0 {
    ; Everything传递的路径参数
    targetPath := A_Args[1]
    ProcessPath(targetPath)
    ExitApp
}

; 热键示例：Win+O 打开选中的路径
#o:: {
    ; 获取选中的文件/文件夹路径
    selectedPath := GetSelectedPath()
    if !selectedPath {
        MsgBox "没有选中任何文件或文件夹!", "错误", 16
        return
    }

    ProcessPath(selectedPath)
}

; 处理路径的主要逻辑
ProcessPath(path) {
    if !path || !FileExist(path) {
        MsgBox "路径不存在: " path, "错误", 16
        return
    }

    ; 检查Total Commander是否正在运行
    if ProcessExist("TOTALCMD.EXE") {
        ; TC正在运行，用TC打开
        OpenWithTC(path)
    } else {
        ; TC没有运行，使用系统默认方式打开
        try Run path
        catch Error as e
            MsgBox "打开失败: " e.Message, "错误", 16
    }
}

; 获取当前选中的路径
GetSelectedPath() {
    A_Clipboard := ""  ; 清空剪贴板
    Send "^c"          ; 模拟复制
    if !ClipWait(0.5)  ; 等待剪贴板内容
        return ""

    ; 处理剪贴板中的路径
    path := Trim(A_Clipboard)
    if (path != "") && FileExist(path)
        return path

    return ""
}

; 使用Total Commander打开路径
OpenWithTC(path) {
    try {
        ; 从运行中的进程获取TC的完整路径
        tcPID := ProcessExist("TOTALCMD.EXE")
        if !tcPID {
            return false
        }

        ; 获取进程的可执行文件路径
        tcExe := ProcessGetPath(tcPID)
        if !tcExe {
            return false
        }

        ; 直接运行TC并传递路径参数
        Run '"' . tcExe . '" "' . path . '"'
        return true

    } catch as e {
        return false
    }
}
