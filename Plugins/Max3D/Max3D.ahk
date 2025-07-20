/*
[PluginInfo]
PluginName=Max3D
Author=Kiro
Version=1.0
Comment=3DsMax搜索工具
*/

Max3D() {
    ; 热键映射数组
    KeyArray := Array()
    
    ; 模式切换
    KeyArray.push({ Key: "<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】" })
    KeyArray.push({ Key: "<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】" })
    KeyArray.push({ Key: "<esc>", Mode: "VIM模式", Group: "模式", Func: "VIMD_清除输入键", Param: "", Comment: "清除输入键及提示" })
    
    ; 搜索功能
    KeyArray.push({ Key: "ts", Mode: "VIM模式", Group: "搜索", Func: "Script_3DsMax", Param: "旋转90.ms", Comment: "旋转90" })
    KeyArray.push({ Key: "tr", Mode: "VIM模式", Group: "搜索", Func: "Script_3DsMax", Param: "旋转-90", Comment: "旋转-90" })
    
    ; 帮助
    KeyArray.push({ Key: "?", Mode: "VIM模式", Group: "帮助", Func: "VIMD_ShowKeyHelpWithGui", Param: "Max3D", Comment: "显示所有按键(ToolTip)" })

    ; 注册窗体
    vim.SetWin("Max3D", "3DsMax", "3dsmax.exe")
    
    ; 设置超时
    vim.SetTimeOut(300, "Max3D")
    
    ; 注册热键
    RegisterPluginKeys(KeyArray, "Max3D")
}

; 对符合条件的控件使用【normal模式】，而不是【Vim模式】
Max3D_Before() {
    ctrl := ControlGetClassNN(ControlGetFocus("ahk_exe 3dsmax.exe"), "ahk_exe 3dsmax.exe")
    if RegExMatch(ctrl, "Edit")
        return true
    return false
}

; 运行3DsMax
Max3D_Run(*) {
    ; 从配置文件获取3DsMax路径
    maxPath := ""
    try {
        maxPath := INIObject.Max3D.max3d_path
    } catch {
        ; 如果配置文件中没有路径，尝试默认路径
        defaultPaths := [
            "D:\BoBO\WorkFlow\tools\TotalCMD\Tools\3DsMax\3DsMax.exe",
            "C:\Program Files\3DsMax\3DsMax.exe",
            "C:\Program Files (x86)\3DsMax\3DsMax.exe"
        ]
        
        for path in defaultPaths {
            if FileExist(path) {
                maxPath := path
                break
            }
        }
    }
    
    ; 如果找到了3DsMax路径，运行它
    if (maxPath && FileExist(maxPath)) {
        Run maxPath
    } else {
        MsgBox("未找到3DsMax程序，请在vimd.ini中设置正确的路径。", "错误", "Icon!")
    }
}

; 打开3DsMax搜索对话框
Max3D_Search(*) {
    ; 先确保3DsMax已运行
    if !WinExist("ahk_exe 3DsMax.exe") {
        Max3D_Run()
        WinWait("ahk_exe 3DsMax.exe", , 3)
    }
    
    ; 激活3DsMax窗口并聚焦到搜索框
    if WinExist("ahk_exe 3DsMax.exe") {
        WinActivate
        Send "^f"  ; 聚焦到搜索框
    }
}