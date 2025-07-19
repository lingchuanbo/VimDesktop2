/*
[PluginInfo]
PluginName=Everything
Author=Kiro
Version=1.0
Comment=Everything搜索工具
*/

Everything() {
    ; 热键映射数组
    KeyArray := Array()
    
    ; 模式切换
    KeyArray.push({ Key: "<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】" })
    KeyArray.push({ Key: "<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】" })
    KeyArray.push({ Key: "<esc>", Mode: "VIM模式", Group: "模式", Func: "VIMD_清除输入键", Param: "", Comment: "清除输入键及提示" })
    
    ; 搜索功能
    ; KeyArray.push({ Key: "s", Mode: "VIM模式", Group: "搜索", Func: "Everything_Search", Param: "", Comment: "打开搜索对话框" })
    ; KeyArray.push({ Key: "r", Mode: "VIM模式", Group: "搜索", Func: "Everything_Run", Param: "", Comment: "运行Everything" })
    
    ; 帮助
    KeyArray.push({ Key: "?", Mode: "VIM模式", Group: "帮助", Func: "VIMD_ShowKeyHelpWithGui", Param: "Everything", Comment: "显示所有按键(ToolTip)" })
    KeyArray.push({ Key: "/", Mode: "VIM模式", Group: "帮助", Func: "VIMD_ShowKeyHelp", Param: "Everything|VIM模式", Comment: "显示所有按键(MsgBox)" })
    
    ; 注册窗体
    vim.SetWin("Everything", "EVERYTHING", "Everything.exe")
    
    ; 设置超时
    vim.SetTimeOut(300, "Everything")
    
    ; 注册热键
    for k, v in KeyArray {
        if (v.Key != "")  ; 方便类似TC类全功能，仅启用部分热键的情况
            vim.map(v.Key, "Everything", v.Mode, v.Func, v.Param, v.Group, v.Comment)
    }
}

; 对符合条件的控件使用【normal模式】，而不是【Vim模式】
Everything_Before() {
    ctrl := ControlGetClassNN(ControlGetFocus("ahk_exe Everything.exe"), "ahk_exe Everything.exe")
    if RegExMatch(ctrl, "Edit")
        return true
    return false
}

; 运行Everything
Everything_Run(*) {
    ; 从配置文件获取Everything路径
    everythingPath := ""
    try {
        everythingPath := INIObject.Everything.everything_path
    } catch {
        ; 如果配置文件中没有路径，尝试默认路径
        defaultPaths := [
            "D:\BoBO\WorkFlow\tools\TotalCMD\Tools\Everything\Everything.exe",
            "C:\Program Files\Everything\Everything.exe",
            "C:\Program Files (x86)\Everything\Everything.exe"
        ]
        
        for path in defaultPaths {
            if FileExist(path) {
                everythingPath := path
                break
            }
        }
    }
    
    ; 如果找到了Everything路径，运行它
    if (everythingPath && FileExist(everythingPath)) {
        Run everythingPath
    } else {
        MsgBox("未找到Everything程序，请在vimd.ini中设置正确的路径。", "错误", "Icon!")
    }
}

; 打开Everything搜索对话框
Everything_Search(*) {
    ; 先确保Everything已运行
    if !WinExist("ahk_exe Everything.exe") {
        Everything_Run()
        WinWait("ahk_exe Everything.exe", , 3)
    }
    
    ; 激活Everything窗口并聚焦到搜索框
    if WinExist("ahk_exe Everything.exe") {
        WinActivate
        Send "^f"  ; 聚焦到搜索框
    }
}