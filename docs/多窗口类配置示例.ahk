/*
多窗口类配置示例
演示如何为同一个插件配置多个窗口类，适用于软件的不同版本
*/

; 方案一：使用管道符分隔多个class（推荐用于少量版本）
AfterEffects_Simple() {
    ; 支持AE 2024的多个版本
    vim.SetWin("AfterEffects", "AE_CApplication_24.6|AE_CApplication_24.7|AE_CApplication_24.8", "AfterFX.exe")
    
    ; 注册热键...
    KeyArray := Array()
    KeyArray.push({ Key: "r", Mode: "VIM模式", Group: "渲染", Func: "AE_Render", Param: "", Comment: "开始渲染" })
    RegisterPluginKeys(KeyArray, "AfterEffects")
}

; 方案二：使用SetWinGroup方法（推荐用于大量版本）
AfterEffects_Advanced() {
    ; 定义所有支持的AE版本
    AE_Classes := [
        "AE_CApplication_11.0",  ; AE CS6
        "AE_CApplication_12.0",  ; AE CC
        "AE_CApplication_13.0",  ; AE CC 2014
        "AE_CApplication_14.0",  ; AE CC 2015
        "AE_CApplication_15.0",  ; AE CC 2017
        "AE_CApplication_16.0",  ; AE CC 2018
        "AE_CApplication_17.0",  ; AE CC 2019
        "AE_CApplication_18.0",  ; AE 2020
        "AE_CApplication_19.0",  ; AE 2021
        "AE_CApplication_20.0",  ; AE 2022
        "AE_CApplication_21.0",  ; AE 2023
        "AE_CApplication_22.0",  ; AE 2024
        "AE_CApplication_23.0"   ; AE 2025
    ]
    
    ; 使用SetWinGroup注册所有版本
    vim.SetWinGroup("AfterEffects", AE_Classes, "AfterFX.exe")
    
    ; 注册热键...
    KeyArray := Array()
    KeyArray.push({ Key: "r", Mode: "VIM模式", Group: "渲染", Func: "AE_Render", Param: "", Comment: "开始渲染" })
    KeyArray.push({ Key: "p", Mode: "VIM模式", Group: "播放", Func: "AE_Preview", Param: "", Comment: "预览" })
    RegisterPluginKeys(KeyArray, "AfterEffects")
}

; 方案三：动态版本检测（最灵活）
AfterEffects_Dynamic() {
    ; 动态检测当前系统中安装的AE版本
    AE_Classes := []
    
    ; 检测常见的AE版本范围
    Loop 30 {
        version := 10.0 + A_Index
        className := "AE_CApplication_" . version
        
        ; 这里可以添加更复杂的检测逻辑
        ; 比如检查注册表或进程等
        AE_Classes.Push(className)
    }
    
    vim.SetWinGroup("AfterEffects", AE_Classes, "AfterFX.exe")
    
    ; 注册热键...
    KeyArray := Array()
    KeyArray.push({ Key: "r", Mode: "VIM模式", Group: "渲染", Func: "AE_Render", Param: "", Comment: "开始渲染" })
    RegisterPluginKeys(KeyArray, "AfterEffects")
}

; 示例函数
AE_Render() {
    MsgBox("开始渲染After Effects项目")
}

AE_Preview() {
    MsgBox("开始预览After Effects项目")
}

/*
使用说明：

1. 方案一（管道符分隔）：
   vim.SetWin("PluginName", "Class1|Class2|Class3", "process.exe")
   - 适用于版本较少的情况
   - 语法简单，易于理解

2. 方案二（SetWinGroup）：
   vim.SetWinGroup("PluginName", ["Class1", "Class2", "Class3"], "process.exe")
   - 适用于版本较多的情况
   - 代码更清晰，易于维护

3. 两种方案都支持：
   - 自动匹配任何一个指定的窗口类
   - 保持原有的单一窗口类配置兼容性
   - 支持进程名和标题的匹配
*/