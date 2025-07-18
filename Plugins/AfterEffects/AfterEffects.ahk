/*
	[PluginInfo]
    PluginName=AfterEffects
    Author=BoBO
    Version=1
	Comment=AfterEffects
*/
AfterEffects() {
    ;热键映射数组
    KeyArray := Array()
    ;ModeChange为内置函数，用于进行模式的切换
    KeyArray.push({ Key: "<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】" })
    KeyArray.push({ Key: "<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】" })
    KeyArray.push({ Key: "<esc>", Mode: "VIM模式", Group: "模式", Func: "VIMD_清除输入键", Param: "", Comment: "清除输入键及提示" })

    ;SendKeyInput 为内置函数，用于send指定键盘输入
    ;Script_AfterEffects 为运行AE脚本函数Param里面填写 脚本文件名

    KeyArray.push({ Key: "aa", Mode: "VIM模式", Group: "控制", Func: "AfterEffects_Msg", Param: "", Comment: "MsgBox" })
    KeyArray.push({ Key: "as", Mode: "VIM模式", Group: "控制", Func: "Script_AfterEffects", Param: "Test.jsx", Comment: "脚本测试" })
    KeyArray.push({ Key: "t1", Mode: "VIM模式", Group: "控制", Func: "Script_AfterEffects", Param: "OrganizeProjectAssets.jsx", Comment: "整理" })
    KeyArray.push({ Key: "t2", Mode: "VIM模式", Group: "控制", Func: "Script_AfterEffects", Param: "RenderToSaveFilesAndOpen.jsx", Comment: "快速渲染" })

    
    ;注册窗体,请务必保证 PluginName 和文件名一致，以避免名称混乱影响使用
    ;如果 class 和 exe 同时填写，以 exe 为准
    ;vim.SetWin("PluginName", "ahk_class名")
    ;vim.SetWin("PluginName", "ahk_class名", "PluginName.exe")
    vim.SetWin("AfterEffects", "", "AfterFX.exe")

    ;设置超时

    vim.SetTimeOut(300, "AfterEffects")

    for k, v in KeyArray {
        if (v.Key != "")  ;方便类似TC类全功能，仅启用部分热键的情况
            vim.map(v.Key, "AfterEffects", v.Mode, v.Func, v.Param, v.Group, v.Comment)
    }
}

;PluginName_Before() ;如有，值=true时，直接发送键值，不执行命令
;PluginName_After() ;如有，值=true时，在执行命令后，再发送键值

;对符合条件的控件使用【normal模式】，而不是【Vim模式】
AfterEffects_Before() {
    ctrl := ControlGetClassNN(ControlGetFocus("ahk_exe AfterFX.exe"), "ahk_exe AfterFX.exe")
    if RegExMatch(ctrl, "Edit")
        return true
    return false
}

AfterEffects_隐藏程序(*) {
    WinMinimize "ahk_class AfterEffects"
    sleep 50
    WinHide "ahk_class AfterEffects"
}

AfterEffects_显示程序(*) {
    WinShow "ahk_class AfterEffects"
}

AfterEffects_Msg(*) {
    msgbox "Hello"
}
