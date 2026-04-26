#Requires AutoHotkey v2.0
/**
 * 注册插件热键的通用函数
 * 
 * 这个函数处理插件中的KeyArray数组，并正确注册所有热键
 * 特别处理SingleDoubleFullHandlers函数，确保它能正确工作
 * 
 * @param KeyArray 热键数组
 * @param pluginName 插件名称
 */

RegisterPluginKeys(KeyArray, pluginName) {
    ; 初始化全局处理函数存储（如果不存在）
    global singleDoubleHandlers
    if (!IsSet(singleDoubleHandlers))
        singleDoubleHandlers := Map()

    for k, v in KeyArray {
        if (v.Key != "") {  ; 方便类似TC类全功能，仅启用部分热键的情况
            ; 特殊处理 SingleDoubleFullHandlers 函数
            if (v.Func = "SingleDoubleFullHandlers") {
                ; 创建处理函数但不直接注册热键，让vim系统来处理
                handler := CreateSingleDoubleFullHandler(v.Param)
                ; 将处理函数存储在全局变量中，以便Action可以调用
                singleDoubleHandlers[v.Key] := handler
                ; 注册到vim映射系统中
                vim.map(v.Key, pluginName, v.Mode, v.Func, v.Param, v.Group, v.Comment)
            } else {
                vim.map(v.Key, pluginName, v.Mode, v.Func, v.Param, v.Group, v.Comment)
            }
        }
    }
}

; 注册所有插件通用的模式切换键（<insert> 在普通模式和VIM模式之间切换）
; normalMode 和 vimMode 的默认值与项目中所有插件一致
RegisterStandardModeKeys(KeyArray, normalMode := "普通模式", vimMode := "VIM模式") {
    KeyArray.push({ Key: "<insert>", Mode: normalMode, Group: "模式", Func: "ModeChange", Param: vimMode, Comment: "切换到【" vimMode "】" })
    KeyArray.push({ Key: "<insert>", Mode: vimMode, Group: "模式", Func: "ModeChange", Param: normalMode, Comment: "切换到【" normalMode "】" })
}