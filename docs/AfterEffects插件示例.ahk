/*
[PluginInfo]
PluginName=AfterEffects
Author=Kiro
Version=2.0
Comment=Adobe After Effects多版本支持示例
*/

AfterEffects() {
    ; 热键映射数组
    KeyArray := Array()

    ; 模式切换
    KeyArray.push({ Key: "<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】" })
    KeyArray.push({ Key: "<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】" })
    KeyArray.push({ Key: "<esc>", Mode: "VIM模式", Group: "模式", Func: "VIMD_清除输入键", Param: "", Comment: "清除输入键及提示" })

    ; 渲染功能
    KeyArray.push({ Key: "r", Mode: "VIM模式", Group: "渲染", Func: "AE_StartRender", Param: "", Comment: "开始渲染" })
    KeyArray.push({ Key: "R", Mode: "VIM模式", Group: "渲染", Func: "AE_StopRender", Param: "", Comment: "停止渲染" })

    ; 播放控制
    KeyArray.push({ Key: "p", Mode: "VIM模式", Group: "播放", Func: "AE_PlayPause", Param: "", Comment: "播放/暂停" })
    KeyArray.push({ Key: "P", Mode: "VIM模式", Group: "播放", Func: "AE_Preview", Param: "", Comment: "RAM预览" })

    ; 脚本执行
    KeyArray.push({ Key: "s", Mode: "VIM模式", Group: "脚本", Func: "Script_AfterEffects", Param: "test.jsx", Comment: "运行测试脚本" })

    ; 帮助
    KeyArray.push({ Key: ":?", Mode: "VIM模式", Group: "帮助", Func: "VIMD_ShowKeyHelpWithGui", Param: "AfterEffects",
        Comment: "显示所有按键" })

    ; 方案一：使用管道符分隔（适用于特定版本）
    ; vim.SetWin("AfterEffects", "AE_CApplication_24.6|AE_CApplication_24.7|AE_CApplication_24.8", "AfterFX.exe")

    ; 方案二：使用SetWinGroup（推荐，支持所有版本）
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
        "AE_CApplication_23.0",  ; AE 2025
        "AE_CApplication_24.0",  ; AE 2026
        "AE_CApplication_24.6",  ; AE 2024.6
        "AE_CApplication_24.7",  ; AE 2024.7
        "AE_CApplication_24.8"   ; AE 2024.8
    ]

    vim.SetWinGroup("AfterEffects", AE_Classes, "AfterFX.exe")

    ; 设置超时
    vim.SetTimeOut(300, "AfterEffects")

    ; 注册热键
    RegisterPluginKeys(KeyArray, "AfterEffects")
}

; AE功能函数
AE_StartRender() {
    Send "^{F12}"  ; Ctrl+F12 开始渲染
}

AE_StopRender() {
    Send "{Esc}"   ; ESC 停止渲染
}

AE_PlayPause() {
    Send "{Space}" ; 空格键播放/暂停
}

AE_Preview() {
    Send "{F12}"   ; F12 RAM预览
}

/*
使用说明：

1. 这个示例展示了如何为Adobe After Effects配置多版本支持
2. 支持从CS6到最新版本的所有AE版本
3. 使用SetWinGroup方法，代码更清晰易维护
4. 保持了与原有Script_AfterEffects函数的兼容性

优势：
- 一次配置，支持所有AE版本
- 用户升级AE版本后无需修改配置
- 代码结构清晰，易于维护和扩展
*/
#Requires AutoHotkey v2.0