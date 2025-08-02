;===================================================================================
; BeautifulToolTip (BTT) - 极致内存优化版 v3
;===================================================================================
; 目标: 将内存占用降低到15MB以下
;
; 极致优化策略:
; 1. 单例GUI模式 - 只使用1个GUI，复用所有资源
; 2. 最小DIB尺寸 - 动态调整位图大小
; 3. 零缓存策略 - 除了必要的，不缓存任何东西
; 4. 轻量级GDI+ - 只保留核心绘图功能
; 5. 内存池管理 - 复用Buffer和对象
; 调整内存池大小
; static maxPoolSize := 2  ; 从3降到2

; ; 更严格的位图尺寸限制
; newW := Min(w + 30, 800)  ; 从w+50降到w+30，最大从1000降到800
; newH := Min(h + 30, 600)  ; 从h+50降到h+30，最大从800降到600

; ; 更小的临时测量尺寸
; this._EnsureResources(300, 80)  ; 从400x100降到300x80

;===================================================================================

; 支持多实例的主函数
btt(Text := "", X := "", Y := "", WhichToolTip := 1, Style := "", Options := "") {
    static BTTInstances := Map()

    ; 创建或获取指定的tooltip实例
    if !BTTInstances.Has(WhichToolTip) {
        BTTInstances[WhichToolTip] := UltraTooltip(WhichToolTip)
    }

    return BTTInstances[WhichToolTip].Show(Text, X, Y, Style, Options)
}

class UltraTooltip {
    ; 全局共享资源（只初始化一次）
    static pToken := 0
    static fontName := ""
    static monitors := ""

    ; 实例专用资源（每个tooltip独立）
    gui := ""
    hwnd := 0
    hdc := 0
    hbm := 0
    graphics := 0
    currentSize := { w: 0, h: 0 }
    lastText := ""
    lastStyle := ""
    instanceId := 0

    ; 内存池（实例独立）
    bufferPool := []
    maxPoolSize := 0

    __New(instanceId := 1) {
        this.instanceId := instanceId

        ; 全局资源只初始化一次
        if (!UltraTooltip.pToken) {
            UltraTooltip.pToken := Gdip_Startup()
            if (!UltraTooltip.pToken) {
                throw Error("GDI+ startup failed")
            }

            ; 获取系统字体名称
            UltraTooltip.fontName := this._GetSystemFont()

            ; 简化的显示器信息
            UltraTooltip.monitors := {
                primary: {
                    left: 0, top: 0,
                    right: A_ScreenWidth, bottom: A_ScreenHeight,
                    dpi: A_ScreenDPI / 96
                }
            }
        }
    }

    ; 获取系统字体
    _GetSystemFont() {
        try {
            ; 尝试获取系统字体
            ncm := Buffer(500, 0)
            NumPut("UInt", ncm.Size, ncm, 0)
            if (DllCall("SystemParametersInfo", "UInt", 0x29, "UInt", ncm.Size, "Ptr", ncm.Ptr, "UInt", 0)) {
                return StrGet(ncm.Ptr + 316 + 28, 32)
            }
        }
        return "Segoe UI"  ; 默认字体
    }

    ; 主显示函数
    Show(Text := "", X := "", Y := "", Style := "", Options := "") {
        if (Text = "") {
            this._Hide()
            return
        }

        ; 快速变化检测
        styleKey := this._GetStyleKey(Style)
        if (Text = this.lastText && styleKey = this.lastStyle) {
            ; 只需要重新定位
            return this._Reposition(X, Y)
        }

        ; 解析样式和选项
        S := this._ParseStyle(Style)
        O := this._ParseOptions(Options)

        ; 先确保基础资源可用（用于文本测量）
        ; this._EnsureResources(400, 100)  ; 临时尺寸，用于创建graphics
        this._EnsureResources(300, 80)  ; 临时尺寸，用于创建graphics

        ; 计算所需尺寸
        textSize := this._MeasureText(Text, S)
        totalW := textSize.w + S.margin * 2 + S.border * 2
        totalH := textSize.h + S.margin * 2 + S.border * 2

        ; 确保GUI和资源满足实际需求
        this._EnsureResources(totalW, totalH)

        ; 渲染
        this._Render(Text, S, textSize, totalW, totalH)

        ; 计算位置
        pos := this._CalcPosition(X, Y, totalW, totalH, O)

        ; 显示
        this._Display(pos.x, pos.y, totalW, totalH, O.transparent)

        ; 缓存状态
        this.lastText := Text
        this.lastStyle := styleKey

        return { Hwnd: this.hwnd, X: pos.x, Y: pos.y, W: totalW, H: totalH }
    }

    ; 隐藏提示并释放资源
    _Hide() {
        if (this.gui) {
            ; this.gui.Hide()
            this.gui.Destroy()
            this.gui := ""
            this.hwnd := 0
        }
        
        ; 释放GDI+资源以节省内存
        if (this.graphics) {
            Gdip_DeleteGraphics(this.graphics)
            this.graphics := 0
        }
        if (this.hbm) {
            DeleteObject(this.hbm)
            this.hbm := 0
        }
        if (this.hdc) {
            DeleteDC(this.hdc)
            this.hdc := 0
        }
        
        ; 清空缓存和内存池
        this.lastText := ""
        this.lastStyle := ""
        this.bufferPool := []
        this.currentSize := { w: 0, h: 0 }

        ; 强制垃圾回收
        DllCall("kernel32.dll\SetProcessWorkingSetSize", "ptr", -1, "uptr", -1, "uptr", -1)
    }

    ; 确保资源可用
    _EnsureResources(w, h) {
        ; 创建GUI（如果不存在）
        if (!this.gui) {
            this.gui := GUI("+E0x80000 -Caption +ToolWindow +LastFound +AlwaysOnTop")
            this.hwnd := this.gui.Hwnd
            this.gui.Show("NA")
            WinSetExStyle("+32", "ahk_id " this.hwnd)
        }

        ; 检查是否需要重新创建位图
        if (!this.hbm || w > this.currentSize.w || h > this.currentSize.h) {
            this._RecreateGraphics(w, h)
        }
    }

    ; 重新创建图形资源
    _RecreateGraphics(w, h) {
        ; 清理旧资源
        if (this.graphics) {
            Gdip_DeleteGraphics(this.graphics)
        }
        if (this.hbm) {
            DeleteObject(this.hbm)
        }
        if (this.hdc) {
            DeleteDC(this.hdc)
        }

        ; 使用最小必要尺寸，添加小量缓冲
        newW := Min(w + 30, 800)  ; 限制最大宽度 从w+50降到w+30，最大从1000降到800
        newH := Min(h + 30, 600)   ; 限制最大高度 从h+50降到h+30，最大从800降到600

        ; 创建新资源
        this.hdc := CreateCompatibleDC()
        this.hbm := CreateDIBSection(newW, newH)
        SelectObject(this.hdc, this.hbm)
        this.graphics := Gdip_GraphicsFromHDC(this.hdc)

        ; 设置图形质量
        Gdip_SetSmoothingMode(this.graphics, 4)

        this.currentSize := { w: newW, h: newH }
    }

    ; 测量文本尺寸
    _MeasureText(text, style) {
        if (!this.graphics) {
            return { w: 200, h: 30 }  ; 默认尺寸
        }

        ; 创建临时字体资源
        hFamily := Gdip_FontFamilyCreate(style.font)
        if (!hFamily) {
            hFamily := Gdip_FontFamilyCreateGeneric(1)
        }

        hFont := Gdip_FontCreate(hFamily, style.fontSize * UltraTooltip.monitors.primary.dpi, 0)
        hFormat := Gdip_StringFormatGetGeneric(1)

        ; 创建测量矩形
        CreateRectF(&rect, 0, 0, 800, 600)

        ; 测量
        result := Gdip_MeasureString(this.graphics, text, hFont, hFormat, &rect)
        parts := StrSplit(result, "|")

        ; 清理资源
        Gdip_DeleteStringFormat(hFormat)
        Gdip_DeleteFont(hFont)
        Gdip_DeleteFontFamily(hFamily)

        return { w: Ceil(parts[3]), h: Ceil(parts[4]) }
    }

    ; 渲染提示框
    _Render(text, style, textSize, totalW, totalH) {
        ; 清空画布
        Gdip_GraphicsClear(this.graphics)

        ; 绘制背景
        if (style.border > 0) {
            borderBrush := Gdip_BrushCreateSolid(style.borderColor)
            if (style.rounded > 0) {
                Gdip_FillRoundedRectangle(this.graphics, borderBrush, 0, 0, totalW, totalH, style.rounded)
            } else {
                Gdip_FillRectangle(this.graphics, borderBrush, 0, 0, totalW, totalH)
            }
            Gdip_DeleteBrush(borderBrush)
        }

        ; 绘制内部背景
        bgBrush := Gdip_BrushCreateSolid(style.bgColor)
        bgX := style.border
        bgY := style.border
        bgW := totalW - style.border * 2
        bgH := totalH - style.border * 2

        if (style.rounded > 0 && style.border > 0) {
            innerRadius := Max(0, style.rounded - style.border)
            Gdip_FillRoundedRectangle(this.graphics, bgBrush, bgX, bgY, bgW, bgH, innerRadius)
        } else {
            Gdip_FillRectangle(this.graphics, bgBrush, bgX, bgY, bgW, bgH)
        }
        Gdip_DeleteBrush(bgBrush)

        ; 绘制文本
        this._DrawText(text, style, textSize)
    }

    ; 绘制文本
    _DrawText(text, style, textSize) {
        ; 创建字体资源
        hFamily := Gdip_FontFamilyCreate(style.font)
        if (!hFamily) {
            hFamily := Gdip_FontFamilyCreateGeneric(1)
        }

        hFont := Gdip_FontCreate(hFamily, style.fontSize * UltraTooltip.monitors.primary.dpi, 0)
        hFormat := Gdip_StringFormatGetGeneric(1)
        textBrush := Gdip_BrushCreateSolid(style.textColor)

        ; 设置对齐
        Gdip_SetStringFormatAlign(hFormat, style.align)

        ; 计算文本位置
        textX := style.border + style.margin
        textY := style.border + style.margin

        ; 创建文本矩形
        CreateRectF(&textRect, textX, textY, textSize.w, textSize.h)

        ; 绘制文本
        Gdip_DrawString(this.graphics, text, hFont, hFormat, textBrush, &textRect)

        ; 清理资源
        Gdip_DeleteBrush(textBrush)
        Gdip_DeleteStringFormat(hFormat)
        Gdip_DeleteFont(hFont)
        Gdip_DeleteFontFamily(hFamily)
    }

    ; 计算显示位置
    _CalcPosition(X, Y, W, H, options) {
        ; 获取鼠标位置
        if (X = "" || Y = "") {
            pt := Buffer(8, 0)
            DllCall("GetCursorPos", "Ptr", pt.Ptr)
            mouseX := NumGet(pt, 0, "Int")
            mouseY := NumGet(pt, 4, "Int")
            if (X = "")
                X := mouseX + 16
            if (Y = "")
                Y := mouseY + 16
        }
        ; 边界检查
        mon := UltraTooltip.monitors.primary
        if (X + W > mon.right)
            X := mon.right - W
        if (Y + H > mon.bottom)
            Y := mon.bottom - H
        if (X < mon.left)
            X := mon.left
        if (Y < mon.top)
            Y := mon.top
        return { x: X, y: Y }
    }

    ; 显示窗口
    _Display(x, y, w, h, alpha) {
        ; 确保GUI是可见的 - 使用Windows API检查窗口可见性
        if (this.gui && !DllCall("IsWindowVisible", "ptr", this.hwnd)) {
            this.gui.Show("NA")
        }
        
        UpdateLayeredWindow(this.hwnd, this.hdc, x, y, w, h, alpha)
        DllCall("SetWindowPos", "ptr", this.hwnd, "ptr", -1, "int", 0, "int", 0, "int", 0, "int", 0, "uint", 19)
    }

    ; 重新定位
    _Reposition(X, Y) {
        if (!this.gui)
            return

        pos := this._CalcPosition(X, Y, this.currentSize.w, this.currentSize.h, {})
        this._Display(pos.x, pos.y, this.currentSize.w, this.currentSize.h, 255)

        return { Hwnd: this.hwnd, X: pos.x, Y: pos.y, W: this.currentSize.w, H: this.currentSize.h }
    }

    ; 解析样式
    _ParseStyle(style) {
        if (style = "" || !IsObject(style)) {
            return {
                border: 1, rounded: 3, margin: 5,
                borderColor: 0xff575757, bgColor: 0xffffffff, textColor: 0xff575757,
                font: UltraTooltip.fontName, fontSize: 12, align: 0
            }
        }

        return {
            border: style.HasOwnProp("Border") ? style.Border : 1,
            rounded: style.HasOwnProp("Rounded") ? style.Rounded : 3,
            margin: style.HasOwnProp("Margin") ? style.Margin : 5,
            borderColor: style.HasOwnProp("BorderColor") ? style.BorderColor : 0xff575757,
            bgColor: style.HasOwnProp("BackgroundColor") ? style.BackgroundColor : 0xffffffff,
            textColor: style.HasOwnProp("TextColor") ? style.TextColor : 0xff575757,
            font: style.HasOwnProp("Font") ? style.Font : UltraTooltip.fontName,
            fontSize: style.HasOwnProp("FontSize") ? style.FontSize : 12,
            align: style.HasOwnProp("Align") ? style.Align : 0
        }
    }

    ; 解析选项
    _ParseOptions(options) {
        if (options = "" || !IsObject(options)) {
            return { transparent: 255 }
        }

        return {
            transparent: options.HasOwnProp("Transparent") ? options.Transparent : 255
        }
    }

    ; 生成样式键
    _GetStyleKey(style) {
        if (!IsObject(style))
            return ""

        key := ""
        for prop, value in style.OwnProps() {
            key .= prop . ":" . value . "|"
        }
        return key
    }

    ; 获取Buffer（内存池）
    _GetBuffer(size) {
        for i, buf in this.bufferPool {
            if (buf.Size >= size) {
                this.bufferPool.RemoveAt(i)
                return buf
            }
        }
        return Buffer(size, 0)
    }

    ; 归还Buffer到池中
    _ReturnBuffer(buf) {
        if (this.bufferPool.Length < this.maxPoolSize) {
            this.bufferPool.Push(buf)
        }
    }

    ; 清理实例资源
    Cleanup() {
        if (this.graphics) {
            Gdip_DeleteGraphics(this.graphics)
            this.graphics := 0
        }
        if (this.hbm) {
            DeleteObject(this.hbm)
            this.hbm := 0
        }
        if (this.hdc) {
            DeleteDC(this.hdc)
            this.hdc := 0
        }
        if (this.gui) {
            this.gui.Destroy()
            this.gui := ""
        }

        ; 清空实例缓存
        this.lastText := ""
        this.lastStyle := ""
        this.bufferPool := []
        this.currentSize := { w: 0, h: 0 }
    }

    ; 清理所有全局资源（静态方法）
    static CleanupAll() {
        if (UltraTooltip.pToken) {
            Gdip_Shutdown(UltraTooltip.pToken)
            UltraTooltip.pToken := 0
        }
    }
}

;===================================================================================
; 极简样式定义
;===================================================================================

; 暗色样式
DarkStyle := {
    Border: 1, Rounded: 3, Margin: 8,
    BorderColor: 0xff3881a7, TextColor: 0xFFFFFFFF, BackgroundColor: 0xFF000000,
    FontSize: 14, Align: 0
}

; 亮色样式
LightStyle := {
    Border: 1, Rounded: 6, Margin: 8,
    BorderColor: 0xFFCCCCCC, TextColor: 0xFF333333, BackgroundColor: 0xFFF8F8F8,
    FontSize: 13, Align: 0
}

; 成功样式
SuccessStyle := {
    Border: 1, Rounded: 8, Margin: 10,
    BorderColor: 0xFF4CAF50, TextColor: 0xFFFFFFFF, BackgroundColor: 0xFF388E3C,
    FontSize: 14, Align: 1
}

; 错误样式
ErrorStyle := {
    Border: 1, Rounded: 8, Margin: 10,
    BorderColor: 0xFFE53935, TextColor: 0xFFFFFFFF, BackgroundColor: 0xFFC62828,
    FontSize: 14, Align: 1
}

; 警告样式
WarningStyle := {
    Border: 1, Rounded: 8, Margin: 10,
    BorderColor: 0xFFFFC107, TextColor: 0xFF212121, BackgroundColor: 0xFFFFD54F,
    FontSize: 14, Align: 1
}

;===================================================================================
; 极简GDI+函数 - 只保留必要的
;===================================================================================

Gdip_Startup() {
    DllCall("LoadLibrary", "str", "gdiplus")
    si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
    NumPut("UInt", 1, si)
    DllCall("gdiplus\GdiplusStartup", "UPtr*", &pToken := 0, "UPtr", si.Ptr, "UPtr", 0)
    return pToken
}

Gdip_Shutdown(pToken) {
    DllCall("gdiplus\GdiplusShutdown", "UPtr", pToken)
    if (hModule := DllCall("GetModuleHandle", "str", "gdiplus", "UPtr"))
        DllCall("FreeLibrary", "UPtr", hModule)
}

CreateCompatibleDC(hdc := 0) => DllCall("CreateCompatibleDC", "UPtr", hdc)
DeleteDC(hdc) => DllCall("DeleteDC", "UPtr", hdc)
DeleteObject(hObject) => DllCall("DeleteObject", "UPtr", hObject)
SelectObject(hdc, hgdiobj) => DllCall("SelectObject", "UPtr", hdc, "UPtr", hgdiobj)

CreateDIBSection(w, h, hdc := "", bpp := 32, &ppvBits := 0) {
    hdc2 := hdc ? hdc : DllCall("GetDC", "UPtr", 0)
    bi := Buffer(40, 0)
    NumPut("UInt", w, bi, 4), NumPut("UInt", h, bi, 8), NumPut("UInt", 40, bi, 0)
    NumPut("ushort", 1, bi, 12), NumPut("uInt", 0, bi, 16), NumPut("ushort", bpp, bi, 14)
    hbm := DllCall("CreateDIBSection", "UPtr", hdc2, "UPtr", bi.Ptr, "UInt", 0, "UPtr*", &ppvBits, "UPtr", 0,
        "UInt", 0, "UPtr")
    if (!hdc)
        DllCall("ReleaseDC", "UPtr", 0, "UPtr", hdc2)
    return hbm
}

Gdip_GraphicsFromHDC(hdc) {
    DllCall("gdiplus\GdipCreateFromHDC", "UPtr", hdc, "UPtr*", &pGraphics := 0)
    return pGraphics
}

Gdip_DeleteGraphics(pGraphics) => DllCall("gdiplus\GdipDeleteGraphics", "UPtr", pGraphics)
Gdip_SetSmoothingMode(pGraphics, SmoothingMode) => DllCall("gdiplus\GdipSetSmoothingMode", "UPtr", pGraphics, "Int",
    SmoothingMode)
Gdip_GraphicsClear(pGraphics, ARGB := 0x00ffffff) => DllCall("gdiplus\GdipGraphicsClear", "UPtr", pGraphics, "Int",
    ARGB)

Gdip_BrushCreateSolid(ARGB := 0xff000000) {
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", ARGB, "UPtr*", &pBrush := 0)
    return pBrush
}

Gdip_DeleteBrush(pBrush) => DllCall("gdiplus\GdipDeleteBrush", "UPtr", pBrush)

Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h) => DllCall("gdiplus\GdipFillRectangle", "UPtr", pGraphics, "UPtr",
    pBrush, "Float", x, "Float", y, "Float", w, "Float", h)

; 简化的圆角矩形
Gdip_FillRoundedRectangle(pGraphics, pBrush, X, Y, W, H, R) {
    if (R <= 0) {
        return Gdip_FillRectangle(pGraphics, pBrush, X, Y, W, H)
    }

    DllCall("Gdiplus.dll\GdipCreatePath", "UInt", 0, "PtrP", &pPath := 0)
    D := R * 2
    W -= D, H -= D

    ; 添加圆角路径
    DllCall("Gdiplus.dll\GdipAddPathArc", "Ptr", pPath, "Float", X, "Float", Y, "Float", D, "Float", D, "Float",
        180, "Float", 90)
    DllCall("Gdiplus.dll\GdipAddPathArc", "Ptr", pPath, "Float", X + W, "Float", Y, "Float", D, "Float", D, "Float",
        270, "Float", 90)
    DllCall("Gdiplus.dll\GdipAddPathArc", "Ptr", pPath, "Float", X + W, "Float", Y + H, "Float", D, "Float", D,
        "Float", 0, "Float", 90)
    DllCall("Gdiplus.dll\GdipAddPathArc", "Ptr", pPath, "Float", X, "Float", Y + H, "Float", D, "Float", D, "Float",
        90, "Float", 90)
    DllCall("Gdiplus.dll\GdipClosePathFigure", "Ptr", pPath)

    result := DllCall("Gdiplus.dll\GdipFillPath", "Ptr", pGraphics, "Ptr", pBrush, "Ptr", pPath)
    DllCall("Gdiplus.dll\GdipDeletePath", "Ptr", pPath)
    return result
}

; 字体相关
Gdip_FontFamilyCreate(Font) {
    DllCall("gdiplus\GdipCreateFontFamilyFromName", "UPtr", StrPtr(Font), "UInt", 0, "UPtr*", &hFamily := 0)
    return hFamily
}

Gdip_FontFamilyCreateGeneric(whichStyle) {
    if (whichStyle = 1)
        DllCall("gdiplus\GdipGetGenericFontFamilySansSerif", "UPtr*", &hFontFamily := 0)
    else
        DllCall("gdiplus\GdipGetGenericFontFamilySerif", "UPtr*", &hFontFamily := 0)
    return hFontFamily
}

Gdip_FontCreate(hFamily, Size, Style := 0) {
    DllCall("gdiplus\GdipCreateFont", "UPtr", hFamily, "Float", Size, "Int", Style, "Int", 0, "UPtr*", &hFont := 0)
    return hFont
}

Gdip_DeleteFont(hFont) => DllCall("gdiplus\GdipDeleteFont", "UPtr", hFont)
Gdip_DeleteFontFamily(hFamily) => DllCall("gdiplus\GdipDeleteFontFamily", "UPtr", hFamily)

Gdip_StringFormatGetGeneric(whichFormat := 0) {
    if (whichFormat = 1)
        DllCall("gdiplus\GdipStringFormatGetGenericTypographic", "UPtr*", &hStringFormat := 0)
    else
        DllCall("gdiplus\GdipStringFormatGetGenericDefault", "UPtr*", &hStringFormat := 0)
    return hStringFormat
}

Gdip_DeleteStringFormat(hFormat) => DllCall("gdiplus\GdipDeleteStringFormat", "UPtr", hFormat)
Gdip_SetStringFormatAlign(hFormat, Align) => DllCall("gdiplus\GdipSetStringFormatAlign", "UPtr", hFormat, "Int",
    Align)

CreateRectF(&RectF, x, y, w, h) {
    RectF := Buffer(16)
    NumPut("Float", x, RectF, 0), NumPut("Float", y, RectF, 4), NumPut("Float", w, RectF, 8), NumPut("Float", h,
        RectF, 12)
}

Gdip_MeasureString(pGraphics, sString, hFont, hFormat, &RectF) {
    RC := Buffer(16)
    DllCall("gdiplus\GdipMeasureString", "UPtr", pGraphics, "UPtr", StrPtr(sString), "Int", -1, "UPtr", hFont,
    "UPtr", RectF.Ptr, "UPtr", hFormat, "UPtr", RC.Ptr, "uint*", &Chars := 0, "uint*", &Lines := 0)
    return RC.Ptr ? NumGet(RC, 0, "Float") "|" NumGet(RC, 4, "Float") "|" NumGet(RC, 8, "Float") "|" NumGet(RC, 12,
        "Float") "|" Chars "|" Lines : 0
}

Gdip_DrawString(pGraphics, sString, hFont, hFormat, pBrush, &RectF) => DllCall("gdiplus\GdipDrawString", "UPtr",
    pGraphics, "UPtr", StrPtr(sString), "Int", -1, "UPtr", hFont, "UPtr", RectF.Ptr, "UPtr", hFormat, "UPtr",
    pBrush)

UpdateLayeredWindow(hwnd, hdc, x := "", y := "", w := "", h := "", Alpha := 255) {
    if ((x != "") && (y != ""))
        pt := Buffer(8), NumPut("UInt", x, pt, 0), NumPut("UInt", y, pt, 4)
    if (w = "") || (h = "") {
        rect := Buffer(16)
        DllCall("GetWindowRect", "UPtr", hwnd, "UPtr", rect.Ptr)
        w := NumGet(rect, 8, "UInt") - NumGet(rect, 0, "UInt")
        h := NumGet(rect, 12, "UInt") - NumGet(rect, 4, "UInt")
    }
    return DllCall("UpdateLayeredWindow", "UPtr", hwnd, "UPtr", 0, "UPtr", ((x = "") && (y = "")) ? 0 : pt.Ptr,
    "Int64*", w | h << 32, "UPtr", hdc, "Int64*", 0, "UInt", 0, "UInt*", Alpha << 16 | 1 << 24, "UInt", 2)
}

;===================================================================================
; 便捷函数
;===================================================================================

; 自动消失提示
bttAutoHide(Text, Timeout := 3000, X := "", Y := "", Style := "") {
    result := btt(Text, X, Y, 1, Style)
    SetTimer(() => btt(""), -Timeout)
    return result
}

; 快速提示
quickTip(Text) => bttAutoHide(Text, 3000)

; 主题感知提示
bttThemeAware(Text, Timeout := 3000, X := "", Y := "") {
    try {
        isDark := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize",
            "AppsUseDarkTheme") = 1
    } catch {
        isDark := false
    }

    style := isDark ? DarkStyle : LightStyle
    return bttAutoHide(Text, Timeout, X, Y, style)
}

; 状态提示
successTip(Text, Timeout := 3000) => bttAutoHide(Text, Timeout, "", "", SuccessStyle)
errorTip(Text, Timeout := 3000) => bttAutoHide(Text, Timeout, "", "", ErrorStyle)
warningTip(Text, Timeout := 3000) => bttAutoHide(Text, Timeout, "", "", WarningStyle)

; 内存清理
BTTCleanup() {
    UltraTooltip.Cleanup()
}

; 清理所有BTT实例的全局函数
BTTCleanupAll() {
    ; 通过调用btt函数来获取实例Map的引用
    try {
        ; 先调用一次btt来确保静态变量被初始化
        btt("", "", "", 999)  ; 使用一个特殊的ID来触发初始化
        
        ; 现在通过反射获取静态变量（这是一个hack方法）
        ; 更安全的方法是直接清理所有可能的实例
        Loop 20 {  ; 假设最多有20个实例
            try {
                ; 尝试隐藏每个可能的tooltip实例
                btt("", "", "", A_Index)
            } catch {
                ; 忽略错误，继续下一个
            }
        }
        
        ; 清理全局GDI+资源
        UltraTooltip.CleanupAll()
        
        ; 强制垃圾回收
        DllCall("kernel32.dll\SetProcessWorkingSetSize", "ptr", -1, "uptr", -1, "uptr", -1)
        
    } catch {
        ; 如果清理失败，至少清理全局资源
        try {
            UltraTooltip.CleanupAll()
        } catch {
            ; 忽略清理错误
        }
    }
}

;=======================================极致优化版本完成===============================================================
