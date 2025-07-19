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
CreateClickHandler(singleFunc, doubleFunc, longFunc, longPressTime := 500, doubleClickTime := 300, showTooltip := true)
{
    ; 全局存储每个热键的状态
    global pressCountMap := Map()
    global longPressActiveMap := Map()
    global timerFuncMap := Map()
    
    ; 返回热键处理函数
    return HotkeyHandler
    
    ; 内部热键处理函数
    HotkeyHandler(ThisHotkey)
    {
        ; 处理热键名称
        hk := StrReplace(ThisHotkey, "$")  ; 去除美元符号
        keyName := RegExReplace(hk, "^[#!^+<>*~$]*")  ; 提取实际按键名称
        
        ; 初始化热键状态(如果不存在)
        if !pressCountMap.Has(hk)
            pressCountMap[hk] := 0
        if !longPressActiveMap.Has(hk)
            longPressActiveMap[hk] := false
        
        ; 如果有正在运行的计时器，先清除它
        if timerFuncMap.Has(hk)
        {
            try
                SetTimer timerFuncMap[hk], 0
        }
            
        ; 显示按下状态的提示
        if showTooltip
            ToolTip "按下" hk "中...", A_ScreenWidth/2, A_ScreenHeight/2
        
        ; 等待按键释放或达到长按阈值
        waitOptions := "T" . longPressTime/1000
        if !KeyWait(keyName, waitOptions)  ; 等待按键释放，如果超时则触发长按
        {
            ; 长按被触发
            longPressActiveMap[hk] := true
            
            if showTooltip
                ToolTip hk "长按已激活!", A_ScreenWidth/2, A_ScreenHeight/2
            
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
        if !longPressActiveMap[hk]
        {
            pressCountMap[hk]++
            
            ; 创建处理点击的函数
            ProcessClicks()
            {
                if pressCountMap[hk] = 1 && singleFunc is Func
                    singleFunc()
                else if pressCountMap[hk] = 2 && doubleFunc is Func
                    doubleFunc()
                
                pressCountMap[hk] := 0
                timerFuncMap.Delete(hk)
            }
            
            ; 保存计时器引用以便后续可以取消
            timerFuncMap[hk] := ProcessClicks
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
CreateSimpleClickHandler(clickFunc, longPressFunc, longPressTime := 500, showTooltip := true)
{
    return SimpleHotkeyHandler
    
    SimpleHotkeyHandler(ThisHotkey)
    {
        hk := StrReplace(ThisHotkey, "$")
        keyName := RegExReplace(hk, "^[#!^+<>*~$]*")
        
        if showTooltip
            ToolTip "按下" hk "中...", A_ScreenWidth/2, A_ScreenHeight/2
        
        waitOptions := "T" . longPressTime/1000
        if !KeyWait(keyName, waitOptions)
        {
            if showTooltip
                ToolTip hk "长按已激活!", A_ScreenWidth/2, A_ScreenHeight/2
            
            KeyWait keyName
            
            if showTooltip
                ToolTip
                
            ; 检查函数是否存在并调用
            if longPressFunc is Func
                longPressFunc()
        }
        else
        {
            if showTooltip
                ToolTip
                
            ; 检查函数是否存在并调用
            if clickFunc is Func
                clickFunc()
        }
    }
}


; ; 示例1：F1键的单击、双击和长按动作
; F1SingleClick()
; {
;     MsgBox "F1单击动作"
; }

; F1DoubleClick()
; {
;     MsgBox "F1双击动作"
; }

; F1LongPress()
; {
;     MsgBox "F1长按动作"
; }

; F1Action := CreateClickHandler(F1SingleClick, F1DoubleClick, F1LongPress)
; Hotkey "$F1", F1Action

; ; 示例2：F2键的单击、双击和长按动作，自定义时间参数
; F2SingleClick()
; {
;     MsgBox "F2单击动作"
; }

; F2DoubleClick()
; {
;     MsgBox "F2双击动作"
; }

; F2LongPress()
; {
;     MsgBox "F2长按动作"
; }

; F2Action := CreateClickHandler(F2SingleClick, F2DoubleClick, F2LongPress, 800, 200)
; Hotkey "$F2", F2Action

; ; 示例3：不显示提示的热键
; F3SingleClick()
; {
;     MsgBox "F3单击动作"
; }

; F3DoubleClick()
; {
;     MsgBox "F3双击动作"
; }

; F3LongPress()
; {
;     MsgBox "F3长按动作"
; }

; F3Action := CreateClickHandler(F3SingleClick, F3DoubleClick, F3LongPress, 500, 300, false)
; Hotkey "$F3", F3Action

; ; 示例4：组合键的处理
; CtrlFSingleClick()
; {
;     MsgBox "Ctrl+F单击动作"
; }

; CtrlFDoubleClick()
; {
;     MsgBox "Ctrl+F双击动作"
; }

; CtrlFLongPress()
; {
;     MsgBox "Ctrl+F长按动作"
; }

; CtrlFAction := CreateClickHandler(CtrlFSingleClick, CtrlFDoubleClick, CtrlFLongPress)
; Hotkey "$^f", CtrlFAction

; ; 示例5：简化版的点击处理(只有单击和长按)
; F4SingleClick()
; {
;     MsgBox "F4单击动作"
; }

; F4LongPress()
; {
;     MsgBox "F4长按动作"
; }

; F4Action := CreateSimpleClickHandler(F4SingleClick, F4LongPress, 600)
; Hotkey "$F4", F4Action

; ==============================================================================
; KeyArray.push 调用 单击、双击和长按函数
; ==============================================================================

/**
 * 处理按键功能，并设置独立热键以支持单击、双击和长按
 * @param paramStr 参数字符串，格式为"热键|单击函数|双击函数|长按函数"
 */
SingleDoubleFullHandlers(paramStr) {
    ; 解析参数字符串
    params := StrSplit(paramStr, "|")
    hotkeyStr := params[1]

    ; 设置默认函数名称
    singleClickFunc := "SingleClick"
    doubleClickFunc := "DoubleClick"
    longPressFunc := "LongPress"

    ; 如果提供了自定义函数名称，则使用它们
    if (params.Length >= 2 && params[2] != "")
        singleClickFunc := params[2]
    if (params.Length >= 3 && params[3] != "")
        doubleClickFunc := params[3]
    if (params.Length >= 4 && params[4] != "")
        longPressFunc := params[4]

    ; 将函数名称转换为函数对象
    singleClickHandler := %singleClickFunc%
    doubleClickHandler := %doubleClickFunc%
    longPressHandler := %longPressFunc%

    ; 创建处理函数
    SingleDoubleFullHandler := CreateClickHandler(singleClickHandler, doubleClickHandler, longPressHandler)

    ; 注册热键
    Hotkey hotkeyStr, SingleDoubleFullHandler
}

/**
 * F1单击功能 - 打开Everything搜索对话框
 */
SingleClick() {
    MsgBox("需要你自己配置功能  这是单击")
}

/**
 * F1双击功能 - 运行Everything程序
 */
DoubleClick() {
    MsgBox("需要你自己配置功能  这是双击")
}

/**
 * F1长按功能 - 显示帮助信息
 */
LongPress() {
    MsgBox("需要你自己配置功能  这是长按")
}