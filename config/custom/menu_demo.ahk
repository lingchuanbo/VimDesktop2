; ==============================================================================
; 菜单示例与主题切换
; ==============================================================================

mainMenu := Menu()
themeMenu := Menu()

global isDarkMode := false

themeMenu.Add("明亮模式", ShowInfoMain)
themeMenu.Add("暗黑模式", ShowInfoMain)
themeMenu.Add("跟随系统", ShowInfoMain)

mainMenu.Add("智能搜索", ShowInfoMain)
mainMenu.Add("翻译", ShowInfoMain)
mainMenu.Add()
mainMenu.Add("截图", themeMenu)
mainMenu.Add("下载", ShowInfoMain)

SetLightMode(*) {
    WindowsTheme.SetAppMode(false)
    isDarkMode := false
    MsgBox "已切换到明亮模式", "主题提示", "T0.5"
}

SetDarkMode(*) {
    WindowsTheme.SetAppMode(true)
    isDarkMode := true
    MsgBox "已切换到暗黑模式", "主题提示", "T0.5"
}

SetSystemTheme(*) {
    WindowsTheme.SetAppMode("Default")
    isDarkMode := false
    MsgBox "已设置为跟随系统主题", "主题提示", "T0.5"
}

ShowInfoMain(ItemName, ItemPos, MyMenu) {
    MsgBox "你点击了 '" ItemName "' 菜单项。"
}
