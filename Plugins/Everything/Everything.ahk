/*
	[PluginInfo]
    PluginName=Everything
    Author=BoBO
    Version=1
	Comment=Everything
*/
Everything() {
    ;热键映射数组
    KeyArray := Array()

    ;ModeChange为内置函数，用于进行模式的切换
    KeyArray.push({ Key: "<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】" })
    KeyArray.push({ Key: "<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】" })
    KeyArray.push({ Key: "<esc>", Mode: "VIM模式", Group: "模式", Func: "VIMD_清除输入键", Param: "", Comment: "清除输入键及提示" })

    ;SendKeyInput为内置函数，用于send指定键盘输入

    ;以下为自定义函数，需要在插件里定义
    KeyArray.push({ Key: "a1", Mode: "VIM模式", Group: "控制", Func: "Everything_隐藏程序", Param: "", Comment: "隐藏程序" })
    KeyArray.push({ Key: "A", Mode: "VIM模式", Group: "控制", Func: "Everything_显示程序", Param: "", Comment: "显示程序" })
    KeyArray.push({ Key: "ab", Mode: "VIM模式", Group: "控制", Func: "Everything_Msg", Param: "", Comment: "MsgBox" })

    KeyArray.push({ Key: "<f1>", Mode: "VIM模式", Group: "控制", Func: "Everything_SingleDoubleLongPress", Param: "", Comment: "测试单双长按-提示" })
    KeyArray.push({ Key: "<f3>", Mode: "VIM模式", Group: "控制", Func: "Everything_SingleDoubleLongPress2", Param: "", Comment: "测试单双长按" })

    
    ;注册窗体,请务必保证 PluginName 和文件名一致，以避免名称混乱影响使用
    ;如果 class 和 exe 同时填写，以 exe 为准
    ;vim.SetWin("PluginName", "ahk_class名")
    ;vim.SetWin("PluginName", "ahk_class名", "PluginName.exe")
    vim.SetWin("Everything", "", "Everything.exe")

    ;设置超时
    ;vim.SetTimeOut(300, "PluginName")

    vim.SetTimeOut(300, "Everything")

    for k, v in KeyArray {
        if (v.Key != "")  ;方便类似TC类全功能，仅启用部分热键的情况
            vim.map(v.Key, "Everything", v.Mode, v.Func, v.Param, v.Group, v.Comment)
    }
    ;设置全局热键
    vim.map("<w-f>", "global", "normal", "Everything_Run", "", "全局", "启动Everything搜索")
}

;PluginName_Before() ;如有，值=true时，直接发送键值，不执行命令
;PluginName_After() ;如有，值=true时，在执行命令后，再发送键值

;对符合条件的控件使用【normal模式】，而不是【Vim模式】
Everything_Before() {
    ctrl := ControlGetClassNN(ControlGetFocus("ahk_exe everything.exe"), "ahk_exe everything64.exe")
    if RegExMatch(ctrl, "Edit")
        return true
    return false
}

Everything_隐藏程序(*) {
    WinMinimize "ahk_class EVERYTHING"
    sleep 50
    WinHide "ahk_class EVERYTHING"
}

Everything_显示程序(*) {
    WinShow "ahk_class EVERYTHING"
}

Everything_Msg(*) {
    msgbox "Hello"
}

Everything_Run(*) {
    ; 从vimd.ini读取Everything路径配置
    IniRead_EverythingPath := IniRead("Custom\vimd.ini", "Everything", "everything_path", "")
    ; 如果配置文件中没有设置路径，使用默认路径
    EverythingPath := IniRead_EverythingPath ? IniRead_EverythingPath :
        "D:\BoBO\WorkFlow\tools\TotalCMD\Tools\Everything\Everything.exe"
    dynamicTitle := "Everything - 搜索 (" . A_YYYY . "-" . A_MM . "-" . A_DD . ")"
    ; 使用转换后的函数
    LaunchOrShow(EverythingPath, "EVERYTHING", dynamicTitle)
}


; 测试单双长按函数

Everything_SingleDoubleLongPress(*) {

    F1Action := CreateClickHandler(SingleClick, DoubleClick, LongPress)
    Hotkey "$F1", F1Action

    SingleClick()
    {
        MsgBox "F1单击动作"
    }

    DoubleClick()
    {
        MsgBox "F1双击动作"
    }

    LongPress()
    {
        MsgBox "F1长按动作"
    }

}
Everything_SingleDoubleLongPress2(*) {
    F3Action := CreateClickHandler(SingleClick, DoubleClick, LongPress, 500, 300, false)
    Hotkey "$F3", F3Action
    ; 示例3：不显示提示的热键
    SingleClick()
    {
        MsgBox "F3单击动作"
    }

    DoubleClick()
    {
        MsgBox "F3双击动作"
    }

    LongPress()
    {
        MsgBox "F3长按动作"
    }
}