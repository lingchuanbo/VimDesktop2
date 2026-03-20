; ==============================================================================
; Win+Z 组合窗口操作
; 单击：打开 CLaunch
; 双击：最大化/还原
; 长按：窗口居中
; 设计目标：完全自包含，可单独删除或停用
; ==============================================================================

WindowQuickAdjustSingleClick() {
    WindowQuickAdjustOpenCLaunch()
}

WindowQuickAdjustDoubleClick() {
    WindowQuickAdjustMaxRestore()
}

WindowQuickAdjustLongPress() {
    WindowQuickAdjustCenter()
}

windowQuickAdjustAction := CreateClickHandler(WindowQuickAdjustSingleClick, WindowQuickAdjustDoubleClick, WindowQuickAdjustLongPress, 500, 300, false)
Hotkey "$#z", windowQuickAdjustAction

WindowQuickAdjustOpenCLaunch() {
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

WindowQuickAdjustMaxRestore() {
    statusMinMax := WinGetMinMax("A")
    if (statusMinMax = 1)
        WinRestore "A"
    else
        WinMaximize "A"
}

WindowQuickAdjustCenter() {
    ToolTipEX("窗口居中", 0.5)

    winID := WinExist("A")
    WinGetPos &winX, &winY, &width, &height, "ahk_id " winID

    winCenterX := winX + width / 2
    winCenterY := winY + height / 2

    monitorCount := MonitorGetCount()
    currentMonitor := 1

    loop monitorCount {
        MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)
        if (winCenterX >= mLeft && winCenterX <= mRight &&
            winCenterY >= mTop && winCenterY <= mBottom) {
            currentMonitor := A_Index
            break
        }
    }

    MonitorGet(currentMonitor, &mLeft, &mTop, &mRight, &mBottom)
    monitorWidth := mRight - mLeft
    monitorHeight := mBottom - mTop

    centerX := mLeft + (monitorWidth / 2) - (width / 2)
    centerY := mTop + (monitorHeight / 2) - (height / 2)

    WinMove centerX, centerY, , , "ahk_id " winID
    ToolTipEX("窗口已在显示器 " currentMonitor " 上居中", 0.8)
}
