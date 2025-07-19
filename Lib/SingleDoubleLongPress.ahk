#Requires AutoHotkey v2.0
; 封装成函数的单击、双击或长按检测

/**
 * 创建一个处理单击、双击和长按的热键处理函数
 * @param singleFunc 单击时执行的函数
 * @param doubleFunc 双击时执行的函数
 * @param longFunc 长按时执行的函数
 * @param longPressTime 长按阈值(毫秒)，默认500ms
 * @param doubleClickTime 双击间隔时间(毫秒)，默认300ms
 * @param showTooltip 是否显示提示，默认true
 * @returns 返回一个可以绑定到热键的函数
 */
CreateClickHandler(singleFunc, doubleFunc, longFunc, longPressTime := 500, doubleClickTime := 300, showTooltip := true) {
    ; 全局存储每个热键的状态
    global pressCountMap := Map()
    global longPressActiveMap := Map()
    global timerFuncMap := Map()

    ; 返回热键处理函数
    return HotkeyHandler

    ; 内部热键处理函数
    HotkeyHandler(ThisHotkey) {
        ; 处理热键名称
        hk := StrReplace(ThisHotkey, "$")  ; 去除美元符号
        keyName := RegExReplace(hk, "^[#!^+<>*~$]*")  ; 提取实际按键名称

        ; 初始化热键状态(如果不存在)
        if !pressCountMap.Has(hk)
            pressCountMap[hk] := 0
        if !longPressActiveMap.Has(hk)
            longPressActiveMap[hk] := false

        ; 如果有正在运行的计时器，先清除它
        if timerFuncMap.Has(hk) {
            try
                SetTimer timerFuncMap[hk], 0
        }

        ; 显示按下状态的提示
        if showTooltip
            ToolTip "按下" hk "中...", A_ScreenWidth / 2, A_ScreenHeight / 2

        ; 等待按键释放或达到长按阈值
        waitOptions := "T" . longPressTime / 1000
        if !KeyWait(keyName, waitOptions)  ; 等待按键释放，如果超时则触发长按
        {
            ; 长按被触发
            longPressActiveMap[hk] := true

            if showTooltip
                ToolTip hk "长按已激活!", A_ScreenWidth / 2, A_ScreenHeight / 2

            ; 等待按键释放
            KeyWait keyName

            ; 执行长按动作
            if showTooltip
                ToolTip  ; 清除提示

            ; 检查函数是否存在并调用
            if longFunc is Func
                longFunc()

            pressCountMap[hk] := 0  ; 重置点击计数
            longPressActiveMap[hk] := false
            return
        }

        ; 按键已释放(短按)
        if showTooltip
            ToolTip  ; 清除提示

        ; 如果不是长按，则处理单击/双击逻辑
        if !longPressActiveMap[hk] {
            ; 增加点击计数
            pressCountMap[hk]++

            ; 创建处理点击的函数
            ProcessClicks() {
                if pressCountMap[hk] = 1 && singleFunc is Func
                    singleFunc()
                else if pressCountMap[hk] = 2 && doubleFunc is Func
                    doubleFunc()

                pressCountMap[hk] := 0
                timerFuncMap.Delete(hk)
            }

            ; 保存计时器引用以便后续可以取消
            timerFuncMap[hk] := ProcessClicks

            ; 设置计时器
            SetTimer ProcessClicks, -doubleClickTime
        }
    }
}

/**
 * 简化版的点击处理函数，只处理单击和长按
 * @param clickFunc 单击时执行的函数
 * @param longPressFunc 长按时执行的函数
 * @param longPressTime 长按阈值(毫秒)，默认500ms
 * @param showTooltip 是否显示提示，默认true
 * @returns 返回一个可以绑定到热键的函数
 */
CreateSimpleClickHandler(clickFunc, longPressFunc, longPressTime := 500, showTooltip := true) {
    return SimpleHotkeyHandler

    SimpleHotkeyHandler(ThisHotkey) {
        hk := StrReplace(ThisHotkey, "$")
        keyName := RegExReplace(hk, "^[#!^+<>*~$]*")

        if showTooltip
            ToolTip "按下" hk "中...", A_ScreenWidth / 2, A_ScreenHeight / 2

        waitOptions := "T" . longPressTime / 1000
        if !KeyWait(keyName, waitOptions) {
            if showTooltip
                ToolTip hk "长按已激活!", A_ScreenWidth / 2, A_ScreenHeight / 2

            KeyWait keyName

            if showTooltip
                ToolTip

            ; 检查函数是否存在并调用
            if longPressFunc is Func
                longPressFunc()
        }
        else {
            if showTooltip
                ToolTip

            ; 检查函数是否存在并调用
            if clickFunc is Func
                clickFunc()
        }
    }
}

/**
 * 处理按键功能，并设置独立热键以支持单击、双击和长按
 * @param paramStr 参数字符串，格式为"热键|单击函数|双击函数|长按函数"
 */
SingleDoubleFullHandlers(paramStr) {
    static handlerMap := Map()     ; 存储每个热键的处理函数

    ; 解析参数字符串
    params := StrSplit(paramStr, "|")
    hotkeyStr := params[1]

    ; 设置默认函数
    singleFunc := SingleClick
    doubleFunc := DoubleClick
    longFunc := LongPress

    ; 如果提供了自定义函数名称，则使用它们
    if (params.Length >= 2 && params[2] != "") {
        ; Store the function name string
        singleFuncName := params[2]
        ; Create a wrapper function that resolves the reference when called
        singleFunc := (*) => (%singleFuncName%)()
    }
    if (params.Length >= 3 && params[3] != "") {
        ; 存储函数名称字符串，而不是尝试立即解析函数引用
        doubleFuncName := params[3]
        ; 创建一个包装函数，在调用时再解析函数引用
        doubleFunc := (*) => (%doubleFuncName%)()
    }
    if (params.Length >= 4 && params[4] != "") {
        ; 存储函数名称字符串，而不是尝试立即解析函数引用
        longFuncName := params[4]
        ; 创建一个包装函数，在调用时再解析函数引用
        longFunc := (*) => (%longFuncName%)()
    }

    ; 创建处理程序
    handler := CreateClickHandler(singleFunc, doubleFunc, longFunc)

    ; 存储并注册热键
    handlerMap[hotkeyStr] := handler
    Hotkey hotkeyStr, handler
}

/**
 * 默认单击功能
 */
SingleClick() {
    MsgBox("默认 这是单击")
}

/**
 * 默认双击功能
 */
DoubleClick() {
    MsgBox("默认 这是双击")
}

/**
 * 默认长按功能
 */
LongPress() {
    MsgBox("默认 这是长按")
}

; === 注册热键 ===


; 自定义函数示例（必须在调用 SingleDoubleFullHandlers 之前定义）
MySingleFunc() {
    MsgBox("自定义单击")
}

; 注册自定义热键
; SingleDoubleFullHandlers("1") ; 使用默认函数设置按键1
; SingleDoubleFullHandlers("F2|MySingleFunc")
