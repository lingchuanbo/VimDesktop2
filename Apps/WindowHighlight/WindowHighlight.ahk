; ===============================================
; 窗口边框高亮显示工具
; By.BoBO
; 版本:v1.0
; 时间:20250807
; ===============================================

#SingleInstance Force
#Requires AutoHotkey v2.0

; === 优化后的全局变量（最小化） ===
; 单个边框GUI（更稳定）
BorderGui := ""
; 核心状态变量
CurrentWin := "", LastPos := ""
; 配置变量（直接使用，避免Map开销）
BorderColor := "FF0000", BorderWidth := 3, Opacity := 255
IsEnabled := true, UpdateInterval := 20
CompatMode := true, ShowDialog := true
; V1程序列表（字符串，节省内存）
V1List := "Photoshop.exe|Weixin.exe|WeChat.exe"
; 排除程序列表（完全不显示高亮）
ExcludeList := ""

; === 初始化 ===
Init()

Init() {
    LoadConfig()
    CreateBorders()
    SetTimer(CheckWindow, UpdateInterval)
    CreateMenu()
    A_IconTip := "窗口高亮工具"
}

; === 配置加载（简化） ===
LoadConfig() {
    global
    ini := A_ScriptDir . "\WindowHighlight.ini"
    if !FileExist(ini)
        return

    BorderColor := IniRead(ini, "Settings", "BorderColor", "0xFF0000")
    BorderWidth := Integer(IniRead(ini, "Settings", "BorderWidth", "3"))
    Opacity := Integer(IniRead(ini, "Settings", "Opacity", "255"))
    UpdateInterval := Integer(IniRead(ini, "Settings", "UpdateInterval", "20"))
    IsEnabled := (IniRead(ini, "Settings", "Enabled", "1") = "1")
    CompatMode := (IniRead(ini, "Settings", "CompatibilityMode", "1") = "1")
    ShowDialog := (IniRead(ini, "Settings", "ShowDialogs", "1") = "1")

    ; 读取V1程序列表
    v1 := IniRead(ini, "V1Programs", "Photoshop.exe", "1")
    if (v1 = "1") {
        V1List .= "|Photoshop.exe"
    }
    v1 := IniRead(ini, "V1Programs", "Weixin.exe", "1")
    if (v1 = "1") {
        V1List .= "|Weixin.exe"
    }
    v1 := IniRead(ini, "V1Programs", "WeChat.exe", "1")
    if (v1 = "1") {
        V1List .= "|WeChat.exe"
    }
    v1 := IniRead(ini, "V1Programs", "TIM.exe", "0")
    if (v1 = "0") {
        V1List .= "|TIM.exe"
    }
    ; 读取排除程序列表
    ExcludeList := ""
    exclude := IniRead(ini, "ExcludePrograms", "explorer.exe", "0")
    if (exclude = "1") {
        ExcludeList .= "|explorer.exe"
    }
    exclude := IniRead(ini, "ExcludePrograms", "taskmgr.exe", "1")
    if (exclude = "1") {
        ExcludeList .= "|taskmgr.exe"
    }
    exclude := IniRead(ini, "ExcludePrograms", "cmd.exe", "1")
    if (exclude = "1") {
        ExcludeList .= "|cmd.exe"
    }
    exclude := IniRead(ini, "ExcludePrograms", "powershell.exe", "1")
    if (exclude = "1") {
        ExcludeList .= "|powershell.exe"
    }
    exclude := IniRead(ini, "ExcludePrograms", "conhost.exe", "1")
    if (exclude = "1") {
        ExcludeList .= "|conhost.exe"
    }
    exclude := IniRead(ini, "ExcludePrograms", "TIM.exe", "1")
    if (exclude = "1") {
        ExcludeList .= "|TIM.exe"
    }
}

; === 创建边框GUI（优化） ===
CreateBorders() {
    global BorderGui, BorderColor, Opacity
    
    ; 先清理旧的边框
    try {
        if (BorderGui && BorderGui.Hwnd) {
            BorderGui.Destroy()
        }
    } catch {
        ; 忽略清理错误
    }
    
    ; 创建单个边框GUI
    BorderGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 +LastFound", "WindowBorder")
    BorderGui.Add("Text", "w1 h1")
    color := SubStr(BorderColor, 3)
    BorderGui.BackColor := color
    WinSetTransparent(Opacity, BorderGui.Hwnd)
}


; === 窗口检查（优化） ===
CheckWindow() {
    global CurrentWin, LastPos, IsEnabled

    if !IsEnabled
        return

    try {
        win := WinGetID("A")
        if !win || !WinExist(win)
            return Hide()

        WinGetPos(&x, &y, &w, &h, win)
        pos := x . "," . y . "," . w . "," . h

        ; 检查是否应该高亮
        if ShouldHighlight(win) {
            ; 每次都强制更新边框，确保不会丢失
            if UseV1Mode(win)
                ShowV1(x, y, w, h)
            else
                ShowV2(x, y, w, h)
            CurrentWin := win
            LastPos := pos
        } else {
            Hide()
            CurrentWin := ""
            LastPos := ""
        }
    } catch {
        Hide()
    }
}

; === 窗口过滤（简化） ===
ShouldHighlight(win) {
    global CompatMode, ShowDialog, ExcludeList
    try {
        cls := WinGetClass(win)
        proc := WinGetProcessName(win)

        ; 检查排除列表（优先级最高）
        if (ExcludeList != "" && InStr(ExcludeList, proc) > 0)
            return false

        ; 排除桌面
        if (proc = "Explorer.exe" && cls ~= "(Progman|WorkerW)")
            return false

        ; 兼容模式
        if CompatMode {
            if (cls ~= "^(Shell_TrayWnd|Button|Static)$")
                return false
            if (cls = "#32770")
                return ShowDialog
            return true
        }

        return (cls != "Shell_TrayWnd")
    }
    return true
}

; === V1模式检查 ===
UseV1Mode(win) {
    global V1List
    try {
        return InStr(V1List, WinGetProcessName(win)) > 0
    }
    return false
}

; === V1模式显示（Region方法） ===
ShowV1(x, y, w, h) {
    global Borders, BorderWidth

    ; 隐藏其他边框，只使用第一个
    loop 4 {
        if (A_Index > 1) {
            Borders[A_Index].Hide()
        }
    }

    ; 显示主边框
    g := Borders[1]
    ow := w + BorderWidth * 2
    oh := h + BorderWidth * 2
    ox := x - BorderWidth
    oy := y - BorderWidth

    g.Show("x" . ox . " y" . oy . " w" . ow . " h" . oh . " NoActivate")

    ; 创建边框区域
    hOuter := DllCall("CreateRectRgn", "int", 0, "int", 0, "int", ow, "int", oh, "ptr")
    hInner := DllCall("CreateRectRgn", "int", BorderWidth, "int", BorderWidth, "int", ow - BorderWidth, "int", oh -
        BorderWidth, "ptr")
    hBorder := DllCall("CreateRectRgn", "int", 0, "int", 0, "int", 0, "int", 0, "ptr")
    DllCall("CombineRgn", "ptr", hBorder, "ptr", hOuter, "ptr", hInner, "int", 4)
    DllCall("SetWindowRgn", "ptr", g.Hwnd, "ptr", hBorder, "int", 1)
    DllCall("DeleteObject", "ptr", hOuter)
    DllCall("DeleteObject", "ptr", hInner)
}

; === V2模式显示（四边框） ===
ShowV2(x, y, w, h) {
    global BorderGui, BorderWidth, BorderColor, Opacity

    ; 获取精确位置
    rect := GetExactRect(CurrentWin)
    if (rect.w > 0) {
        x := rect.x, y := rect.y, w := rect.w, h := rect.h
    }

    ; 使用单个GUI显示边框
    try {
        if (!BorderGui || !BorderGui.Hwnd) {
            CreateBorders()
        }
        
        ; 设置GUI属性
        color := SubStr(BorderColor, 3)
        BorderGui.BackColor := color
        WinSetTransparent(Opacity, BorderGui.Hwnd)
        WinSetAlwaysOnTop(1, BorderGui.Hwnd)
        
        ; 计算边框区域
        ow := w + BorderWidth * 2
        oh := h + BorderWidth * 2
        ox := x - BorderWidth
        oy := y - BorderWidth
        
        ; 显示GUI
        BorderGui.Show("NA x" . ox . " y" . oy . " w" . ow . " h" . oh)
        
        ; 创建边框区域（外框减去内框）
        hOuter := DllCall("CreateRectRgn", "int", 0, "int", 0, "int", ow, "int", oh, "ptr")
        hInner := DllCall("CreateRectRgn", "int", BorderWidth, "int", BorderWidth, "int", ow - BorderWidth, "int", oh - BorderWidth, "ptr")
        hBorder := DllCall("CreateRectRgn", "int", 0, "int", 0, "int", 0, "int", 0, "ptr")
        DllCall("CombineRgn", "ptr", hBorder, "ptr", hOuter, "ptr", hInner, "int", 4) ; RGN_DIFF
        DllCall("SetWindowRgn", "ptr", BorderGui.Hwnd, "ptr", hBorder, "int", 1)
        
        ; 清理资源
        DllCall("DeleteObject", "ptr", hOuter)
        DllCall("DeleteObject", "ptr", hInner)
        
    } catch {
        ; 如果显示失败，重新创建边框
        CreateBorders()
        ShowV2(x, y, w, h)
    }
}

; === 获取精确窗口位置 ===
GetExactRect(win) {
    static DWMWA_EXTENDED_FRAME_BOUNDS := 9
    rect := Buffer(16)
    if DllCall("dwmapi\DwmGetWindowAttribute", "ptr", win, "int", DWMWA_EXTENDED_FRAME_BOUNDS, "ptr", rect, "int", 16) =
    0 {
        return {
            x: NumGet(rect, 0, "int"),
            y: NumGet(rect, 4, "int"),
            w: NumGet(rect, 8, "int") - NumGet(rect, 0, "int"),
            h: NumGet(rect, 12, "int") - NumGet(rect, 4, "int")
        }
    }
    WinGetPos(&x, &y, &w, &h, win)
    return { x: x, y: y, w: w, h: h }
}

; === 隐藏边框 ===
Hide() {
    global BorderGui, CurrentWin
    CurrentWin := ""
    try {
        if (BorderGui && BorderGui.Hwnd) {
            BorderGui.Hide()
        }
    } catch {
        ; 忽略隐藏错误
    }
}

; === 托盘菜单（简化） ===
CreateMenu() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("开关高亮", Toggle)
    A_TrayMenu.Add("重新加载", Reload)
    A_TrayMenu.Add()
    A_TrayMenu.Add("退出", (*) => ExitApp())
    A_TrayMenu.Default := "开关高亮"
}

; === 功能函数 ===
Toggle(*) {
    global IsEnabled
    IsEnabled := !IsEnabled
    if !IsEnabled Hide()
        A_IconTip := "窗口高亮工具" . (IsEnabled ? "" : " (已禁用)")
}

Reload(*) {
    global BorderGui, CurrentWin
    try {
        if (BorderGui && BorderGui.Hwnd) {
            BorderGui.Destroy()
        }
    } catch {
        ; 忽略销毁错误
    }
    BorderGui := ""
    LoadConfig()
    CreateBorders()
    SetTimer(CheckWindow, UpdateInterval)
    CurrentWin := ""
}

; === 热键 ===
F12:: Toggle