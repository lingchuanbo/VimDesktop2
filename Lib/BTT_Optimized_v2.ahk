;===================================================================================
; BeautifulToolTip (BTT) - 内存优化版 v2
;===================================================================================
; 原作者: telppa  https://github.com/telppa/BeautifulToolTip
; v2 转换: @github:liuyi91
; 内存优化版本: 大幅减少内存占用，提高性能
; 优化目标: 将内存占用从648MB降低到50MB以下
;
; 主要优化:
; 1. 按需创建GUI资源，而非预分配20个
; 2. 使用更小的DIB位图尺寸
; 3. 优化缓存策略，及时释放不用的资源
; 4. 改进GDI资源管理
; 5. 减少静态变量和全局缓存
;===================================================================================

; 优化后的主函数
btt(Text := "", X := "", Y := "", WhichToolTip := "", BulitInStyleOrStyles := "", BulitInOptionOrOptions := "") {
    static BTT

    ; 延迟初始化，只在需要时创建
    if !isset(BTT)
        BTT := BeautifulToolTip()

    return BTT.ToolTip(Text, X, Y, WhichToolTip, BulitInStyleOrStyles, BulitInOptionOrOptions)
}

class BeautifulToolTip extends Map {
    static DebugMode := 0
    CaseSense := 'off'

    ; 减少静态缓存，改为实例缓存
    _cachedDPI := Map()
    _cachedFontName := ""
    _activeGUIs := Map()  ; 只存储活跃的GUI
    _maxActiveGUIs := 5   ; 最大同时活跃GUI数量

    __New() {
        if (!this.HasOwnProp("pToken") or !this.pToken) {
            this.pToken := Gdip_Startup()
            if (!this.pToken) {
                MsgBox("Gdiplus failed to start. Please ensure you have gdiplus on your system", "gdiplus error!", 48)
                ExitApp
            }

            ; 优化显示器初始化
            this._InitializeMonitors()

            ; 使用更小的DIB尺寸 - 只使用主显示器尺寸而非扩展桌面
            this.DIBWidth := A_ScreenWidth
            this.DIBHeight := A_ScreenHeight

            ; 缓存字体名称
            if (!this._cachedFontName)
                this._cachedFontName := this.Fnt_GetTooltipFontName()
            this.ToolTipFontName := this._cachedFontName
        }
    }

    ; 优化显示器初始化 - 减少内存占用
    _InitializeMonitors() {
        this.Monitors := MDMF_Enum()

        ; 只缓存主显示器DPI，其他按需计算
        osv := StrSplit(A_OSVersion, ".")
        isWin8Plus := !(osv[1] < 6 || (osv[1] == 6 && osv[2] < 3))

        ; 只初始化主显示器
        primaryMonitor := this.Monitors["Primary"]
        if (primaryMonitor) {
            if (isWin8Plus) {
                DllCall("Shcore.dll\GetDpiForMonitor", "Ptr", primaryMonitor, "Int", 0, "UIntP", &dpiX := 0, "UIntP", &
                    dpiY := 0, "UInt")
            } else {
                hDC := DllCall("Gdi32.dll\CreateDC", "Str", this.Monitors[primaryMonitor].name, "Ptr", 0, "Ptr", 0,
                    "Ptr", 0, "Ptr")
                dpiX := DllCall("Gdi32.dll\GetDeviceCaps", "Ptr", hDC, "Int", 88)
                DllCall("Gdi32.dll\DeleteDC", "Ptr", hDC)
            }

            dpiScale := this.NonNull_Ret(dpiX, A_ScreenDPI) / 96
            this.Monitors[primaryMonitor].DPIScale := dpiScale
            this._cachedDPI[primaryMonitor] := dpiScale
        }
    }

    ; 按需创建GUI资源
    _GetOrCreateGUI(WhichToolTip) {
        ; 如果已存在，直接返回
        if (this._activeGUIs.Has(WhichToolTip)) {
            return this._activeGUIs[WhichToolTip]
        }

        ; 如果活跃GUI数量超过限制，清理最旧的
        if (this._activeGUIs.Count >= this._maxActiveGUIs) {
            this._CleanupOldestGUI()
        }

        ; 创建新的GUI资源
        guiObj := {}
        guiObj.gui := GUI("+E0x80000 -Caption +ToolWindow +LastFound +AlwaysOnTop")
        guiObj.hwnd := guiObj.gui.Hwnd
        guiObj.gui.Show("NA")
        WinSetExStyle("+32", "ahk_id " guiObj.hwnd)

        ; 使用更小的位图尺寸 - 根据实际需要动态调整
        maxSize := Min(this.DIBWidth, this.DIBHeight, 2000)  ; 限制最大尺寸
        guiObj.hbm := CreateDIBSection(maxSize, maxSize)
        guiObj.hdc := CreateCompatibleDC()
        guiObj.obm := SelectObject(guiObj.hdc, guiObj.hbm)
        guiObj.graphics := Gdip_GraphicsFromHDC(guiObj.hdc)

        ; 设置图形属性
        Gdip_SetSmoothingMode(guiObj.graphics, 4)
        Gdip_SetPixelOffsetMode(guiObj.graphics, 2)

        ; 记录创建时间用于清理
        guiObj.lastUsed := A_TickCount

        this._activeGUIs[WhichToolTip] := guiObj
        return guiObj
    }

    ; 清理最旧的GUI
    _CleanupOldestGUI() {
        oldestKey := ""
        oldestTime := A_TickCount

        for key, guiObj in this._activeGUIs {
            if (guiObj.lastUsed < oldestTime) {
                oldestTime := guiObj.lastUsed
                oldestKey := key
            }
        }

        if (oldestKey) {
            this._ReleaseGUI(oldestKey)
        }
    }

    ; 释放GUI资源
    _ReleaseGUI(WhichToolTip) {
        if (!this._activeGUIs.Has(WhichToolTip)) {
            return
        }

        guiObj := this._activeGUIs[WhichToolTip]

        ; 清理GDI资源
        if (guiObj.HasOwnProp("graphics") && guiObj.graphics) {
            Gdip_DeleteGraphics(guiObj.graphics)
        }
        if (guiObj.HasOwnProp("obm") && guiObj.obm) {
            SelectObject(guiObj.hdc, guiObj.obm)
        }
        if (guiObj.HasOwnProp("hbm") && guiObj.hbm) {
            DeleteObject(guiObj.hbm)
        }
        if (guiObj.HasOwnProp("hdc") && guiObj.hdc) {
            DeleteDC(guiObj.hdc)
        }
        if (guiObj.HasOwnProp("gui")) {
            guiObj.gui.Destroy()
        }

        this._activeGUIs.Delete(WhichToolTip)

        ; 清理相关缓存
        this._ClearToolTipCache(WhichToolTip)
    }

    ; 清理ToolTip缓存
    _ClearToolTipCache(WhichToolTip) {
        clearVars := ["SavedText", "SavedOptions", "SavedX", "SavedY", "SavedW", "SavedH",
            "SavedTargetHWND", "SavedCoordMode", "SavedTransparent"]
        for var in clearVars {
            if (this.HasOwnProp(var WhichToolTip)) {
                this.DeleteProp(var WhichToolTip)
            }
        }
    }

    __Delete() {
        ; 清理所有活跃的GUI
        for key in this._activeGUIs.Clone() {
            this._ReleaseGUI(key)
        }

        if (this.HasOwnProp("pToken") && this.pToken) {
            Gdip_Shutdown(this.pToken)
        }
    }

    ; 优化后的主要ToolTip函数
    ToolTip(Text := "", X := "", Y := "", WhichToolTip := "", Styles := "", Options := "") {
        ; 参数验证和默认值设置
        this.NonNull(&WhichToolTip, 1, 1, 20)

        if (Text != "") {
            O := this._CheckStylesAndOptions(Styles, Options)
        } else {
            O := { Checksum: "" }
        }

        ; 缓存键生成
        cacheKey := "SavedText" WhichToolTip

        ; 变化检测优化
        FirstCallOrNeedToUpdate := (Text != (this.HasOwnProp(cacheKey) ? this[cacheKey] : "")
        or O.Checksum != (this.HasOwnProp("SavedOptions" WhichToolTip) ? this["SavedOptions" WhichToolTip] : ""))

        if (Text = "") {
            this._ClearToolTip(WhichToolTip)
            return
        }

        if (FirstCallOrNeedToUpdate) {
            return this._UpdateToolTip(Text, &X, &Y, WhichToolTip, O)
        } else {
            return this._RepositionToolTip(&X, &Y, WhichToolTip, O)
        }
    }

    ; 清空ToolTip（优化版）
    _ClearToolTip(WhichToolTip) {
        guiObj := this._GetOrCreateGUI(WhichToolTip)
        Gdip_GraphicsClear(guiObj.graphics)
        UpdateLayeredWindow(guiObj.hwnd, guiObj.hdc)

        ; 清空缓存变量
        this._ClearToolTipCache(WhichToolTip)
    }

    ; 更新ToolTip内容（优化版）
    _UpdateToolTip(Text, &X, &Y, WhichToolTip, O) {
        guiObj := this._GetOrCreateGUI(WhichToolTip)
        guiObj.lastUsed := A_TickCount  ; 更新使用时间

        ; 计算显示区域
        TargetSize := this._CalculateDisplayPosition(&X, &Y, "", "", O, GetTargetSize := 1)
        MaxTextWidth := TargetSize.W - O.Margin * 2 - O.Border * 2
        MaxTextHeight := (TargetSize.H * 90) // 100 - O.Margin * 2 - O.Border * 2

        O.Width := MaxTextWidth
        O.Height := MaxTextHeight

        ; 文本测量
        TextArea := StrSplit(this._TextToGraphics(guiObj.graphics, Text, O, Measure := 1), "|")
        TextWidth := Min(Ceil(TextArea[3]), MaxTextWidth)
        TextHeight := Min(Ceil(TextArea[4]), MaxTextHeight)

        ; 计算尺寸
        RectWidth := TextWidth + O.Margin * 2
        RectHeight := TextHeight + O.Margin * 2
        RectWithBorderWidth := RectWidth + O.Border * 2
        RectWithBorderHeight := RectHeight + O.Border * 2
        R := (O.Rounded > Min(RectWidth, RectHeight) // 2) ? Min(RectWidth, RectHeight) // 2 : O.Rounded

        if (O.JustCalculateSize != 1) {
            this._RenderToolTip(guiObj, Text, TextArea, O, RectWidth, RectHeight,
                RectWithBorderWidth, RectWithBorderHeight, R, TextWidth, TextHeight)
            this._CalculateDisplayPosition(&X, &Y, RectWithBorderWidth, RectWithBorderHeight, O)

            ; 显示和置顶
            UpdateLayeredWindow(guiObj.hwnd, guiObj.hdc, X, Y, RectWithBorderWidth,
                RectWithBorderHeight, O.Transparent)
            DllCall("SetWindowPos", "ptr", guiObj.hwnd, "ptr", -1, "int", 0, "int", 0,
                "int", 0, "int", 0, "uint", 26139)
        }

        ; 保存状态
        this._SaveToolTipState(WhichToolTip, Text, O, X, Y, RectWithBorderWidth, RectWithBorderHeight)

        return { Hwnd: guiObj.hwnd, X: X, Y: Y, W: RectWithBorderWidth, H: RectWithBorderHeight }
    }

    ; 渲染ToolTip内容（优化版）
    _RenderToolTip(guiObj, Text, TextArea, O, RectWidth, RectHeight, RectWithBorderWidth, RectWithBorderHeight, R,
        TextWidth, TextHeight) {
        Gdip_GraphicsClear(guiObj.graphics)

        ; 创建画刷（优化：减少重复创建）
        pBrushBorder := this._CreateBorderBrush(O, RectWithBorderWidth, RectWithBorderHeight)
        pBrushBackground := this._CreateBackgroundBrush(O, RectWidth, RectHeight)

        ; 绘制边框
        if (O.Border > 0) {
            if (R = 0) {
                Gdip_FillRectangle(guiObj.graphics, pBrushBorder, 0, 0, RectWithBorderWidth, RectWithBorderHeight)
            } else {
                Gdip_FillRoundedRectanglePath(guiObj.graphics, pBrushBorder, 0, 0, RectWithBorderWidth,
                    RectWithBorderHeight, R)
            }
        }

        ; 绘制背景
        if (R = 0) {
            Gdip_FillRectangle(guiObj.graphics, pBrushBackground, O.Border, O.Border, RectWidth, RectHeight)
        } else {
            Gdip_FillRoundedRectanglePath(guiObj.graphics, pBrushBackground, O.Border, O.Border, RectWidth, RectHeight,
                (R > O.Border) ? R - O.Border : R)
        }

        ; 立即清理画刷
        Gdip_DeleteBrush(pBrushBorder)
        Gdip_DeleteBrush(pBrushBackground)

        ; 绘制文本
        O.X := O.Border + O.Margin
        O.Y := O.Border + O.Margin
        O.Width := TextWidth
        O.Height := TextHeight

        ; 处理文本截断
        TempText := (TextArea[5] < StrLen(Text)) ?
            (TextArea[5] > 4 ? SubStr(Text, 1, TextArea[5] - 4) "…………" : SubStr(Text, 1, 1) "…………") : Text

        this._TextToGraphics(guiObj.graphics, TempText, O)
    }
    #Requires AutoHotkey v2.0

    ; 创建边框画刷（优化版）
    _CreateBorderBrush(O, RectWithBorderWidth, RectWithBorderHeight) {
        if (O.BCLGA != "" and O.BCLGM and O.BCLGS and O.BCLGE) {
            return this._CreateLinearGrBrush(O.BCLGA, O.BCLGM, O.BCLGS, O.BCLGE, 0, 0, RectWithBorderWidth,
                RectWithBorderHeight)
        }
        return Gdip_BrushCreateSolid(O.BorderColor)
    }

    ; 创建背景画刷（优化版）
    _CreateBackgroundBrush(O, RectWidth, RectHeight) {
        if (O.BGCLGA != "" and O.BGCLGM and O.BGCLGS and O.BGCLGE) {
            return this._CreateLinearGrBrush(O.BGCLGA, O.BGCLGM, O.BGCLGS, O.BGCLGE, O.Border, O.Border, RectWidth,
                RectHeight)
        }
        return Gdip_BrushCreateSolid(O.BackgroundColor)
    }

    ; 重新定位ToolTip（优化版）
    _RepositionToolTip(&X, &Y, WhichToolTip, O) {
        guiObj := this._GetOrCreateGUI(WhichToolTip)
        guiObj.lastUsed := A_TickCount  ; 更新使用时间

        if ((X = "" or Y = "") or O.CoordMode != "Screen"
        or O.TargetHWND != this["SavedTargetHWND" WhichToolTip] or O.CoordMode != this["SavedCoordMode" WhichToolTip]
        or O.Transparent != this["SavedTransparent" WhichToolTip]) {

            this._CalculateDisplayPosition(&X, &Y, this["SavedW" WhichToolTip], this["SavedH" WhichToolTip], O)

            if (X != this["SavedX" WhichToolTip] or Y != this["SavedY" WhichToolTip] or O.Transparent != this[
                "SavedTransparent" WhichToolTip]) {
                UpdateLayeredWindow(guiObj.hwnd, guiObj.hdc, X, Y, this["SavedW" WhichToolTip], this["SavedH" WhichToolTip
                    ], O.Transparent)

                ; 更新保存的位置信息
                this["SavedX" WhichToolTip] := X
                this["SavedY" WhichToolTip] := Y
                this["SavedTargetHWND" WhichToolTip] := O.TargetHWND
                this["SavedCoordMode" WhichToolTip] := O.CoordMode
                this["SavedTransparent" WhichToolTip] := O.Transparent
            }
        }

        return { Hwnd: guiObj.hwnd, X: X, Y: Y, W: this["SavedW" WhichToolTip], H: this["SavedH" WhichToolTip] }
    }

    ; 保存ToolTip状态（优化版）
    _SaveToolTipState(WhichToolTip, Text, O, X, Y, W, H) {
        this["SavedText" WhichToolTip] := Text
        this["SavedOptions" WhichToolTip] := O.Checksum
        this["SavedX" WhichToolTip] := X
        this["SavedY" WhichToolTip] := Y
        this["SavedW" WhichToolTip] := W
        this["SavedH" WhichToolTip] := H
        this["SavedTargetHWND" WhichToolTip] := O.TargetHWND
        this["SavedCoordMode" WhichToolTip] := O.CoordMode
        this["SavedTransparent" WhichToolTip] := O.Transparent
    }

    ; 优化后的文本到图形转换 - 减少缓存，及时释放资源
    _TextToGraphics(pGraphics, Text, Options, Measure := 0) {
        static Styles := "Regular|Bold|Italic|BoldItalic|Underline|Strikeout"

        ; 简化字体样式计算，不使用静态缓存
        Style := 0
        for eachStyle, valStyle in StrSplit(Styles, "|") {
            if InStr(Options.FontStyle, valStyle)
                Style |= (valStyle != "StrikeOut") ? (A_Index - 1) : 8
        }

        ; 字体处理（减少缓存）
        hFontFamily := this._GetFontFamily(Options.Font)
        if (!hFontFamily)
            hFontFamily := Gdip_FontFamilyCreateGeneric(1)

        hFont := Gdip_FontCreate(hFontFamily, Options.FontSize * Options.DPIScale, Style)
        hStringFormat := Gdip_StringFormatGetGeneric(1)

        ; 文本画刷
        pBrush := this._CreateTextBrush(Options)

        ; 参数检查
        if !(hFontFamily && hFont && hStringFormat && pBrush && pGraphics) {
            this._CleanupTextResources(pBrush, hStringFormat, hFont, hFontFamily)
            return !pGraphics ? -2 : !hFontFamily ? -3 : !hFont ? -4 : !hStringFormat ? -5 : -6
        }

        ; 设置格式
        this._SetupStringFormat(hStringFormat, Options)
        Gdip_SetTextRenderingHint(pGraphics, Options.FontRender)

        ; 创建矩形并测量/绘制
        CreateRectF(&RC, Options.HasOwnProp("X") ? this.NonNull_Ret(Options.X, 0) : 0,
        Options.HasOwnProp("Y") ? this.NonNull_Ret(Options.Y, 0) : 0,
        Options.Width, Options.Height)

        returnRC := Gdip_MeasureString(pGraphics, Text, hFont, hStringFormat, &RC)

        if (!Measure) {
            Gdip_DrawString(pGraphics, Text, hFont, hStringFormat, pBrush, &RC)
        }

        ; 立即清理资源
        this._CleanupTextResources(pBrush, hStringFormat, hFont, hFontFamily)
        return returnRC
    }

    ; 获取字体族（减少缓存）
    _GetFontFamily(Font) {
        ; 只缓存少量常用字体
        static FontFamilyCache := Map()
        static MaxCacheSize := 5

        if (FontFamilyCache.Has(Font)) {
            return FontFamilyCache[Font]
        }

        hFontFamily := ""
        if (FileExist(Font)) {
            hFontCollection := Gdip_NewPrivateFontCollection()
            hFontFamily := Gdip_CreateFontFamilyFromFile(Font, hFontCollection)
        }

        if (!hFontFamily) {
            hFontFamily := Gdip_FontFamilyCreate(Font)
        }

        ; 限制缓存大小
        if (FontFamilyCache.Count >= MaxCacheSize) {
            ; 清理最旧的缓存项
            for key in FontFamilyCache {
                FontFamilyCache.Delete(key)
                break
            }
        }

        FontFamilyCache[Font] := hFontFamily
        return hFontFamily
    }

    ; 创建文本画刷
    _CreateTextBrush(Options) {
        if (Options.TCLGA != "" and Options.TCLGM and Options.TCLGS and Options.TCLGE and Options.Width and Options.Height
        ) {
            return this._CreateLinearGrBrush(Options.TCLGA, Options.TCLGM, Options.TCLGS, Options.TCLGE,
                this.NonNull_Ret(Options.HasOwnProp("X") ? Options.X : 0, 0),
                this.NonNull_Ret(Options.HasOwnProp("Y") ? Options.Y : 0, 0),
                Options.Width, Options.Height)
        }
        return Gdip_BrushCreateSolid(Options.TextColor)
    }

    ; 设置字符串格式
    _SetupStringFormat(hStringFormat, Options) {
        TabStops := []
        for k, v in Options.TabStops {
            TabStops.Push(v * Options.DPIScale)
        }
        Gdip_SetStringFormatTabStops(hStringFormat, TabStops)
        Gdip_SetStringFormatAlign(hStringFormat, Options.Align)
    }

    ; 清理文本资源
    _CleanupTextResources(pBrush, hStringFormat, hFont, hFontFamily, hFontCollection := "") {
        if (pBrush)
            Gdip_DeleteBrush(pBrush)
        if (hStringFormat)
            Gdip_DeleteStringFormat(hStringFormat)
        if (hFont)
            Gdip_DeleteFont(hFont)
        if (hFontFamily)
            Gdip_DeleteFontFamily(hFontFamily)
        if (hFontCollection)
            Gdip_DeletePrivateFontCollection(hFontCollection)
    }

    ; 优化后的样式和选项检查 - 减少字符串操作
    _CheckStylesAndOptions(Styles, Options) {
        O := {}

        ; 使用预定义样式或默认值
        if (Styles = "") {
            O := { Border: 1, Rounded: 3, Margin: 5, TabStops: [50], TextColor: 0xff575757, BackgroundColor: 0xffffffff,
                FontSize: 12, FontRender: 5, FontStyle: "", Align: 0, BCLGS: "", BCLGE: "", BCLGA: "", BCLGM: "", TCLGS: "",
                TCLGE: "", TCLGA: "", TCLGM: "", BGCLGS: "", BGCLGE: "", BGCLGA: "", BGCLGM: "", BorderColor: 0xff575757 }
            O.Font := this.ToolTipFontName
        } else {
            ; 高效的属性设置
            O.Border := Styles.HasOwnProp("Border") ? this.NonNull_Ret(Styles.Border, 1, 0, 20) : 1
            O.Rounded := Styles.HasOwnProp("Rounded") ? this.NonNull_Ret(Styles.Rounded, 3, 0, 30) : 3
            O.Margin := Styles.HasOwnProp("Margin") ? this.NonNull_Ret(Styles.Margin, 5, 0, 30) : 5
            O.TabStops := Styles.HasOwnProp("TabStops") ? this.NonNull_Ret(Styles.TabStops, [50], "", "") : [50]
            O.TextColor := Styles.HasOwnProp("TextColor") ? this.NonNull_Ret(Styles.TextColor, 0xff575757, "", "") :
                0xff575757
            O.BackgroundColor := Styles.HasOwnProp("BackgroundColor") ? this.NonNull_Ret(Styles.BackgroundColor,
                0xffffffff, "", "") : 0xffffffff
            O.Font := Styles.HasOwnProp("Font") ? this.NonNull_Ret(Styles.Font, this.ToolTipFontName, "", "") : this.ToolTipFontName
            O.FontSize := Styles.HasOwnProp("FontSize") ? this.NonNull_Ret(Styles.FontSize, 12, "", "") : 12
            O.FontRender := Styles.HasOwnProp("FontRender") ? this.NonNull_Ret(Styles.FontRender, 5, 0, 5) : 5
            O.FontStyle := Styles.HasOwnProp("FontStyle") ? Styles.FontStyle : ""
            O.Align := Styles.HasOwnProp("Align") ? Styles.Align : 0

            ; 渐变属性（使用简化的属性名）
            O.BCLGS := Styles.HasOwnProp("BorderColorLinearGradientStart") ? Styles.BorderColorLinearGradientStart : ""
            O.BCLGE := Styles.HasOwnProp("BorderColorLinearGradientEnd") ? Styles.BorderColorLinearGradientEnd : ""
            O.BCLGA := Styles.HasOwnProp("BorderColorLinearGradientAngle") ? Styles.BorderColorLinearGradientAngle : ""
            O.BCLGM := Styles.HasOwnProp("BorderColorLinearGradientMode") ? this.NonNull_Ret(Styles.BorderColorLinearGradientMode,
                "", 1, 8) : ""

            O.TCLGS := Styles.HasOwnProp("TextColorLinearGradientStart") ? Styles.TextColorLinearGradientStart : ""
            O.TCLGE := Styles.HasOwnProp("TextColorLinearGradientEnd") ? Styles.TextColorLinearGradientEnd : ""
            O.TCLGA := Styles.HasOwnProp("TextColorLinearGradientAngle") ? Styles.TextColorLinearGradientAngle : ""
            O.TCLGM := Styles.HasOwnProp("TextColorLinearGradientMode") ? this.NonNull_Ret(Styles.TextColorLinearGradientMode,
                "", 1, 8) : ""

            O.BGCLGS := Styles.HasOwnProp("BackgroundColorLinearGradientStart") ? Styles.BackgroundColorLinearGradientStart :
                ""
            O.BGCLGE := Styles.HasOwnProp("BackgroundColorLinearGradientEnd") ? Styles.BackgroundColorLinearGradientEnd :
                ""
            O.BGCLGA := Styles.HasOwnProp("BackgroundColorLinearGradientAngle") ? Styles.BackgroundColorLinearGradientAngle :
                ""
            O.BGCLGM := Styles.HasOwnProp("BackgroundColorLinearGradientMode") ? this.NonNull_Ret(Styles.BackgroundColorLinearGradientMode,
                "", 1, 8) : ""

            ; 边框颜色计算
            BlendedColor2 := (O.TCLGS and O.TCLGE) ? O.TCLGS : O.TextColor
            BlendedColor := ((O.BackgroundColor >> 24) << 24) + (BlendedColor2 & 0xffffff)
            O.BorderColor := Styles.HasOwnProp("BorderColor") ? this.NonNull_Ret(Styles.BorderColor, BlendedColor, "",
                "") : BlendedColor
        }

        ; 选项处理
        if (Options = "") {
            O.TargetHWND := WinExist("A")
            O.CoordMode := A_CoordModeToolTip
            O.Transparent := 255
            O.MouseNeverCoverToolTip := 1
            O.DistanceBetweenMouseXAndToolTip := 16
            O.DistanceBetweenMouseYAndToolTip := 16
            O.JustCalculateSize := ""
        } else {
            O.TargetHWND := Options.HasOwnProp("TargetHWND") ? this.NonNull_Ret(Options.TargetHWND, WinExist("A"), "",
            "") : WinExist("A")
            O.CoordMode := Options.HasOwnProp("CoordMode") ? this.NonNull_Ret(Options.CoordMode, A_CoordModeToolTip, "",
                "") : A_CoordModeToolTip
            O.Transparent := Options.HasOwnProp("Transparent") ? this.NonNull_Ret(Options.Transparent, 255, 0, 255) :
                255
            O.MouseNeverCoverToolTip := Options.HasOwnProp("MouseNeverCoverToolTip") ? this.NonNull_Ret(Options.MouseNeverCoverToolTip,
                1, 0, 1) : 1
            O.DistanceBetweenMouseXAndToolTip := Options.HasOwnProp("DistanceBetweenMouseXAndToolTip") ? this.NonNull_Ret(
                Options.DistanceBetweenMouseXAndToolTip, 16, "", "") : 16
            O.DistanceBetweenMouseYAndToolTip := Options.HasOwnProp("DistanceBetweenMouseYAndToolTip") ? this.NonNull_Ret(
                Options.DistanceBetweenMouseYAndToolTip, 16, "", "") : 16
            O.JustCalculateSize := Options.HasOwnProp("JustCalculateSize") ? Options.JustCalculateSize : ""
        }

        ; 优化校验和生成 - 使用更高效的方法
        O.Checksum := O.Border . "|" . O.Rounded . "|" . O.Margin . "|" . O.BorderColor . "|" . O.TextColor . "|" . O.BackgroundColor .
            "|" . O.Font . "|" . O.FontSize . "|" . O.FontRender . "|" . O.FontStyle

        return O
    }

    ; 按需获取DPI信息
    _GetDPIScale(hMonitor) {
        if (this._cachedDPI.Has(hMonitor)) {
            return this._cachedDPI[hMonitor]
        }

        osv := StrSplit(A_OSVersion, ".")
        isWin8Plus := !(osv[1] < 6 || (osv[1] == 6 && osv[2] < 3))

        if (isWin8Plus) {
            DllCall("Shcore.dll\GetDpiForMonitor", "Ptr", hMonitor, "Int", 0, "UIntP", &dpiX := 0, "UIntP", &dpiY := 0,
                "UInt")
        } else {
            monitorInfo := this.Monitors[hMonitor]
            hDC := DllCall("Gdi32.dll\CreateDC", "Str", monitorInfo.name, "Ptr", 0, "Ptr", 0, "Ptr", 0, "Ptr")
            dpiX := DllCall("Gdi32.dll\GetDeviceCaps", "Ptr", hDC, "Int", 88)
            DllCall("Gdi32.dll\DeleteDC", "Ptr", hDC)
        }

        dpiScale := this.NonNull_Ret(dpiX, A_ScreenDPI) / 96

        ; 限制缓存大小
        if (this._cachedDPI.Count >= 10) {
            ; 清理一个旧的缓存项
            for key in this._cachedDPI {
                this._cachedDPI.Delete(key)
                break
            }
        }

        this._cachedDPI[hMonitor] := dpiScale
        return dpiScale
    }

    ; 优化后的显示位置计算
    _CalculateDisplayPosition(&X, &Y, W, H, Options, GetTargetSize := 0) {
        Point := Buffer(8, 0)
        DllCall("GetCursorPos", "Ptr", Point.Ptr, "Int")
        MouseX := NumGet(Point, 0, "Int")
        MouseY := NumGet(Point, 4, "Int")

        ; 根据坐标模式计算显示位置
        if (X = "" and Y = "") {
            DisplayX := MouseX
            DisplayY := MouseY
            hMonitor := MDMF_FromPoint(&DisplayX, &DisplayY, 2)

            try {
                TargetLeft := this.Monitors[hMonitor].Left
            } catch {
                this._InitializeMonitors()  ; 重新初始化显示器信息
                TargetLeft := this.Monitors[hMonitor].Left
            }

            TargetTop := this.Monitors[hMonitor].Top
            TargetRight := this.Monitors[hMonitor].Right
            TargetBottom := this.Monitors[hMonitor].Bottom
            TargetWidth := TargetRight - TargetLeft
            TargetHeight := TargetBottom - TargetTop
            Options.DPIScale := this._GetDPIScale(hMonitor)
        } else {
            ; 其他坐标模式的处理（简化版）
            this._HandleOtherCoordModes(&X, &Y, Options, MouseX, MouseY, &DisplayX, &DisplayY, &TargetLeft, &TargetTop, &
                TargetWidth, &TargetHeight, &TargetRight, &TargetBottom)
        }

        if (GetTargetSize = 1) {
            return { X: TargetLeft, Y: TargetTop, W: Min(TargetWidth, this.DIBWidth), H: Min(TargetHeight, this.DIBHeight
            ) }
        }

        ; 位置调整和边界检查
        DPIScale := Options.DPIScale
        DisplayX := (X = "") ? DisplayX + Options.DistanceBetweenMouseXAndToolTip * DPIScale : DisplayX
        DisplayY := (Y = "") ? DisplayY + Options.DistanceBetweenMouseYAndToolTip * DPIScale : DisplayY

        ; 边界限制
        DisplayX := (DisplayX + W >= TargetRight) ? TargetRight - W : DisplayX
        DisplayY := (DisplayY + H >= TargetBottom) ? TargetBottom - H : DisplayY
        DisplayX := (DisplayX < TargetLeft) ? TargetLeft : DisplayX
        DisplayY := (DisplayY < TargetTop) ? TargetTop : DisplayY

        ; 鼠标遮挡处理
        if (Options.MouseNeverCoverToolTip = 1 and (X = "" or Y = "")
        and MouseX >= DisplayX and MouseY >= DisplayY and MouseX <= DisplayX + W and MouseY <= DisplayY + H) {
            DisplayY := MouseY - H - 16 >= TargetTop ? MouseY - H - 16 : MouseY + H + 16 <= TargetBottom ? MouseY + 16 :
                DisplayY
        }

        X := DisplayX
        Y := DisplayY
    }

    ; 处理其他坐标模式
    _HandleOtherCoordModes(&X, &Y, Options, MouseX, MouseY, &DisplayX, &DisplayY, &TargetLeft, &TargetTop, &TargetWidth, &
        TargetHeight, &TargetRight, &TargetBottom) {
        if (Options.CoordMode = "Window" or Options.CoordMode = "Relative") {
            WinGetPos(&WinX, &WinY, &WinW, &WinH, "ahk_id " Options.TargetHWND)
            XInScreen := WinX + X
            YInScreen := WinY + Y
            TargetLeft := WinX
            TargetTop := WinY
            TargetWidth := WinW
            TargetHeight := WinH
            TargetRight := WinX + WinW
            TargetBottom := WinY + WinH
            DisplayX := (X = "") ? MouseX : XInScreen
            DisplayY := (Y = "") ? MouseY : YInScreen
        } else if (Options.CoordMode = "Client") {
            ClientArea := Buffer(16, 0)
            DllCall("GetClientRect", "Ptr", Options.TargetHWND, "Ptr", ClientArea.Ptr)
            DllCall("ClientToScreen", "Ptr", Options.TargetHWND, "Ptr", ClientArea.Ptr)
            ClientX := NumGet(ClientArea, 0, "Int")
            ClientY := NumGet(ClientArea, 4, "Int")
            ClientW := NumGet(ClientArea, 8, "Int")
            ClientH := NumGet(ClientArea, 12, "Int")

            XInScreen := ClientX + (X ? X : 0)
            YInScreen := ClientY + (Y ? Y : 0)
            TargetLeft := ClientX
            TargetTop := ClientY
            TargetWidth := ClientW
            TargetHeight := ClientH
            TargetRight := ClientX + ClientW
            TargetBottom := ClientY + ClientH
            DisplayX := (X = "") ? MouseX : XInScreen
            DisplayY := (Y = "") ? MouseY : YInScreen
        } else {
            DisplayX := (X = "") ? MouseX : X
            DisplayY := (Y = "") ? MouseY : Y
            hMonitor := MDMF_FromPoint(&DisplayX, &DisplayY, 2)
            TargetLeft := this.Monitors[hMonitor].Left
            TargetTop := this.Monitors[hMonitor].Top
            TargetRight := this.Monitors[hMonitor].Right
            TargetBottom := this.Monitors[hMonitor].Bottom
            TargetWidth := TargetRight - TargetLeft
            TargetHeight := TargetBottom - TargetTop
        }

        hMonitor := MDMF_FromPoint(&DisplayX, &DisplayY, 2)
        Options.DPIScale := this._GetDPIScale(hMonitor)
    }

    ; 创建线性渐变画刷（优化版）
    _CreateLinearGrBrush(Angle, Mode, StartColor, EndColor, x, y, w, h) {
        switch Mode {
            case 1, 3, 5, 7: pBrush := Gdip_CreateLinearGrBrush(x, y, x + w, y, StartColor, EndColor)
            case 2, 4, 6, 8: pBrush := Gdip_CreateLinearGrBrush(x, y + h // 2, x + w, y + h // 2, StartColor, EndColor)
        }

        switch Mode {
            case 1, 2: Gdip_RotateLinearGrBrushTransform(pBrush, Angle, 0)
            case 3, 4: Gdip_RotateLinearGrBrushTransform(pBrush, Angle, 1)
            case 5, 6: Gdip_RotateLinearGrBrushAtCenter(pBrush, Angle, 0)
            case 7, 8: Gdip_RotateLinearGrBrushAtCenter(pBrush, Angle, 1)
        }

        return pBrush
    }

    ; 字体相关函数（优化版）
    Fnt_GetTooltipFontName() {
        static LF_FACESIZE := 32
        return StrGet(this.Fnt_GetNonClientMetrics().Ptr + 316 + 28, LF_FACESIZE)
    }

    Fnt_GetNonClientMetrics() {
        static SPI_GETNONCLIENTMETRICS := 0x29

        cbSize := 500
        if (((GV := DllCall("GetVersion")) & 0xFF . "." . GV >> 8 & 0xFF) >= 6.0) {
            cbSize += 4
        }

        NONCLIENTMETRICS := Buffer(cbSize, 0)
        NumPut("UInt", cbSize, NONCLIENTMETRICS, 0)

        if (!DllCall("SystemParametersInfo", "UInt", SPI_GETNONCLIENTMETRICS, "UInt", cbSize, "Ptr", NONCLIENTMETRICS.Ptr,
            "UInt", 0)) {
            return false
        }

        return NONCLIENTMETRICS
    }

    ; 工具函数（优化版）
    NonNull(&var, DefaultValue, MinValue := "", MaxValue := "") {
        var := var = "" ? DefaultValue : MinValue = "" ? (MaxValue = "" ? var : Min(var, MaxValue)) : (MaxValue != "" ?
            Max(Min(var, MaxValue), MinValue) : Max(var, MinValue))
    }

    NonNull_Ret(var, DefaultValue, MinValue := "", MaxValue := "") {
        return var = "" ? DefaultValue : MinValue = "" ? (MaxValue = "" ? var : Min(var, MaxValue)) : (MaxValue != "" ?
            Max(Min(var, MaxValue), MinValue) : Max(var, MinValue))
    }

    ; 内存清理函数 - 定期清理不活跃的GUI
    CleanupInactiveGUIs(maxIdleTime := 30000) {  ; 30秒不活跃则清理
        currentTime := A_TickCount
        toRemove := []

        for key, guiObj in this._activeGUIs {
            if (currentTime - guiObj.lastUsed > maxIdleTime) {
                toRemove.Push(key)
            }
        }

        for key in toRemove {
            this._ReleaseGUI(key)
        }
    }

    ; 强制垃圾回收
    ForceGarbageCollection() {
        ; 清理所有非活跃GUI
        this.CleanupInactiveGUIs(0)

        ; 清理字体缓存
        if (this.HasOwnProp("_fontFamilyCache")) {
            this._fontFamilyCache.Clear()
        }

        ; 清理DPI缓存（保留主显示器）
        primaryMonitor := this.Monitors["Primary"]
        primaryDPI := this._cachedDPI.Has(primaryMonitor) ? this._cachedDPI[primaryMonitor] : ""
        this._cachedDPI.Clear()
        if (primaryDPI != "") {
            this._cachedDPI[primaryMonitor] := primaryDPI
        }
    }
}
;===================================================================================
; 预定义样式 - 轻量版
;===================================================================================

; 经典暗色样式 - 黑底白字，蓝色边框
OwnzztooltipStyle1 := {
    Border: 1,
    Rounded: 2,
    Margin: 8,
    BorderColor: 0xff3881a7,
    FontSize: 16,
    TextColor: 0xFFFFFFFF,
    BackgroundColor: 0xFF000000,
    FontStyle: "Regular",
    Align: 0
}

; 半透明暗色样式 - 灰黑底白字
OwnzztooltipStyle2 := {
    Border: 1,
    Rounded: 8,
    TextColor: 0xfff4f4f4,
    BackgroundColor: 0xaa3e3d45,
    FontSize: 14
}

; 现代暗色样式 - 深灰底，白字
OwnzztooltipStyle3 := {
    Border: 2,
    Rounded: 10,
    Margin: 10,
    BorderColor: 0xff6a11cb,
    FontSize: 14,
    TextColor: 0xFFFFFFFF,
    BackgroundColor: 0xFF222222,
    FontStyle: "Bold",
    Align: 1
}

; 简约亮色样式 - 白底黑字，细边框
OwnzztooltipStyle4 := {
    Border: 1,
    Rounded: 6,
    Margin: 8,
    BorderColor: 0xFFCCCCCC,
    FontSize: 13,
    TextColor: 0xFF333333,
    BackgroundColor: 0xFFF8F8F8,
    FontStyle: "Regular",
    Align: 0
}

; 柔和亮色样式 - 浅蓝底，深蓝字
OwnzztooltipStyle5 := {
    Border: 2,
    Rounded: 12,
    Margin: 10,
    BorderColor: 0xFF4DA0FF,
    FontSize: 14,
    TextColor: 0xFF003366,
    BackgroundColor: 0xFFE6F4FF,
    FontStyle: "Bold",
    Align: 1
}

;================================GDIP================================================
; 保持必要的GDIP函数，但移除了一些不常用的功能以减少内存占用

Gdip_Startup() {
    DllCall("LoadLibrary", "str", "gdiplus")
    si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
    NumPut("UInt", 1, si)
    DllCall("gdiplus\GdiplusStartup", "UPtr*", &pToken := 0, "UPtr", si.Ptr, "UPtr", 0)
    if (!pToken) {
        throw Error("Gdiplus failed to start. Please ensure you have gdiplus on your system")
    }
    return pToken
}

MDMF_Enum(HMON := "") {
    static EnumProc := CallbackCreate(MDMF_EnumProc)
    static Obj := "Map"
    static Monitors := {}
    if (HMON = "") {
        Monitors := %Obj%("TotalCount", 0)
        if !DllCall("User32.dll\EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", EnumProc, "Ptr", ObjPtr(Monitors),
        "Int")
            return False
    }
    return (HMON = "") ? Monitors : Monitors.Has(HMON) ? Monitors[HMON] : False
}

CreateDIBSection(w, h, hdc := "", bpp := 32, &ppvBits := 0) {
    hdc2 := hdc ? hdc : GetDC()
    bi := Buffer(40, 0)
    NumPut("UInt", w, bi, 4), NumPut("UInt", h, bi, 8), NumPut("UInt", 40, bi, 0)
    NumPut("ushort", 1, bi, 12), NumPut("uInt", 0, bi, 16), NumPut("ushort", bpp, bi, 14)
    hbm := DllCall("CreateDIBSection", "UPtr", hdc2, "UPtr", bi.Ptr, "UInt", 0, "UPtr*", &ppvBits, "UPtr", 0, "UInt", 0,
        "UPtr")
    if (!hdc)
        ReleaseDC(hdc2)
    return hbm
}

CreateCompatibleDC(hdc := 0) => DllCall("CreateCompatibleDC", "UPtr", hdc)
Gdip_GraphicsFromHDC(hdc) => (DllCall("gdiplus\GdipCreateFromHDC", "UPtr", hdc, "UPtr*", &pGraphics := 0), pGraphics)
Gdip_SetSmoothingMode(pGraphics, SmoothingMode) => !pGraphics ? 2 : DllCall("gdiplus\GdipSetSmoothingMode", "UPtr",
    pGraphics, "Int", SmoothingMode)
Gdip_SetPixelOffsetMode(graphics, pixelOffsetMode) => DllCall('Gdiplus\GdipSetPixelOffsetMode', 'ptr', graphics, 'ptr',
    pixelOffsetMode, 'uint')
SelectObject(hdc, hgdiobj) => DllCall("SelectObject", "UPtr", hdc, "UPtr", hgdiobj)
Gdip_DeleteGraphics(pGraphics) => DllCall("gdiplus\GdipDeleteGraphics", "UPtr", pGraphics)
DeleteObject(hObject) => DllCall("DeleteObject", "UPtr", hObject)
DeleteDC(hdc) => DllCall("DeleteDC", "UPtr", hdc)
Gdip_Shutdown(pToken) => (DllCall("gdiplus\GdiplusShutdown", "UPtr", pToken), (hModule := DllCall("GetModuleHandle",
    "str", "gdiplus", "UPtr")) ? DllCall("FreeLibrary", "UPtr", hModule) : 0, 0)
Gdip_GraphicsClear(pGraphics, ARGB := 0x00ffffff) => !pGraphics ? 2 : DllCall("gdiplus\GdipGraphicsClear", "UPtr",
    pGraphics, "Int", ARGB)

UpdateLayeredWindow(hwnd, hdc, x := "", y := "", w := "", h := "", Alpha := 255) {
    if ((x != "") && (y != ""))
        pt := Buffer(8), NumPut("UInt", x, pt, 0), NumPut("UInt", y, pt, 4)
    if (w = "") || (h = "") {
        CreateRect(&winRect := "", 0, 0, 0, 0)
        DllCall("GetWindowRect", "UPtr", hwnd, "UPtr", winRect.Ptr)
        w := NumGet(winRect, 8, "UInt") - NumGet(winRect, 0, "UInt")
        h := NumGet(winRect, 12, "UInt") - NumGet(winRect, 4, "UInt")
    }
    return DllCall("UpdateLayeredWindow", "UPtr", hwnd, "UPtr", 0, "UPtr", ((x = "") && (y = "")) ? 0 : pt.Ptr,
    "Int64*", w | h << 32, "UPtr", hdc, "Int64*", 0, "UInt", 0, "UInt*", Alpha << 16 | 1 << 24, "UInt", 2)
}

Gdip_BrushCreateSolid(ARGB := 0xff000000) => (DllCall("gdiplus\GdipCreateSolidFill", "UInt", ARGB, "UPtr*", &pBrush :=
    0), pBrush)
Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h) => DllCall("gdiplus\GdipFillRectangle", "UPtr", pGraphics, "UPtr",
    pBrush, "Float", x, "Float", y, "Float", w, "Float", h)

Gdip_FillRoundedRectanglePath(pGraphics, pBrush, X, Y, W, H, R) {
    DllCall("Gdiplus.dll\GdipCreatePath", "UInt", 0, "PtrP", &pPath := 0)
    D := (R * 2), W -= D, H -= D
    DllCall("Gdiplus.dll\GdipAddPathArc", "Ptr", pPath, "Float", X, "Float", Y, "Float", D, "Float", D, "Float", 180,
        "Float", 90)
    DllCall("Gdiplus.dll\GdipAddPathArc", "Ptr", pPath, "Float", X + W, "Float", Y, "Float", D, "Float", D, "Float",
        270, "Float", 90)
    DllCall("Gdiplus.dll\GdipAddPathArc", "Ptr", pPath, "Float", X + W, "Float", Y + H, "Float", D, "Float", D, "Float",
        0, "Float", 90)
    DllCall("Gdiplus.dll\GdipAddPathArc", "Ptr", pPath, "Float", X, "Float", Y + H, "Float", D, "Float", D, "Float", 90,
        "Float", 90)
    DllCall("Gdiplus.dll\GdipClosePathFigure", "Ptr", pPath)
    RS := DllCall("Gdiplus.dll\GdipFillPath", "Ptr", pGraphics, "Ptr", pBrush, "Ptr", pPath)
    DllCall("Gdiplus.dll\GdipDeletePath", "Ptr", pPath)
    return RS
}

Gdip_DeleteBrush(pBrush) => DllCall("gdiplus\GdipDeleteBrush", "UPtr", pBrush)
Gdip_NewPrivateFontCollection(fontCollection := 0) => DllCall('Gdiplus\GdipNewPrivateFontCollection', 'ptr',
    fontCollection, 'uint')

Gdip_CreateFontFamilyFromFile(FontFile, hFontCollection, FontName := "") {
    if !hFontCollection
        return
    E := DllCall("gdiplus\GdipPrivateAddFontFile", "ptr", hFontCollection, "str", FontFile)
    if (FontName = "" && !E) {
        pFontFamily := Buffer(10, 0)
        DllCall("gdiplus\GdipGetFontCollectionFamilyList", "ptr", hFontCollection, "int", 1, "ptr", pFontFamily.Ptr,
            "int*", &found := 0)
        FontName := Buffer(100, 0)
        DllCall("gdiplus\GdipGetFamilyName", "ptr", NumGet(pFontFamily, 0, "ptr"), "str", FontName, "ushort", 1033)
    }
    if !E
        DllCall("gdiplus\GdipCreateFontFamilyFromName", "str", FontName, "ptr", hFontCollection, "uint*", &hFontFamily :=
            0)
    return hFontFamily
}

Gdip_FontFamilyCreate(Font) => (DllCall("gdiplus\GdipCreateFontFamilyFromName", "UPtr", StrPtr(Font), "UInt", 0,
"UPtr*", &hFamily := 0), hFamily)
Gdip_FontFamilyCreateGeneric(whichStyle) {
    if (whichStyle = 0)
        DllCall("gdiplus\GdipGetGenericFontFamilyMonospace", "UPtr*", &hFontFamily := 0)
    else if (whichStyle = 1)
        DllCall("gdiplus\GdipGetGenericFontFamilySansSerif", "UPtr*", &hFontFamily := 0)
    else if (whichStyle = 2)
        DllCall("gdiplus\GdipGetGenericFontFamilySerif", "UPtr*", &hFontFamily := 0)
    return hFontFamily
}

Gdip_FontCreate(hFamily, Size, Style := 0) => (DllCall("gdiplus\GdipCreateFont", "UPtr", hFamily, "Float", Size, "Int",
    Style, "Int", 0, "UPtr*", &hFont := 0), hFont)
Gdip_StringFormatGetGeneric(whichFormat := 0) {
    if (whichFormat = 1)
        DllCall("gdiplus\GdipStringFormatGetGenericTypographic", "UPtr*", &hStringFormat := 0)
    else
        DllCall("gdiplus\GdipStringFormatGetGenericDefault", "UPtr*", &hStringFormat := 0)
    return hStringFormat
}

Gdip_DeleteStringFormat(hFormat) => DllCall("gdiplus\GdipDeleteStringFormat", "UPtr", hFormat)
Gdip_DeleteFont(hFont) => DllCall("gdiplus\GdipDeleteFont", "UPtr", hFont)
Gdip_DeleteFontFamily(hFamily) => DllCall("gdiplus\GdipDeleteFontFamily", "UPtr", hFamily)
Gdip_DeletePrivateFontCollection(fontCollection) => DllCall('Gdiplus\GdipDeletePrivateFontCollection', 'ptr',
    fontCollection, 'uint')

Gdip_SetStringFormatTabStops(format, tabStops) {
    firstTabOffset := 0
    count := tabStops.Length
    buf := Buffer(4 * count), p := buf.Ptr
    loop count
        p := NumPut('Float', tabStops[A_index], p)
    return DllCall('Gdiplus\GdipSetStringFormatTabStops', 'ptr', format, 'int', firstTabOffset, 'int', count, 'ptr',
        buf, 'uint')
}

Gdip_SetStringFormatAlign(hFormat, Align) => DllCall("gdiplus\GdipSetStringFormatAlign", "UPtr", hFormat, "Int", Align)
Gdip_SetTextRenderingHint(pGraphics, RenderingHint) => !pGraphics ? 2 : DllCall("gdiplus\GdipSetTextRenderingHint",
    "UPtr", pGraphics, "Int", RenderingHint)

CreateRectF(&RectF, x, y, w, h) {
    RectF := Buffer(16)
    NumPut("Float", x, RectF, 0), NumPut("Float", y, RectF, 4), NumPut("Float", w, RectF, 8), NumPut("Float", h, RectF,
        12)
}

Gdip_MeasureString(pGraphics, sString, hFont, hFormat, &RectF) {
    RC := Buffer(16)
    DllCall("gdiplus\GdipMeasureString", "UPtr", pGraphics, "UPtr", StrPtr(sString), "Int", -1, "UPtr", hFont, "UPtr",
    RectF.Ptr, "UPtr", hFormat, "UPtr", RC.Ptr, "uint*", &Chars := 0, "uint*", &Lines := 0)
    return RC.Ptr ? NumGet(RC, 0, "Float") "|" NumGet(RC, 4, "Float") "|" NumGet(RC, 8, "Float") "|" NumGet(RC, 12,
        "Float") "|" Chars "|" Lines : 0
}

Gdip_DrawString(pGraphics, sString, hFont, hFormat, pBrush, &RectF) => DllCall("gdiplus\GdipDrawString", "UPtr",
    pGraphics, "UPtr", StrPtr(sString), "Int", -1, "UPtr", hFont, "UPtr", RectF.Ptr, "UPtr", hFormat, "UPtr", pBrush)

Gdip_CreateLinearGrBrush(x1, y1, x2, y2, ARGB1, ARGB2, WrapMode := 1) {
    CreatePointF(&PointF1, x1, y1)
    CreatePointF(&PointF2, x2, y2)
    DllCall("gdiplus\GdipCreateLineBrush", "UPtr", PointF1.Ptr, "UPtr", PointF2.Ptr, "Uint", ARGB1, "Uint", ARGB2,
        "int", WrapMode, "UPtr*", &pLinearGradientBrush := 0)
    return pLinearGradientBrush
}

Gdip_RotateLinearGrBrushTransform(pLinearGradientBrush, Angle, matrixOrder := 0) => DllCall(
    "gdiplus\GdipRotateLineTransform", "UPtr", pLinearGradientBrush, "float", Angle, "int", matrixOrder)

Gdip_RotateLinearGrBrushAtCenter(pLinearGradientBrush, Angle, MatrixOrder := 1) {
    Rect := Gdip_GetLinearGrBrushRect(pLinearGradientBrush)
    cX := Rect.x + (Rect.w / 2)
    cY := Rect.y + (Rect.h / 2)
    pMatrix := Gdip_CreateMatrix()
    Gdip_TranslateMatrix(pMatrix, -cX, -cY)
    Gdip_RotateMatrix(pMatrix, Angle, MatrixOrder)
    Gdip_TranslateMatrix(pMatrix, cX, cY, MatrixOrder)
    E := Gdip_SetLinearGrBrushTransform(pLinearGradientBrush, pMatrix)
    Gdip_DeleteMatrix(pMatrix)
    return E
}

MDMF_FromPoint(&X := "", &Y := "", Flag := 0) {
    if (X = "") || (Y = "") {
        PT := Buffer(8, 0)
        DllCall("User32.dll\GetCursorPos", "Ptr", PT.Ptr, "Int")
        if (X = "")
            X := NumGet(PT, 0, "Int")
        if (Y = "")
            Y := NumGet(PT, 4, "Int")
    }
    return DllCall("User32.dll\MonitorFromPoint", "Int64", (X & 0xFFFFFFFF) | (Y << 32), "UInt", Flag, "Ptr")
}

GetDC(hwnd := 0) => DllCall("GetDC", "UPtr", hwnd)
ReleaseDC(hdc, hwnd := 0) => DllCall("ReleaseDC", "UPtr", hwnd, "UPtr", hdc)
CreatePointF(&PointF, x, y) => (PointF := Buffer(8), NumPut("Float", x, PointF, 0), NumPut("Float", y, PointF, 4))

Gdip_GetLinearGrBrushRect(pLinearGradientBrush) {
    RectF := Buffer(16, 0)
    E := DllCall("gdiplus\GdipGetLineRect", "UPtr", pLinearGradientBrush, "UPtr", RectF.Ptr)
    if (!E) {
        rData := Object()
        rData.x := NumGet(RectF, 0, "float")
        rData.y := NumGet(RectF, 4, "float")
        rData.w := NumGet(RectF, 8, "float")
        rData.h := NumGet(RectF, 12, "float")
        return rData
    } else {
        return E
    }
}

Gdip_CreateMatrix() => (DllCall("gdiplus\GdipCreateMatrix", "UPtr*", &Matrix := 0), Matrix)
Gdip_TranslateMatrix(matrix, offsetX, offsetY, order := 0) => DllCall('Gdiplus\GdipTranslateMatrix', 'ptr', matrix,
    'int', offsetX, 'int', offsetY, 'uint', order, 'uint')
Gdip_RotateMatrix(matrix, angle, order := 0) => DllCall('Gdiplus\GdipRotateMatrix', 'ptr', matrix, 'int', angle, 'uint',
    order, 'uint')
Gdip_SetLinearGrBrushTransform(pLinearGradientBrush, pMatrix) => DllCall("gdiplus\GdipSetLineTransform", "UPtr",
    pLinearGradientBrush, "UPtr", pMatrix)
Gdip_DeleteMatrix(Matrix) => DllCall("gdiplus\GdipDeleteMatrix", "UPtr", Matrix)

MDMF_EnumProc(HMON, HDC, PRECT, ObjectAddr) {
    Monitors := objfromptraddref(ObjectAddr)
    Monitors[HMON] := MDMF_GetInfo(HMON)
    Monitors["TotalCount"]++
    if (Monitors[HMON].Primary) {
        Monitors["Primary"] := HMON
    }
    return true
}

MDMF_GetInfo(HMON) {
    MIEX := Buffer(40 + (32 << !!1))
    NumPut("UInt", MIEX.Size, MIEX, 0)
    if DllCall("User32.dll\GetMonitorInfo", "Ptr", HMON, "Ptr", MIEX.Ptr, "Int") {
        return { Name: (Name := StrGet(MIEX.Ptr + 40, 32)),
            Num: RegExReplace(Name, ".*(\d+)$", "$1"),
            Left: NumGet(MIEX, 4, "Int"),
            Top: NumGet(MIEX, 8, "Int"),
            Right: NumGet(MIEX, 12, "Int"),
            Bottom: NumGet(MIEX, 16, "Int"),
            WALeft: NumGet(MIEX, 20, "Int"),
            WATop: NumGet(MIEX, 24, "Int"),
            WARight: NumGet(MIEX, 28, "Int"),
            WABottom: NumGet(MIEX, 32, "Int"),
            Primary: NumGet(MIEX, 36, "UInt") }
    }
    return False
}

CreateRect(&Rect, x, y, w, h) => (Rect := Buffer(16), NumPut("UInt", x, Rect, 0), NumPut("UInt", y, Rect, 4), NumPut(
    "UInt", w, Rect, 8), NumPut("UInt", h, Rect, 12))

;===================================================================================
; 自动消失提示函数 - 轻量版
;===================================================================================

/**
 * 显示一个自动消失的提示
 * @param {String} Text - 提示文本
 * @param {Number} Timeout - 自动消失时间(毫秒)，默认3000毫秒(3秒)
 * @param {Number|String} X - X坐标，留空则跟随鼠标
 * @param {Number|String} Y - Y坐标，留空则跟随鼠标
 * @param {Number} WhichToolTip - 使用第几个提示框(1-20)
 * @param {Object} Style - 样式设置
 * @param {Object} Options - 选项设置
 * @returns {Object} 包含提示框信息的对象
 */
bttAutoHide(Text, Timeout := 3000, X := "", Y := "", WhichToolTip := 1, Style := "", Options := "") {
    ; 显示提示
    result := btt(Text, X, Y, WhichToolTip, Style, Options)

    ; 设置定时器自动关闭提示
    SetTimer(() => btt("", , , WhichToolTip), -Timeout)

    return result
}

/**
 * 显示一个自动消失的提示(简化版)
 * @param {String} Text - 提示文本
 * @returns {Void}
 */
quickTip(Text) {
    bttAutoHide(Text, 3000)
}

/**
 * 检测系统是否使用暗色主题
 * @returns {Boolean} 如果系统使用暗色主题返回true，否则返回false
 */
isDarkTheme() {
    try {
        AppsUseDarkTheme := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize",
            "AppsUseDarkTheme")
        return AppsUseDarkTheme = 1
    } catch {
        return false
    }
}

/**
 * 根据系统主题显示自动消失的提示
 * @param {String} Text - 提示文本
 * @param {Number} Timeout - 自动消失时间(毫秒)，默认3000毫秒(3秒)
 * @param {Number|String} X - X坐标，留空则跟随鼠标
 * @param {Number|String} Y - Y坐标，留空则跟随鼠标
 * @returns {Object} 包含提示框信息的对象
 */
bttThemeAware(Text, Timeout := 3000, X := "", Y := "") {
    ; 根据系统主题选择样式
    Style := isDarkTheme() ? OwnzztooltipStyle3 : OwnzztooltipStyle5

    ; 显示提示并设置自动消失
    result := btt(Text, X, Y, 1, Style)
    SetTimer(() => btt("", , , 1), -Timeout)

    return result
}

/**
 * 显示一个成功提示(绿色)，自动消失
 * @param {String} Text - 提示文本
 * @param {Number} Timeout - 自动消失时间(毫秒)，默认3000毫秒(3秒)
 */
successTip(Text, Timeout := 3000) {
    ; 成功提示样式 - 绿色
    SuccessStyle := {
        Border: 1,
        Rounded: 8,
        Margin: 10,
        BorderColor: 0xFF4CAF50,
        FontSize: 14,
        TextColor: 0xFFFFFFFF,
        BackgroundColor: 0xFF388E3C,
        FontStyle: "Bold",
        Align: 1
    }

    bttAutoHide(Text, Timeout, "", "", 2, SuccessStyle)
}

/**
 * 显示一个错误提示(红色)，自动消失
 * @param {String} Text - 提示文本
 * @param {Number} Timeout - 自动消失时间(毫秒)，默认3000毫秒(3秒)
 */
errorTip(Text, Timeout := 3000) {
    ; 错误提示样式 - 红色
    ErrorStyle := {
        Border: 1,
        Rounded: 8,
        Margin: 10,
        BorderColor: 0xFFE53935,
        FontSize: 14,
        TextColor: 0xFFFFFFFF,
        BackgroundColor: 0xFFC62828,
        FontStyle: "Bold",
        Align: 1
    }

    bttAutoHide(Text, Timeout, "", "", 3, ErrorStyle)
}

/**
 * 显示一个警告提示(黄色)，自动消失
 * @param {String} Text - 提示文本
 * @param {Number} Timeout - 自动消失时间(毫秒)，默认3000毫秒(3秒)
 */
warningTip(Text, Timeout := 3000) {
    ; 警告提示样式 - 黄色
    WarningStyle := {
        Border: 1,
        Rounded: 8,
        Margin: 10,
        BorderColor: 0xFFFFC107,
        FontSize: 14,
        TextColor: 0xFF212121,
        BackgroundColor: 0xFFFFD54F,
        FontStyle: "Bold",
        Align: 1
    }

    bttAutoHide(Text, Timeout, "", "", 4, WarningStyle)
}

;===================================================================================
; 内存优化工具函数
;===================================================================================

/**
 * 手动触发内存清理
 */
BTTCleanup() {
    static BTT
    if isset(BTT) {
        BTT.ForceGarbageCollection()
    }
}

/**
 * 设置自动内存清理定时器
 * @param {Number} interval - 清理间隔(毫秒)，默认60000毫秒(1分钟)
 */
BTTSetAutoCleanup(interval := 60000) {
    SetTimer(BTTCleanup, interval)
}

/**
 * 停止自动内存清理
 */
BTTStopAutoCleanup() {
    SetTimer(BTTCleanup, 0)
}

;=======================================内存优化版本完成===============================================================
