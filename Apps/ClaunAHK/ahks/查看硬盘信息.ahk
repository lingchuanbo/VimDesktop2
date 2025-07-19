; 判断是否打开TC


#If WinActive("ahk_class CabinetWClass")
{
    activedirTC:=getCurrentDir()
    SplitPath, activedirTC, name, dir, ext, name_no_ext, Drive
    Run %ComSpec% /c ""D:\SoftDir\系统\SpaceSniffer.exe" scan " %dir%,,Hide
    Return
}


#If WinActive("ahk_class TTOTAL_CMD")
{
    activedirTC:=getCurrentDir()
    SplitPath, activedirTC, name, dir, ext, name_no_ext, Drive
    Run %ComSpec% /c ""D:\SoftDir\系统\SpaceSniffer.exe" scan " %dir%,,Hide
    Return
}


;获取当前目录
getCurrentDir(ByRef CurWinClass="")
{
    if CurWinClass=
    {
        WinGetClass, CurWinClass, A
        sleep 50
    }
    ;获取当前目录
    ;CurWinClass:=QZData("winclass") ;将获取的class名赋值给用户变量
    ;Curhwnd:=QZData("hWnd")
    if CurWinClass in ExploreWClass,CabinetWClass ;如果当前激活窗口为资源管理器
    {
        DirectionDir:=Explorer_GetSelected(Curhwnd)
        IfInString,DirectionDir,`;		;我的电脑、回收站、控制面板等退出
            return
    }
    if CurWinClass in WorkerW,Progman    ;如果当前激活窗口为桌面
    {
        DirectionDir:=Explorer_GetSelected(Curhwnd)
    }
    if (CurWinClass="Shell_TrayWnd") ;如果当前激活窗口为任务栏
        DirectionDir:=""

    if CurWinClass in TTOTAL_CMD ;如果当前激活窗口为TC
    {
        IfWinNotActive ahk_class TTOTAL_CMD
        {
            Postmessage, 1075, 2015, 0,, ahk_class TTOTAL_CMD	;最大化
            WinWait,ahk_class TTOTAL_CMD
            WinActivate
        }
        Postmessage, 1075, 332, 0,, ahk_class TTOTAL_CMD	;光标定位到焦点地址栏
        sleep 300
        ;PostMessage,1075,2029,0,,ahk_class TTOTAL_CMD ;获取路径
        PostMessage,1075,2018,0,,ahk_class TTOTAL_CMD ;获取路径2
        sleep 100
        DirectionDir:=Clipboard
    }
    If(DirectionDir="ERROR")		;错误则退出
        DirectionDir:=""
    
    return DirectionDir
}


;以下是库
; Explorer_GetPath(hwnd="")
; {
;     if !(window := Explorer_GetWindow(hwnd))
;         return ErrorLevel := "ERROR"
;     if (window="desktop")
;         return A_Desktop
;     path := window.LocationURL
;     path := RegExReplace(path, "ftp://.*@","ftp://")
;     path := RegExReplace(path, "%20"," ") ;替换空格，否则显示%20
;     StringReplace, path, path, file:///
;     StringReplace, path, path, /, \, All
;     ; thanks to polyethene
;     Loop
;         If RegExMatch(path, "i)(?<=%)[da-f]{1,2}", hex)
;             StringReplace, path, path, `%%hex%, % Chr("0x" . hex), All
;         Else Break
;     return path
; }
 
Explorer_GetAll(hwnd="")
{
    return Explorer_Get(hwnd)
}
 
Explorer_GetSelected(hwnd="")
{
    return Explorer_Get(hwnd,true)
}
 
Explorer_GetWindow(hwnd="")
{
    ; thanks to jethrow for some pointers here
    WinGet, process, processName, % "ahk_id" hwnd := hwnd? hwnd:WinExist("A")
    WinGetClass class, ahk_id %hwnd%
 
    if (process!="explorer.exe")
        return
    if (class ~= "(Cabinet|Explore)WClass")
    {
        for window in ComObjCreate("Shell.Application").Windows
            if (window.hwnd==hwnd)
                return window
    }
    else if (class ~= "Progman|WorkerW")
        return "desktop" ; desktop found
}
 
Explorer_Get(hwnd="",selection=false)
{
    if !(window := Explorer_GetWindow(hwnd))
        return ErrorLevel := "ERROR"
    if (window="desktop")
    {
        ControlGet, hwWindow, HWND,, SysListView321, ahk_class Progman
        if !hwWindow ; #D mode
            ControlGet, hwWindow, HWND,, SysListView321, A
        ControlGet, files, List, % ( selection ? "Selected":"") "Col1",,ahk_id %hwWindow%
        base := SubStr(A_Desktop,0,1)=="" ? SubStr(A_Desktop,1,-1) : A_Desktop
        Loop, Parse, files, `n, `r
        {
            path := base "" A_LoopField
            IfExist %path% ; ignore special icons like Computer (at least for now)
                ret .= path "`n"
        }
    }
    else
    {
        if selection
            collection := window.document.SelectedItems
        else
            collection := window.document.Folder.Items
        for item in collection
            ret .= item.path "`n"
    }
    return Trim(ret,"`n")
}
ExitApp