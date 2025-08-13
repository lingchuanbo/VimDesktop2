; ======================================================================================================================
; ToolTipManager - 统一的ToolTip管理器，支持ToolTipOptions和BTT两种库
; 作者：BoBO
; 时间：20250728
; ======================================================================================================================

class ToolTipManager {
    static currentLibrary := ""
    static isInitialized := false

    ; 初始化ToolTip管理器
    static Init(library := "") {
        if (library = "") {
            ; 从配置文件读取库选择
            try {
                library := INIObject.config.tooltip_library
            } catch {
                library := "ToolTipOptions"  ; 默认使用ToolTipOptions
            }
        }

        this.currentLibrary := library

        ; 根据选择的库进行初始化
        switch library {
            case "ToolTipOptions":
                this._InitToolTipOptions()
            case "BTT":
                this._InitBTT()
            default:
                this.currentLibrary := "ToolTipOptions"
                this._InitToolTipOptions()
        }

        this.isInitialized := true
    }

    ; 初始化ToolTipOptions
    static _InitToolTipOptions() {
        ToolTipOptions.Init()

        ; 应用主题设置
        try {
            currentTheme := INIObject.config.theme_mode
            bgColor := ""
            textColor := ""

            if (currentTheme = "light") {
                bgColor := INIObject.config.tooltip_light_bg_color
                textColor := INIObject.config.tooltip_light_text_color
            } else if (currentTheme = "dark") {
                bgColor := INIObject.config.tooltip_dark_bg_color
                textColor := INIObject.config.tooltip_dark_text_color
            } else {
                ; 跟随系统主题
                try {
                    ; 检测系统是否处于深色模式
                    isDarkMode := RegRead(
                        "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize",
                        "AppsUseLightTheme")
                    if (isDarkMode = 0) {
                        bgColor := INIObject.config.tooltip_dark_bg_color
                        textColor := INIObject.config.tooltip_dark_text_color
                    } else {
                        bgColor := INIObject.config.tooltip_light_bg_color
                        textColor := INIObject.config.tooltip_light_text_color
                    }
                } catch {
                    ; 如果无法读取注册表，默认使用亮色主题
                    bgColor := INIObject.config.tooltip_light_bg_color
                    textColor := INIObject.config.tooltip_light_text_color
                }
            }

            ToolTipOptions.SetColors(bgColor, textColor)

            ; 设置字体
            fontName := INIObject.config.tooltip_font_name
            fontSize := INIObject.config.tooltip_font_size
            ToolTipOptions.SetFont("s" fontSize, fontName)

        } catch {
            ; 使用默认设置
            ToolTipOptions.SetColors("White", "0x381255")
            ToolTipOptions.SetFont("s12", "Microsoft YaHei")
        }
    }

    ; 初始化BTT
    static _InitBTT() {
        ; BTT 会自动初始化，无需特殊处理
        ; 可以在这里设置BTT的默认样式
    }

    ; 显示ToolTip
    static Show(text, x := "", y := "", whichToolTip := 1) {
        if (!this.isInitialized) {
            this.Init()
        }

        ; 处理空字符串参数，转换为unset以使用默认位置
        xParam := (x = "") ? unset : x
        yParam := (y = "") ? unset : y

        switch this.currentLibrary {
            case "ToolTipOptions":
                ; 确保ToolTipOptions已正确初始化和配置
                this._EnsureToolTipOptionsConfigured()
                
                if (x = "" && y = "") {
                    ToolTip(text, , , whichToolTip)
                } else if (x = "") {
                    ToolTip(text, , yParam, whichToolTip)
                } else if (y = "") {
                    ToolTip(text, xParam, , whichToolTip)
                } else {
                    ToolTip(text, xParam, yParam, whichToolTip)
                }
            case "BTT":
                this._ShowBTT(text, x, y, whichToolTip)
        }
    }

    ; 确保ToolTipOptions已正确配置
    static _EnsureToolTipOptionsConfigured() {
        ; 重新应用样式设置，确保每次显示时都有正确的样式
        try {
            currentTheme := INIObject.config.theme_mode
            bgColor := ""
            textColor := ""

            if (currentTheme = "light") {
                bgColor := INIObject.config.tooltip_light_bg_color
                textColor := INIObject.config.tooltip_light_text_color
            } else if (currentTheme = "dark") {
                bgColor := INIObject.config.tooltip_dark_bg_color
                textColor := INIObject.config.tooltip_dark_text_color
            } else {
                ; 跟随系统主题
                try {
                    ; 检测系统是否处于深色模式
                    isDarkMode := RegRead(
                        "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize",
                        "AppsUseLightTheme")
                    if (isDarkMode = 0) {
                        bgColor := INIObject.config.tooltip_dark_bg_color
                        textColor := INIObject.config.tooltip_dark_text_color
                    } else {
                        bgColor := INIObject.config.tooltip_light_bg_color
                        textColor := INIObject.config.tooltip_light_text_color
                    }
                } catch {
                    ; 如果无法读取注册表，默认使用亮色主题
                    bgColor := INIObject.config.tooltip_light_bg_color
                    textColor := INIObject.config.tooltip_light_text_color
                }
            }

            ToolTipOptions.SetColors(bgColor, textColor)

            ; 设置字体
            fontName := INIObject.config.tooltip_font_name
            fontSize := INIObject.config.tooltip_font_size
            ToolTipOptions.SetFont("s" fontSize, fontName)

        } catch {
            ; 使用默认设置
            ToolTipOptions.SetColors("White", "0x381255")
            ToolTipOptions.SetFont("s12", "Microsoft YaHei")
        }
    }

    ; 使用BTT显示ToolTip
    static _ShowBTT(text, x := "", y := "", whichToolTip := 1) {
        ; 获取主题相关的样式
        style := this._GetBTTStyle()

        ; 对于包含制表符的文本，使用等宽字体以确保更好的对齐效果
        if (InStr(text, "`t")) {
            style.Font := "Consolas"  ; 使用等宽字体
        }

        ; BTT使用GDI+绘制，需要更精确地处理制表符对齐
        ; 使用更智能的制表符处理方式
        text := this._ProcessTabAlignment(text, style)

        ; 处理空字符串参数，转换为unset以使用默认位置
        xParam := (x = "") ? unset : x
        yParam := (y = "") ? unset : y

        if (x = "" && y = "") {
            btt(text, , , whichToolTip, style)
        } else if (x = "") {
            btt(text, , yParam, whichToolTip, style)
        } else if (y = "") {
            btt(text, xParam, , whichToolTip, style)
        } else {
            btt(text, xParam, yParam, whichToolTip, style)
        }
    }

    ; 使用BTT显示带超时的ToolTip
    static _ShowBTTWithTimeout(text, x := "", y := "", whichToolTip := 1, timeout := 300) {
        ; 获取主题相关的样式
        style := this._GetBTTStyle()

        ; 使用 bttAutoHide 函数，但需要适配多实例
        if (whichToolTip = 1) {
            ; 对于实例1，可以直接使用 bttAutoHide
            return bttAutoHide(text, timeout, x, y, style)
        } else {
            ; 对于其他实例，使用原来的方法
            this._ShowBTT(text, x, y, whichToolTip)
            SetTimer(() => btt("", , , whichToolTip), -timeout)
        }
    }

    ; 获取BTT样式
    static _GetBTTStyle() {
        style := {}

        try {
            currentTheme := INIObject.config.theme_mode

            if (currentTheme = "light") {
                style.BackgroundColor := this._ColorToBGR(INIObject.config.tooltip_light_bg_color)
                style.TextColor := this._ColorToBGR(INIObject.config.tooltip_light_text_color)
            } else if (currentTheme = "dark") {
                style.BackgroundColor := this._ColorToBGR(INIObject.config.tooltip_dark_bg_color)
                style.TextColor := this._ColorToBGR(INIObject.config.tooltip_dark_text_color)
            } else {
                ; 跟随系统主题
                try {
                    ; 检测系统是否处于深色模式
                    isDarkMode := RegRead(
                        "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize",
                        "AppsUseLightTheme")
                    if (isDarkMode = 0) {
                        style.BackgroundColor := this._ColorToBGR(INIObject.config.tooltip_dark_bg_color)
                        style.TextColor := this._ColorToBGR(INIObject.config.tooltip_dark_text_color)
                    } else {
                        style.BackgroundColor := this._ColorToBGR(INIObject.config.tooltip_light_bg_color)
                        style.TextColor := this._ColorToBGR(INIObject.config.tooltip_light_text_color)
                    }
                } catch {
                    ; 如果无法读取注册表，默认使用亮色主题
                    style.BackgroundColor := this._ColorToBGR(INIObject.config.tooltip_light_bg_color)
                    style.TextColor := this._ColorToBGR(INIObject.config.tooltip_light_text_color)
                }
            }

            ; 设置字体
            style.Font := INIObject.config.tooltip_font_name
            style.FontSize := INIObject.config.tooltip_font_size

        } catch {
            ; 使用默认样式
            style.BackgroundColor := 0xffffffff  ; 白色
            style.TextColor := 0xff381255       ; 深紫色
            style.Font := "Microsoft YaHei"
            style.FontSize := 12
        }

        ; 设置其他样式属性
        style.Border := 1
        style.Rounded := 10
        style.Margin := 5

        return style
    }

    ; 处理制表符对齐，使BTT的显示效果与ToolTipOptions一致
    static _ProcessTabAlignment(text, style) {
        ; 如果文本中没有制表符，直接返回
        if (!InStr(text, "`t")) {
            return text
        }

        ; 分行处理
        lines := StrSplit(text, "`n")
        processedLines := []

        for lineIndex, line in lines {
            if (!InStr(line, "`t")) {
                processedLines.Push(line)
                continue
            }

            ; 处理包含制表符的行
            parts := StrSplit(line, "`t")
            if (parts.Length < 2) {
                processedLines.Push(line)
                continue
            }

            ; 计算第一部分（通常是按键）的显示宽度
            firstPart := parts[1]

            ; 更精确地计算字符显示宽度
            estimatedWidth := this._CalculateTextWidth(firstPart)

            ; 使用更简单但更可靠的对齐方法
            ; 根据按键长度确定空格数量，模拟ToolTipOptions的效果
            if (estimatedWidth <= 4) {
                spacesNeeded := 2  ; 短按键用12个空格
            } else if (estimatedWidth <= 8) {
                spacesNeeded := 2   ; 中等按键用8个空格
            } else if (estimatedWidth <= 12) {
                spacesNeeded := 2   ; 较长按键用6个空格
            } else {
                spacesNeeded := 2   ; 很长按键用4个空格
            }

            ; 重建行，使用计算出的空格数
            newLine := firstPart . this.StrRepeat(" ", spacesNeeded)

            ; 添加剩余部分
            Loop parts.Length - 1 {
                i := A_Index + 1
                if (i > 2) {
                    newLine .= "    "  ; 后续制表符用4个空格
                }
                newLine .= parts[i]
            }

            processedLines.Push(newLine)
        }

        return this.StrJoin(processedLines, "`n")
    }

    ; 字符串重复函数
    static StrRepeat(str, count) {
        result := ""
        loop count {
            result .= str
        }
        return result
    }

    ; 字符串连接函数
    static StrJoin(array, separator) {
        result := ""
        for index, item in array {
            if (index > 1) {
                result .= separator
            }
            result .= item
        }
        return result
    }

    ; 计算文本显示宽度（字符单位）
    static _CalculateTextWidth(text) {
        width := 0
        for i, char in StrSplit(text, "") {
            charCode := Ord(char)
            if (charCode > 127) {
                ; 中文字符和其他宽字符
                width += 2
            } else if (charCode >= 32) {
                ; 普通ASCII字符
                switch char {
                    case "i", "l", "I", "1", ".", ",", ";", ":", "'", "`"", "|":
                        width += 0.5  ; 窄字符
                    case "m", "M", "w", "W":
                        width += 1.5  ; 宽字符
                    default:
                        width += 1    ; 标准字符
                }
            }
        }
        return Ceil(width)
    }

    ; 颜色转换辅助函数
    static _ColorToBGR(color) {
        if (color is String) {
            ; 处理颜色名称
            colorMap := Map(
                "White", 0xffffffff,
                "Black", 0xff000000,
                "Red", 0xff0000ff,
                "Green", 0xff00ff00,
                "Blue", 0xffff0000
            )

            if (colorMap.Has(color)) {
                return colorMap[color]
            }

            ; 处理十六进制颜色
            if (RegExMatch(color, "^0x([0-9a-fA-F]+)$", &m)) {
                colorValue := Integer(color)
                ; 转换为ARGB格式
                return 0xff000000 | colorValue
            }
        } else if (color is Integer) {
            ; 确保有alpha通道
            if (color < 0x01000000) {
                return 0xff000000 | color
            }
            return color
        }

        return 0xffffffff  ; 默认白色
    }

    ; 隐藏ToolTip
    static Hide(whichToolTip := 1) {
        if (!this.isInitialized) {
            return
        }

        switch this.currentLibrary {
            case "ToolTipOptions":
                ToolTip("", , , whichToolTip)
            case "BTT":
                btt("", , , whichToolTip)
        }
    }

    ; 重置ToolTip设置
    static Reset() {
        if (!this.isInitialized) {
            return
        }

        switch this.currentLibrary {
            case "ToolTipOptions":
                ToolTipOptions.Reset()
            case "BTT":
                ; BTT会自动清理
        }

        this.isInitialized := false
    }

    ; 显示带超时的ToolTip
    static ShowWithTimeout(text, x := "", y := "", whichToolTip := 1, timeout := 1000) {
        if (!this.isInitialized) {
            this.Init()
        }

        switch this.currentLibrary {
            case "ToolTipOptions":
                ; 先显示提示
                this.Show(text, x, y, whichToolTip)
                ; 使用定时器自动隐藏
                SetTimer(() => this.Hide(whichToolTip), -timeout)
            case "BTT":
                ; 使用BTT的内置自动隐藏功能
                this._ShowBTTWithTimeout(text, x, y, whichToolTip, timeout)
        }
    }

    ; 切换库
    static SwitchLibrary(newLibrary) {
        if (this.currentLibrary = newLibrary) {
            return
        }

        ; 清理当前库
        this.Reset()

        ; 初始化新库
        this.Init(newLibrary)

        ; 更新配置
        try {
            INIObject.config.tooltip_library := newLibrary
            INIObject.save()
        }
    }
}
