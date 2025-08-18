#Requires AutoHotkey v2.0

/* ModeChange【模式切换】
    函数:  ModeChange
    作用:  模式切换并显示提示
    参数:  modeName：切换到的模式
    返回:
    作者:  Kawvin
    修改:  BoBO
    版本:  1.1
    AHK版本: 2.0.18
*/
ModeChange(modeName) {
    ; 设置模式
    vim.mode(modeName, vim.LastFoundWin)

    ; 创建一个自定义的GUI窗口作为提示
    static modeGui := 0

    ; 如果已经有一个GUI存在，先销毁它
    if (modeGui != 0) {
        try {
            modeGui.Destroy()
            modeGui := 0
        }
    }

    ; 获取主题相关的颜色设置
    bgColor := ""
    textColor := ""
    fontName := "Microsoft YaHei"
    fontSize := 12

    try {
        currentTheme := INIObject.config.theme_mode
        fontName := INIObject.config.tooltip_font_name
        fontSize := INIObject.config.tooltipswitch_font_size

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
    } catch {
        ; 使用默认设置
        bgColor := "White"
        textColor := "0x381255"
        fontName := "Microsoft YaHei"
        fontSize := 12
    }

    ; 处理颜色格式转换
    if (bgColor is String) {
        ; 如果是颜色名称或十六进制字符串，直接使用
        guiBgColor := bgColor
    } else {
        ; 如果是数字，转换为十六进制字符串
        guiBgColor := Format("0x{:06X}", bgColor)
    }

    ; 处理文本颜色
    if (textColor is String) {
        if (RegExMatch(textColor, "^0x([0-9a-fA-F]+)$")) {
            guiTextColor := textColor
        } else {
            guiTextColor := textColor
        }
    } else {
        guiTextColor := Format("0x{:06X}", textColor)
    }

    ; 创建一个新的GUI
    modeGui := Gui("-Caption +AlwaysOnTop +ToolWindow")
    modeGui.BackColor := guiBgColor

    ; 计算文本尺寸以自适应背景大小
    textWidth := CalculateTextWidth("当前模式: " modeName, fontName, fontSize)
    textHeight := fontSize + 8  ; 字体大小加上一些边距

    ; 计算GUI尺寸（添加边距）
    guiWidth := textWidth + 40   ; 左右各20像素边距
    guiHeight := textHeight + 20  ; 上下各10像素边距

    ; 确保最小尺寸
    if (guiWidth < 120)
        guiWidth := 120
    if (guiHeight < 35)
        guiHeight := 35

    ; 添加文本控件，使用最简单可靠的方式
    modeGui.SetFont("s" fontSize " bold", fontName)
    
    ; 先尝试最基本的设置，确保文字可见
    if (guiTextColor = "" || guiTextColor = "0x") {
        ; 如果颜色有问题，使用默认黑色
        textCtrl := modeGui.Add("Text", "cBlack Center x10 y10 w" (guiWidth-20) " h" (guiHeight-20), "当前模式: " modeName)
    } else {
        textCtrl := modeGui.Add("Text", "c" guiTextColor " Center x10 y10 w" (guiWidth-20) " h" (guiHeight-20), "当前模式: " modeName)
    }

    ; 获取最佳显示位置（支持双屏幕）
    pos := GetOptimalDisplayPosition()

    ; 计算居中位置
    centerX := pos.x - (guiWidth // 2)
    centerY := pos.y - (guiHeight // 2)

    ; 显示GUI在最佳位置
    modeGui.Show("x" . centerX . " y" . centerY . " w" . guiWidth . " h" . guiHeight . " NoActivate")

    ; 设置淡出效果和自动关闭
    ; 初始化透明度为255（完全不透明）
    WinSetTransparent(255, modeGui)

    ; 设置淡出效果
    SetTimer(FadeOutModeGui, -100)

    FadeOutModeGui() {
        static fadeSteps := 2  ; 淡出步骤数
        static fadeDelay := 100  ; 每步延迟（毫秒）
        static transparency := 255  ; 初始透明度
        static fadeStep := 0  ; 当前步骤

        ; 如果GUI已经不存在，则退出
        if (modeGui = 0)
            return

        ; 计算每步透明度减少量
        stepAmount := 255 / fadeSteps

        ; 创建淡出定时器
        SetTimer(DoFade, fadeDelay)

        DoFade() {
            fadeStep++

            ; 计算新的透明度值
            transparency := 255 - (stepAmount * fadeStep)

            ; 如果GUI已经不存在，则停止定时器
            if (modeGui = 0) {
                SetTimer(, 0)
                fadeStep := 0
                transparency := 255
                return
            }

            ; 应用新的透明度
            if (transparency > 0) {
                try {
                    WinSetTransparent(Round(transparency), modeGui)
                }
            } else {
                ; 淡出完成，销毁GUI并重置变量
                try {
                    modeGui.Destroy()
                    modeGui := 0
                }
                SetTimer(, 0)
                fadeStep := 0
                transparency := 255
            }
        }
    }
}

/* GetOptimalTooltipPosition【获取最佳提示显示位置】
    函数:  GetOptimalTooltipPosition
    作用:  获取最佳的提示显示位置，支持多屏幕
    参数:  无
    返回:  {x: 坐标x, y: 坐标y}
    作者:  BoBO
    版本:  1.0
    AHK版本: 2.0.18
*/
GetOptimalTooltipPosition() {
    ; 优先级：活动窗口 > 鼠标位置 > 主屏幕

    ; 方法1: 尝试获取活动窗口所在的显示器
    try {
        activeHwnd := WinGetID("A")
        if (activeHwnd) {
            WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " activeHwnd)
            winCenterX := winX + winW // 2
            winCenterY := winY + winH // 2

            ; 检查窗口中心点在哪个显示器
            monitorIndex := GetMonitorFromPoint(winCenterX, winCenterY)
            if (monitorIndex > 0) {
                return GetMonitorCenter(monitorIndex)
            }
        }
    }

    ; 方法2: 使用鼠标位置
    MouseGetPos(&mouseX, &mouseY)
    monitorIndex := GetMonitorFromPoint(mouseX, mouseY)
    if (monitorIndex > 0) {
        return GetMonitorCenter(monitorIndex)
    }

    ; 方法3: 使用主显示器
    return GetMonitorCenter(1)
}

/* GetMonitorFromPoint【根据坐标获取显示器索引】
    函数:  GetMonitorFromPoint
    作用:  根据坐标点获取对应的显示器索引
    参数:  x, y - 坐标点
    返回:  显示器索引，0表示未找到
    作者:  BoBO
    版本:  1.0
    AHK版本: 2.0.18
*/
GetMonitorFromPoint(x, y) {
    try {
        monitorCount := MonitorGet()
        if (monitorCount <= 0) {
            return 1  ; 如果无法获取显示器信息，返回主显示器
        }

        ; 遍历所有显示器，找到包含该点的显示器
        loop monitorCount {
            ; 使用 MonitorGet 获取显示器的完整区域（不是工作区域）
            MonitorGet(A_Index, &left, &top, &right, &bottom)
            if (x >= left && x < right && y >= top && y < bottom) {
                return A_Index
            }
        }

        ; 如果没有找到精确匹配，找最近的显示器
        minDistance := 999999
        closestMonitor := 1

        loop monitorCount {
            MonitorGet(A_Index, &left, &top, &right, &bottom)
            centerX := (left + right) // 2
            centerY := (top + bottom) // 2
            distance := Sqrt((x - centerX) ** 2 + (y - centerY) ** 2)

            if (distance < minDistance) {
                minDistance := distance
                closestMonitor := A_Index
            }
        }

        return closestMonitor
    } catch {
        ; 如果出现任何错误，返回主显示器
        return 1
    }
}

/* GetMonitorCenter【获取显示器中心位置】
    函数:  GetMonitorCenter
    作用:  获取指定显示器的中心位置
    参数:  monitorIndex - 显示器索引
    返回:  {x: 中心x坐标, y: 中心y坐标}
    作者:  BoBO
    版本:  1.0
    AHK版本: 2.0.18
*/
GetMonitorCenter(monitorIndex) {
    try {
        ; 确保显示器索引有效
        monitorCount := MonitorGet()
        if (monitorIndex < 1 || monitorIndex > monitorCount) {
            monitorIndex := 1  ; 使用主显示器
        }

        ; 使用工作区域，避免任务栏等区域
        MonitorGetWorkArea(monitorIndex, &left, &top, &right, &bottom)

        centerX := (left + right) // 2
        centerY := (top + bottom) // 2

        ; 稍微向上偏移，避免正中心可能被其他窗口遮挡
        centerY := centerY - 50

        return { x: centerX - 90, y: centerY }  ; -90 是为了让文本居中
    } catch {
        ; 如果出现错误，返回屏幕中心的默认位置
        return { x: A_ScreenWidth // 2 - 90, y: A_ScreenHeight // 2 - 50 }
    }
}

/* SendKeyInput【按键输出】
    函数:  SendKeyInput
    作用:  按键输出
    参数:  Param，为空时直接返回
            字符串，如{enter}，直接发送对应的内容
			数组，最后一位如果为类似 “|300”，即 “|”后加数字的，则输入按键序列之前按指定的时间加延迟，否则按默认100加延迟
				如["^a", "^c"]，则 ①发送Ctrl+A；②延迟100ms；③发送Ctrl+C
				如["^a", "^c", "^v", "|1500"]，则 ①发送Ctrl+A；②延迟1500ms；③发送Ctrl+C；④延迟1500ms；⑤发送Ctrl+V
    返回:
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
SendKeyInput(Param) {
    if Param = ""
        return
    switch Type(Param) {
        case "String", "Integer", "Float":
            SendInput Param
        case "Array":
            Flag_definedDelay := 0
            aDelay := 100
            if (Param.length >= 3 && RegExMatch(Param[Param.length], "\|\d+")) {
                aDelay := substr(Param[Param.length], 2) + 0
                Flag_definedDelay := 1
            }
            loopTimes := Param.length - Flag_definedDelay
            loop loopTimes {
                SendInput Param[A_Index]
                if (A_Index != loopTimes)
                    Sleep aDelay
            }
        case "Map":
            return
        case "Object":
            return
        default:
            return
    }
}

/* KyFunc_ArrayJoin【数组合并为String】
    函数:  KyFunc_ArrayJoin
    作用:  数组合并为String
    参数:  arr: 数组
			delimiter: 分隔符
			withBracket: 是否加引号, 默认为单引号,可选值为【单引号】或【双引号】或【空】
    返回:  生成的String
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
KyFunc_ArrayJoin(arr, delimiter, withBracket := "") {
    for s in arr
        str .= withBracket s withBracket delimiter
    return SubStr(str, 1, -StrLen(delimiter))
}

/* KyFunc_StringParam【参数输出为String】
    函数:  KyFunc_StringParam
    作用:  参数输出为String
    参数:  Param: 参数
			delimiter: 分隔符
			withBracket: 是否加引号, 默认为单引号,可选值为【单引号】或【双引号】或【空】
    返回:
		String: 直接输出，abcde--> abcde
 		Array:  KyFunc_StringParam(["a", "b", 100]) 			--> [ a, b, 100]
			    KyFunc_StringParam(["a", "b", 100], ";", "'") 	--> [ 'a'; 'b'; '100']
		Map:   KyFunc_StringParam(Map("a", 1, "b", 2})			--> {"a":1, "b":2}
		Object:   KyFunc_StringParam({a:1, b:2})				--> {"a":1, "b":2}
    作者:  Kawvin
    版本:  0.1_2025.06.18
    AHK版本: 2.0.18
*/
KyFunc_StringParam(Param, delimiter := ",", withBracket := "") {
    switch Type(Param) {
        case "Array":
            return "[ " KyFunc_ArrayJoin(Param, delimiter, withBracket := "") " ]"
        case "String", "Integer", "Float":
            return Param
        case "Map":
            return JSON.stringify(Param)
        case "Object":
            return JSON.stringify(Param)
        default:
            return ""
    }
}

/*KyFunc_RegExMatchAll 【作用:  获取正则表达式所有匹配的数组】
	函数: KyFunc_RegExMatchAll
	作用: 获取正则表达式所有匹配的数组
	参数: Haystack				源字符串
			NeedleRegEx		正则表达式
			SubPat			第几个（）的匹配组
	返回:剪切板内容
	作者: Kawvin
	版本: 0.1
	用法:
		MyOriStr:="MyHotKey1 = !cMyHotKey2 = !F9"
		MyMatchArray:=MyFun_RegExMatchAll(MyOriStr,"(.*?)\d")
		i:=1
		while (i<=MyMatchArray.Length)
		{
			MsgBox MyMatchArray[i]
			i+=1
		}
*/
MyFun_RegExMatchAll(Haystack, NeedleRegEx, SubPat := 1) {
    arr := [], StartPos := 1
    while (pos := RegexMatch(Haystack, NeedleRegEx, &match, startPos)) {
        arr.push(match[1])
        startPos := pos + StrLen(match[SubPat])
    }
    return arr.Length ? arr : []
}

/*KyFunc_AutoAligned【文本自动对齐整理】
    函数: KyFunc_AutoAligned(iText, iSplit:="`t", iStrLen:=90, iStrFront:="", iStrBehind:="")
    作用: 文本自动对齐整理
    参数: iHwnd（可选） - 程序的 hwnd
    返回:
    作者: Kawvin
    版本: 0.2_2025.06.13
	环境：>=2.0.18
*/
KyFunc_AutoAligned(iText, iSplit := "`t", iStrLen := 90, iStrFront := "", iStrBehind := "") {
    LimitMax := iStrLen     ;左侧超过该长度时，该行不参与对齐，该数字可自行修改
    MaxLen := 0
    StrSpace := " "
    loop LimitMax + 1
        StrSpace .= " "
    Aligned := ""
    loop parse, iText, "`n", "`r"                   ;首先求得左边最长的长度，以便向它看齐
    {
        if A_LoopField = ""
            continue
        RegStr := iSplit . "{1,}"
        RegStr := RegExReplace(RegStr, "``", "\")
        TemStr := RegExReplace(A_LoopField, RegStr, "[==]")
        RegStr := "\s*(.*?)\s*\[==\].*$"
        ItemLeft := RegExReplace(TemStr, RegStr, "$1")        ;本条目的 分隔符 左侧部分
        ThisLen := StrLen(RegExReplace(ItemLeft, "[^\x00-\xff]", "11"))       ;本条左侧的长度
        MaxLen := (ThisLen > MaxLen And ThisLen <= LimitMax) ? ThisLen : MaxLen       ;得到小于LimitMax内的最大的长度，这个是最终长度
    }

    loop parse, iText, "`n", "`r" {
        if A_LoopField = ""
            continue
        RegStr := iSplit . "{1,}"
        RegStr := RegExReplace(RegStr, "``", "\")
        TemStr := RegExReplace(A_LoopField, RegStr, "[==]")
        RegStr := "\s*\[==\].*?$"
        ItemLeft := Trim(RegExReplace(TemStr, RegStr))        ;本条目的 分隔符 左侧部分
        RegStr := "^.*?\[==\]"
        ItemRight := Trim(RegExReplace(TemStr, RegStr))          ;本条目的 分隔符 右侧部分

        ThisLen := StrLen(RegExReplace(ItemLeft, "[^\x00-\xff]", "11"))   ;本条左侧的长度
        if (ThisLen > MaxLen) {      ;如果本条左侧大于最大长度，注意是最大长度，而不是LimitMax，则不参与对齐
            Aligned .= ItemLeft "        " ItemRight "`r`n"
            continue
        } else {
            Aligned .= ItemLeft . SubStr(StrSpace, 1, MaxLen + 8 - ThisLen) ItemRight "`r`n"        ;该处给右侧 分隔符 后添加了一个空格，根据需求可删
        }
    }
    Aligned := RegExReplace(Aligned, "\s*$", "")   ;顺便删除最后的空白行，可根据需求注释掉
    if iStrFront != ""
        Aligned := iStrFront . "`r`n" . Aligned
    if iStrBehind != ""
        Aligned := Aligned . "`r`n" . iStrBehind
    return Aligned
}

/*TC_SendPos【Tc发送消息指令】
    函数: TC_SendPos
    作用: Tc发送消息指令
    参数: Number：命令编号，请详见Tc插件目录下的excel文件
    返回:
    作者: Kawvin
    版本: 0.2_2025.06.13
	环境：>=2.0.18
*/
; TC_SendPos(2065)
TC_SendPos(Number) {
    PostMessage 1075, Number, 0, , "AHK_CLASS TTOTAL_CMD"
}
/*EscapeRegex【正则字符转义】
    函数: EscapeRegex
    作用: 正则字符转义
    参数: str
    返回:
    作者: Kawvin
    版本: 0.2_2025.06.13
	环境：>=2.0.18
*/
EscapeRegex(str) {
    static specialChars := ".*?+[](){}|^$\-<>"
    _str := ""
    loop parse str
        _str .= InStr(specialChars, A_LoopField) ? "\" A_LoopField : A_LoopField
    return _str
}

MsgBoxTest(a) {
    MsgBox a
}

/* CalculateTextWidth【计算文本宽度】
    函数:  CalculateTextWidth
    作用:  计算指定字体和大小的文本显示宽度
    参数:  text - 文本内容
           fontName - 字体名称
           fontSize - 字体大小
    返回:  文本宽度（像素）
    作者:  BoBO
    版本:  1.0
    AHK版本: 2.0.18
*/
CalculateTextWidth(text, fontName, fontSize) {
    ; 简化版本：使用估算方法，避免复杂的API调用
    ; 这个方法更稳定，适用于大多数情况

    textLength := StrLen(text)

    ; 基础字符宽度估算（像素）
    baseCharWidth := fontSize * 0.6  ; 大致估算

    ; 计算中文字符和英文字符
    chineseChars := 0
    englishChars := 0

    ; 遍历每个字符
    loop textLength {
        char := SubStr(text, A_Index, 1)
        charCode := Ord(char)

        if (charCode > 127) {
            ; 中文或其他宽字符
            chineseChars++
        } else {
            ; 英文字符
            englishChars++
        }
    }

    ; 中文字符通常比英文字符宽1.5-2倍
    estimatedWidth := (englishChars * baseCharWidth) + (chineseChars * baseCharWidth * 1.8)

    ; 添加一些缓冲空间
    return Round(estimatedWidth * 1.1)
}

/* GetOptimalDisplayPosition【获取最佳显示位置】
    函数:  GetOptimalDisplayPosition
    作用:  获取最佳的显示位置，支持多屏幕
    参数:  无
    返回:  {x: 中心x坐标, y: 中心y坐标}
    作者:  BoBO
    版本:  1.0
    AHK版本: 2.0.18
*/
GetOptimalDisplayPosition() {
    ; 优先级：鼠标所在显示器 > 活动窗口所在显示器 > 主显示器

    ; 方法1: 获取鼠标位置所在的显示器
    MouseGetPos(&mouseX, &mouseY)
    monitorIndex := GetMonitorFromPoint(mouseX, mouseY)

    if (monitorIndex > 0) {
        return GetMonitorCenter(monitorIndex)
    }

    ; 方法2: 尝试获取活动窗口所在的显示器
    try {
        activeHwnd := WinGetID("A")
        if (activeHwnd) {
            WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " activeHwnd)
            winCenterX := winX + winW // 2
            winCenterY := winY + winH // 2

            ; 检查窗口中心点在哪个显示器
            monitorIndex := GetMonitorFromPoint(winCenterX, winCenterY)
            if (monitorIndex > 0) {
                return GetMonitorCenter(monitorIndex)
            }
        }
    }

    ; 方法3: 使用主显示器
    return GetMonitorCenter(1)
}
