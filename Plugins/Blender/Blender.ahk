/*
[PluginInfo]
PluginName=Blender
Author= BoBO
Version=1.0
Comment=Blender插件
*/

Blender() {
    ; 热键映射数组
    KeyArray := Array()

    ; 模式切换
    KeyArray.push({ Key: "<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】" })
    KeyArray.push({ Key: "<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】" })
    KeyArray.push({ Key: "<esc>", Mode: "VIM模式", Group: "模式", Func: "VIMD_清除输入键", Param: "", Comment: "清除输入键及提示" })
    KeyArray.push({ Key: "<capslock>", Mode: "VIM模式", Group: "模式", Func: "VIMD_清除输入键", Param: "", Comment: "清除输入键及提示" })

    KeyArray.push({ Key: "/g", Mode: "VIM模式", Group: "创建", Func: "run_BlenderScript", Param: "create_cube.py",Comment: "打开google" })

    ; 注册窗体
    vim.SetWin("Blender", "GHOST_WindowClass", "Blender.exe")

    ; 设置超时
    vim.SetTimeOut(300, "Blender")

    ; 注册热键
    RegisterPluginKeys(KeyArray, "Blender")
}

; 对符合条件的控件使用【normal模式】，而不是【Vim模式】
Blender_Before() {
    ctrl := ControlGetClassNN(ControlGetFocus("ahk_class Blender"), "ahk_exe Blender.exe")
    if RegExMatch(ctrl, "Edit") || RegExMatch(ctrl, "Edit1")
        return true
    return false
}
