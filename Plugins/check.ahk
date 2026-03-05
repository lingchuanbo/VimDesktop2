#requires AutoHotkey v2.0

#NoTrayIcon

FileEncoding "UTF-8"
ExtensionsAHK := A_ScriptDir "\plugins.ahk"

; 清理无用#include
FileDelete ExtensionsAHK
FileAppend "", ExtensionsAHK, "UTF-8"

; 查询是否有新插件加入
loop files, A_ScriptDir "\*.*", "D" {
    pluginName := A_LoopFileName
    entry := _GetPluginEntry(pluginName)
    if (entry = "")
        entry := pluginName ".ahk"
    plugins .= _BuildIncludeLine(pluginName, entry)
}
FileAppend plugins, ExtensionsAHK, "UTF-8"

; 保存修改时间
SaveTime := "/*`r`n[ExtensionsTime]`r`n"
loop files, A_ScriptDir "\*.*", "D" {
    pluginName := A_LoopFileName
    pluginFile := _GetPluginFilePath(pluginName)
    ; 检查文件是否存在再获取修改时间
    if FileExist(pluginFile) {
        ExtensionsTime := FileGetTime(pluginFile, "M")
        SaveTime .= pluginName "=" ExtensionsTime "`r`n"
    }
}

SaveTime .= "*/`r`n"
Sleep 200
FileAppend SaveTime, ExtensionsAHK, "UTF-8"
Extensions := FileRead(ExtensionsAHK, "UTF-8")
Send_WM_COPYDATA("Reload")
Exit

Send_WM_COPYDATA(StringToSend) { ; 此函数发送指定的字符串到指定的窗口然后返回收到的回复. 如果目标窗口处理了消息则回复为 1, 而消息被忽略了则为 0.
    CopyDataStruct := Buffer(3 * A_PtrSize, 0)
    SizeInBytes := (StrLen(StringToSend) + 1) * 2
    NumPut("UInt", SizeInBytes, CopyDataStruct, A_PtrSize)
    NumPut("Ptr", StrPtr(StringToSend), CopyDataStruct, 2 * A_PtrSize)
    Prev_DetectHiddenWindows := A_DetectHiddenWindows
    Prev_TitleMatchMode := A_TitleMatchMode
    DetectHiddenWindows True
    SetTitleMatchMode 2
    hwnd := iniRead(A_Temp "\vimd_auto.ini", "auto", "hwnd")
    ; SendMessage 0x4a, 0, &CopyDataStruct, , "ahk_id " hwnd
    try
        SendMessage 0x4a, 0, CopyDataStruct.Ptr, , "ahk_id " hwnd
    DetectHiddenWindows Prev_DetectHiddenWindows
    SetTitleMatchMode Prev_TitleMatchMode
    return A_LastError
}

_GetPluginEntry(pluginName) {
    metaPath := A_ScriptDir "\" pluginName "\plugin.meta.ini"
    if !FileExist(metaPath)
        return ""
    try {
        entry := IniRead(metaPath, "plugin", "entry", "")
        if (entry = "")
            entry := IniRead(metaPath, "plugin", "main", "")
        entry := Trim(entry, " `t")
        if (SubStr(entry, 1, 1) = "\" || SubStr(entry, 1, 1) = "/")
            entry := SubStr(entry, 2)
        return entry
    } catch {
        return ""
    }
}

_GetPluginFilePath(pluginName) {
    entry := _GetPluginEntry(pluginName)
    if (entry = "")
        entry := pluginName ".ahk"
    return A_ScriptDir "\" pluginName "\" entry
}

_BuildIncludeLine(pluginName, entry) {
    if (RegExMatch(entry, "i)^[a-z]:\\") || SubStr(entry, 1, 2) = "\\") {
        return '#include *i "' entry '"`n'
    }
    return Format('#include *i ..\plugins\{1}\{2}`n', pluginName, entry)
}
