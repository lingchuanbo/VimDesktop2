; ======================================================================================================================
; ToolTipOptions        -  additional options for ToolTips (Memory Optimized)
; ======================================================================================================================
class ToolTipOptions {
    ; 延迟初始化 - 只在需要时创建窗口
    static HTT := 0
    static SWP := 0
    static OWP := 0
    static ToolTips := 0  ; 延迟创建Map
    ; 使用更紧凑的存储
    static BkgColor := 0
    static TxtColor := 0
    static Icon := 0
    static Title := 0
    static HFONT := 0
    static Margins := 0
    static Border := 0
    ; -------------------------------------------------------------------------------------------------------------------
    static Call(*) => False ; do not create instances
    ; -------------------------------------------------------------------------------------------------------------------
    ; Init()          -  Initialize some class variables and subclass the tooltip control.
    ; -------------------------------------------------------------------------------------------------------------------
    static Init() {
        if (This.OWP = 0) {
            ; 延迟创建窗口和回调
            if (!This.HTT) {
                This.HTT := DllCall("User32.dll\CreateWindowEx", "UInt", 8, "Str", "tooltips_class32", "Ptr", 0, "UInt",
                    3
                    , "Int", 0, "Int", 0, "Int", 0, "Int", 0, "Ptr", A_ScriptHwnd, "Ptr", 0, "Ptr", 0, "Ptr", 0)
            }
            if (!This.SWP) {
                This.SWP := CallbackCreate(ObjBindMethod(ToolTipOptions, "_WNDPROC_"), , 4)
            }
            if (!This.ToolTips) {
                This.ToolTips := Map()
            }

            ; 重置状态变量为空字符串而不是保持为0
            This.BkgColor := ""
            This.TxtColor := ""
            This.Icon := ""
            This.Title := ""
            This.Margins := ""

            if (A_PtrSize = 8)
                This.OWP := DllCall("User32.dll\SetClassLongPtr", "Ptr", This.HTT, "Int", -24, "Ptr", This.SWP, "UPtr")
            else
                This.OWP := DllCall("User32.dll\SetClassLongW", "Ptr", This.HTT, "Int", -24, "Int", This.SWP, "UInt")
            OnExit(ToolTipOptions._EXIT_, -1)
            return This.OWP
        }
        else
            return False
    }
    ; -------------------------------------------------------------------------------------------------------------------
    ;  Reset()        -  Close all existing tooltips, delete the font object, and remove the tooltip's subclass.
    ; -------------------------------------------------------------------------------------------------------------------
    static Reset() {
        if (This.OWP != 0) {
            ; 优化清理过程 - 避免不必要的Clone操作
            if (This.ToolTips) {
                for HWND In This.ToolTips
                    DllCall("DestroyWindow", "Ptr", HWND)
                This.ToolTips.Clear()
                This.ToolTips := 0  ; 释放Map对象
            }

            if This.HFONT {
                DllCall("DeleteObject", "Ptr", This.HFONT)
                This.HFONT := 0
            }

            ; 清理回调
            if This.SWP {
                CallbackFree(This.SWP)
                This.SWP := 0
            }

            if (A_PtrSize = 8)
                DllCall("User32.dll\SetClassLongPtrW", "Ptr", This.HTT, "Int", -24, "Ptr", This.OWP, "UPtr")
            else
                DllCall("User32.dll\SetClassLongW", "Ptr", This.HTT, "Int", -24, "Int", This.OWP, "UInt")

            ; 销毁窗口
            if This.HTT {
                DllCall("DestroyWindow", "Ptr", This.HTT)
                This.HTT := 0
            }

            This.OWP := 0
            return True
        }
        return False
    }
    ; -------------------------------------------------------------------------------------------------------------------
    ; SetColors()     -  Set or remove the text and/or the background color for the tooltip.
    ; -------------------------------------------------------------------------------------------------------------------
    static SetColors(BkgColor := "", TxtColor := "") {
        This.BkgColor := BkgColor = "" ? "" : This._BGR(BkgColor)
        This.TxtColor := TxtColor = "" ? "" : This._BGR(TxtColor)
    }

    ; 内部BGR转换函数 - 优化内存使用
    static _BGR(Color, Default := "") {
        ; 预定义常用颜色的BGR值，减少对象创建
        switch StrUpper(Color) {
            case "WHITE": return 0xFFFFFF
            case "BLACK": return 0x000000
            case "RED": return 0x0000FF
            case "GREEN": return 0x008000
            case "BLUE": return 0xFF0000
            case "YELLOW": return 0x00FFFF
            case "GRAY": return 0x808080
            case "SILVER": return 0xC0C0C0
        }

        if (Color Is String) && IsXDigit(Color) && (StrLen(Color) = 6)
            Color := Integer("0x" . Color)
        if IsInteger(Color)
            return ((Color >> 16) & 0xFF) | (Color & 0x00FF00) | ((Color & 0xFF) << 16)
        return Default
    }
    ; -------------------------------------------------------------------------------------------------------------------
    ; SetFont()       -  Set or remove the font used by the tooltip (Memory Optimized)
    ; -------------------------------------------------------------------------------------------------------------------
    static SetFont(FntOpts := "", FntName := "") {
        static HDEF := 0, LOGFONTW := 0, LOGPIXELSY := 0

        if (FntOpts = "") && (FntName = "") {
            if This.HFONT {
                DllCall("DeleteObject", "Ptr", This.HFONT)
                This.HFONT := 0
            }
            return
        }

        ; 延迟初始化
        if (!HDEF) {
            HDEF := DllCall("GetStockObject", "Int", 17, "UPtr")
            HDC := DllCall("GetDC", "Ptr", 0, "UPtr")
            LOGPIXELSY := DllCall("GetDeviceCaps", "Ptr", HDC, "Int", 90, "Int")
            DllCall("ReleaseDC", "Ptr", 0, "Ptr", HDC)
        }

        if (!LOGFONTW) {
            LOGFONTW := Buffer(92, 0)
            DllCall("GetObject", "Ptr", HDEF, "Int", 92, "Ptr", LOGFONTW)
        }

        ; 优化字体选项处理
        if (FntOpts != "") {
            opts := StrSplit(RegExReplace(Trim(FntOpts), "\s+", " "), " ")
            loop opts.Length {
                opt := StrUpper(opts[A_Index])
                switch opt {
                    case "BOLD": NumPut("Int", 700, LOGFONTW, 16)
                    case "ITALIC": NumPut("Char", 1, LOGFONTW, 20)
                    case "UNDERLINE": NumPut("Char", 1, LOGFONTW, 21)
                    case "STRIKE": NumPut("Char", 1, LOGFONTW, 22)
                    case "NORM": NumPut("Int", 400, "Char", 0, "Char", 0, "Char", 0, LOGFONTW, 16)
                    Default:
                        firstChar := SubStr(opt, 1, 1)
                        value := SubStr(opt, 2)
                        switch firstChar {
                            case "C": continue
                            case "Q":
                                if IsInteger(value) && (value >= 0) && (value <= 5)
                                    NumPut("Char", Integer(value), LOGFONTW, 26)
                            case "S":
                                if IsNumber(value) && (value >= 1) && (value <= 255)
                                    NumPut("Int", -Round(Integer(value + 0.5) * LOGPIXELSY / 72), LOGFONTW)
                            case "W":
                                if IsInteger(value) && (value >= 1) && (value <= 1000)
                                    NumPut("Int", Integer(value), LOGFONTW, 16)
                        }
                }
            }
        }

        NumPut("Char", 1, "Char", 4, "Char", 0, LOGFONTW, 23)
        NumPut("Char", 0, LOGFONTW, 27)
        if (FntName != "")
            StrPut(FntName, LOGFONTW.Ptr + 28, 32)

        HFONT := DllCall("CreateFontIndirectW", "Ptr", LOGFONTW, "UPtr")
        if (HFONT) {
            if This.HFONT
                DllCall("DeleteObject", "Ptr", This.HFONT)
            This.HFONT := HFONT
        }
    }
    ; -------------------------------------------------------------------------------------------------------------------
    ; SetMargins()    -  Set or remove the margins used by the tooltip (Memory Optimized)
    ; -------------------------------------------------------------------------------------------------------------------
    static SetMargins(L := 0, T := 0, R := 0, B := 0) {
        if ((L + T + R + B) = 0) {
            This.Margins := ""
        } else {
            ; 重用现有Buffer或创建新的
            if (Type(This.Margins) != "Buffer") {
                This.Margins := Buffer(16, 0)
            }
            NumPut("Int", L, "Int", T, "Int", R, "Int", B, This.Margins)
        }
    }
    ; -------------------------------------------------------------------------------------------------------------------
    ; SetTitle()      -  Set or remove the title and/or the icon displayed on the tooltip.
    ; Parameters:
    ;     Title       -  string to be used as title.
    ;     Icon        -  icon to be shown in the ToolTip.
    ;                    This can be the number of a predefined icon (1 = info, 2 = warning, 3 = error
    ;                    (add 3 to display large icons on Vista+) or a HICON handle.
    ; -------------------------------------------------------------------------------------------------------------------
    static SetTitle(Title := "", Icon := "") {
        switch {
            case (Title = "") && (Icon != ""):
                This.Icon := Icon
                This.Title := " "
            case (Title != "") && (Icon = ""):
                This.Icon := 0
                This.Title := Title
            Default:
                This.Icon := Icon
                This.Title := Title
        }
    }
    ; -------------------------------------------------------------------------------------------------------------------
    ; For internal use only!
    ; -------------------------------------------------------------------------------------------------------------------
    static _WNDPROC_(hWnd, uMsg, wParam, lParam) {
        ; WNDPROC -> https://learn.microsoft.com/en-us/windows/win32/api/winuser/nc-winuser-wndproc
        switch uMsg {
            case 0x0411: ; TTM_TRACKACTIVATE - just handle the first message after the control has been created
                if This.ToolTips.Has(hWnd) && (This.ToolTips[hWnd] = 0) {
                    if (This.BkgColor != "")
                        SendMessage(1043, This.BkgColor, 0, hWnd)                ; TTM_SETTIPBKCOLOR
                    if (This.TxtColor != "")
                        SendMessage(1044, This.TxtColor, 0, hWnd)                ; TTM_SETTIPTEXTCOLOR
                    if This.HFONT
                        SendMessage(0x30, This.HFONT, 0, hWnd)                   ; WM_SETFONT
                    if (Type(This.Margins) = "Buffer")
                        SendMessage(1050, 0, This.Margins.Ptr, hWnd)             ; TTM_SETMARGIN
                    if (This.Icon != "") || (This.Title != "")
                        SendMessage(1057, This.Icon, StrPtr(This.Title), hWnd)   ; TTM_SETTITLE
                    This.ToolTips[hWnd] := 1
                }
            case 0x0001: ; WM_CREATE
                DllCall("UxTheme.dll\SetWindowTheme", "Ptr", hWnd, "Ptr", 0, "Ptr", StrPtr(""))
                This.ToolTips[hWnd] := 0
            case 0x0002: ; WM_DESTROY
                This.ToolTips.Delete(hWnd)
        }
        return DllCall(This.OWP, "Ptr", hWnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam, "UInt")
    }
    ; -------------------------------------------------------------------------------------------------------------------
    static _EXIT_(*) {
        if (ToolTipOptions.OWP != 0)
            ToolTipOptions.Reset()
    }
}
