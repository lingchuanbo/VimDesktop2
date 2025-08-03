#Requires AutoHotkey v2.0

; 引入必要的库文件
#Include ..\Lib\ToolTipEx.ahk

; ==============================================================================
;  1. 创建划词菜单对象
; ==============================================================================

; 创建主菜单
mainMenu := Menu()

; 创建一个用于切换主题的子菜单
themeMenu := Menu()

; 跟踪当前主题状态
global isDarkMode := false

; ==============================================================================
;  2. 向菜单中添加项目
; ==============================================================================

; --- 向"主题"子菜单中添加项目 ---
; 每个项目都关联一个回调函数
themeMenu.Add("明亮模式", ShowInfoMain)
themeMenu.Add("暗黑模式", ShowInfoMain)
themeMenu.Add("跟随系统", ShowInfoMain)

; --- 向主菜单中添加项目 ---
; 添加一些常规菜单项作为示例
mainMenu.Add("智能搜索", ShowInfoMain)
mainMenu.Add("翻译", ShowInfoMain)
mainMenu.Add() ; 添加一条分割线
mainMenu.Add("截图", themeMenu) ; 将"主题"子菜单添加到主菜单
mainMenu.Add("下载", ShowInfoMain)
; mainMenu.Add()
; mainMenu.Add("退出", (*) => ExitApp()) ; 使用 Fat-arrow 函数直接退出脚本

; ==============================================================================
;  3. 定义菜单项的回调函数
; ==============================================================================

/**
 * 将菜单设置为明亮模式
 */
SetLightMode(*) {
    ; 使用 WindowsTheme 类设置为亮色模式
    WindowsTheme.SetAppMode(false)
    isDarkMode := false
    MsgBox "已切换到明亮模式", "主题提示", "T0.5"
}

/**
 * 将菜单设置为暗黑模式
 */
SetDarkMode(*) {
    ; 使用 WindowsTheme 类设置为暗色模式
    WindowsTheme.SetAppMode(true)
    isDarkMode := true
    MsgBox "已切换到暗黑模式", "主题提示", "T0.5"
}

/**
 * 将菜单主题设置为跟随系统
 */
SetSystemTheme(*) {
    ; 恢复默认设置，跟随系统主题
    WindowsTheme.SetAppMode("Default")
    isDarkMode := false
    MsgBox "已设置为跟随系统主题", "主题提示", "T0.5"
}

/**
 * 一个通用的信息提示函数，用于演示其他菜单项
 */
ShowInfoMain(ItemName, ItemPos, MyMenu) {
    MsgBox "你点击了 '" ItemName "' 菜单项。"
}

; ==============================================================================
;  4. 设置一个热键来显示菜单
; ==============================================================================

; 按下 F1 键，在当前鼠标指针位置显示主菜单

; 初始化时应用系统默认主题
; WindowsTheme.SetAppMode("Default")

; MsgBox "脚本已启动。`n`n按 F1 键显示菜单，并通过'主题'子菜单更改颜色。", "提示"

; ==============================================================================
/*
    快速访问 Deepseek、Gemini、Kimi
*/
; 预先创建处理函数，然后绑定到热键
DeepseekSingleClick() {
    Run "https://chat.deepseek.com"
}

DeepseekDoubleClick() {
    Run "https://aistudio.google.com/"
}

DeepseekLongPress() {
    Run "https://www.kimi.com"
}

; 创建处理函数并绑定到热键
deepseekAction := CreateClickHandler(DeepseekSingleClick, DeepseekDoubleClick, DeepseekLongPress)
Hotkey "$#s", deepseekAction

; ==============================================================================
/*
    claunch 启动器 - 在当前屏幕居中显示
*/
; #z:: claunch()
claunch() {
    ; 读取claunch.ini文件中的所有name信息，并存储在一个数组中
    names := []
    loop {
        notfind := "notfind"
        nowpage := "page" . Format("{:03}", A_Index - 1)
        name := IniRead(A_ScriptDir "\Apps\ClaunAHK\Data\BoBO\CLaunch.ini", nowpage, "Name", notfind)
        if (name = notfind)
            break
        names.Push(name)
    }

    ; 获取当前激活窗口的信息
    title := WinGetTitle("A")
    class := WinGetClass("A")
    exe := WinGetProcessName("A")
    exe := StrReplace(exe, ".exe")

    ; 与claunch.ini中的所有name信息依次比较，如果一致，则将对应的page编号赋值给变量pagenow
    pagenow := 1 ; 如果没有匹配的name，pagenow为1
    loop names.Length {
        name := names[A_Index]
        if (name = exe or name = "c " . class or name = "t " . title) {
            pagenow := A_Index ; page编号从1开始
            break
        }
    }

    ; 获取鼠标当前位置
    CoordMode "Mouse", "Screen"
    MouseGetPos &mouseX, &mouseY

    ; 找到鼠标所在的显示器
    MonitorCount := MonitorGetCount()
    currentMonitor := 1

    loop MonitorCount {
        MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)

        ; 检查鼠标是否在这个显示器内
        if (mouseX >= mLeft && mouseX <= mRight &&
            mouseY >= mTop && mouseY <= mBottom) {
            currentMonitor := A_Index
            break
        }
    }

    ; 获取当前显示器的工作区域
    MonitorGetWorkArea(currentMonitor, &mLeft, &mTop, &mRight, &mBottom)
    monitorWidth := mRight - mLeft
    monitorHeight := mBottom - mTop

    ; 计算屏幕中心点
    centerX := mLeft + monitorWidth / 2
    centerY := mTop + monitorHeight / 2

    ; CLaunch的默认尺寸（可根据实际情况调整）
    claunchWidth := 600
    claunchHeight := 400

    ; 计算CLaunch窗口的左上角坐标，使其居中显示
    claunchX := centerX - claunchWidth / 2
    claunchY := centerY - claunchHeight / 2

    ; 运行CLaunch并设置位置
    Run A_ScriptDir "\Apps\ClaunAHK\claunch.exe /n /m /p" pagenow

    ; 等待CLaunch窗口出现
    WinWait "ahk_exe claunch.exe", , 2

    ; 移动CLaunch窗口到计算的位置
    if WinExist("ahk_exe claunch.exe") {
        WinMove claunchX, claunchY, claunchWidth, claunchHeight, "ahk_exe claunch.exe"
    }
}

; ==============================================================================
/*
    FSCapture 截图
*/
FSCaptureSingleClick() {
    FSCaptureExe("Ctrl+Alt+F3")
}

FSCaptureDoubleClick() {
    Run "https://aistudio.google.com/"
}

; 创建处理函数并绑定到热键
fsCaptureAction := CreateSimpleClickHandler(FSCaptureSingleClick, FSCaptureDoubleClick)
Hotkey "$^!a", fsCaptureAction

FSCaptureExe(keymap) {
    /*
    激活窗口         "Alt+PrtSc"
    窗口或对象       "Shift+PrtSc"
    矩形区域         "Ctrl+PrtSc"
    手绘区域         "Ctrl+Shift+PrtSc"
    整个屏幕         "PrtSc"
    滚动窗口         "Ctrl+Alt+PrtSc"
    固定大小区域     "Ctrl+Alt+Shift+PrtSc"
    系统自带截图     "Ctrl+Alt+Shift+PrtSc"
    ;
    */
    FSCaptureExe := "D:\BoBO\WorkFlow\tools\TotalCMD\Tools\FSCapture\FSCLoader.exe "
    Run FSCaptureExe keymap
    ; send ^!{F3}
}
; ==============================================================================
/*
    ;功能：窗口置顶
*/
; #MButton:: AppAlwaysOnTop()
^!MButton:: AppAlwaysOnTop()
AppAlwaysOnTop() {
    WinSetAlwaysOnTop -1, "A"  ; -1 means toggle
    getTitle := WinGetTitle("A")
    getTop := WinGetExStyle("A")

    if (getTop & 0x8)  ; 0x8 is WS_EX_TOPMOST
    {
        ToolTipEX("已置顶", 0.5)
    }
    else {
        ToolTipEX("取消置顶", 0.5)
    }
}

; ==============================================================================
/*
    打开当前程序所在目录
    如果Total Commander运行则使用TC打开，否则使用资源管理器
*/
^!LButton:: OpenLocalDirExe()
OpenLocalDirExe() {
    ; 获取当前活动窗口的进程路径
    pPath := WinGetProcessPath("A")
    SplitPath(pPath, &pName, &pDir, , &pNameNoExt)

    ; 从配置文件获取Total Commander路径
    ; tcPath := "D:\BoBO\WorkFlow\tools\TotalCMD\TOTALCMD.EXE"  ; 默认路径
    tcPath := INIObject.TTOTAL_CMD.tc_path

    ; 检查Total Commander是否正在运行
    if ProcessExist("TOTALCMD.EXE") {
        ; 使用Total Commander打开目录
        Run tcPath " /T /O /S /L=" pDir
        Sleep 200
        Send "{Esc}"
        ToolTipEX("使用TC打开：" pDir, 1)
    } else {
        ; 使用资源管理器打开目录
        Run "explorer.exe /select," pPath
        ToolTipEX("使用资源管理器打开：" pDir, 1)
    }
}
; ==============================================================================
/*
    LShift+鼠标滚轮调整窗口透明度（设置30-255的透明度，低于30基本上就看不见了，如需要可自行修改）
*/
~LShift & WheelUp:: AdjustTransparencyUp()
AdjustTransparencyUp() {
    ; 透明度调整，增加
    Transparent := WinGetTransparent("A")
    if (Transparent = "")
        Transparent := 255

    Transparent_New := Transparent + 20    ; 透明度增加速度
    if (Transparent_New > 254)
        Transparent_New := 255

    WinSetTransparent(Transparent_New, "A")

    ; 显示透明度信息
    xMidScrn := A_ScreenWidth // 2
    yMidScrn := A_ScreenHeight // 2
    Text := "原透明度: " Transparent " `n新透明度: " Transparent_New

    ToolTipEX(Text, 0.5, , , xMidScrn - 100, yMidScrn - 100)
}

~LShift & WheelDown:: AdjustTransparencyDown()
AdjustTransparencyDown() {
    ; 透明度调整，减少
    Transparent := WinGetTransparent("A")
    if (Transparent = "")
        Transparent := 255

    Transparent_New := Transparent - 10    ; 透明度减少速度
    if (Transparent_New < 30)              ; 最小透明度限制
        Transparent_New := 30

    WinSetTransparent(Transparent_New, "A")

    ; 显示透明度信息
    xMidScrn := A_ScreenWidth // 2
    yMidScrn := A_ScreenHeight // 2
    Text := "原透明度: " Transparent " `n新透明度: " Transparent_New

    ToolTipEX(Text, 0.5, , , xMidScrn - 100, yMidScrn - 100)
}

; ==============================================================================
/*
    测试ToolTip库切换功能
    使用Ctrl+Alt+T切换ToolTip库，使用Ctrl+Alt+Shift+T测试ToolTip显示
*/
^!t:: SwitchTooltipLibrary()
SwitchTooltipLibrary() {
    ; 获取当前使用的库
    currentLib := ""
    try {
        currentLib := INIObject.config.tooltip_library
    } catch {
        currentLib := "ToolTipOptions"
    }
    
    ; 切换到另一个库
    newLib := (currentLib = "ToolTipOptions") ? "BTT" : "ToolTipOptions"
    
    ; 使用ToolTipManager切换库
    ToolTipManager.SwitchLibrary(newLib)
    
    ; 显示切换结果
    ToolTipManager.Show("已切换到: " newLib "`n当前库: " ToolTipManager.currentLibrary, , , 1)
    
    ; 3秒后隐藏
    SetTimer(() => ToolTipManager.Hide(1), -3000)
}

^!+t:: TestTooltipDisplay()
TestTooltipDisplay() {
    ; 测试当前ToolTip库的显示效果
    currentLib := ToolTipManager.currentLibrary
    
    testText := "ToolTip库测试`n"
    testText .= "当前使用: " currentLib "`n"
    testText .= "时间: " FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") "`n"
    testText .= "这是一个多行测试文本"
    
    ; 显示测试ToolTip
    ToolTipManager.Show(testText, , , 2)
    
    ; 5秒后隐藏
    SetTimer(() => ToolTipManager.Hide(2), -5000)
}

; ==============================================================================
/*
    窗口 最大化/还原/居中
*/
WinSizeAdjustSingleClick() {
    claunch()
}

WinSizeAdjustDoubleClick() {
    MaxRestore()
}

WinSizeAdjustLongPress() {
    WindowCenter()
}

; 创建处理函数并绑定到热键
winSizeAction := CreateClickHandler(WinSizeAdjustSingleClick, WinSizeAdjustDoubleClick, WinSizeAdjustLongPress, 500, 300, false)
Hotkey "$#z", winSizeAction

#LButton:: MaxRestore()

MaxRestore() {
    Status_minmax := WinGetMinMax("A")
    if (Status_minmax = 1) {
        WinRestore "A"
    } else {
        WinMaximize "A"
    }
}

; ==============================================================================
/*
    窗口 全屏/还原
*/
!Enter:: MaxAllRestore()
MaxAllRestore() {
    static FullscreenWindow := 0
    static PMenu := 0
    static PX := 0, PY := 0, PW := 0, PH := 0

    if WinExist("ahk_id " FullscreenWindow) {
        if PMenu                    ; Restore the menu.
            DllCall("SetMenu", "UInt", FullscreenWindow, "UInt", PMenu)
        WinSetStyle "+0xC40000", "ahk_id " FullscreenWindow    ; Restore WS_CAPTION|WS_SIZEBOX.
        WinMove PX, PY, PW, PH, "ahk_id " FullscreenWindow   ; Restore position and size.
        FullscreenWindow := 0
        return
    }

    Style := WinGetStyle("A")
    if ((Style & 0xC40000) != 0xC40000) ; WS_CAPTION|WS_SIZEBOX
        return

    FullscreenWindow := WinExist("A")

    WinGetPos &PX, &PY, &PW, &PH, "A"

    ; Remove WS_CAPTION|WS_SIZEBOX.
    WinSetStyle "-0xC40000", "A"

    PMenu := DllCall("GetMenu", "UInt", FullscreenWindow)
    ; Remove the window's menu.
    if PMenu
        DllCall("SetMenu", "UInt", FullscreenWindow, "UInt", 0)

    ; Get the area of whichever monitor the window is on.
    MonitorIndex := ClosestMonitorTo(PX + PW // 2, PY + PH // 2)
    MonitorGet MonitorIndex, &mLeft, &mTop, &mRight, &mBottom

    ; Size the window to fill the entire screen.
    WinMove mLeft, mTop, mRight - mLeft, mBottom - mTop, "A"
}

; Helper function to find the closest monitor
ClosestMonitorTo(x, y) {
    ; Get the number of monitors
    MonitorCount := MonitorGetCount()

    closestDistance := 99999999
    closestMonitor := 1

    ; Find the closest monitor
    loop MonitorCount {
        MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)

        ; Calculate the center of the monitor
        mCenterX := mLeft + (mRight - mLeft) / 2
        mCenterY := mTop + (mBottom - mTop) / 2

        ; Calculate the distance to the point
        distance := Sqrt((x - mCenterX) ** 2 + (y - mCenterY) ** 2)

        ; Update if this is the closest so far
        if (distance < closestDistance) {
            closestDistance := distance
            closestMonitor := A_Index
        }
    }

    return closestMonitor
}

; ==============================================================================
/*
    窗口 最大化所有窗口
    慎用 会把一些隐藏的窗口也一起最大化 后续改写规则只处理 指定的程序
*/
; ^!#up:: MaxAllWindows()
MaxAllWindows() {
    ; Constants for window styles
    WS_DISABLED := 0x8000000
    WS_EX_TOOLWINDOW := 0x80
    WS_EX_APPWINDOW := 0x40000

    ; Get a list of all windows
    windowList := WinGetList()

    ; Loop through all windows
    for wid in windowList {
        wid_Title := WinGetTitle("ahk_id " wid)
        Style := WinGetStyle("ahk_id " wid)

        if (!(Style & 0xC90000) || !(Style & 0x40000) || (Style & WS_DISABLED) || !(wid_Title)) ; skip unimportant windows
            continue

        es := WinGetExStyle("ahk_id " wid)
        Parent := Format("0x{:X}", DllCall("GetParent", "UInt", wid))
        Style_parent := Parent ? WinGetStyle("ahk_id " Parent) : 0
        Owner := Format("0x{:X}", DllCall("GetWindow", "UInt", wid, "UInt", 4)) ; GW_OWNER = 4
        Style_Owner := Owner ? WinGetStyle("ahk_id " Owner) : 0

        if (((es & WS_EX_TOOLWINDOW) && !Parent)
        || (!(es & WS_EX_APPWINDOW)
        && ((Parent && ((Style_parent & WS_DISABLED) = 0))
        || (Owner && ((Style_Owner & WS_DISABLED) = 0)))))
            continue

        Status_minmax := WinGetMinMax("ahk_id " wid)
        if (Status_minmax != 1) {
            WinMaximize "ahk_id " wid
        }
    }
}

; ==============================================================================
/*
    使用Win+鼠标右键拖动窗口
*/
#RButton:: WindowsMoveSimple()
WindowsMoveSimple() {
    ; 简化版的窗口移动函数，使用更直接的方法
    CoordMode "Mouse", "Screen"

    ; 获取鼠标位置和当前窗口
    MouseGetPos &startX, &startY, &winID

    ; 获取窗口原始位置
    WinGetPos &winX, &winY, , , "ahk_id " winID

    ; 检查窗口是否最大化
    if (WinGetMinMax("ahk_id " winID) != 0)
        return  ; 如果窗口已最大化，则不执行移动

    ; 显示提示
    ToolTipEX("按住右键拖动窗口", 0.5)

    ; 等待右键释放
    while GetKeyState("RButton", "P") {
        Sleep 10  ; 短暂延迟以减少CPU使用

        ; 获取新的鼠标位置
        MouseGetPos &newX, &newY

        ; 计算移动距离
        moveX := newX - startX
        moveY := newY - startY

        ; 如果鼠标移动了，则移动窗口
        if (moveX != 0 || moveY != 0) {
            ; 移动窗口
            WinMove winX + moveX, winY + moveY, , , "ahk_id " winID

            ; 更新起始位置
            startX := newX
            startY := newY
            winX += moveX
            winY += moveY
        }
    }
}

; 备用方法 - 使用Alt+鼠标左键拖动窗口
; !LButton::
; {
;     CoordMode "Mouse", "Screen"
;     MouseGetPos &startX, &startY, &winID

;     ; 获取窗口原始位置
;     WinGetPos &winX, &winY, , , "ahk_id " winID

;     ; 检查窗口是否最大化
;     if (WinGetMinMax("ahk_id " winID) != 0)
;         return  ; 如果窗口已最大化，则不执行移动

;     ; 等待左键释放
;     while GetKeyState("LButton", "P") {
;         Sleep 10  ; 短暂延迟以减少CPU使用

;         ; 获取新的鼠标位置
;         MouseGetPos &newX, &newY

;         ; 计算移动距离
;         moveX := newX - startX
;         moveY := newY - startY

;         ; 如果鼠标移动了，则移动窗口
;         if (moveX != 0 || moveY != 0) {
;             ; 移动窗口
;             WinMove winX + moveX, winY + moveY, , , "ahk_id " winID

;             ; 更新起始位置
;             startX := newX
;             startY := newY
;             winX += moveX
;             winY += moveY
;         }
;     }
;     return
; }

; ==============================================================================
/*
    窗口居中 - 使用Win+F12快捷键
    支持多显示器，窗口会在当前所在的显示器上居中
*/
#MButton:: WindowCenter()
WindowCenter() {
    ; 显示提示
    ToolTipEX("窗口居中", 0.5)

    ; 获取当前窗口ID和位置
    winID := WinExist("A")
    WinGetPos &winX, &winY, &Width, &Height, "ahk_id " winID

    ; 计算窗口中心点
    winCenterX := winX + Width / 2
    winCenterY := winY + Height / 2

    ; 找到窗口当前所在的显示器
    MonitorCount := MonitorGetCount()
    currentMonitor := 1

    loop MonitorCount {
        MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)

        ; 检查窗口中心点是否在这个显示器内
        if (winCenterX >= mLeft && winCenterX <= mRight &&
            winCenterY >= mTop && winCenterY <= mBottom) {
            currentMonitor := A_Index
            break
        }
    }

    ; 获取当前显示器的工作区域
    MonitorGet(currentMonitor, &mLeft, &mTop, &mRight, &mBottom)
    monitorWidth := mRight - mLeft
    monitorHeight := mBottom - mTop

    ; 计算在当前显示器上的居中位置
    centerX := mLeft + (monitorWidth / 2) - (Width / 2)
    centerY := mTop + (monitorHeight / 2) - (Height / 2)

    ; 移动窗口到当前显示器的中央
    WinMove centerX, centerY, , , "ahk_id " winID

    ; 显示在哪个显示器上居中
    ToolTipEX("窗口已在显示器 " currentMonitor " 上居中", 0.8)
}

; ==============================================================================
/*
    窗口100%显示 - 使用Win+F11快捷键
    将窗口设置为其原始/设计尺寸，不缩放，不最大化
*/
#F11:: WindowFullSize()
WindowFullSize() {
    ; 显示提示
    ToolTipEX("窗口100%显示", 0.5)

    ; 获取当前窗口ID
    winID := WinExist("A")

    ; 如果窗口已最大化，先还原
    if (WinGetMinMax("ahk_id " winID) = 1) {
        WinRestore "ahk_id " winID
        Sleep 100  ; 等待窗口还原
    }

    ; 获取窗口的位置和尺寸
    WinGetPos &winX, &winY, &winWidth, &winHeight, "ahk_id " winID

    ; 计算窗口中心点
    winCenterX := winX + winWidth / 2
    winCenterY := winY + winHeight / 2

    ; 找到窗口当前所在的显示器
    MonitorCount := MonitorGetCount()
    currentMonitor := 1

    loop MonitorCount {
        MonitorGet(A_Index, &mLeft, &mTop, &mRight, &mBottom)

        ; 检查窗口中心点是否在这个显示器内
        if (winCenterX >= mLeft && winCenterX <= mRight &&
            winCenterY >= mTop && winCenterY <= mBottom) {
            currentMonitor := A_Index
            break
        }
    }

    ; 获取当前显示器信息
    MonitorGet currentMonitor, &mLeft, &mTop, &mRight, &mBottom
    monitorWidth := mRight - mLeft
    monitorHeight := mBottom - mTop

    ; 获取窗口的客户区尺寸
    WinGetClientPos &clientX, &clientY, &clientWidth, &clientHeight, "ahk_id " winID

    ; 计算边框尺寸
    borderWidth := winWidth - clientWidth
    borderHeight := winHeight - clientHeight

    ; 获取窗口的原始/设计尺寸 - 这里我们使用一些常见的标准尺寸
    ; 可以根据不同的应用程序调整这些尺寸

    ; 常见的应用程序设计尺寸
    designSizes := Map(
        "chrome.exe", [1280, 800],       ; 浏览器
        "msedge.exe", [1280, 800],       ; Edge浏览器
        "firefox.exe", [1280, 800],      ; Firefox浏览器
        "notepad.exe", [800, 600],       ; 记事本
        "explorer.exe", [1024, 768],     ; 文件资源管理器
        "mspaint.exe", [1024, 768],      ; 画图
        "WINWORD.EXE", [1024, 768],      ; Word
        "EXCEL.EXE", [1024, 768],        ; Excel
        "POWERPNT.EXE", [1024, 768],     ; PowerPoint
        "Code.exe", [1280, 800],         ; VS Code
        "devenv.exe", [1280, 800],       ; Visual Studio
        "photoshop.exe", [1280, 800],    ; Photoshop
        "illustrator.exe", [1280, 800],  ; Illustrator
        "TOTALCMD.EXE", [1024, 768]      ; Total Commander
    )

    ; 获取当前进程名
    processName := WinGetProcessName("ahk_id " winID)

    ; 设置默认尺寸
    designWidth := 1024
    designHeight := 768

    ; 如果在预设尺寸中找到了当前进程，使用预设尺寸
    if designSizes.Has(processName) {
        designSize := designSizes[processName]
        designWidth := designSize[1]
        designHeight := designSize[2]
    }

    ; 确保窗口尺寸不超过显示器尺寸的80%
    if (designWidth > monitorWidth * 0.8)
        designWidth := monitorWidth * 0.8

    if (designHeight > monitorHeight * 0.8)
        designHeight := monitorHeight * 0.8

    ; 计算窗口尺寸（包括边框）
    newWidth := designWidth + borderWidth
    newHeight := designHeight + borderHeight

    ; 计算居中位置
    newX := mLeft + (monitorWidth - newWidth) / 2
    newY := mTop + (monitorHeight - newHeight) / 2

    ; 移动并调整窗口大小
    WinMove newX, newY, newWidth, newHeight, "ahk_id " winID
}

; ==============================================================================
/*
    关闭所有程序
*/
#Esc:: CloseAllExe()
CloseAllExe() {
    ; 获取命令处理器路径
    ComSpec := EnvGet("ComSpec")

    ; 直接执行批处理文件 - 使用完整路径并确保路径正确
    batPath := A_ScriptDir "\Apps\CloseAllPortable\CloseAllp.bat"
    if FileExist(batPath) {
        ; 显示正在执行的提示
        ToolTipEX("正在关闭程序...", 1)

        ; 使用管理员权限运行批处理文件
        RunWait "*RunAs " ComSpec " /c " batPath, A_ScriptDir
    } else {
        MsgBox "批处理文件不存在: " batPath
        return
    }
    Sleep 200

    ; 获取环境变量
    SoftDir := EnvGet("SoftDir")

    ; 运行无UI的CloseAll64程序
    closeAllPath := A_ScriptDir "\Apps\CloseAllPortable\App\CloseAll\64\CloseAll64.exe"
    if FileExist(closeAllPath) {
        Run closeAllPath " /NOUI"
    } else {
        MsgBox "CloseAll64.exe 不存在: " closeAllPath
    }

    ; 检查内存优化程序是否运行
    if ProcessWait("memreduct.exe", 1) {
        ; 如果已运行，发送Ctrl+F2快捷键
        Send "^{F2}"
    } else {
        ; 如果未运行，启动程序并发送Ctrl+F2快捷键
        SoftDir := EnvGet("SoftDir")
        if SoftDir {
            memReductPath := SoftDir "\MemReduct\memreduct.exe"
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