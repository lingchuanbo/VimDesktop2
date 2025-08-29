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
    KeyArray.push({ Key: "E", Mode: "VIM模式", Group: "控制", Func: "Script_3DsMax", Param: "旋转90.ms", Comment: "旋转90" })
    KeyArray.push({ Key: "R", Mode: "VIM模式", Group: "控制", Func: "Script_3DsMax", Param: "旋转-90.ms", Comment: "旋转-90" })
    KeyArray.push({ Key: "<LB-e>", Mode: "VIM模式", Group: "控制", Func: "Script_3DsMax", Param: "Mod_EditPoly.ms", Comment: "添加 EditPoly" })
    KeyArray.push({ Key: "<LB-d>", Mode: "VIM模式", Group: "控制", Func: "Script_3DsMax", Param: "Mod_DeleteMesh.ms",
        Comment: "添加 DeleteMesh" })
    KeyArray.push({ Key: "<LB-u>", Mode: "VIM模式", Group: "控制", Func: "Script_3DsMax", Param: "Mod_Unwrap_UVW.ms",
        Comment: "添加 Unwrap_UVW" })
    KeyArray.push({ Key: "<LB-r>", Mode: "VIM模式", Group: "控制", Func: "Script_3DsMax", Param: "Mod_Relax.ms", Comment: "添加 Mod_Relax" })
    KeyArray.push({ Key: "<LB-s>", Mode: "VIM模式", Group: "控制", Func: "Script_3DsMax", Param: "Mod_meshsmooth.ms",
        Comment: "添加 Meshsmooth" })

    ; 菜单
    KeyArray.push({ Key: "3", Mode: "VIM模式", Group: "打开", Func: "Max3D_Menu", Param: "", Comment: "功能菜单" })

    ;KeyArray.push({ Key: "1", Mode: "VIM模式", Group: "搜索", Func: "SingleDoubleFullHandlers", Param: "1|Everything_1|Everything_2|Everything_3",Comment: "单击/双击/长按"})
    KeyArray.push({ Key: "qq", Mode: "VIM模式", Group: "渲染", Func: "Script_3DsMax", Param: "RenderQ.ms", Comment: "快速渲染" })
    KeyArray.push({ Key: "qt", Mode: "VIM模式", Group: "渲染", Func: "Max3D_RenderDirtoTC", Param: "", Comment: "快速渲染到TC激活面板" })
    ; 打开
    KeyArray.push({ Key: "of", Mode: "VIM模式", Group: "打开", Func: "Script_3DsMax", Param: "openMaxfileDir.ms", Comment: "打开 Max文件所在位置" })
    KeyArray.push({ Key: "or", Mode: "VIM模式", Group: "打开", Func: "Script_3DsMax", Param: "openRenderDir.ms", Comment: "打开 渲染文件所在位置" })
    KeyArray.push({ Key: "oo", Mode: "VIM模式", Group: "打开", Func: "Script_3DsMax", Param: "id40003", Comment: "打开 文件" })
    KeyArray.push({ Key: "om", Mode: "VIM模式", Group: "打开", Func: "Script_3DsMax", Param: "id40195", Comment: "打开 融合文件" })
    ; KeyArray.push({ Key: "os", Mode: "VIM模式", Group: "打开", Func: "Script_3DsMax", Param: "id40196", Comment: "打开 场景文件" })

    ; 帮助
    KeyArray.push({ Key: "?", Mode: "VIM模式", Group: "帮助", Func: "VIMD_ShowKeyHelpWithGui", Param: "Max3D", Comment: "显示所有按键(ToolTip)" })

    ; 类别显示控制
    KeyArray.push({ Key: "hc", Mode: "VIM模式", Group: "显示", Func: "Script_3DsMax", Param: "hideByCategoryGUI.ms",
        Comment: "类别显示控制面板" })
    KeyArray.push({ Key: "/ct", Mode: "VIM模式", Group: "帮助", Func: "Script_3DsMax", Param: "CollectorTexture.ms",
        Comment: "收集 贴图到文件目录下" })
    KeyArray.push({ Key: "/co", Mode: "VIM模式", Group: "帮助", Func: "Script_3DsMax", Param: "CollectorTextureAdvanced.ms",
        Comment: "收集 贴图到文件目录下" })

    ; 注册窗体
    vim.SetWin("Max3D", "3DsMax", "3dsmax.exe")

    ; 设置超时
    vim.SetTimeOut(300, "Max3D")

    ; 注册热键
    RegisterPluginKeys(KeyArray, "Max3D")

    ; 设置自动IME切换（优化延迟配置）
    AutoIMESwitcher.Setup("3dsmax.exe"), {
        enableDebug: false,  ; 关闭调试信息，减少干扰
        checkInterval: 200,  ; 减少检查间隔，提高响应速度
        enableMouseClick: true,
        inputControlPatterns: ["Edit", "Edit2", "Edit3", "MXS_Scintilla", "EDITDUMMY"],
        cursorTypes: ["IBeam"],  ; 根据鼠标光标类型判断
        maxRetries: 3,  ; 减少重试次数，提高速度
        autoSwitchTimeout: 5000  ; 5
    }
}

; 对符合条件的控件使用【normal模式】，而不是【Vim模式】
Max3D_Before() {
    return AutoIMESwitcher.HandleBeforeAction("3dsmax.exe")
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
    ; 由于我们使用了ScanDirectoryForMenuEx，filePath已经是完整路径
    ; 不需要再次构建路径

    ; 如果没有提供文件路径（这种情况不应该发生），尝试构建一个
    ; if (!filePath) {
    ;     ; 获取脚本路径配置
    ;     pathConfig := GetMax3DScriptPaths()

    ;     ; 尝试在各个子目录中查找文件
    ;     for _, dirPath in pathConfig.dirPaths {
    ;         possiblePath := dirPath "\" ItemName
    ;         if (FileExist(possiblePath)) {
    ;             filePath := possiblePath
    ;             break
    ;         }
    ;     }

    ;     ; 如果仍然没有找到，使用默认路径
    ;     if (!filePath) {
    ;         filePath := A_ScriptDir "\" ItemName
    ;     }
    ; }
    ; 显示选择的文件
    ; MsgBox("您选择了文件: " . filePath)
    ; 运行脚本
    Script_3DsMax(filePath)
}
