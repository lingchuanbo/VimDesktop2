; ==============================================================================
; 网页快捷入口
; ==============================================================================

DeepseekSingleClick() {
    Run "https://chat.deepseek.com"
}

DeepseekDoubleClick() {
    Run "https://gemini.google.com/"
}

DeepseekLongPress() {
    Run "https://grok.com"
}

deepseekAction := CreateClickHandler(DeepseekSingleClick, DeepseekDoubleClick, DeepseekLongPress)
Hotkey "$#s", deepseekAction
