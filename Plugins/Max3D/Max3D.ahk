/*
[PluginInfo]
PluginName=Max3D
Author=BoBO
Version=1.0
Comment=3DsMax插件
*/
Max3D() {
    ; 热键映射数组
    KeyArray := Array()

    ; 模式切换
    KeyArray.push({ Key: "<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】" })
    KeyArray.push({ Key: "<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】" })
    KeyArray.push({ Key: "<esc>", Mode: "VIM模式", Group: "模式", Func: "VIMD_清除输入键", Param: "", Comment: "清除输入键及提示" })

    ; 搜索功能
    KeyArray.push({ Key: "<s-e>", Mode: "VIM模式", Group: "控制", Func: "Script_3DsMax", Param: "旋转90.ms", Comment: "旋转90" })
    KeyArray.push({ Key: "h", Mode: "VIM模式", Group: "控制", Func: "Script_3DsMax", Param: "旋转90.ms", Comment: "旋转90" })

    KeyArray.push({ Key: "<s-r>", Mode: "VIM模式", Group: "控制", Func: "Script_3DsMax", Param: "旋转-90.ms", Comment: "旋转-90" })
    KeyArray.push({ Key: "<LB-e>", Mode: "VIM模式", Group: "控制", Func: "Script_3DsMax", Param: "Mod_EditPoly.ms", Comment: "添加 EditPoly" })
    KeyArray.push({ Key: "<LB-d>", Mode: "VIM模式", Group: "控制", Func: "Script_3DsMax", Param: "Mod_DeleteMesh.ms", Comment: "添加 DeleteMesh" })
    KeyArray.push({ Key: "<LB-u>", Mode: "VIM模式", Group: "控制", Func: "Script_3DsMax", Param: "Mod_Unwrap_UVW.ms", Comment: "添加 Unwrap_UVW" })
    KeyArray.push({ Key: "<LB-r>", Mode: "VIM模式", Group: "控制", Func: "Script_3DsMax", Param: "Mod_Relax.ms", Comment: "添加 Mod_Relax" })
    KeyArray.push({ Key: "<LB-s>", Mode: "VIM模式", Group: "控制", Func: "Script_3DsMax", Param: "Mod_meshsmooth.ms", Comment: "添加 Meshsmooth" })

    ; 菜单
    KeyArray.push({ Key: "3", Mode: "VIM模式", Group: "打开", Func: "Max3D_Menu", Param: "", Comment: "功能菜单" })

    ;KeyArray.push({ Key: "1", Mode: "VIM模式", Group: "搜索", Func: "SingleDoubleFullHandlers", Param: "1|Everything_1|Everything_2|Everything_3",Comment: "单击/双击/长按"})

    ; 打开
    KeyArray.push({ Key: "of", Mode: "VIM模式", Group: "打开", Func: "Script_3DsMax", Param: "openMaxfileDir.ms", Comment: "打开 Max文件所在位置" })
    KeyArray.push({ Key: "or", Mode: "VIM模式", Group: "打开", Func: "Script_3DsMax", Param: "openRenderDir.ms", Comment: "打开 渲染文件所在位置" })
    KeyArray.push({ Key: "oo", Mode: "VIM模式", Group: "打开", Func: "Script_3DsMax", Param: "id40003", Comment: "打开 文件" })
    KeyArray.push({ Key: "om", Mode: "VIM模式", Group: "打开", Func: "Script_3DsMax", Param: "id40195", Comment: "打开 融合文件" })


    ; 渲染
    KeyArray.push({ Key: "qc", Mode: "VIM模式", Group: "项目", Func: "Script_3DsMax", Param: "BatchCloneRender.ms", Comment: "批量克隆渲染" })
    KeyArray.push({ Key: "qb", Mode: "VIM模式", Group: "项目", Func: "Script_3DsMax", Param: "BatchRenderP.ms", Comment: "批量渲染工具" })
    KeyArray.push({ Key: "qq", Mode: "VIM模式", Group: "渲染", Func: "Script_3DsMax", Param: "RenderQ.ms", Comment: "快速渲染" })
    KeyArray.push({ Key: "qt", Mode: "VIM模式", Group: "渲染", Func: "Max3D_RenderDirtoTC", Param: "", Comment: "快速渲染到TC激活面板" })
    KeyArray.push({ Key: "qs", Mode: "VIM模式", Group: "项目", Func: "Script_3DsMax", Param: "Render.ms", Comment: "快速渲染-文件同级目录" })
    KeyArray.push({ Key: "qa", Mode: "VIM模式", Group: "项目", Func: "Script_3DsMax", Param: "RenderLayer.ms", Comment: "分层渲染" })
    KeyArray.push({ Key: "qx", Mode: "VIM模式", Group: "项目", Func: "Max3D_WinClose", Param: "", Comment: "批量渲染工具" })


    ; FumeFX
    KeyArray.push({ Key: "ff", Mode: "VIM模式", Group: "FumeFX", Func: "Script_3DsMax", Param: "FumeFX_FXdef.ms", Comment: "FumeFX快速创建" })
    KeyArray.push({ Key: "fa", Mode: "VIM模式", Group: "FumeFX", Func: "Script_3DsMax", Param: "FumeFX_AddLight.ms", Comment: "FumeFX快速创建" })
    KeyArray.push({ Key: "fo", Mode: "VIM模式", Group: "FumeFX", Func: "Script_3DsMax", Param: "FumeFX_DefaultOpenUI.ms", Comment: "打开FumenFX" })

    ; 视图
    KeyArray.push({ Key: "<Numpad0>", Mode: "VIM模式", Group: "视图", Func: "Max3D_Viewport_Switch", Param: "", Comment: "视图切换大小" })
    KeyArray.push({ Key: "<Numpad2>", Mode: "VIM模式", Group: "视图", Func: "Max3D_Viewport_Front", Param: "", Comment: "前视图" })
    KeyArray.push({ Key: "<LB-Numpad2>", Mode: "VIM模式", Group: "视图", Func: "Max3D_Viewport_Back", Param: "", Comment: "后视图" })
    KeyArray.push({ Key: "<Numpad6>", Mode: "VIM模式", Group: "视图", Func: "Max3D_Viewport_Left", Param: "", Comment: "左视图" })
    KeyArray.push({ Key: "<Numpad4>", Mode: "VIM模式", Group: "视图", Func: "Max3D_Viewport_Right", Param: "", Comment: "右视图" })
    KeyArray.push({ Key: "<Numpad8>", Mode: "VIM模式", Group: "视图", Func: "Max3D_Viewport_Top", Param: "", Comment: "顶视图" })
    KeyArray.push({ Key: "<LB-Numpad8>", Mode: "VIM模式", Group: "视图", Func: "Max3D_Viewport_Buttom", Param: "", Comment: "底视图" })
    KeyArray.push({ Key: "<Numpad5>", Mode: "VIM模式", Group: "视图", Func: "Max3D_Viewport_Perspective", Param: "", Comment: "透视图" })
    KeyArray.push({ Key: "<Numpad1>", Mode: "VIM模式", Group: "视图", Func: "Max3D_Viewport_Camera", Param: "", Comment: "摄像机视图" })


    ; 帮助
    KeyArray.push({ Key: "?", Mode: "VIM模式", Group: "帮助", Func: "VIMD_ShowKeyHelpWithGui", Param: "Max3D", Comment: "显示所有按键(ToolTip)" })


    ; 类别显示控制
    KeyArray.push({ Key: "hc", Mode: "VIM模式", Group: "显示", Func: "Script_3DsMax", Param: "hideByCategoryGUI.ms", Comment: "类别显示控制面板" })
    KeyArray.push({ Key: "/ct", Mode: "VIM模式", Group: "帮助", Func: "Script_3DsMax", Param: "CollectorTexture.ms", Comment: "收集 贴图到文件目录下" })
    KeyArray.push({ Key: "/co", Mode: "VIM模式", Group: "帮助", Func: "Script_3DsMax", Param: "CollectorTextureAdvanced.ms",Comment: "收集 贴图到文件目录下-高级" })

    ; 设置
    KeyArray.push({ Key: ":u", Mode: "VIM模式", Group: "设置", Func: "Script_3DsMax", Param: "UnitSettings.ms", Comment: "单位设置" })
    KeyArray.push({ Key: ":a", Mode: "VIM模式", Group: "设置", Func: "Script_3DsMax", Param: "Initialization.ms", Comment: "场景初始设置" })

    ; 注册窗体
    vim.SetWin("Max3D", "3DsMax", "3dsmax.exe")

    ; 设置超时
    vim.SetTimeOut(300, "Max3D")

    ; 注册热键
    RegisterPluginKeys(KeyArray, "Max3D")

    ; 设置自动IME切换（优化延迟配置）
    AutoIMESwitcher.Setup("3dsmax.exe", {
        enabled: true,  ; 是否启用自动IME切换，可以通过配置文件修改
        enableDebug: false,  ; 关闭调试信息，减少干扰
        checkInterval: 200,  ; 减少检查间隔，提高响应速度
        enableMouseClick: true,
        inputControlPatterns: ["Edit", "Edit2", "Edit3", "MXS_Scintilla", "EDITDUMMY"],
        cursorTypes: ["IBeam"],  ; 根据鼠标光标类型判断
        maxRetries: 3,  ; 减少重试次数，提高速度
        autoSwitchTimeout: 5000,  ; 5秒超时
        specialHandling: "ignoreIBeamWithoutControl"  ; 特殊处理：忽略只有IBeam光标但没有输入控件的情况
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