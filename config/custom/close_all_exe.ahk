; ==============================================================================
; 系统与收尾工具
; ==============================================================================

#Esc:: CloseAllExe()
CloseAllExe() {
    comSpec := EnvGet("ComSpec")
    batPath := A_ScriptDir "\..\apps\CloseAllPortable\CloseAllp.bat"

    if FileExist(batPath) {
        ToolTipEX("正在关闭程序...", 1)
        RunWait "*RunAs " comSpec " /c " batPath, A_ScriptDir "\.."
    } else {
        MsgBox "批处理文件不存在: " batPath
        return
    }

    Sleep 200

    softDir := EnvGet("SoftDir")
    closeAllPath := A_ScriptDir "\..\apps\CloseAllPortable\App\CloseAll\64\CloseAll64.exe"

    if FileExist(closeAllPath)
        Run closeAllPath " /NOUI"
    else
        MsgBox "CloseAll64.exe 不存在: " closeAllPath

    if ProcessWait("memreduct.exe", 1) {
        Send "^{F2}"
    } else {
        softDir := EnvGet("SoftDir")
        if softDir {
            memReductPath := softDir "\MemReduct\memreduct.exe"
            if FileExist(memReductPath) {
                Run memReductPath
                Sleep 200
                Send "^{F2}"
            } else {
                MsgBox "MemReduct.exe 不存在: " memReductPath
            }
        } else {
            MsgBox "环境变量 SoftDir 未设置"
        }
    }
}
