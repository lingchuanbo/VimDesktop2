/*
[PluginInfo]
PluginName=AfterEffects
Author=BoBO
Version=1.0
Comment=AfterEffects
*/

; 引入自动IME切换库

AfterEffects() {
    ;热键映射数组
    KeyArray := Array()
    ;ModeChange为内置函数，用于进行模式的切换
    KeyArray.push({ Key: "<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】" })
    KeyArray.push({ Key: "<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】" })
    KeyArray.push({ Key: "<esc>", Mode: "VIM模式", Group: "模式", Func: "VIMD_清除输入键", Param: "", Comment: "清除输入键及提示" })

    ;SendKeyInput 为内置函数，用于send指定键盘输入
    ;Script_AfterEffects 为运行AE脚本函数Param里面填写 脚本文件名

    KeyArray.push({ Key: "as", Mode: "VIM模式", Group: "控制", Func: "Script_AfterEffects", Param: "Test.jsx", Comment: "脚本测试" })
    KeyArray.push({ Key: "t1", Mode: "VIM模式", Group: "控制", Func: "Script_AfterEffects", Param: "OrganizeProjectAssets.jsx",
        Comment: "整理" })
    KeyArray.push({ Key: "t2", Mode: "VIM模式", Group: "控制", Func: "Script_AfterEffects", Param: "RenderToSaveFilesAndOpen.jsx",
        Comment: "快速渲染" })

    ; 添加效果
    KeyArray.push({ Key: "<LB-t>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&Tint.jsx",
        Comment: "添加 Tint" })
    KeyArray.push({ Key: "<LB-r>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&RoughenEdges.jsx",
        Comment: "添加 RoughenEdges" })
    KeyArray.push({ Key: "<LB-g>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&Glow.jsx",
        Comment: "添加 Glow" })
    KeyArray.push({ Key: "<LB-s>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&Sharpen.jsx",
        Comment: "添加 Sharpen" })
    KeyArray.push({ Key: "<LB-u>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&UnMult.jsx",
        Comment: "添加 UnMult" })
    KeyArray.push({ Key: "<LB-w>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&LinearWipe.jsx",
        Comment: "添加 LinearWipe" })
    KeyArray.push({ Key: "<LB-k>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&LinearColorKey.jsx",
        Comment: "添加 LinearColorKey" })
    KeyArray.push({ Key: "<LB-i>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&Invert.jsx",
        Comment: "添加 Invert" })
    KeyArray.push({ Key: "<LB-c>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&Curves.jsx",
        Comment: "添加 Curves" })

    ; 帮助
    KeyArray.push({ Key: ":/", Mode: "VIM模式", Group: "帮助", Func: "VIMD_ShowKeyHelpWithGui", Param: "AfterEffects",
        Comment: "显示所有按键(ToolTip)" })
    KeyArray.push({ Key: ":1", Mode: "VIM模式", Group: "帮助", Func: "AfterEffects_Initialization", Param: "", Comment: "初始化" })
    ;注册窗体,请务必保证 PluginName 和文件名一致，以避免名称混乱影响使用
    ;如果 class 和 exe 同时填写，以 exe 为准
    ;vim.SetWin("PluginName", "ahk_class名")
    ;vim.SetWin("PluginName", "ahk_class名", "PluginName.exe")
    ; vim.SetWin("AfterEffects", "", "AfterFX.exe")
    vim.SetWin("AfterEffects", "AE_CApplication_24.6|AE_CApplication_24.7|AE_CApplication_24.8", "AfterFX.exe")

    ;设置超时
    vim.SetTimeOut(300, "AfterEffects")

    RegisterPluginKeys(KeyArray, "AfterEffects")

    ; 设置自动IME切换
    AutoIMESwitcher.Setup("AfterFX.exe", {
        enableDebug: false,
        checkInterval: 500,
        enableMouseClick: true,
        inputControlPatterns: ["Edit", "Edit2", "Edit3"],
        cursorTypes: ["IBeam", "Unknown"]
    })
}

;PluginName_Before() ;如有，值=true时，直接发送键值，不执行命令
;PluginName_After() ;如有，值=true时，在执行命令后，再发送键值

;对符合条件的控件使用【normal模式】，而不是【Vim模式】
AfterEffects_Before() {
    ; 使用AutoIMESwitcher处理输入状态检测和IME切换
    return AutoIMESwitcher.HandleBeforeAction("AfterFX.exe")
}

AfterEffects_隐藏程序(*) {
    WinMinimize "ahk_class AfterEffects"
    sleep 50
    WinHide "ahk_class AfterEffects"
}

AfterEffects_显示程序(*) {
    WinShow "ahk_class AfterEffects"
}

;初始化脚本路径
AfterEffects_Initialization() {
    ; 检查After Effects是否正在运行
    if !ProcessExist("AfterFX.exe") {
        MsgBox "After Effects未运行，请先启动After Effects。", "初始化失败", "Icon!"
        return
    }

    ; 获取After Effects路径
    AeExePath := GetProcessPath("AfterFX.exe")
    if !AeExePath {
        MsgBox "无法获取After Effects路径，请确保After Effects正在运行。", "初始化失败", "Icon!"
        return
    }

    ; 确保目录结构存在
    scriptDir := A_ScriptDir "\plugins\AfterEffects\Script"
    if !DirExist(scriptDir)
        DirCreate scriptDir

    commandsDir := scriptDir "\Commands"
    if !DirExist(commandsDir)
        DirCreate commandsDir

    ; 创建初始化脚本文件
    setPreset := scriptDir "\runAEScript.jsx"

    ; 使用FileOpen写入文件
    try {
        ; 创建或清空文件
        FileObj := FileOpen(setPreset, "w", "UTF-8")
        if !FileObj {
            MsgBox Format("无法创建文件: {1}", setPreset)
            return
        }

        ; 写入更可靠的JavaScript代码
        jsCode := "try {`n"
        jsCode .= "    // 确保脚本在After Effects中正确执行`n"
        jsCode .= "    var scriptpath = `"执行初始化`";`n"
        jsCode .= "    alert(scriptpath);`n"
        jsCode .= "    // 写入一个标记文件表示成功`n"
        jsCode .= "    var successFile = new File(File.decode('" StrReplace(scriptDir "\init_success.txt", "\", "\\") "'));`n"
        jsCode .= "    successFile.open('w');`n"
        jsCode .= "    successFile.write('初始化成功: ' + new Date().toString());`n"
        jsCode .= "    successFile.close();`n"
        jsCode .= "} catch(e) {`n"
        jsCode .= "    alert('初始化出错: ' + e.toString());`n"
        jsCode .= "}`n"

        ; 写入文件内容
        FileObj.Write(jsCode)
        FileObj.Close()
    } catch Error as e {
        MsgBox Format("写入文件时出错: {1}", e.Message)
        return
    }

    ; 删除可能存在的旧成功标记文件
    successFile := scriptDir "\init_success.txt"
    if FileExist(successFile)
        FileDelete successFile

    ; 运行脚本
    try {
        ; 使用更可靠的方式运行脚本
        Run AeExePath " -r " setPreset, , "Hide"

        ; 等待脚本执行完成，最多等待3秒
        startTime := A_TickCount
        loop {
            Sleep 100
            if FileExist(successFile) {
                MsgBox "After Effects初始化成功！", "初始化成功", "Icon!"
                break
            }

            ; 如果超过3秒还没成功，提示用户
            if (A_TickCount - startTime > 3000) {
                MsgBox "初始化可能未完成，请再次尝试或检查After Effects是否响应。", "初始化提示", "Icon!"
                break
            }
        }
    } catch Error as e {
        MsgBox Format("运行脚本时出错: {1}", e.Message)
    }

    ; 清理文件
    Sleep 200
    if FileExist(setPreset)
        FileDelete setPreset
    if FileExist(successFile)
        FileDelete successFile
}
