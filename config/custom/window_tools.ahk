; ==============================================================================
; 窗口操作工具
; ==============================================================================

^!MButton:: AppAlwaysOnTop()
AppAlwaysOnTop() {
    WinSetAlwaysOnTop -1, "A"
    getTop := WinGetExStyle("A")

    if (getTop & 0x8)
        ToolTipEX("已置顶", 0.5)
    else
        ToolTipEX("取消置顶", 0.5)
}

^!LButton:: OpenLocalDirExe()
OpenLocalDirExe() {
    pPath := WinGetProcessPath("A")
    SplitPath(pPath, &pName, &pDir, , &pNameNoExt)

    tcPath := INIObject.TTOTAL_CMD.tc_path

    if ProcessExist("TOTALCMD.EXE") {
        Run tcPath " /T /O /S /L=" pDir
        Sleep 200
        Send "{Esc}"
        ToolTipEX("使用TC打开：" pDir, 1)
    } else {
        Run "explorer.exe /select," pPath
        ToolTipEX("使用资源管理器打开：" pDir, 1)
    }
}

~LShift & WheelUp:: AdjustTransparencyUp()
AdjustTransparencyUp() {
    transparent := WinGetTransparent("A")
    if (transparent = "")
        transparent := 255

    transparentNew := transparent + 20
    if (transparentNew > 254)
        transparentNew := 255

    WinSetTransparent(transparentNew, "A")

    xMidScrn := A_ScreenWidth // 2
    yMidScrn := A_ScreenHeight // 2
    text := "原透明度: " transparent " `n新透明度: " transparentNew

    ToolTipEX(text, 0.5, , , xMidScrn - 100, yMidScrn - 100)
}

~LShift & WheelDown:: AdjustTransparencyDown()
AdjustTransparencyDown() {
    transparent := WinGetTransparent("A")
    if (transparent = "")
        transparent := 255

    transparentNew := transparent - 10
    if (transparentNew < 30)
        transparentNew := 30

    WinSetTransparent(transparentNew, "A")

    xMidScrn := A_ScreenWidth // 2
    yMidScrn := A_ScreenHeight // 2
    text := "原透明度: " transparent " `n新透明度: " transparentNew

    ToolTipEX(text, 0.5, , , xMidScrn - 100, yMidScrn - 100)
}

#LButton:: MaxRestore()
MaxRestore() {
    statusMinMax := WinGetMinMax("A")
    if (statusMinMax = 1)
        WinRestore "A"
    else
        WinMaximize "A"
}

!Enter:: MaxAllRestore()
MaxAllRestore() {
    static fullscreenWindow := 0
    static pMenu := 0
    static pX := 0, pY := 0, pW := 0, pH := 0

    if WinExist("ahk_id " fullscreenWindow) {
        if pMenu
            DllCall("SetMenu", "UInt", fullscreenWindow, "UInt", pMenu)
        WinSetStyle "+0xC40000", "ahk_id " fullscreenWindow
        WinMove pX, pY, pW, pH, "ahk_id " fullscreenWindow
        fullscreenWindow := 0
        return
    }

    style := WinGetStyle("A")
    if ((style & 0xC40000) != 0xC40000)
        return

    fullscreenWindow := WinExist("A")
    WinGetPos &pX, &pY, &pW, &pH, "A"

    WinSetStyle "-0xC40000", "A"

    pMenu := DllCall("GetMenu", "UInt", fullscreenWindow)
    if pMenu
        DllCall("SetMenu", "UInt", fullscreenWindow, "UInt", 0)

    monitorIndex := ClosestMonitorTo(pX + pW // 2, pY + pH // 2)
    MonitorGet monitorIndex, &mLeft, &mTop, &mRight, &mBottom
    WinMove mLeft, mTop, mRight - mLeft, mBottom - mTop, "A"
}

ClosestMonitorTo(x, y) {
    monitorCount := MonitorGetCount()
    closestDistance := 99999999
    closestMonitor := 1

    loop monitorCount {
        MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)

        mCenterX := mLeft + (mRight - mLeft) / 2
        mCenterY := mTop + (mBottom - mTop) / 2
        distance := Sqrt((x - mCenterX) ** 2 + (y - mCenterY) ** 2)

        if (distance < closestDistance) {
            closestDistance := distance
            closestMonitor := A_Index
        }
    }

    return closestMonitor
}

MaxAllWindows() {
    wsDisabled := 0x8000000
    wsExToolWindow := 0x80
    wsExAppWindow := 0x40000

    windowList := WinGetList()

    for wid in windowList {
        widTitle := WinGetTitle("ahk_id " wid)
        style := WinGetStyle("ahk_id " wid)

        if (!(style & 0xC90000) || !(style & 0x40000) || (style & wsDisabled) || !(widTitle))
            continue

        es := WinGetExStyle("ahk_id " wid)
        parent := Format("0x{:X}", DllCall("GetParent", "UInt", wid))
        styleParent := parent ? WinGetStyle("ahk_id " parent) : 0
        owner := Format("0x{:X}", DllCall("GetWindow", "UInt", wid, "UInt", 4))
        styleOwner := owner ? WinGetStyle("ahk_id " owner) : 0

        if (((es & wsExToolWindow) && !parent)
        || (!(es & wsExAppWindow)
        && ((parent && ((styleParent & wsDisabled) = 0))
        || (owner && ((styleOwner & wsDisabled) = 0)))))
            continue

        statusMinMax := WinGetMinMax("ahk_id " wid)
        if (statusMinMax != 1)
            WinMaximize "ahk_id " wid
    }
}

#RButton:: WindowsMoveSimple()
WindowsMoveSimple() {
    CoordMode "Mouse", "Screen"

    MouseGetPos &startX, &startY, &winID
    WinGetPos &winX, &winY, , , "ahk_id " winID

    if (WinGetMinMax("ahk_id " winID) != 0)
        return

    ToolTipEX("按住右键拖动窗口", 0.5)

    while GetKeyState("RButton", "P") {
        Sleep 10
        MouseGetPos &newX, &newY

        moveX := newX - startX
        moveY := newY - startY

        if (moveX != 0 || moveY != 0) {
            WinMove winX + moveX, winY + moveY, , , "ahk_id " winID
            startX := newX
            startY := newY
            winX += moveX
            winY += moveY
        }
    }
}

#MButton:: WindowCenter()
WindowCenter() {
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

#F11:: WindowFullSize()
WindowFullSize() {
    ToolTipEX("窗口100%显示", 0.5)

    winID := WinExist("A")

    if (WinGetMinMax("ahk_id " winID) = 1) {
        WinRestore "ahk_id " winID
        Sleep 100
    }

    WinGetPos &winX, &winY, &winWidth, &winHeight, "ahk_id " winID

    winCenterX := winX + winWidth / 2
    winCenterY := winY + winHeight / 2

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

    MonitorGet currentMonitor, &mLeft, &mTop, &mRight, &mBottom
    monitorWidth := mRight - mLeft
    monitorHeight := mBottom - mTop

    WinGetClientPos &clientX, &clientY, &clientWidth, &clientHeight, "ahk_id " winID
    borderWidth := winWidth - clientWidth
    borderHeight := winHeight - clientHeight

    designSizes := Map(
        "chrome.exe", [1280, 800],
        "msedge.exe", [1280, 800],
        "firefox.exe", [1280, 800],
        "notepad.exe", [800, 600],
        "explorer.exe", [1024, 768],
        "mspaint.exe", [1024, 768],
        "WINWORD.EXE", [1024, 768],
        "EXCEL.EXE", [1024, 768],
        "POWERPNT.EXE", [1024, 768],
        "Code.exe", [1280, 800],
        "devenv.exe", [1280, 800],
        "photoshop.exe", [1280, 800],
        "illustrator.exe", [1280, 800],
        "TOTALCMD.EXE", [1024, 768]
    )

    processName := WinGetProcessName("ahk_id " winID)
    designWidth := 1024
    designHeight := 768

    if designSizes.Has(processName) {
        designSize := designSizes[processName]
        designWidth := designSize[1]
        designHeight := designSize[2]
    }

    if (designWidth > monitorWidth * 0.8)
        designWidth := monitorWidth * 0.8
    if (designHeight > monitorHeight * 0.8)
        designHeight := monitorHeight * 0.8

    newWidth := designWidth + borderWidth
    newHeight := designHeight + borderHeight
    newX := mLeft + (monitorWidth - newWidth) / 2
    newY := mTop + (monitorHeight - newHeight) / 2

    WinMove newX, newY, newWidth, newHeight, "ahk_id " winID
}
