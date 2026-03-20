; ==============================================================================
; Tooltip 测试与辅助函数
; ==============================================================================

^!t:: SwitchTooltipLibrary()
SwitchTooltipLibrary() {
    currentLib := ""
    try {
        currentLib := INIObject.config.tooltip_library
    } catch {
        currentLib := "ToolTipOptions"
    }

    newLib := (currentLib = "ToolTipOptions") ? "BTT" : "ToolTipOptions"
    ToolTipManager.SwitchLibrary(newLib)
    ToolTipManager.Show("已切换到: " newLib "`n当前库: " ToolTipManager.currentLibrary, , , 1)
    SetTimer(HideLibrarySwitchTip, -3000)
}

^!+t:: TestTooltipDisplay()
TestTooltipDisplay() {
    currentLib := ToolTipManager.currentLibrary

    testText := "ToolTip库测试`n"
    testText .= "当前使用: " currentLib "`n"
    testText .= "时间: " FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") "`n"
    testText .= "这是一个多行测试文本"

    ToolTipManager.Show(testText, , , 2)
    SetTimer(HideTestDisplayTip, -5000)
}

^!+h:: TestAutoHideTooltip()
TestAutoHideTooltip() {
    try {
        autoHide := INIObject.config.tooltip_auto_hide
        mouseLeave := INIObject.config.tooltip_hide_on_mouse_leave
        clickOutside := INIObject.config.tooltip_hide_on_click_outside
        windowChange := INIObject.config.tooltip_hide_on_window_change
        timeout := INIObject.config.tooltip_hide_timeout
        clearKeyCache := INIObject.config.tooltip_clear_key_cache_on_hide
        globalWindowMonitor := INIObject.config.tooltip_global_window_monitor
    } catch {
        autoHide := 1
        mouseLeave := 1
        clickOutside := 1
        windowChange := 1
        timeout := 5000
        clearKeyCache := 1
        globalWindowMonitor := 1
    }

    testText := "按键提示自动隐藏测试`n"
    testText .= "===================`n"
    testText .= "配置状态:`n"
    testText .= "自动隐藏: " (autoHide ? "启用" : "禁用") "`n"
    testText .= "鼠标离开隐藏: " (mouseLeave ? "启用" : "禁用") "`n"
    testText .= "点击外部隐藏: " (clickOutside ? "启用" : "禁用") "`n"
    testText .= "窗口切换隐藏: " (windowChange ? "启用" : "禁用") "`n"
    testText .= "超时时间: " (timeout > 0 ? timeout "ms" : "禁用") "`n"
    testText .= "清除按键缓存: " (clearKeyCache ? "启用" : "禁用") "`n"
    testText .= "全局窗口监控: " (globalWindowMonitor ? "启用" : "禁用") "`n"
    testText .= "===================`n"
    testText .= "测试说明:`n"
    testText .= "• 移动鼠标离开此提示框`n"
    testText .= "• 点击提示框外的区域`n"
    testText .= "• 切换到其他窗口`n"
    testText .= "• 等待超时自动隐藏"

    ToolTipInfoManager.Show(testText)
    SetTimer(ShowTestHint, -100)
}

ShowTestHint() {
    ToolTipManager.Show("测试提示已显示，请尝试各种隐藏条件", , , 3)
    SetTimer(HideTestHint, -2000)
}

HideTestHint() {
    ToolTipManager.Hide(3)
}

HideLibrarySwitchTip() {
    ToolTipManager.Hide(1)
}

HideTestDisplayTip() {
    ToolTipManager.Hide(2)
}
