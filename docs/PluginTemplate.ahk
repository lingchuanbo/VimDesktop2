; 插件名和目录名一致，插件要放到 plugins/PluginName/PluginName.ahk 位置。
; 放入插件后，重新运行 vimd 会自动启用插件。
; 标签名请添加 PluginName_ 前缀，避免和其他插件冲突。

;该函数名需要和插件名一致
;PluginName(){
PotPlayer(){
    ;热键映射数组
    KeyArray:=Array()

    ;ModeChange为内置函数，用于进行模式的切换
	KeyArray.push({Key:"<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】"})
	KeyArray.push({Key:"<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】"})

    ;SendKeyInput为内置函数，用于send指定键盘输入
	KeyArray.push({Key:"z", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "{up}", Comment: "声音增大"})
	KeyArray.push({Key:"Z", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "{down}", Comment: "声音减小"})
	KeyArray.push({Key:"x", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "{Volume_Up 2}", Comment: "系统声音增大"})
	
    ;以下为自定义函数，需要在插件里定义
    KeyArray.push({Key:"a", Mode: "VIM模式", Group: "控制", Func: "PotPlayer_隐藏程序", Param: "", Comment: "隐藏程序"})
	KeyArray.push({Key:"A", Mode: "VIM模式", Group: "控制", Func: "PotPlayer_显示程序", Param: "", Comment: "显示程序"})
	KeyArray.push({Key:"C", Mode: "VIM模式", Group: "存档", Func: "PotPlayer_打开存档1", Param: "", Comment: "打开存档1"})
	KeyArray.push({Key:"B", Mode: "VIM模式", Group: "存档", Func: "PotPlayer_保存存档1", Param: "", Comment: "保存存档1"})


    ;;以下为 单双长按 自定义函数，需要在插件里定义 其中 SingleDoubleFullHandlers" 必填函数 Param需要自定义内容运行
    KeyArray.push({ Key: "1", Mode: "VIM模式", Group: "搜索", Func: "SingleDoubleFullHandlers", Param: "1|Everything_1|Everything_2|Everything_3",
        Comment: "单击/双击/长按" })
    KeyArray.push({ Key: "2", Mode: "VIM模式", Group: "搜索", Func: "SingleDoubleFullHandlers", Param: "2|Everything_1|Everything_2",
        Comment: "单击/双击" })
    KeyArray.push({ Key: "3", Mode: "VIM模式", Group: "搜索", Func: "SingleDoubleFullHandlers", Param: "3",
        Comment: "单击" })


    ;注册窗体,请务必保证 PluginName 和文件名一致，以避免名称混乱影响使用
    ;如果 class 和 exe 同时填写，以 exe 为准
    ;vim.SetWin("PluginName", "ahk_class名")
    ;vim.SetWin("PluginName", "ahk_class名", "PluginName.exe")
    vim.SetWin("PotPlayer", "", "PotPlayerMini64.exe")
    ;设置超时
    ;vim.SetTimeOut(300, "PluginName")
    vim.SetTimeOut(300, "PotPlayer")

    ; 注册热键
    ; RegisterPluginKeys(KeyArray, "PluginName")
    RegisterPluginKeys(KeyArray, "Everything")

    ;设置全局热键
    vim.map("<w-o>", "global", "VIM", "MsgBoxTest", "aaBBBcc", "", "这是全局热键示例")
}

;PluginName_Before() ;如有，值=true时，直接发送键值，不执行命令
;PluginName_After() ;如有，值=true时，在执行命令后，再发送键值

;对符合条件的控件使用【normal模式】，而不是【Vim模式】
PotPlayer_Before() {
    ctrl:=ControlGetClassNN(ControlGetFocus("ahk_exe PotPlayerMini64.exe"), "ahk_exe PotPlayerMini64.exe")
    if RegExMatch(ctrl, "Edit2")
        return true
    return false
}

PotPlayer_隐藏程序(*){
    WinMinimize "ahk_class PotPlayer"
    sleep 50
    WinHide "ahk_class PotPlayer"
}

PotPlayer_显示程序(*){
    WinShow "ahk_class PotPlayer"
}

PotPlayer_打开存档1(aFile){
    run aFile
}

PotPlayer_保存存档1(*){
    MsgBox "已保存"
}

