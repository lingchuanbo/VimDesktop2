#Include .\VimTooltipManager.ahk

/* ShowInfo【显示热键信息】
    函数:  ShowInfo
    作用:  显示热键信息，支持配置的自动隐藏规则
    参数:
    返回:
    作者:  Kawvin
    版本:  2.0
    AHK版本: 2.0.18
*/
ShowInfo() {
    global vim
    obj := vim.GetMore(true)
    winObj := vim.GetWin(vim.LastFoundWin)
    CurMode := vim.GetCurMode(vim.LastFoundWin)
    if winObj.Count
        np .= winObj.Count
    loop obj.Length {
        ; if INIObject.config.enable_debug
        ;     vim._Debug.add(Format("热键：{1}`n窗体：{2}`n模式：{3}`n---------------", obj[A_Index]["key"], vim.LastFoundWin, CurMode))
        act := vim.GetAction(vim.LastFoundWin, CurMode, vim.convert2MapKey(obj[A_Index]["key"]))
        if !act
            continue
        np .= act.name "`t" act.Comment "`n"
        if (A_Index = 1) {
            np .= "=====================`n"
        }
    }

    ; 初始化ToolTip管理器
    ToolTipManager.Init()

    ; 使用增强的提示信息管理器
    ToolTipInfoManager.Show(np)

}

/* HideInfo【隐藏热键信息】
    函数: HideInfo
    作用:  隐藏热键信息，支持配置的自动隐藏规则
    参数: force - 强制隐藏，忽略配置规则 (默认false)
    返回:
    作者:  Kawvin
    版本:  2.0
    AHK版本: 2.0.18
*/
HideInfo(force := false) {
    if (!VimDesktop_Global.showToolTipStatus) ; 当屏幕有非快捷键补全帮助信息时，不清理
        ToolTipManager.Hide()

    ; 如果强制隐藏，直接执行
    if (force) {
        ToolTipInfoManager.ForceHide()
        return
    }

    ; 否则使用配置的隐藏规则
    ToolTipInfoManager.Hide()

    ; BTT提示关闭后进行内存优化，清理累积的内存
    _VIMD_MemoryCleanup()
}
