/*
[PluginInfo]
PluginName=Max3D
Author=BoBO
Version=1.0
Comment=3DsMax插件
*/
Max3D() {
    pluginName := "Max3D"
    exeName := "3dsmax.exe"

    keyArray := Max3D_BuildKeymap()

    ; 注册窗体
    vim.SetWin(pluginName, "3DsMax", exeName)

    timeoutMs := ConfigService.GetPluginTimeout(pluginName, 300, pluginName)
    imeCfg := ConfigService.GetPluginIMEConfig(pluginName, {
        enabled: true,
        enableDebug: false,
        checkInterval: 200,
        enableMouseClick: true,
        maxRetries: 3,
        autoSwitchTimeout: 5000,
        specialHandling: "ignoreIBeamWithoutControl"
    }, pluginName)

    ; 设置超时
    vim.SetTimeOut(timeoutMs, pluginName)

    ; 注册热键
    RegisterPluginKeys(keyArray, pluginName)

    ; 设置自动IME切换（优化延迟配置）
    Max3D_SetupIME(exeName, imeCfg)
}

Max3D_BuildKeymap() {
    keyArray := []

    ; 模式切换
    Max3D_AddKey(keyArray, "<insert>", "普通模式", "模式", "ModeChange", "VIM模式", "切换到【VIM模式】")
    Max3D_AddKey(keyArray, "<insert>", "VIM模式", "模式", "ModeChange", "普通模式", "切换到【普通模式】")
    Max3D_AddKey(keyArray, "<esc>", "VIM模式", "模式", "VIMD_清除输入键", "", "清除输入键及提示")

    ; 搜索功能
    Max3D_AddKey(keyArray, "<s-e>", "VIM模式", "控制", "Script_3DsMax", "旋转90.ms", "旋转90")
    Max3D_AddKey(keyArray, "h", "VIM模式", "控制", "Script_3DsMax", "旋转90.ms", "旋转90")
    Max3D_AddKey(keyArray, "<s-r>", "VIM模式", "控制", "Script_3DsMax", "旋转-90.ms", "旋转-90")
    Max3D_AddKey(keyArray, "<LB-e>", "VIM模式", "控制", "Script_3DsMax", "Mod_EditPoly.ms", "添加 EditPoly")
    Max3D_AddKey(keyArray, "<LB-d>", "VIM模式", "控制", "Script_3DsMax", "Mod_DeleteMesh.ms", "添加 DeleteMesh")
    Max3D_AddKey(keyArray, "<LB-u>", "VIM模式", "控制", "Script_3DsMax", "Mod_Unwrap_UVW.ms", "添加 Unwrap_UVW")
    Max3D_AddKey(keyArray, "<LB-r>", "VIM模式", "控制", "Script_3DsMax", "Mod_Relax.ms", "添加 Mod_Relax")
    Max3D_AddKey(keyArray, "<LB-s>", "VIM模式", "控制", "Script_3DsMax", "Mod_meshsmooth.ms", "添加 Meshsmooth")

    ; 菜单
    Max3D_AddKey(keyArray, "3", "VIM模式", "打开", "Max3D_Menu", "", "功能菜单")

    ;Max3D_AddKey(keyArray, "1", "VIM模式", "搜索", "SingleDoubleFullHandlers", "1|Everything_1|Everything_2|Everything_3", "单击/双击/长按")

    ; 打开
    Max3D_AddKey(keyArray, "of", "VIM模式", "打开", "Script_3DsMax", "openMaxfileDir.ms", "打开 Max文件所在位置")
    Max3D_AddKey(keyArray, "or", "VIM模式", "打开", "Script_3DsMax", "openRenderDir.ms", "打开 渲染文件所在位置")
    Max3D_AddKey(keyArray, "oo", "VIM模式", "打开", "Script_3DsMax", "id40003", "打开 文件")
    Max3D_AddKey(keyArray, "om", "VIM模式", "打开", "Script_3DsMax", "id40195", "打开 融合文件")

    ; 渲染
    Max3D_AddKey(keyArray, "qc", "VIM模式", "项目", "Script_3DsMax", "BatchCloneRender.ms", "批量克隆渲染")
    Max3D_AddKey(keyArray, "qb", "VIM模式", "项目", "Script_3DsMax", "BatchRenderP.ms", "批量渲染工具")
    Max3D_AddKey(keyArray, "qq", "VIM模式", "渲染", "Script_3DsMax", "RenderQ.ms", "快速渲染")
    Max3D_AddKey(keyArray, "qt", "VIM模式", "渲染", "Max3D_RenderDirtoTC", "", "快速渲染到TC激活面板")
    Max3D_AddKey(keyArray, "qs", "VIM模式", "项目", "Script_3DsMax", "Render.ms", "快速渲染-文件同级目录")
    Max3D_AddKey(keyArray, "qa", "VIM模式", "项目", "Script_3DsMax", "RenderLayer.ms", "分层渲染")
    Max3D_AddKey(keyArray, "qx", "VIM模式", "项目", "Max3D_WinClose", "", "批量渲染工具")

    ; FumeFX
    Max3D_AddKey(keyArray, "ff", "VIM模式", "FumeFX", "Script_3DsMax", "FumeFX_FXdef.ms", "FumeFX快速创建")
    Max3D_AddKey(keyArray, "fa", "VIM模式", "FumeFX", "Script_3DsMax", "FumeFX_AddLight.ms", "FumeFX快速创建")
    Max3D_AddKey(keyArray, "fo", "VIM模式", "FumeFX", "Script_3DsMax", "FumeFX_DefaultOpenUI.ms", "打开FumenFX")

    ; 视图
    Max3D_AddKey(keyArray, "<Numpad0>", "VIM模式", "视图", "Max3D_Viewport_Switch", "", "视图切换大小")
    Max3D_AddKey(keyArray, "<Numpad2>", "VIM模式", "视图", "Max3D_Viewport_Front", "", "前视图")
    Max3D_AddKey(keyArray, "<LB-Numpad2>", "VIM模式", "视图", "Max3D_Viewport_Back", "", "后视图")
    Max3D_AddKey(keyArray, "<Numpad6>", "VIM模式", "视图", "Max3D_Viewport_Left", "", "左视图")
    Max3D_AddKey(keyArray, "<Numpad4>", "VIM模式", "视图", "Max3D_Viewport_Right", "", "右视图")
    Max3D_AddKey(keyArray, "<Numpad8>", "VIM模式", "视图", "Max3D_Viewport_Top", "", "顶视图")
    Max3D_AddKey(keyArray, "<LB-Numpad8>", "VIM模式", "视图", "Max3D_Viewport_Buttom", "", "底视图")
    Max3D_AddKey(keyArray, "<Numpad5>", "VIM模式", "视图", "Max3D_Viewport_Perspective", "", "透视图")
    Max3D_AddKey(keyArray, "<Numpad1>", "VIM模式", "视图", "Max3D_Viewport_Camera", "", "摄像机视图")

    ; 帮助
    Max3D_AddKey(keyArray, "?", "VIM模式", "帮助", "VIMD_ShowKeyHelpWithGui", "Max3D", "显示所有按键(ToolTip)")

    ; 类别显示控制
    Max3D_AddKey(keyArray, "hc", "VIM模式", "显示", "Script_3DsMax", "hideByCategoryGUI.ms", "类别显示控制面板")
    Max3D_AddKey(keyArray, "/ct", "VIM模式", "帮助", "Script_3DsMax", "CollectorTexture.ms", "收集 贴图到文件目录下")
    Max3D_AddKey(keyArray, "/co", "VIM模式", "帮助", "Script_3DsMax", "CollectorTextureAdvanced.ms", "收集 贴图到文件目录下-高级")

    ; 设置
    Max3D_AddKey(keyArray, ":u", "VIM模式", "设置", "Script_3DsMax", "UnitSettings.ms", "单位设置")
    Max3D_AddKey(keyArray, ":a", "VIM模式", "设置", "Script_3DsMax", "Initialization.ms", "场景初始设置")

    return keyArray
}

Max3D_AddKey(keyArray, key, mode, group, func, param, comment) {
    keyArray.Push({ Key: key, Mode: mode, Group: group, Func: func, Param: param, Comment: comment })
}

Max3D_SetupIME(exeName, imeCfg) {
    AutoIMESwitcher.Setup(exeName, {
        enabled: imeCfg.enabled,  ; 是否启用自动IME切换，可以通过配置文件修改
        enableDebug: imeCfg.enableDebug,  ; 关闭调试信息，减少干扰
        checkInterval: imeCfg.checkInterval,  ; 减少检查间隔，提高响应速度
        enableMouseClick: imeCfg.enableMouseClick,
        inputControlPatterns: ["Edit", "Edit2", "Edit3", "MXS_Scintilla", "EDITDUMMY"],
        cursorTypes: ["IBeam"],  ; 根据鼠标光标类型判断
        maxRetries: imeCfg.maxRetries,  ; 减少重试次数，提高速度
        autoSwitchTimeout: imeCfg.autoSwitchTimeout,  ; 5秒超时
        specialHandling: imeCfg.specialHandling  ; 特殊处理：忽略只有IBeam光标但没有输入控件的情况
    })
}

; 对符合条件的控件使用【normal模式】，而不是【Vim模式】
Max3D_Before() {
    return AutoIMESwitcher.HandleBeforeAction("3dsmax.exe")
}
;渲染到激活窗口 目前支持TC 和 默认窗口
Max3D_RenderDirtoTC() {
    ; 获取激活资源管理器路径
    ; 修正：winID 未定义，改为传入空值
    srcDIR := GetActiveFileManagerFolder("")
    setPath := StrReplace(srcDIR, "\", "\\") "\\"
    setPreset := A_ScriptDir "\plugins\Max3D\Script\commands\QuikeRenderTC.ms"
    try {
        MsCode := ""
        MsCode .= "    --确保脚本在 3DsMax 中正确执行`n"
        MsCode .= "    rendSaveFile = true `n"
        MsCode .= "    theName = `"" "10000" "`" `n"
        MsCode .= "    Prefix = `"`.tga`"`n"
        MsCode .= "    getpath = `"" setPath "`"`n "
        MsCode .= "    outPutFiledir = getpath + theName + Prefix `n"
        MsCode .= "    rendOutputFileName = outPutFiledir `n"
        MsCode .= "    scanlineRender.antiAliasFilter = Catmull_Rom() `n"
        MsCode .= "    actionMan.executeAction 0 `"" 50031 "`"--Render: Render`n "
        FileAppend(MsCode, setPreset, "UTF-8")
        Script_3DsMax("QuikeRenderTC.ms")
        Sleep(500)
        FileDelete(setPreset) ;避免重复删除文件
    } catch Error as e {
        MsgBox Format("写入文件时出错: {1}", e.Message)
        return
    }
}

; 定义全局脚本路径配置
GetMax3DScriptPaths() {
    ; 基础目录
    baseDir := A_ScriptDir "\plugins\Max3D\Script"

    ; 返回路径配置
    return {
        baseDir: baseDir,
        dirPaths: [
            baseDir "\MenuScript",           ; 脚本目录
            baseDir "\MenuScriptCreate",     ; 创建脚本目录
            baseDir "\GameDevelop"           ; 开发脚本目录
        ],
        dirNames: ["脚本", "创建", "开发"]
    }
}

Max3D_Menu() {
    try {
        ; 创建父菜单
        parentMenu := Menu()

        ; 获取脚本路径配置
        pathConfig := GetMax3DScriptPaths()

        ; 跟踪添加到父菜单的项目数量
        totalMenuItems := 0

        ; 为每个目录创建子菜单
        for index, dirPath in pathConfig.dirPaths {
            ; 创建子菜单
            subMenu := Menu()

            ; 使用增强版的目录扫描函数，它会自动保留完整文件路径
            itemCount := ScanDirectoryForMenuEx(subMenu, dirPath, "*.ms|*.mse|*.py", Max3D_HandleMenuClick)

            ; 如果子菜单有内容，添加到父菜单
            if (itemCount > 0) {
                parentMenu.Add(pathConfig.dirNames[index], subMenu)
                totalMenuItems++
            }
        }

        parentMenu.Add("FumeFX缓存路径修改", (*) => Script_3DsMax("QuikeFXLocalChang.ms"))
        parentMenu.Add("快速渲染", (*) => Script_3DsMax("Render.ms"))
        parentMenu.Add("初始化【删灯光黑背景设单位设网格】", (*) => Script_3DsMax("initialization.ms"))

        try {
            if (totalMenuItems > 0) {
                parentMenu.Show()
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

Max3D_HandleMenuClick(ItemName, ItemPos, MenuName, filePath := "") {
    Script_3DsMax(filePath)
}


Max3D_WinClose() {
    try WinClose("Measure")
    try WinClose("Display Floater")
    try WinClose("Layer: ")
    try WinClose("Transform Type-In")
    try WinClose("Material Editor -")
    try WinClose("Slate Material Editor ")
    try WinClose("Render Setup: ")
    try WinClose("Scene Explorer -")
    try WinClose("materialByName")
    try WinClose("LPM v2.00 ")
}



; ViewportDisplay/视窗显示
; Views: Viewport Visual Style Wireframe / Shaded Toggle 线显示
Max3D_Viewport_Wireframe() {
    Script_3DsMax("id415")
}

Max3D_Viewport_DefaultShading() {
    Script_3DsMax("id63566")
}

;  Views: Viewport Visual Style Edged Faces Toggle
Max3D_Viewport_EdgedFaces() {
    Script_3DsMax("id557")
}

; Viewport Front/Back Toggle/前后切换显示
Max3D_Viewport_FrontBack() {
    runPath := 'actionMan.executeAction 98641878 "1834539833"'
    Script_3DsMax(runPath)
}

; UVW Seam Display Toggle/
Max3D_Viewport_UVWDisplay() {
    runPath := 'actionMan.executeAction 98641878 "1696817703"'
    Script_3DsMax(runPath)
}



; 视图切换
Max3D_Viewport_Front() {
    Send("{f}")
}

Max3D_Viewport_Left() {
    Send("{l}")
}

Max3D_Viewport_Right() {
    Send("{v}{r}")
}

Max3D_Viewport_Top() {
    Send("{t}")
}

Max3D_Viewport_Buttom() {
    Send("{v}{b}")
}

Max3D_Viewport_Back() {
    Send("{v}{k}")
}

Max3D_Viewport_Perspective() {
    Send("{p}")
}

Max3D_Viewport_Camera() {
    Send("{v}{c}")
}

Max3D_Viewport_Switch() {
    Send("!{w}")
}
