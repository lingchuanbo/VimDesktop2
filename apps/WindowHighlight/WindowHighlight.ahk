; ===============================================
; 窗口边框高亮显示工具
; By.BoBO
; 版本:v1.1
; 时间:20250807
; ===============================================
#SingleInstance Force
#Requires AutoHotkey v2.0

; 全局变量
BorderGui := ""
IsEnabled := true
BorderColor := "12ED93"
BorderWidth := 2
Opacity := 255
UpdateInterval := 50
V1List := ""
ExcludeList := ""

; 初始化
LoadConfig()
CreateBorder()
SetTimer(CheckWindow, UpdateInterval)
CreateMenu()
A_IconTip := "窗口高亮工具 - 已启用"

; 加载配置
LoadConfig() {
    global
    ini := A_ScriptDir . "\WindowHighlight.ini"
    if !FileExist(ini)
        return

    ; 读取基本设置
    BorderColor := IniRead(ini, "Settings", "BorderColor", "12ED93")
    if (SubStr(BorderColor, 1, 2) = "0x") {
        BorderColor := SubStr(BorderColor, 3)
    }
    BorderWidth := Integer(IniRead(ini, "Settings", "BorderWidth", "2"))
    Opacity := Integer(IniRead(ini, "Settings", "Opacity", "255"))
    UpdateInterval := Integer(IniRead(ini, "Settings", "UpdateInterval", "50"))
    IsEnabled := (IniRead(ini, "Settings", "Enabled", "1") = "1")

    ; 读取V1程序列表
    V1List := ""
    if (IniRead(ini, "V1Programs", "Photoshop.exe", "1") = "1") {
        V1List .= "|Photoshop.exe"
    }
    if (IniRead(ini, "V1Programs", "Weixin.exe", "1") = "1") {
        V1List .= "|Weixin.exe"
    }
    if (IniRead(ini, "V1Programs", "WeChat.exe", "1") = "1") {
        V1List .= "|WeChat.exe"
    }
    if (IniRead(ini, "V1Programs", "TIM.exe", "0") = "1") {
        V1List .= "|TIM.exe"
    }

    ; 读取排除程序列表
    ExcludeList := ""
    if (IniRead(ini, "ExcludePrograms", "explorer.exe", "0") = "1") {
        ExcludeList .= "|explorer.exe"
    }
    if (IniRead(ini, "ExcludePrograms", "taskmgr.exe", "0") = "1") {
        ExcludeList .= "|taskmgr.exe"
    }
    if (IniRead(ini, "ExcludePrograms", "cmd.exe", "1") = "1") {
        ExcludeList .= "|cmd.exe"
    }
    if (IniRead(ini, "ExcludePrograms", "powershell.exe", "1") = "1") {
        ExcludeList .= "|powershell.exe"
    }
    if (IniRead(ini, "ExcludePrograms", "conhost.exe", "1") = "1") {
        ExcludeList .= "|conhost.exe"
    }
    if (IniRead(ini, "ExcludePrograms", "TIM.exe", "1") = "1") {
        ExcludeList .= "|TIM.exe"
    }
}

; 创建边框
CreateBorder() {
    global BorderGui, BorderColor, Opacity

    try {
        if (BorderGui && BorderGui.Hwnd) {
            BorderGui.Destroy()
        }
    } catch {
    }

    BorderGui := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20", "WindowBorder")
    BorderGui.Add("Text", "w1 h1")
    BorderGui.BackColor := BorderColor
    WinSetTransparent(Opacity, BorderGui.Hwnd)
}

; 检查窗口
CheckWindow() {
    global IsEnabled, BorderGui, BorderWidth, ExcludeList, V1List

    if !IsEnabled {
        try {
            if (BorderGui && BorderGui.Hwnd) {
                BorderGui.Hide()
            }
        } catch {
        }
        return
    }

    try {
        win := WinGetID("A")
        if !win || !WinExist(win) {
            BorderGui.Hide()
            return
        }

        ; 获取窗口信息
        cls := WinGetClass(win)
        proc := WinGetProcessName(win)

        ; 基本过滤
        if (cls = "Shell_TrayWnd" || cls = "Progman" || cls = "WorkerW") {
            BorderGui.Hide()
            return
        }

        ; 检查排除列表
        if (ExcludeList != "" && InStr(ExcludeList, proc) > 0) {
            BorderGui.Hide()
            return
        }

        ; 显示边框 - 根据程序类型选择V1或V2模式
        WinGetPos(&x, &y, &w, &h, win)
        if (V1List != "" && InStr(V1List, proc) > 0) {
            ShowBorderV1(x, y, w, h)  ; V1模式
        } else {
            ShowBorderV2(x, y, w, h)  ; V2模式（默认）
        }

    } catch {
        try {
            BorderGui.Hide()
        } catch {
        }
    }
}

; V1模式显示边框（Region方法）
ShowBorderV1(x, y, w, h) {
    global BorderGui, BorderWidth

    try {
        if (!BorderGui || !BorderGui.Hwnd) {
            CreateBorder()
        }

        ; 计算边框位置
        ow := w + BorderWidth * 2
        oh := h + BorderWidth * 2
        ox := x - BorderWidth
        oy := y - BorderWidth

        ; 显示边框
        BorderGui.Show("NA x" . ox . " y" . oy . " w" . ow . " h" . oh)

        ; 创建边框区域（外框减去内框）
        hOuter := DllCall("CreateRectRgn", "int", 0, "int", 0, "int", ow, "int", oh, "ptr")
        hInner := DllCall("CreateRectRgn", "int", BorderWidth, "int", BorderWidth, "int", ow - BorderWidth, "int", oh -
            BorderWidth, "ptr")
        hBorder := DllCall("CreateRectRgn", "int", 0, "int", 0, "int", 0, "int", 0, "ptr")
        DllCall("CombineRgn", "ptr", hBorder, "ptr", hOuter, "ptr", hInner, "int", 4) ; RGN_DIFF
        DllCall("SetWindowRgn", "ptr", BorderGui.Hwnd, "ptr", hBorder, "int", 1)

        ; 清理资源
        DllCall("DeleteObject", "ptr", hOuter)
        DllCall("DeleteObject", "ptr", hInner)

    } catch {
        CreateBorder()
    }
}

; V2模式显示边框（默认模式，使用精确窗口位置）
ShowBorderV2(x, y, w, h) {
    global BorderGui, BorderWidth

    try {
        if (!BorderGui || !BorderGui.Hwnd) {
            CreateBorder()
        }

        ; 尝试获取精确窗口位置
        win := WinGetID("A")
        if (win) {
            rect := GetExactRect(win)
            if (rect.w > 0) {
                x := rect.x, y := rect.y, w := rect.w, h := rect.h
            }
        }

        ; 计算边框位置
        ow := w + BorderWidth * 2
        oh := h + BorderWidth * 2
        ox := x - BorderWidth
        oy := y - BorderWidth

        ; 显示边框
        BorderGui.Show("NA x" . ox . " y" . oy . " w" . ow . " h" . oh)

        ; 创建边框区域（外框减去内框）
        hOuter := DllCall("CreateRectRgn", "int", 0, "int", 0, "int", ow, "int", oh, "ptr")
        hInner := DllCall("CreateRectRgn", "int", BorderWidth, "int", BorderWidth, "int", ow - BorderWidth, "int", oh -
            BorderWidth, "ptr")
        hBorder := DllCall("CreateRectRgn", "int", 0, "int", 0, "int", 0, "int", 0, "ptr")
        DllCall("CombineRgn", "ptr", hBorder, "ptr", hOuter, "ptr", hInner, "int", 4) ; RGN_DIFF
        DllCall("SetWindowRgn", "ptr", BorderGui.Hwnd, "ptr", hBorder, "int", 1)

        ; 清理资源
        DllCall("DeleteObject", "ptr", hOuter)
        DllCall("DeleteObject", "ptr", hInner)

    } catch {
        CreateBorder()
    }
}

; 获取精确窗口位置（V2模式专用）
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

; 托盘菜单
CreateMenu() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("开关高亮", Toggle)
    A_TrayMenu.Add("退出", (*) => ExitApp())
    A_TrayMenu.Default := "开关高亮"
}

; 切换功能
Toggle(*) {
    global IsEnabled
    IsEnabled := !IsEnabled
    if IsEnabled {
        A_IconTip := "窗口高亮工具 - 已启用"
    } else {
        A_IconTip := "窗口高亮工具 - 已禁用"
        try {
            if (BorderGui && BorderGui.Hwnd) {
                BorderGui.Hide()
            }
        } catch {
        }
    }
}

; 热键
F12:: Toggle()