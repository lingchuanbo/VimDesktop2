; ==============================================================================
; 启动器与截图工具
; ==============================================================================

claunch() {
    names := []
    loop {
        notfind := "notfind"
        nowpage := "page" . Format("{:03}", A_Index - 1)
        name := IniRead(A_ScriptDir "\..\apps\ClaunAHK\Data\BoBO\CLaunch.ini", nowpage, "Name", notfind)
        if (name = notfind)
            break
        names.Push(name)
    }

    title := WinGetTitle("A")
    class := WinGetClass("A")
    exe := WinGetProcessName("A")
    exe := StrReplace(exe, ".exe")

    pagenow := 1
    loop names.Length {
        name := names[A_Index]
        if (name = exe or name = "c " . class or name = "t " . title) {
            pagenow := A_Index
            break
        }
    }

    CoordMode "Mouse", "Screen"
    MouseGetPos &mouseX, &mouseY

    monitorCount := MonitorGetCount()
    currentMonitor := 1

    loop monitorCount {
        MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)
        if (mouseX >= mLeft && mouseX <= mRight &&
            mouseY >= mTop && mouseY <= mBottom) {
            currentMonitor := A_Index
            break
        }
    }

    MonitorGetWorkArea(currentMonitor, &mLeft, &mTop, &mRight, &mBottom)
    monitorWidth := mRight - mLeft
    monitorHeight := mBottom - mTop

    centerX := mLeft + monitorWidth / 2
    centerY := mTop + monitorHeight / 2

    claunchWidth := 600
    claunchHeight := 400
    claunchX := centerX - claunchWidth / 2
    claunchY := centerY - claunchHeight / 2

    Run A_ScriptDir "\..\apps\ClaunAHK\claunch.exe /n /m /p" pagenow
    WinWait "ahk_exe claunch.exe", , 2

    if WinExist("ahk_exe claunch.exe")
        WinMove claunchX, claunchY, claunchWidth, claunchHeight, "ahk_exe claunch.exe"
}