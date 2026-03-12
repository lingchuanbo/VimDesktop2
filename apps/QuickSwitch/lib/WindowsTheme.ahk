; WindowsTheme - 内存优化版本
; 优化策略：
; 1. 延迟初始化 - 只在需要时加载资源
; 2. 缓存优化 - 避免重复的DLL调用
; 3. 静态资源复用 - 减少重复创建
; 4. 条件优化 - 减少不必要的操作

class WindowsTheme {
    ; 延迟初始化的静态变量
    static _uxtheme := 0
    static _SetPreferredAppMode := 0
    static _FlushMenuThemes := 0
    static _isInitialized := false
    static _currentMode := ""
    static _darkColors := 0
    static _textBackgroundBrush := 0
    
    ; 预定义常量 - 避免重复创建Map
    static PreferredAppMode := {Default: 0, AllowDark: 1, ForceDark: 2, ForceLight: 3, Max: 4}
    
    ; 延迟初始化
    static _Init() {
        if (this._isInitialized)
            return
            
        this._uxtheme := DllCall("GetModuleHandle", "str", "uxtheme", "ptr")
        this._SetPreferredAppMode := DllCall("GetProcAddress", "ptr", this._uxtheme, "ptr", 135, "ptr")
        this._FlushMenuThemes := DllCall("GetProcAddress", "ptr", this._uxtheme, "ptr", 136, "ptr")
        
        ; 初始化暗色主题颜色
        this._darkColors := {Background: 0x202020, Controls: 0x404040, Font: 0xE0E0E0}
        this._textBackgroundBrush := DllCall("gdi32\CreateSolidBrush", "UInt", this._darkColors.Background, "Ptr")
        
        this._isInitialized := true
    }

    static SetAppMode(DarkMode := True) {
        this._Init()
        
        ; 避免重复设置相同模式
        newMode := ""
        modeValue := 0
        
        switch DarkMode {
            case True, "dark":
                newMode := "ForceDark"
                modeValue := this.PreferredAppMode.ForceDark
            case False, "light":
                newMode := "ForceLight"
                modeValue := this.PreferredAppMode.ForceLight
            case "Default", "system":
                newMode := "Default"
                modeValue := this.PreferredAppMode.Default
            default:
                newMode := "Default"
                modeValue := this.PreferredAppMode.Default
        }
        
        ; 只在模式真正改变时才执行DLL调用
        if (this._currentMode != newMode) {
            DllCall(this._SetPreferredAppMode, "Int", modeValue)
            DllCall(this._FlushMenuThemes)
            this._currentMode := newMode
        }
    }

    static SetWindowAttribute(GuiObj, DarkMode := True) {
        this._Init()
        
        ; 缓存版本检查结果
        static osVersionChecked := false
        static supportsDarkMode := false
        static dwmAttribute := 0
        
        if (!osVersionChecked) {
            if (VerCompare(A_OSVersion, "10.0.17763") >= 0) {
                supportsDarkMode := true
                dwmAttribute := (VerCompare(A_OSVersion, "10.0.18985") >= 0) ? 20 : 19
            }
            osVersionChecked := true
        }
        
        if (!supportsDarkMode)
            return
            
        switch DarkMode {
            case True:
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", GuiObj.hWnd, "Int", dwmAttribute, "Int*", True, "Int", 4)
                DllCall(this._SetPreferredAppMode, "Int", this.PreferredAppMode.ForceDark)
                DllCall(this._FlushMenuThemes)
                GuiObj.BackColor := this._darkColors.Background
            default:
                DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", GuiObj.hWnd, "Int", dwmAttribute, "Int*", False, "Int", 4)
                DllCall(this._SetPreferredAppMode, "Int", this.PreferredAppMode.Default)
                DllCall(this._FlushMenuThemes)
                GuiObj.BackColor := "Default"
        }
    }

    static SetWindowTheme(GuiObj, DarkMode := True) {
        this._Init()
        
        ; 缓存常量和函数指针
        static constants := {
            GWL_WNDPROC: -4,
            GWL_STYLE: -16,
            ES_MULTILINE: 0x0004,
            LVM_GETTEXTCOLOR: 0x1023,
            LVM_SETTEXTCOLOR: 0x1024,
            LVM_GETTEXTBKCOLOR: 0x1025,
            LVM_SETTEXTBKCOLOR: 0x1026,
            LVM_GETBKCOLOR: 0x1000,
            LVM_SETBKCOLOR: 0x1001,
            LVM_GETHEADER: 0x101F
        }
        
        static windowLongFunc := A_PtrSize = 8 ? "GetWindowLongPtr" : "GetWindowLong"
        static setWindowLongFunc := A_PtrSize = 8 ? "SetWindowLongPtr" : "SetWindowLong"
        static isInitialized := false
        static lvInitialized := false
        static lvColors := {text: 0, textBk: 0, bk: 0}
        
        ; 预计算主题字符串
        themes := DarkMode ? 
            {Explorer: "DarkMode_Explorer", CFD: "DarkMode_CFD", ItemsView: "DarkMode_ItemsView"} :
            {Explorer: "Explorer", CFD: "CFD", ItemsView: "ItemsView"}

        ; 批量处理控件
        for hWnd, GuiCtrlObj in GuiObj {
            this._SetControlTheme(GuiCtrlObj, themes, constants, windowLongFunc, DarkMode, lvInitialized, lvColors)
        }

        ; 初始化窗口过程回调（只执行一次）
        if (!isInitialized) {
            global WindowProcNew := CallbackCreate(WindowProc)
            global WindowProcOld := DllCall("user32\" setWindowLongFunc, "Ptr", GuiObj.Hwnd, "Int", constants.GWL_WNDPROC, "Ptr", WindowProcNew, "Ptr")
            global IsDarkMode := DarkMode
            isInitialized := true
        } else {
            global IsDarkMode := DarkMode
        }
    }
    
    ; 优化的控件主题设置
    static _SetControlTheme(GuiCtrlObj, themes, constants, windowLongFunc, DarkMode, &lvInitialized, &lvColors) {
        switch GuiCtrlObj.Type {
            case "Button", "CheckBox", "ListBox", "UpDown":
                DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", themes.Explorer, "Ptr", 0)
                
            case "ComboBox", "DDL":
                DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", themes.CFD, "Ptr", 0)
                
            case "Edit":
                theme := (DllCall("user32\" windowLongFunc, "Ptr", GuiCtrlObj.hWnd, "Int", constants.GWL_STYLE) & constants.ES_MULTILINE) ?
                    themes.Explorer : themes.CFD
                DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", theme, "Ptr", 0)
                
            case "ListView":
                this._SetListViewTheme(GuiCtrlObj, themes, constants, DarkMode, lvInitialized, lvColors)
        }
    }
    
    ; 优化的ListView主题设置
    static _SetListViewTheme(GuiCtrlObj, themes, constants, DarkMode, &lvInitialized, &lvColors) {
        ; 只在第一次初始化时获取原始颜色
        if (!lvInitialized) {
            lvColors.text := SendMessage(constants.LVM_GETTEXTCOLOR, 0, 0, GuiCtrlObj.hWnd)
            lvColors.textBk := SendMessage(constants.LVM_GETTEXTBKCOLOR, 0, 0, GuiCtrlObj.hWnd)
            lvColors.bk := SendMessage(constants.LVM_GETBKCOLOR, 0, 0, GuiCtrlObj.hWnd)
            lvInitialized := true
        }
        
        GuiCtrlObj.Opt("-Redraw")
        
        if (DarkMode) {
            SendMessage(constants.LVM_SETTEXTCOLOR, 0, this._darkColors.Font, GuiCtrlObj.hWnd)
            SendMessage(constants.LVM_SETTEXTBKCOLOR, 0, this._darkColors.Background, GuiCtrlObj.hWnd)
            SendMessage(constants.LVM_SETBKCOLOR, 0, this._darkColors.Background, GuiCtrlObj.hWnd)
        } else {
            SendMessage(constants.LVM_SETTEXTCOLOR, 0, lvColors.text, GuiCtrlObj.hWnd)
            SendMessage(constants.LVM_SETTEXTBKCOLOR, 0, lvColors.textBk, GuiCtrlObj.hWnd)
            SendMessage(constants.LVM_SETBKCOLOR, 0, lvColors.bk, GuiCtrlObj.hWnd)
        }
        
        DllCall("uxtheme\SetWindowTheme", "Ptr", GuiCtrlObj.hWnd, "Str", themes.Explorer, "Ptr", 0)
        
        ; 设置Header主题
        lvHeader := SendMessage(constants.LVM_GETHEADER, 0, 0, GuiCtrlObj.hWnd)
        DllCall("uxtheme\SetWindowTheme", "Ptr", lvHeader, "Str", themes.ItemsView, "Ptr", 0)
        
        GuiCtrlObj.Opt("+Redraw")
    }

    static ToggleTheme(GuiCtrlObj, *) {
        isDark := (GuiCtrlObj.Text = "DarkMode")
        this.SetWindowAttribute(GuiCtrlObj, isDark)
        this.SetWindowTheme(GuiCtrlObj, isDark)
    }
    
    ; 清理资源
    static Cleanup() {
        if (this._textBackgroundBrush) {
            DllCall("gdi32\DeleteObject", "Ptr", this._textBackgroundBrush)
            this._textBackgroundBrush := 0
        }
    }
}

; 优化的窗口过程
WindowProc(hwnd, uMsg, wParam, lParam) {
    critical
    
    ; 缓存常量
    static constants := {
        WM_CTLCOLOREDIT: 0x0133,
        WM_CTLCOLORLISTBOX: 0x0134,
        WM_CTLCOLORBTN: 0x0135,
        WM_CTLCOLORSTATIC: 0x0138,
        DC_BRUSH: 18
    }
    
    if (!IsSet(IsDarkMode) || !IsDarkMode)
        return DllCall("user32\CallWindowProc", "Ptr", WindowProcOld, "Ptr", hwnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam)
    
    ; 获取暗色主题颜色
    static darkColors := WindowsTheme._darkColors
    static textBrush := WindowsTheme._textBackgroundBrush
    
    switch uMsg {
        case constants.WM_CTLCOLOREDIT, constants.WM_CTLCOLORLISTBOX:
            DllCall("gdi32\SetTextColor", "Ptr", wParam, "UInt", darkColors.Font)
            DllCall("gdi32\SetBkColor", "Ptr", wParam, "UInt", darkColors.Controls)
            DllCall("gdi32\SetDCBrushColor", "Ptr", wParam, "UInt", darkColors.Controls, "UInt")
            return DllCall("gdi32\GetStockObject", "Int", constants.DC_BRUSH, "Ptr")
            
        case constants.WM_CTLCOLORBTN:
            DllCall("gdi32\SetDCBrushColor", "Ptr", wParam, "UInt", darkColors.Background, "UInt")
            return DllCall("gdi32\GetStockObject", "Int", constants.DC_BRUSH, "Ptr")
            
        case constants.WM_CTLCOLORSTATIC:
            DllCall("gdi32\SetTextColor", "Ptr", wParam, "UInt", darkColors.Font)
            DllCall("gdi32\SetBkColor", "Ptr", wParam, "UInt", darkColors.Background)
            return textBrush
    }
    
    return DllCall("user32\CallWindowProc", "Ptr", WindowProcOld, "Ptr", hwnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam)
}

; 程序退出时清理资源
OnExit((*) => WindowsTheme.Cleanup())