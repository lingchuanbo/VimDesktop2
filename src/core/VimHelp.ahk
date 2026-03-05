_VIMD_ParseHelpParam(param) {
    global vim
    result := Map("win", "", "mode", "")
    if (param != "") {
        params := StrSplit(param, "|")
        result["win"] := params[1]
        result["mode"] := params.Length > 1 ? params[2] : ""
    } else {
        result["win"] := vim.LastFoundWin
        result["mode"] := ""
    }
    return result
}

_VIMD_GetModeObj(win, mode) {
    global vim
    if strlen(mode) {
        winObj := vim.GetWin(win)
        return winObj.modeList[mode]
    }
    return vim.getMode(win)
}

_VIMD_GetActionComment(actionObj, key) {
    if (actionObj.Type = 1) {
        ActionDescList := actionObj.Comment
        if (IsObject(ActionDescList) && ActionDescList.Has(key)) {
            actionDesc := StrSplit(ActionDescList[key], "|")
            return (actionDesc.Length >= 2) ? actionDesc[2] : ActionDescList[key]
        }
        return ActionDescList
    }
    return actionObj.Comment
}

_VIMD_GetDisplayComment(actionObj, key) {
    comment := _VIMD_GetActionComment(actionObj, key)
    if (comment != "")
        return comment

    funcName := actionObj.Function ? actionObj.Function : ""
    param := actionObj.Param ? actionObj.Param : ""
    if (funcName != "" && param != "")
        return funcName "(" param ")"
    if (funcName != "")
        return funcName
    return param
}

_VIMD_GetActionGroup(actionObj) {
    return actionObj.Group ? actionObj.Group : "未分组"
}

_VIMD_GetHelpContext(param, resolveModeName := false) {
    global vim
    parsed := _VIMD_ParseHelpParam(param)
    win := parsed["win"]
    mode := parsed["mode"]
    modeObj := _VIMD_GetModeObj(win, mode)
    if (resolveModeName && !strlen(mode))
        mode := vim.GetCurMode(win)
    return { win: win, mode: mode, modeObj: modeObj }
}

_VIMD_CollectGroupedKeysForMode(pluginName, modeName) {
    global vim
    groupedKeys := Map()
    if (!vim.ActionList.Has(pluginName) || !vim.ActionList[pluginName].Has(modeName))
        return groupedKeys

    for keyName, actionObj in vim.ActionList[pluginName][modeName] {
        key := actionObj.OriKey ? actionObj.OriKey : keyName
        comment := _VIMD_GetDisplayComment(actionObj, keyName)
        group := _VIMD_GetActionGroup(actionObj)

        if (!groupedKeys.Has(group))
            groupedKeys[group] := []

        groupedKeys[group].Push({ key: key, comment: comment })
    }
    return groupedKeys
}

_VIMD_BuildGroupedKeysText(groupedKeys, indent := "") {
    keyList := ""
    for group, keys in groupedKeys {
        keyList .= indent "◆ " group " ◆`n"
        for _, keyInfo in keys {
            keyList .= indent "  " keyInfo.key "`t" keyInfo.comment "`n"
        }
        keyList .= "`n"
    }
    return keyList
}

_VIMD_BuildAlignedKeyTable(keys, alignWidth := 30) {
    keyTable := ""
    for _, keyInfo in keys {
        keyTable .= keyInfo.key "`t" keyInfo.comment "`n"
    }
    return KyFunc_AutoAligned(keyTable, , alignWidth)
}

/* VIMD_ShowKeyHelp【示当前模式下，所有热键及相应的功能】
    函数:  VIMD_ShowKeyHelp
    作用:  显示当前模式下，所有热键及相应的功能，超过40行，自动换行
    参数:
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
VIMD_ShowKeyHelp(param := "") {
    global vim
    global current_keyMap := ""

    context := _VIMD_GetHelpContext(param)
    win := context.win
    mode := context.mode
    modeObj := context.modeObj

    ; 收集按键信息，按Group分组
    groupedKeys := Map()

    ; 首先按Group分组收集按键
    for key, actionName in modeObj.keyMapList {
        ; 获取Action对象
        actionObj := vim.GetAction(win, mode, key)

        if (!actionObj)
            continue

        ; 获取按键、注释和分组
        HotKeyStr := vim.CheckCapsLock(vim.Convert2VIM(key))
        HotKeyStr := vim.ShiftUpper(HotKeyStr)

        ; 获取注释
        comment := _VIMD_GetDisplayComment(actionObj, key)

        ; 获取分组
        group := _VIMD_GetActionGroup(actionObj)

        ; 如果该分组不存在，创建一个新数组
        if (!groupedKeys.Has(group))
            groupedKeys[group] := []

        ; 将按键信息添加到对应分组
        groupedKeys[group].Push({ key: HotKeyStr, comment: comment })
    }

    ; 然后按分组构建显示文本
    current_keyMap := "【" (mode ? mode : modeObj.name) "】模式下的按键列表`n`n"

    ; 按分组显示按键
    for group, keys in groupedKeys {
        ; 添加分组标题
        current_keyMap .= "◆ " group " ◆`n"

        ; 添加该分组下的所有按键
        keyTable := _VIMD_BuildAlignedKeyTable(keys, 30)
        current_keyMap .= keyTable "`n"
    }

    ; 创建临时文件
    Title_Txt := A_Temp "\" win "_按键列表_" FormatTime(, "yyyy_MM_dd_HH_mm_ss") ".txt"
    FileAppend current_keyMap, Title_Txt

    ; 使用文本编辑器打开
    try {
        RunWait "Notepad++.exe " Title_Txt
    } catch {
        RunWait "Notepad.exe " Title_Txt
    }
}

/*
函数: VIMD_ShowKeyHelpWithMsgBox
作用: 使用MsgBox显示按键列表（备用方案）
参数: pluginName - 插件名称VIMD_ShowKeyHelpWithMsgBox
返回: 无
作者: BoBO
*/
VIMD_ShowKeyHelpWithMsgBox(pluginName) {
    global vim

    ; 构建显示文本
    displayText := pluginName " 按键列表`n`n"

    ; 尝试获取按键信息
    try {
        ; 检查窗口是否存在
        if (!vim.WinList.Has(pluginName)) {
            MsgBox("没有找到插件：" pluginName)
            return
        }

        winObj := vim.GetWin(pluginName)

        ; 获取所有模式
        modes := []
        for modeName, modeObj in winObj.modeList
            modes.Push(modeName)

        ; 按模式显示按键
        for _, modeName in modes {
            ; 跳过空模式
            if (!vim.ActionList.Has(pluginName) || !vim.ActionList[pluginName].Has(modeName))
                continue

            displayText .= "【" modeName "】`n"

            ; 收集该模式下的所有按键，按Group分组
            keyList := ""
            groupedKeys := Map()

            ; 首先按Group分组收集按键
            for keyName, actionObj in vim.ActionList[pluginName][modeName] {
                ; 获取按键、注释和分组
                key := actionObj.OriKey ? actionObj.OriKey : keyName
                comment := actionObj.Comment
                group := actionObj.Group ? actionObj.Group : "未分组"

                ; 如果该分组不存在，创建一个新数组
                if (!groupedKeys.Has(group))
                    groupedKeys[group] := []

                ; 将按键信息添加到对应分组
                groupedKeys[group].Push({ key: key, comment: comment })
            }

            ; 然后按分组显示按键
            for group, keys in groupedKeys {
                ; 添加分组标题
                keyList .= "  ◆ " group " ◆`n"

                ; 添加该分组下的所有按键
                for _, keyInfo in keys {
                    keyList .= "    " keyInfo.key "`t" keyInfo.comment "`n"
                }

                keyList .= "`n"
            }

            ; 添加按键信息到显示文本
            displayText .= keyList
        }
    } catch as e {
        displayText .= "获取按键信息时出错: " e.Message "`n"
    }

    ; 使用MsgBox显示按键列表
    MsgBox(displayText, pluginName " 按键列表")
}
/*
函数: VIMD_ShowKeyHelpMD
作用: 生成Markdown文件并使用inlyne.exe打开显示按键绑定，如果inlyne.exe不存在则使用VIMD_ShowKeyHelp
参数: param - 参数，格式为"窗口名|模式名"，如果为空则使用当前窗口
返回: 无
作者: BoBO
版本: 2.0
AHK版本: 2.0
*/
VIMD_ShowKeyHelpMD(param := "") {
    global vim

    ; 检查 inlyne.exe 是否存在
    inlyneExe := PathResolver.AppsPath("inlyne\inlyne.exe")
    if (!FileExist(inlyneExe)) {
        ; 如果 inlyne.exe 不存在，使用原来的 VIMD_ShowKeyHelp 函数
        VIMD_ShowKeyHelp(param)
        return
    }

    context := _VIMD_GetHelpContext(param, true)
    win := context.win
    mode := context.mode
    modeObj := context.modeObj

    ; 构建Markdown内容
    markdownContent := BuildMarkdownContent(win, mode, modeObj)

    ; 生成临时MD文件并用inlyne打开
    OpenMarkdownWithInlyne(markdownContent, win " - " (mode ? mode : modeObj.name) " 按键列表")
}

/*
函数: BuildMarkdownContent
作用: 构建按键帮助的纯Markdown内容
参数: win - 窗口名称, mode - 模式名称, modeObj - 模式对象
返回: Markdown格式的字符串
*/
BuildMarkdownContent(win, mode, modeObj) {
    global vim

    ; 收集按键信息，按Group分组
    groupedKeys := Map()
    totalKeys := 0

    ; 首先按Group分组收集按键
    for key, actionName in modeObj.keyMapList {
        ; 获取Action对象
        actionObj := vim.GetAction(win, mode, key)

        if (!actionObj)
            continue

        ; 获取按键 - 使用原始按键
        HotKeyStr := key

        ; 如果按键为空，跳过
        if (!HotKeyStr || StrLen(HotKeyStr) = 0) {
            continue
        }

        ; 获取注释
        comment := _VIMD_GetDisplayComment(actionObj, key)

        ; 获取分组和函数信息
        group := _VIMD_GetActionGroup(actionObj)
        funcName := actionObj.Function ? actionObj.Function : "未知"
        param := actionObj.Param ? actionObj.Param : ""

        ; 如果该分组不存在，创建一个新数组
        if (!groupedKeys.Has(group))
            groupedKeys[group] := []

        ; 将按键信息添加到对应分组
        groupedKeys[group].Push({
            key: HotKeyStr,
            comment: comment,
            func: funcName,
            param: param
        })
        totalKeys++
    }

    ; 构建纯Markdown内容
    markdownContent := "## " win " - " (mode ? mode : modeObj.name) " 按键列表`n`n"
    markdownContent .= "**总计按键数量:** " totalKeys "`n`n"

    ; 使用简单的单列布局 - 按分组竖直排列
    for group, keys in groupedKeys {
        ; 添加分组标题
        markdownContent .= "## " GetGroupIcon(group) " " group "`n`n"

        ; 创建表格
        markdownContent .= "| 按键 | 功能描述 |`n"
        markdownContent .= "|------|----------|`n"

        ; 添加该分组下的所有按键
        for _, keyInfo in keys {
            ; 对包含 < > 的按键进行HTML实体编码，避免被Markdown渲染器误认为HTML标签
            key := StrReplace(StrReplace(keyInfo.key, "<", "&lt;"), ">", "&gt;")
            comment := keyInfo.comment

            ; 构建表格行
            tableRow := Format("| `{1}` | {2} |`n", key, comment)
            markdownContent .= tableRow
        }

        markdownContent .= "`n"
    }

    return markdownContent
}

/*
函数: GetGroupIcon
作用: 根据分组名称获取对应的图标
参数: group - 分组名称
返回: 图标字符串
*/
GetGroupIcon(group) {
    ; 根据分组名称返回对应的图标
    switch StrLower(group) {
        case "模式", "mode":
            return "🔄"
        case "搜索", "search":
            return "🔍"
        case "帮助", "help":
            return "❓"
        case "编辑", "edit":
            return "✏️"
        case "导航", "navigation":
            return "🧭"
        case "文件", "file":
            return "📁"
        case "窗口", "window":
            return "🪟"
        case "系统", "system":
            return "⚙️"
        case "音量", "volume":
            return "🔊"
        case "播放", "play":
            return "▶️"
        case "工具", "tools":
            return "🔧"
        default:
            return "📋"
    }
}

/*
函数: OpenMarkdownWithInlyne
作用: 生成临时MD文件并使用inlyne.exe打开
参数: markdownContent - Markdown内容, title - 文件标题
返回: 无
*/
OpenMarkdownWithInlyne(markdownContent, title) {
    ; inlyne.exe 路径
    inlyneExe := PathResolver.AppsPath("inlyne\inlyne.exe")

    ; 检查 inlyne.exe 是否存在
    if (!FileExist(inlyneExe)) {
        MsgBox("找不到 inlyne.exe 文件:`n" inlyneExe "`n`n请确认路径是否正确。", "错误", "Icon!")
        return
    }

    ; 生成临时文件名
    safeTitle := RegExReplace(title, '[<>:"/\\|?*]', "_")
    tempDir := A_Temp "\VimD_KeyHelp"

    ; 确保临时目录存在
    if (!DirExist(tempDir)) {
        try {
            DirCreate(tempDir)
        } catch as e {
            MsgBox("创建临时目录失败: " e.Message, "错误", "Icon!")
            return
        }
    }

    ; 生成临时文件路径 - 使用Markdown格式
    tempFile := tempDir "\" safeTitle "_" FormatTime(, "yyyyMMdd_HHmmss") ".md"

    ; 写入Markdown内容到临时文件
    try {
        FileAppend(markdownContent, tempFile, "UTF-8")
    } catch as e {
        MsgBox("写入临时文件失败: " e.Message, "错误", "Icon!")
        return
    }

    ; 使用inlyne.exe打开文件
    try {
        Run('"' inlyneExe '" "' tempFile '"', , "Hide", &inlynePID)
    } catch as e {
        MsgBox("启动 inlyne.exe 失败: " e.Message, "错误", "Icon!")
        ; 清理临时文件
        try {
            FileDelete(tempFile)
        }
        return
    }

    ; 等待inlyne窗口出现并设置窗口属性
    SetTimer(SetInlyneWindowProperties.Bind(inlynePID, title), -500)

    ; 设置定时器清理临时文件（30秒后）
    SetTimer(CleanupTempFile.Bind(tempFile), -30000)
}

/*
函数: CleanupTempFile
作用: 清理临时文件
参数: filePath - 要清理的文件路径
返回: 无
*/
CleanupTempFile(filePath) {
    try {
        if (FileExist(filePath)) {
            FileDelete(filePath)
        }
    } catch {
        ; 忽略清理错误
    }
}

/*
函数: SetInlyneWindowProperties
作用: 设置inlyne窗口属性（置顶、居中、大小）
参数: pid - inlyne进程ID, title - 窗口标题
返回: 无
*/
SetInlyneWindowProperties(pid, title) {
    ; 等待窗口出现，最多等待5秒
    maxWaitTime := 5000
    startTime := A_TickCount
    inlyneHwnd := 0

    while (A_TickCount - startTime < maxWaitTime) {
        ; 尝试通过进程ID找到窗口
        try {
            windows := WinGetList("ahk_pid " pid)
            for hwnd in windows {
                if (WinExist("ahk_id " hwnd)) {
                    inlyneHwnd := hwnd
                    break
                }
            }
        } catch {
            ; 如果通过PID找不到，尝试通过可执行文件名查找
            try {
                windows := WinGetList("ahk_exe inlyne.exe")
                for hwnd in windows {
                    if (WinExist("ahk_id " hwnd)) {
                        inlyneHwnd := hwnd
                        break
                    }
                }
            }
        }

        if (inlyneHwnd != 0)
            break

        Sleep(100)
    }

    if (inlyneHwnd == 0) {
        ; 如果还是找不到，就不设置窗口属性
        return
    }

    try {
        ; 激活inlyne窗口
        WinActivate("ahk_id " inlyneHwnd)
        Sleep(100)

        ; 获取主屏幕尺寸
        screenWidth := A_ScreenWidth
        screenHeight := A_ScreenHeight

        ; 设置窗口大小为1024x800
        windowWidth := 1024
        windowHeight := 800

        ; 计算屏幕中心位置
        centerX := (screenWidth - windowWidth) / 2
        centerY := (screenHeight - windowHeight) / 2

        ; 移动窗口到屏幕中心并设置大小
        WinMove(centerX, centerY, windowWidth, windowHeight, "ahk_id " inlyneHwnd)
        Sleep(100)

        ; 设置窗口置顶
        WinSetAlwaysOnTop(1, "ahk_id " inlyneHwnd)

    } catch as e {
        ; 忽略设置窗口属性时的错误
    }
}

/*
函数: VIMD_ShowKeyHelpGui
作用: 显示指定插件中定义的所有按键绑定
参数: pluginName - 插件名称
返回: 无
作者: BoBO
版本: 9.0_2025.07.18
*/
VIMD_ShowKeyHelpWithGui(pluginName) {
    global vim, INIObject
    static keyListGui := 0
    static editControl := 0
    static msgHandler := 0

    ; 如果已经有一个活动的GUI，先关闭它
    if (keyListGui != 0) {
        try {
            ; 移除消息处理器
            if (msgHandler != 0) {
                OnMessage(0x0201, msgHandler, 0)
                msgHandler := 0
            }

            keyListGui.Destroy()
        }
        keyListGui := 0
        editControl := 0
        return
    }

    ; 构建显示文本
    displayText := ""

    ; 尝试获取按键信息
    try {
        ; 检查窗口是否存在
        if (!vim.WinList.Has(pluginName)) {
            MsgBox("没有找到插件：" pluginName)
            return
        }

        winObj := vim.GetWin(pluginName)

        ; 获取所有模式
        modes := []
        for modeName, modeObj in winObj.modeList
            modes.Push(modeName)

        ; 按模式显示按键
        for _, modeName in modes {
            displayText .= "【" modeName "】`n"

            groupedKeys := _VIMD_CollectGroupedKeysForMode(pluginName, modeName)
            if (groupedKeys.Count = 0)
                continue
            keyList := _VIMD_BuildGroupedKeysText(groupedKeys, "  ")

            ; 添加按键信息到显示文本
            displayText .= keyList
        }
    } catch as e {
        displayText .= "获取按键信息时出错: " e.Message "`n"
    }

    ; 从配置文件读取颜色设置
    try {
        bgColor := INIObject.config.tooltip_bg_color
        txtColor := INIObject.config.tooltip_text_color
    } catch {
        bgColor := "Green"
        txtColor := "White"
    }

    ; 创建GUI，使用正常标题
    keyListGui := Gui("+AlwaysOnTop +Resize +MinSize400x300")
    keyListGui.Title := pluginName " 按键列表"

    ; 设置GUI背景颜色为灰色
    keyListGui.BackColor := "Silver"  ; 灰色背景

    ; 添加内容编辑框，尝试使用微软雅黑字体，如果不可用则使用Consolas Microsoft YaHei
    try {
        keyListGui.SetFont("s10", "Consolas")
    } catch {
        keyListGui.SetFont("s10", "Consolas")
    }

    ; 设置编辑框为灰色背景黑色文字
    editControl := keyListGui.Add("Edit", "cBlack BackgroundSilver ReadOnly -WantReturn vKeyListEdit", displayText)

    ; 获取屏幕尺寸
    MonitorGetWorkArea(1, &left, &top, &right, &bottom)
    screenWidth := right - left
    screenHeight := bottom - top

    ; 计算窗口位置（居中）
    guiWidth := Min(800, screenWidth)  ; 窗口宽度为屏幕宽度的70%，最大800
    guiHeight := Min(600, screenHeight)  ; 窗口高度为屏幕高度的70%，最大600
    xPos := (screenWidth - guiWidth) / 2
    yPos := (screenHeight - guiHeight) / 2

    ; 显示GUI
    keyListGui.Show("x" xPos " y" yPos " w" guiWidth " h" guiHeight)

    ; 调整编辑框大小以填充整个窗口
    keyListGui.GetClientPos(&cX, &cY, &cW, &cH)
    editControl.Move(0, 0, cW, cH)

    ; 取消文本选中状态
    SendMessage(0xB1, 0, 0, editControl.Hwnd)  ; EM_SETSEL with 0,0 to deselect text

    ; 添加GUI事件
    keyListGui.OnEvent("Close", CleanupGui)
    keyListGui.OnEvent("Escape", CleanupGui)

    ; 添加窗口大小调整事件
    keyListGui.OnEvent("Size", OnResize)

    ; 窗口大小调整时重新调整编辑框大小
    OnResize(thisGui, minMax, width, height) {
        if (minMax = -1)  ; 窗口最小化
            return

        thisGui.GetClientPos(&cX, &cY, &cW, &cH)
        editControl.Move(0, 0, cW, cH)
    }

    ; 添加拖动功能
    msgHandler := WM_LBUTTONDOWN
    OnMessage(0x0201, msgHandler)

    ; 清理GUI的函数
    CleanupGui(*) {
        ; 移除消息处理器
        if (msgHandler != 0) {
            OnMessage(0x0201, msgHandler, 0)
            msgHandler := 0
        }

        ; 销毁GUI
        keyListGui.Destroy()
        keyListGui := 0
        editControl := 0
    }

    ; 鼠标左键按下时移动窗口
    WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
        static ELM_DRAGMOVE := 0xA2

        ; 检查GUI和控件是否仍然存在
        if (keyListGui && editControl) {
            if (hwnd = keyListGui.Hwnd || hwnd = editControl.Hwnd) {
                PostMessage(0xA1, ELM_DRAGMOVE, 0, , "A")
                return 0
            }
        }
    }
}
