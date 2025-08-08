/*
[PluginInfo]
PluginName=Everything
Author=Kiro
Version=1.0
Comment=Everything搜索工具
*/

; 引入 SingleDoubleLongPress.ahk 库

Everything() {
    ; 热键映射数组
    KeyArray := Array()

    ; 模式切换
    KeyArray.push({ Key: "<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】" })
    KeyArray.push({ Key: "<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】" })
    KeyArray.push({ Key: "<esc>", Mode: "VIM模式", Group: "模式", Func: "VIMD_清除输入键", Param: "", Comment: "清除输入键及提示" })
    KeyArray.push({ Key: "<capslock>", Mode: "VIM模式", Group: "模式", Func: "VIMD_清除输入键", Param: "", Comment: "清除输入键及提示" })

    ; 搜索功能
    ; KeyArray.push({ Key: "1", Mode: "VIM模式", Group: "搜索", Func: "SingleDoubleFullHandlers", Param: "1|Everything_1|Everything_2|Everything_3",
    ;     Comment: "单击/双击/长按" })
    ; KeyArray.push({ Key: "2", Mode: "VIM模式", Group: "搜索", Func: "SingleDoubleFullHandlers", Param: "2|Everything_1|Everything_2",
    ;     Comment: "单击/双击" })
    ; KeyArray.push({ Key: "<c-1>", Mode: "VIM模式", Group: "搜索", Func: "SingleDoubleFullHandlers", Param: "3",
    ;     Comment: "单击" })
    KeyArray.push({ Key: "/d", Mode: "VIM模式", Group: "网站", Func: "run", Param: "http://www.deepseek.com",
    Comment: "打开deepseek" })
    KeyArray.push({ Key: "/g", Mode: "VIM模式", Group: "网站", Func: "run", Param: "http://www.google.com",
    Comment: "打开google" })


    ; 帮助
    KeyArray.push({ Key: ":?", Mode: "VIM模式", Group: "帮助", Func: "VIMD_ShowKeyHelpWithGui", Param: "Everything",
        Comment: "显示所有按键(GUI)" })
    KeyArray.push({ Key: "i", Mode: "VIM模式", Group: "帮助", Func: "VIMD_ShowKeyHelpMD", Param: "Everything|VIM模式",
        Comment: "显示按键(Markdown)" })

    ; 注册窗体
    vim.SetWin("Everything", "EVERYTHING", "Everything.exe")

    ; 设置超时
    vim.SetTimeOut(300, "Everything")

    ; 注册热键
    RegisterPluginKeys(KeyArray, "Everything")
}

; 对符合条件的控件使用【normal模式】，而不是【Vim模式】
Everything_Before() {
    ctrl := ControlGetClassNN(ControlGetFocus("ahk_exe Everything.exe"), "ahk_exe Everything.exe")
    if RegExMatch(ctrl, "Edit")
        return true
    return false
}

; 运行Everything
Run_Everything(*) {
    ; 从插件配置文件获取Everything路径
    everythingPath := ""
    try {
        ; 优先从插件独立配置文件读取
        if (PluginConfigs.HasOwnProp("Everything") && PluginConfigs.Everything.HasOwnProp("Everything")) {
            everythingPath := PluginConfigs.Everything.Everything.everything_path
        }
        ; 如果插件配置不存在，尝试从主配置文件读取（向后兼容）
        else if (INIObject.HasOwnProp("Everything")) {
            everythingPath := INIObject.Everything.everything_path
        }
    } catch {
        ; 配置读取失败，使用默认路径
    }
    
    ; 如果配置中没有路径，尝试默认路径
    if (!everythingPath) {
        defaultPaths := [
            "C:\Program Files\Everything\Everything.exe",
            "C:\Program Files (x86)\Everything\Everything.exe",
            "D:\WorkFlow\tools\TotalCMD\Tools\Everything\Everything.exe"
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
        ; 使用修改后的 LaunchOrShow 函数，现在可以安全地省略第三个参数
        LaunchOrShow(everythingPath, "EVERYTHING")
    } else {
        MsgBox("未找到Everything程序，请检查插件配置文件或在主配置文件中设置正确的路径。", "错误", "Icon!")
    }
}

; 打开Everything搜索对话框
Everything_Search(*) {
    ; 先确保Everything已运行
    if !WinExist("ahk_exe Everything.exe") {
        Run_Everything()
        WinWait("ahk_exe Everything.exe", , 3)
    }

    ; 激活Everything窗口并聚焦到搜索框
    if WinExist("ahk_exe Everything.exe") {
        WinActivate
        Send "^f"  ; 聚焦到搜索框
    }
}

Everything_1() {
    MsgBox("1")
}
Everything_2() {
    MsgBox("2")
}
Everything_3() {
    MsgBox("3")
}
