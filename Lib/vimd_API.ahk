#Requires AutoHotkey v2.0

/* ModeChange【模式切换】
    函数:  ModeChange
    作用:  模式切换并显示提示
    参数:  modeName：切换到的模式
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
ModeChange(modeName) {
    ; 设置模式
    vim.mode(modeName, vim.LastFoundWin)
    
    ; 使用ToolTipManager显示模式切换提示
    ToolTipManager.Init()
    
    ; 构建提示文本
    modeText := "当前模式: " modeName
    
    ; 获取屏幕中心位置来显示提示
    MonitorGetWorkArea(1, &left, &top, &right, &bottom)
    centerX := Integer((right - left) / 2)
    centerY := Integer((bottom - top) / 2)
    
    ; 显示模式切换提示
    ToolTipManager.Show(modeText, centerX - 90, centerY - 20, 2)
    
    ; 设置定时器自动隐藏提示
    static modeChangeTimer := 0
    
    ; 清除之前的定时器
    if (modeChangeTimer != 0) {
        SetTimer(modeChangeTimer, 0)
    }
    
    ; 创建新的定时器来隐藏提示
    modeChangeTimer := () => ToolTipManager.Hide(2)
    SetTimer(modeChangeTimer, -300)  ; 1.5秒后自动隐藏
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
            Aligned .= ItemLeft "    " ItemRight "`r`n"
            continue
        } else {
            Aligned .= ItemLeft . SubStr(StrSpace, 1, MaxLen + 4 - ThisLen) ItemRight "`r`n"        ;该处给右侧 分隔符 后添加了一个空格，根据需求可删
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
; 用法 TC_Command("tem(`cm_MkDir`)")
TC_Command(CommandName) {
    ; 使用TC_Global中的配置路径
    Run(TC_Global.TCDirPath . "\Tools\TCFS2\TCFS2.exe /ef " . CommandName)
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