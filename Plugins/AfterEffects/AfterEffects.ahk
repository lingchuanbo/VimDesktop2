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

    ; 基本

    KeyArray.push({ Key: "<Alt>", Mode: "VIM模式", Group: "基本", Func: "AfterEffects_Menu", Param: "", Comment: "菜单" })
    KeyArray.push({ Key: "1", Mode: "VIM模式", Group: "基本", Func: "Script_AfterEffects", Param: "OrganizeProjectAssets.jsx",Comment: "整理" })
    KeyArray.push({ Key: "oo", Mode: "VIM模式", Group: "基本", Func: "SendKeyInput", Param: "^o", Comment: "打开 文件" })
    KeyArray.push({ Key: "or", Mode: "VIM模式", Group: "基本", Func: "AfterEffects_OpenLocalFilesRender", Param: "",Comment: "打开 渲染文件所以位置" })
    KeyArray.push({ Key: "of", Mode: "VIM模式", Group: "基本", Func: "AfterEffects_OpenLocalFiles", Param: "", Comment: "打开 文件所以位置" })
    KeyArray.push({ Key: "op", Mode: "VIM模式", Group: "基本", Func: "Script_AfterEffects", Param: "CompostionOption.jsx",Comment: "修改 合成设置" })

    ; 控制 位置 旋转 缩放 透明
    KeyArray.push({ Key: "p", Mode: "VIM模式", Group: "控制", Func: "SingleDoubleFullHandlers", Param: "p|AfterEffects_位置|Everything_2|AfterEffects_位置K帧",Comment: "位置/双击/位置K帧" })
    KeyArray.push({ Key: "r", Mode: "VIM模式", Group: "控制", Func: "SingleDoubleFullHandlers", Param: "r|AfterEffects_旋转|Everything_2|AfterEffects_旋转K帧",Comment: "旋转/双击/旋转K帧" })
    KeyArray.push({ Key: "s", Mode: "VIM模式", Group: "控制", Func: "SingleDoubleFullHandlers", Param: "s|AfterEffects_缩放|Everything_2|AfterEffects_缩放K帧",Comment: "缩放/双击/缩放K帧" })
    KeyArray.push({ Key: "t", Mode: "VIM模式", Group: "控制", Func: "SingleDoubleFullHandlers", Param: "t|AfterEffects_透明|Everything_2|AfterEffects_透明K帧",Comment: "透明/双击/透明K帧" })
    KeyArray.push({ Key: "d", Mode: "VIM模式", Group: "控制", Func: "SingleDoubleFullHandlers", Param: "d|AfterEffects_图层切换到Add|AfterEffects_克隆图层|AfterEffects_删除",Comment: "Add/克隆/透明K帧" })
    KeyArray.push({ Key: "g", Mode: "VIM模式", Group: "控制", Func: "SingleDoubleFullHandlers", Param: "g|AfterEffects_图层转为网格层|AfterEffects_图层定位项目位置|AfterEffects_素材本地位置",Comment: "图层转为网格层/定位/所在位置" })

    ; 图层
    KeyArray.push({ Key: "cc", Mode: "VIM模式", Group: "控制", Func: "Script_AfterEffects", Param: "LayerConvertLocalAssets.jsx",Comment: "转为本地素材" })

    ; 项目
    KeyArray.push({ Key: "cf", Mode: "VIM模式", Group: "项目", Func: "Script_AfterEffects", Param: "CollectFootages.jsx",Comment: "收集素材到文件目录" })
    KeyArray.push({ Key: "b", Mode: "VIM模式", Group: "项目", Func: "Script_AfterEffects", Param: "CollectFootages_Fixed.jsx",Comment: "收集素材到文件目录" })

    ;渲染
    KeyArray.push({ Key: "qq", Mode: "VIM模式", Group: "基本", Func: "Script_AfterEffects", Param: "RenderToSaveFilesAndOpen.jsx",Comment: "渲染 快速" })
    KeyArray.push({ Key: "qt", Mode: "VIM模式", Group: "项目", Func: "AfterEffects_RenderFilesWithTC", Param: "", Comment: "渲染 TC激活窗口" })
    KeyArray.push({ Key: "qb", Mode: "VIM模式", Group: "项目", Func: "SendKeyInput", Param: "^m", Comment: "收集素材到文件目录" })
    KeyArray.push({ Key: "qx", Mode: "VIM模式", Group: "项目", Func: "Script_AfterEffects", Param: "RenderQueueDel.jsx",Comment: "清理渲染列队" })
    KeyArray.push({ Key: "qc", Mode: "VIM模式", Group: "项目", Func: "Script_AfterEffects", Param: "分层渲染.jsx", Comment: "渲染 分层" })
    KeyArray.push({ Key: "qa", Mode: "VIM模式", Group: "项目", Func: "render_menu", Param: "", Comment: "渲染菜单" })

    ; 效果
    KeyArray.push({ Key: "<LB-t>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&Tint.jsx",Comment: "添加 Tint" })
    KeyArray.push({ Key: "<LB-r>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&RoughenEdges.jsx",Comment: "添加 RoughenEdges" })
    KeyArray.push({ Key: "<LB-g>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&Glow.jsx",Comment: "添加 Glow" })
    KeyArray.push({ Key: "<LB-s>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&Sharpen.jsx",Comment: "添加 Sharpen" })
    KeyArray.push({ Key: "<LB-u>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&UnMult.jsx",Comment: "添加 UnMult" })
    KeyArray.push({ Key: "<LB-w>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&LinearWipe.jsx",Comment: "添加 LinearWipe" })
    KeyArray.push({ Key: "<LB-k>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&LinearColorKey.jsx",Comment: "添加 LinearColorKey" })
    KeyArray.push({ Key: "<LB-i>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&Invert.jsx",Comment: "添加 Invert" })
    KeyArray.push({ Key: "<LB-c>", Mode: "VIM模式", Group: "效果", Func: "Script_AfterEffects", Param: "AddEffect\&Curves.jsx",Comment: "添加 Curves" })

    ; 帮助
    KeyArray.push({ Key: ":/", Mode: "VIM模式", Group: "帮助", Func: "VIMD_ShowKeyHelpWithGui", Param: "AfterEffects",Comment: "显示所有按键(ToolTip)" })
    KeyArray.push({ Key: ":1", Mode: "VIM模式", Group: "帮助", Func: "AfterEffects_Initialization", Param: "", Comment: "初始化" })
    ;注册窗体,请务必保证 PluginName 和文件名一致，以避免名称混乱影响使用
    ;如果 class 和 exe 同时填写，以 exe 为准
    ;vim.SetWin("PluginName", "ahk_class名")
    ;vim.SetWin("PluginName", "ahk_class名", "PluginName.exe")
    ; vim.SetWin("AfterEffects", "", "AfterFX.exe")
    vim.SetWin("AfterEffects", "AE_CApplication_24.6|AE_CApplication_24.7|AE_CApplication_24.6.2", "AfterFX.exe")

    ;设置超时
    vim.SetTimeOut(300, "AfterEffects")

    RegisterPluginKeys(KeyArray, "AfterEffects")

    ; 设置自动IME切换（优化延迟配置）
    AutoIMESwitcher.Setup("AfterFX.exe"), {
        enableDebug: false,  ; 关闭调试信息，减少干扰
        checkInterval: 200,  ; 减少检查间隔，提高响应速度
        enableMouseClick: true,
        inputControlPatterns: ["Edit", "Edit2", "Edit3"],
        cursorTypes: ["IBeam"],  ; 移除Unknown，避免误判
        maxRetries: 3,  ; 减少重试次数，提高速度
        autoSwitchTimeout: 5000  ; 5
    }
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

AfterEffects_位置() {
    Send("{p}")
}
AfterEffects_位置K帧() {
    Send ("!+P")
}
AfterEffects_旋转() {
    Send("r")
}
AfterEffects_旋转K帧() {
    Send("!+r")
}
AfterEffects_缩放() {
    Send("s")
}
AfterEffects_缩放K帧() {
    Send("!+s")
}
AfterEffects_透明() {
    Send("t")
}
AfterEffects_透明K帧() {
    Send("!+t")
}

AfterEffects_克隆图层() {
    Send("^d")
}

AfterEffects_图层切换到Add() {
    Script_AfterEffects("DifferenceToggleAdd.jsx")
}

AfterEffects_删除() {
    Send("^{{Delete}}")
}

; 基本功能(快捷键)

AfterEffects_预合成() {
    Send "^+c"
}

AfterEffects_新建合成() {
    send "^n"
}

AfterEffects_固态层() {
    send "^y"
}

AfterEffects_调节层() {
    send "^!y"
}

AfterEffects_Null() {
    send "^!+y"
}

AfterEffects_优化合成时间() {
    send "^+x"
}

; 时间轴 图层

; 图层 上移一层
AfterEffects_LayerMoveUp() {
    send ("^{]}")
}
; 图层 下移一层
AfterEffects_LayerMoveDown() {
    send ("^{[}")
}

AfterEffects_图层转为网格层() {
    Script_AfterEffects("LayerGuideLayer.jsx")
}

AfterEffects_图层定位项目位置() {
    Script_AfterEffects("RevealLayerSourceInProject.jsx")
}

AfterEffects_素材本地位置() {
    Script_AfterEffects("RevealLayerSourceInExplorer.jsx")
}

AfterEffects_图层转为本地素材() {
    Script_AfterEffects("LayerConvertLocalAssets.jsx")
}

; 打开本地文件
AfterEffects_OpenLocalFiles() {
    if ProcessExist("TOTALCMD.exe") {
        Script_AfterEffects("OpenLocalFliesTC.jsx")

    } else {
        Script_AfterEffects("OpenLocalFlies.jsx")
    }
}

; 打开本地渲染文件
AfterEffects_OpenLocalFilesRender() {

    if ProcessExist("TOTALCMD.exe") {

        Script_AfterEffects("OpenLocalFilesRenderTC.jsx")

    } else {

        Script_AfterEffects("OpenLocalFilesRender.jsx")

        Sleep(1000)

        Send("{Enter}")
    }
}
; 渲染 到 ToTal Commander打开的窗口
AfterEffects_RenderFilesWithTC() {
    FileList := A_Clipboard
    sleep 100
    TC_SendPos(2029) ;获取路径
    sleep 100
    ClipWait(1)
    srcDIR := A_Clipboard
    setPath := StrReplace(srcDIR, "\", "\\")
    setPreset := A_ScriptDir . "\plugins\AfterEffects\Script\OpenLocalFilesRenderTCAtive.jsx"
    ; FileDelete(setPreset) ;避免重复删除文件
    jsCode := "// 清空渲染列队`n"
    jsCode .= "while (app.project.renderQueue.numItems > 0){`n"
    jsCode .= "    app.project.renderQueue.item(app.project.renderQueue.numItems).remove();`n"
    jsCode .= "    };`n"
    jsCode .= "// 输出格式`n"
    jsCode .= "var outputName =`"[#####].png`";`n"
    jsCode .= "// 添加渲染`n"
    jsCode .= "var comp = app.project.activeItem;`n"
    jsCode .= "var qItem = app.project.renderQueue.items.add(comp);`n"
    jsCode .= "//获取输出路径`n"
    jsCode .= "var getPath = `"" . setPath . "`";`n"
    jsCode .= "// Folder(getPath).create();`n"
    jsCode .= "//设置渲染输出`n"
    jsCode .= "qItem.outputModules[1].file = new File(getPath + `"\\\\`" + outputName);`n"
    jsCode .= "// 渲染`n"
    jsCode .= "app.project.renderQueue.render();"
    FileAppend(jsCode, setPreset, "UTF-8")
    Sleep(400)
    Script_AfterEffects("OpenLocalFilesRenderTCAtive.jsx")
    Sleep(1000)
    FileDelete(setPreset) ;避免重复删除文件
}

render_menu() {
    RenderMenu := Menu()
    ; 添加菜单项
    RenderMenu.Add("动作#方向", (*) => Script_AfterEffects(
        "Render_CreateFolderAndOutputForSelectedComps_AttackDirection.jsx"))
    RenderMenu.Add("名字#动作#方向", (*) => Script_AfterEffects(
        "Render_CreateFolderAndOutputForSelectedComps_NameAttackDirection.jsx"))
    RenderMenu.Add("名字#方向", (*) => Script_AfterEffects("Render_CreateFolderAndOutputForSelectedComps_NameDirection.jsx"
    ))
    RenderMenu.Add("名字", (*) => Script_AfterEffects("Render_CreateFolderAndOutputForSelectedComps_Name.jsx"))
    ; VIMD_清除输入键()
    RenderMenu.Show()
}

; 定义全局脚本路径配置
GetAfterEffectsScriptPaths() {
    ; 基础目录
    baseDir := A_ScriptDir "\plugins\AfterEffects\Script"

    ; 返回路径配置
    return {
        baseDir: baseDir,
        dirPaths: [
            baseDir "\Menu",
            baseDir "\AddEffect",
            baseDir "\Expression"
        ],
        dirNames: ["脚本库", "特效", "表达式"]
    }
}

AfterEffects_Menu() {
    try {
        AfterEffectsMenu := Menu()
        ; 获取脚本路径配置
        pathConfig := GetAfterEffectsScriptPaths()
        ; 跟踪添加到父菜单的项目数量
        totalMenuItems := 0
        ; 为每个目录创建子菜单
        for index, dirPath in pathConfig.dirPaths {
            ; 创建子菜单
            subMenu := Menu()
            ; 使用增强版的目录扫描函数，它会自动保留完整文件路径
            itemCount := ScanDirectoryForMenuEx(subMenu, dirPath, "*.js|*.jsx|*.txt", AfterEffects_HandleMenuClick)
            ; 如果子菜单有内容，添加到父菜单
            if (itemCount > 0) {
                AfterEffectsMenu.Add(pathConfig.dirNames[index], subMenu)
                totalMenuItems++
            }
        }
        AfterEffectsMenu.Add("快速匹配素材", (*) => Script_AfterEffects(".jsx"))
        AfterEffectsMenu.Add("替换素材", (*) => Script_AfterEffects("BatchReplaceFileLocationsWithTextFile.jsx"))
        AfterEffectsMenu.Add("重命名", (*) => Script_AfterEffects(".jsx"))
        AfterEffectsMenu.Add("素材帧率统一", (*) => Script_AfterEffects(".jsx"))
        AfterEffectsMenu.Add("克隆合成组", (*) => Script_AfterEffects(".jsx"))
        AfterEffectsMenu.Add("拆分为序列", (*) => Script_AfterEffects(".jsx"))
        try {
            if (totalMenuItems > 0) {
                AfterEffectsMenu.Show()
            } else {
                MsgBox("没有在指定目录中找到匹配的文件")
            }
        } catch as err {
            MsgBox("显示菜单时出错: " err.Message)
        }
    } catch as err {
        MsgBox("创建多目录菜单时出错: " err.Message)
    }
}

AfterEffects_HandleMenuClick(ItemName, ItemPos, MenuName, filePath := "") {
    ; 获取文件扩展名
    SplitPath(filePath, , , &fileExt)

    ; 根据文件类型进行不同处理
    if (fileExt = "txt") {
        ; 处理表达式文件 - 读取内容并复制到剪贴板
        AfterEffects_HandleExpression(filePath)
    } else if (fileExt = "js" || fileExt = "jsx") {
        ; 处理脚本文件 - 正常执行
        Script_AfterEffects(filePath)
    } else {
        ; 未知文件类型，默认按脚本处理
        Script_AfterEffects(filePath)
    }
}

; 处理表达式文件的函数
AfterEffects_HandleExpression(filePath) {
    try {
        ; 检查文件是否存在
        if !FileExist(filePath) {
            MsgBox("表达式文件不存在: " . filePath, "错误", "Icon!")
            return
        }

        ; 读取文件内容
        expressionContent := FileRead(filePath, "UTF-8")

        ; 检查内容是否为空
        if (StrLen(Trim(expressionContent)) = 0) {
            MsgBox("表达式文件为空: " . filePath, "提示", "Icon!")
            return
        }

        ; 获取文件名用于提示
        SplitPath(filePath, &fileName)

        ; 创建临时JSX脚本来应用表达式
        AfterEffects_ApplyExpressionScript(expressionContent, fileName)

    } catch Error as e {
        MsgBox("读取表达式文件时出错: " . e.Message, "错误", "Icon!")
    }
}

; 创建并执行JSX脚本来应用表达式
AfterEffects_ApplyExpressionScript(expressionContent, fileName) {
    try {
        ; 转义表达式内容中的特殊字符
        escapedExpression := StrReplace(expressionContent, "\", "\\")
        escapedExpression := StrReplace(escapedExpression, "`"", "\`"")
        escapedExpression := StrReplace(escapedExpression, "`n", "\\n")
        escapedExpression := StrReplace(escapedExpression, "`r", "\\r")

        ; 创建临时JSX脚本
        tempScriptPath := A_ScriptDir "\plugins\AfterEffects\Script\temp_apply_expression.jsx"
        ; JSX脚本内容
        jsxCode := "try {`n"
        jsxCode .= "    // 检查是否有活动合成`n"
        jsxCode .= "    if (!app.project.activeItem || !(app.project.activeItem instanceof CompItem)) {`n"
        jsxCode .= "        alert('请先选择一个合成');`n"
        jsxCode .= "        return;`n"
        jsxCode .= "    }`n"
        jsxCode .= "`n"
        jsxCode .= "    var comp = app.project.activeItem;`n"
        jsxCode .= "    var selectedLayers = comp.selectedLayers;`n"
        jsxCode .= "`n"
        jsxCode .= "    if (selectedLayers.length === 0) {`n"
        jsxCode .= "        alert('请先选择图层');`n"
        jsxCode .= "        return;`n"
        jsxCode .= "    }`n"
        jsxCode .= "`n"
        jsxCode .= "    // 表达式内容`n"
        jsxCode .= "    var expressionText = `"" . escapedExpression . "`";`n"
        jsxCode .= "`n"
        jsxCode .= "    app.beginUndoGroup('应用表达式: " . fileName . "');`n"
        jsxCode .= "`n"
        jsxCode .= "    var appliedCount = 0;`n"
        jsxCode .= "    var errorCount = 0;`n"
        jsxCode .= "`n"
        jsxCode .= "    // 遍历选中的图层`n"
        jsxCode .= "    for (var i = 0; i < selectedLayers.length; i++) {`n"
        jsxCode .= "        var layer = selectedLayers[i];`n"
        jsxCode .= "        `n"
        jsxCode .= "        // 检查图层是否有选中的属性`n"
        jsxCode .= "        var selectedProperties = layer.selectedProperties;`n"
        jsxCode .= "        `n"
        jsxCode .= "        if (selectedProperties.length > 0) {`n"
        jsxCode .= "            // 应用到选中的属性`n"
        jsxCode .= "            for (var j = 0; j < selectedProperties.length; j++) {`n"
        jsxCode .= "                var prop = selectedProperties[j];`n"
        jsxCode .= "                if (prop.canSetExpression) {`n"
        jsxCode .= "                    try {`n"
        jsxCode .= "                        prop.expression = expressionText;`n"
        jsxCode .= "                        appliedCount++;`n"
        jsxCode .= "                    } catch (e) {`n"
        jsxCode .= "                        errorCount++;`n"
        jsxCode .= "                    }`n"
        jsxCode .= "                }`n"
        jsxCode .= "            }`n"
        jsxCode .= "        } else {`n"
        jsxCode .= "            // 如果没有选中属性，尝试应用到位置属性`n"
        jsxCode .= "            try {`n"
        jsxCode .= "                if (layer.transform && layer.transform.position.canSetExpression) {`n"
        jsxCode .= "                    layer.transform.position.expression = expressionText;`n"
        jsxCode .= "                    appliedCount++;`n"
        jsxCode .= "                }`n"
        jsxCode .= "            } catch (e) {`n"
        jsxCode .= "                errorCount++;`n"
        jsxCode .= "            }`n"
        jsxCode .= "        }`n"
        jsxCode .= "    }`n"
        jsxCode .= "`n"
        jsxCode .= "    app.endUndoGroup();`n"
        jsxCode .= "`n"
        jsxCode .= "    // 显示结果`n"
        jsxCode .= "    var message = '表达式应用完成:\\n';`n"
        jsxCode .= "    message += '成功: ' + appliedCount + ' 个属性\\n';`n"
        jsxCode .= "    if (errorCount > 0) {`n"
        jsxCode .= "        message += '失败: ' + errorCount + ' 个属性';`n"
        jsxCode .= "    }`n"
        jsxCode .= "    alert(message);`n"
        jsxCode .= "`n"
        jsxCode .= "} catch (e) {`n"
        jsxCode .= "    alert('应用表达式时出错: ' + e.toString());`n"
        jsxCode .= "}"

        ; 写入临时脚本文件
        ; FileDelete(tempScriptPath)  ; 删除可能存在的旧文件
        FileAppend(jsxCode, tempScriptPath, "UTF-8")

        ; 执行脚本
        Script_AfterEffects("temp_apply_expression.jsx")

        ; 显示提示
        ToolTip("正在应用表达式: " . fileName)
        SetTimer(() => ToolTip(), -2000)
        Sleep(500)
        FileDelete(tempScriptPath) ;避免重复删除文件
    } catch Error as e {
        MsgBox("创建表达式脚本时出错: " . e.Message, "错误", "Icon!")
    }
}