/* vim_Init【vim初始化】
    函数:  vim_Init
    作用:  vim初始化
    参数:
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
vim_Init() {
    #UseHook
    SetKeyDelay -1
}

/* vim_Key【hotkey注册对应函数，热键调用】
    函数:  vim_Key
    作用:  hotkey注册对应函数，热键调用
    参数:  aThisHotkey,未使用【v2 hotkey callback函数要求】
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
vim_Key(aThisHotkey) {
    vim.Key()
}

/* vim_TimeOut【热键超时】
    函数:  热键超时
    作用:  hotkey注册对应函数，热键调用
    参数:
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
vim_TimeOut() {
    vim.IsTimeOut()
}

/* VIMD_清除输入键【清除输入键】
    函数:  VIMD_清除输入键
    作用:  清除输入键
    参数:
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
VIMD_清除输入键() {
    vim.clear()
    HideInfo()
    ; 确保CapsLock状态被关闭，防止卡在大写状态
    SetCapsLockState "AlwaysOff"

    ; BTT tooltip清理 - 清理所有tooltip实例
    try {
        BTTCleanupAll()
    } catch {
        ; 忽略BTT清理错误，不影响主功能
    }

    ; 执行内存优化清理
    try {
        if (IsSet(MemoryOptimizer)) {
            MemoryOptimizer.ManualCleanup()
        }
    } catch {
        ; 忽略内存优化错误，不影响主功能
        MemoryOptimizer.ManualCleanup()
    }
}

/* VIMD_重复上次热键【重复上次热键】
    函数:  VIMD_重复上次热键
    作用:  重复上次热键
    参数:
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
VIMD_重复上次热键() {
    SendInput vim.LastHotKey
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

    ; 解析参数
    if (param != "") {
        params := StrSplit(param, "|")
        win := params[1]
        mode := params.Length > 1 ? params[2] : ""
    } else {
        win := vim.LastFoundWin
        mode := ""
    }

    if strlen(mode) {
        winObj := vim.GetWin(win)
        modeObj := winObj.modeList[mode]
    } else
        modeObj := vim.getMode(win)

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
        if (actionObj.Type = 1) {
            ActionDescList := actionObj.Comment
            if (IsObject(ActionDescList) && ActionDescList.Has(key)) {
                actionDesc := StrSplit(ActionDescList[key], "|")
                comment := (actionDesc.Length >= 2) ? actionDesc[2] : ActionDescList[key]
            } else {
                comment := ActionDescList
            }
        } else {
            comment := actionObj.Comment
        }

        ; 获取分组
        group := actionObj.Group ? actionObj.Group : "未分组"

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
        keyTable := ""
        for _, keyInfo in keys {
            keyTable .= keyInfo.key "`t" keyInfo.comment "`n"
        }

        ; 对每个分组内的按键表格进行对齐
        keyTable := KyFunc_AutoAligned(keyTable, , 30)
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

/* ShowInfo【显示热键信息】
    函数:  ShowInfo
    作用:  显示热键信息
    参数:
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
ShowInfo() {
    global vim
    obj := vim.GetMore(true)
    winObj := vim.GetWin(vim.LastFoundWin)
    CurMode := vim.GetCurMode(vim.LastFoundWin)
    if winObj.Count
        np .= winObj.Count
    loop obj.Length {
        ; if INIObject.config.enable_debug
        ;     vim._Debug.add(Format("热键：{1}`n窗体：{2}`n模式：{3}`n---------------", obj[A_Index]["key"], vim.LastFoundWin, CurMode))
        act := vim.GetAction(vim.LastFoundWin, CurMode, vim.convert2MapKey(obj[A_Index]["key"]))
        if !act
            continue
        np .= act.name "`t" act.Comment "`n"
        if (A_Index = 1) {
            np .= "=====================`n"
        }
    }

    ; 初始化ToolTip管理器
    ToolTipManager.Init()
    ToolTipManager.Show(np)        ; show a ToolTip

}

/* HideInfo【隐藏热键信息】
    函数: HideInfo
    作用:  隐藏热键信息
    参数:
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
HideInfo() {
    if (!VimDesktop_Global.showToolTipStatus) ; 当屏幕有非快捷键补全帮助信息时，不清理
        ToolTipManager.Hide()

    ; BTT提示关闭后进行内存优化，清理累积的内存
    try {
        if (IsSet(MemoryOptimizer)) {
            MemoryOptimizer.ManualCleanup()
        }
    } catch {
        ; 忽略内存优化错误，不影响主功能
    }
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
    inlyneExe := A_ScriptDir "\Apps\inlyne\inlyne.exe"
    if (!FileExist(inlyneExe)) {
        ; 如果 inlyne.exe 不存在，使用原来的 VIMD_ShowKeyHelp 函数
        VIMD_ShowKeyHelp(param)
        return
    }

    ; 解析参数
    if (param != "") {
        params := StrSplit(param, "|")
        win := params[1]
        mode := params.Length > 1 ? params[2] : ""
    } else {
        win := vim.LastFoundWin
        mode := ""
    }

    ; 获取模式对象
    if strlen(mode) {
        winObj := vim.GetWin(win)
        modeObj := winObj.modeList[mode]
    } else {
        modeObj := vim.getMode(win)
        mode := vim.GetCurMode(win)
    }

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
        if (actionObj.Type = 1) {
            ActionDescList := actionObj.Comment
            if (IsObject(ActionDescList) && ActionDescList.Has(key)) {
                actionDesc := StrSplit(ActionDescList[key], "|")
                comment := (actionDesc.Length >= 2) ? actionDesc[2] : ActionDescList[key]
            } else {
                comment := ActionDescList
            }
        } else {
            comment := actionObj.Comment
        }

        ; 获取分组和函数信息
        group := actionObj.Group ? actionObj.Group : "未分组"
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
    inlyneExe := A_ScriptDir "\Apps\inlyne\inlyne.exe"

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
    SetTimer(() => SetInlyneWindowProperties(inlynePID, title), -500)

    ; 设置定时器清理临时文件（30秒后）
    SetTimer(() => CleanupTempFile(tempFile), -30000)
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

/* Class_vim【Class_vim主类 】
    类名:  Class_vim
    作用:  Class_vim主类
    参数:
    返回:  Class_vim
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
Class_vim() {
    global __v
    vim_Init()
    __v := v := __vim()
    return v
}

/* __vim【__vim数据结构】
    类名: __vim
    作用: __vim数据结构
    参数:
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
class __vim {
    /* __new【新建类】
        函数: __new
        作用: 新建类
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    __new() {
        this.PluginList := Map()               ;插件列表
        this.WinList := Map()               ;窗体列表
        this.WinList["global"] := __win()      ;全局窗体
        ;this.winGlobal  := __win()          ;全局窗体
        this.WinInfo := Map()               ;窗体信息
        this.ActionList := Map()               ;动作列表
        this.ActionFromPlugin := Map()         ;动作来源插件
        this.ExcludeWinList := Map()           ;排除窗体列表
        this.ErrorCode := 0                ;错误代码
        this.ActionFromPluginName := ""     ;动作来源插件名称
        this.LastFoundWin := ""             ;最后发现窗体
        This.HotKeyStr := ""                  ;用于记录全部的热键字符串
        This.HelpStr := ""                    ;用于记录热键功能说明
        This.LastHotKey := ""                 ;记录最后一次的命令
        This._Debug := ""
    }

    /* LoadPlugin【加载插件】
        函数: LoadPlugin
        作用: 加载插件
        参数: PluginName：类名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    LoadPlugin(PluginName) {
        if this.PluginList.Has(PluginName)
            return this.PluginList[PluginName]
        p := __Plugin(PluginName)
        this.PluginList[PluginName] := p
        back := this.ActionFromPluginName
        this.ActionFromPluginName := PluginName
        p.CheckFunc()
        if (p.Error) {
            MsgBox Format(Lang["General"]["Plugin_Load"], PluginName), Lang["General"]["Error"], "4112"
            this.ActionFromPluginName := back
        }
    }

    /* SetPlugin【设置Plugin信息】
        函数: SetPlugin
        作用: 设置Plugin信息
        参数: PluginName：类名称
                Author：作者
                Ver:版本
                Comment:备注
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetPlugin(PluginName, Author := "", Ver := "", Comment := "") {
        p := this.PluginList[PluginName]
        p.Author := Author
        p.Ver := Ver
        p.Comment := Comment
    }

    /* GetPlugin【Plugin对象】
        函数: GetPlugin
        作用: Plugin对象
        参数: PluginName：插件名称
        返回: Plugin对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetPlugin(PluginName) {
        return this.PluginList[PluginName]
    }

    /* SetAction【设置Action(动作)信息 】
        函数: SetAction
        作用: 设置Action(动作)信息
        参数:  KeyName：按键名称
                winName：程序名称
                Mode：模式
                Action：动作，函数名称，VIMD_CMD
                Param：参数，数组
                Group：分组
                Comment：备注
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetAction(KeyName, winName, Mode, Action, Param := "", Group := "", Comment := "", OriKey := "") {
        if (!this.ActionList.Has(winName))
            this.ActionList[winName] := Map()
        if (!this.ActionList[winName].Has(Mode))
            this.ActionList[winName][Mode] := Map()
        if this.ActionList[winName][Mode].Has(KeyName)
            ra := this.ActionList[winName][Mode][KeyName]
        else
            ra := this.ActionList[winName][Mode][KeyName] := __Action(KeyName, Action, Param, Group, Comment, OriKey)
        This.ActionFromPlugin[KeyName] := this.ActionFromPluginName
        return ra
    }

    /* GetAction【获取Action对象】
        函数: GetAction
        作用: 获取Action对象
        参数:  winName：程序名称
                Mode：模式
                KeyName：按键名称
        返回: Action对象 或 false
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetAction(winName, Mode, KeyName) {
        if (!this.ActionList.Has(winName))
            return false
        if (!this.ActionList[winName].Has(Mode))
            return false
        if (this.ActionList[winName][Mode].has(KeyName))
            return this.ActionList[winName][Mode][KeyName]
        else
            return false
    }

    /* SetWin【设置win对象信息 】
        函数: SetWin
        作用: 设置win对象信息
        参数: winName：窗体名称
                class：窗体class
                filepath：窗体进程名
                title：窗体标题
        返回: win对象信息
        作者: Kawvin
        版本: 1.0
        AHK版本: 2.0.18
    */
    SetWin(winName, class, filepath := "", title := "") {
        if this.WinList.Has(winName)
            rw := this.WinList[winName]
        else
            rw := this.WinList[winName] := __win(class, filepath, title)
        this.WinInfo["class`t" class] := winName
        this.WinInfo["filepath`t" filepath] := winName
        this.WinInfo["title`t" title] := winName
        return rw
    }

    /* GetWin【返回Win对象 】
        函数: GetWin
        作用: 返回Win对象
        参数: winName：窗体名称
        返回: 返回Win对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetWin(winName := "") {
        if strlen(winName)
            return this.WinList[winName]
        else
            return this.WinList["global"]
    }

    /* CheckWin【检查并返回当前窗体名称】
        函数: CheckWin
        作用: 检查并返回当前窗体名称
        参数:
        返回: 窗体名称
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    CheckWin() {
        f := WinGetProcessName("A")
        if (this.WinInfo.Has("filepath`t" f))
            return winName := this.WinInfo["filepath`t" f]
        c := WinGetClass("A")
        if (this.WinInfo.Has("class`t" c))
            return winName := this.WinInfo["class`t" c]
        return "global"
        ; if Strlen(winName := this.WinInfo["filepath`t" f])
        ;     return winName
        ; c:=WinGetClass("A")
        ; if Strlen(winName := this.WinInfo["class`t" c])
        ;     return winName
    }

    /* mode【设置窗体模式，设置模式时，使用此函数】
        函数: mode
        作用: 设置窗体模式，设置模式时，使用此函数
        参数: mode：模式
                win：窗体，为空则为不当前窗体
        返回:  mode对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    mode(mode, win := "") {
        if not IsObject(this.GetWin(win))
            this.SetWin(win, win)
        return this.SetMode(mode, win)
    }

    /* SetMode【设置窗体模式】
        函数: SetMode
        作用: 设置窗体模式
        参数: modeName：模式
                winName：窗体，为空则为不当前窗体
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetMode(modeName, winName := "") {
        winObj := This.GetWin(winName)
        return winObj.ChangeMode(modeName)
    }

    /* SetModeFunction【设置模式的函数】
        函数: SetModeFunction
        作用: 设置模式的函数
        参数: func：函数名称
                modeName：模式名称
                winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetModeFunction(func, modeName, winName := "") {
        winObj := This.GetWin(winName)
        modeObj := winObj.modeList[modeName]
        modeObj.modeFunction := func
    }

    /* getMode【获取mode对象】
        函数: getMode
        作用: 获取mode对象
        参数: winName：窗体名称
        返回: mode对象
        作者: Kawvin
        版本: 1.0
        AHK版本: 2.0.18
    */
    getMode(winName := "") {
        winObj := This.GetWin(winName)
        return winObj.modeList[winObj.ExistMode()]
    }

    /* GetCurMode【获取当前mode名称】
        函数: GetCurMode
        作用: 获取当前mode名称
        参数: winName：窗体名称
        返回: 当前mode名称
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetCurMode(winName := "") {
        winObj := This.GetWin(winName)
        return winObj.ExistMode()
    }

    /* GetInputState【获取输入状态】
        函数: GetInputState
        作用: 获取输入状态
        参数: winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetInputState(WinTitle := "A") {
        hwnd := ControlGetHwnd(WinTitle)
        if (A_Cursor = "IBeam")
            return 1
        if (WinActive(WinTitle)) {
            ptrSize := !A_PtrSize ? 4 : A_PtrSize
            stGTI := Buffer(cbSize := 4 + 4 + (PtrSize * 6) + 16, 0)
            NumPut(cbSize, stGTI, 0, "UInt")   ;   DWORD   cbSize;
            hwnd := DllCall("GetGUIThreadInfo", "Uint", 0, "Uint", &stGTI) ? NumGet(stGTI, 8 + PtrSize, "UInt") : hwnd
        }
        return DllCall("SendMessage"
            , "UInt", DllCall("imm32\ImmGetDefaultIMEWnd", "Uint", hwnd)
            , "UInt", 0x0283  ;Message : WM_IME_CONTROL
            , "Int", 0x0005  ;wParam  : IMC_GETOPENSTATUS
            , "Int", 0)      ;lParam  : 0
    }

    /* BeforeActionDo【设置Action执行前运行的函数】
        函数: BeforeActionDo
        作用: 设置Action执行前运行的函数
        参数: Function：函数名称
                winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    BeforeActionDo(Function, winName := "") {
        winObj := this.GetWin(winName)
        winObj.BeforeActionDoFunc := Function
    }

    /* AfterActionDo【设置Action执行后运行的函数】
        函数:  AfterActionDo
        作用: 设置Action执行后运行的函数
        参数: Function：函数名称
                winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    AfterActionDo(Function, winName := "") {
        winObj := this.GetWin(winName)
        winObj.AfterActionDoFunc := Function
    }

    /* SetMaxCount【设置最大执行数量】
        函数: SetMaxCount
        作用: 设置最大执行数量
        参数: Int：数量
                winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetMaxCount(Int, winName := "") {
        winObj := This.GetWin(winName)
        winObj.MaxCount := int
    }

    /* GetMaxCount【获取最大执行数量】
        函数:  GetMaxCount
        作用: 获取最大执行数量
        参数: winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetMaxCount(winName := "") {
        winObj := This.GetWin(winName)
        return winObj.MaxCount
    }

    /* SetCount【设置执行次数】
        函数: SetCount
        作用: 设置执行次数
        参数: Int：数量
                winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetCount(int, winName := "") {
        winObj := This.GetWin(winName)
        winObj.Count := int
    }

    /* GetCount【获取执行次数】
        函数: GetCount
        作用: 获取执行次数
        参数: winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetCount(winName := "") {
        winObj := This.GetWin(winName)
        return winObj.Count
    }

    /* SetTimeOut【设置超时时间】
        函数: SetTimeOut
        作用: 设置超时时间
        参数: Int：超时时间，单位ms
                winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetTimeOut(Int, winName := "") {
        winObj := This.GetWin(winName)
        winObj.TimeOut := int
    }

    /* GetTimeOut【获取超时时间】
        函数: GetTimeOut
        作用: 获取超时时间
        参数: winName：窗体名称
        返回: 超时时间，单位ms
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetTimeOut(winName := "") {
        winObj := This.GetWin(winName)
        return winObj.TimeOut
    }

    /* Map【热键映射到动作（Action）对象 】
        函数: Map
        作用: 热键映射到动作（Action）对象
        参数: keyName：VIMD按键
                winName：窗体名称
                Mode：模式
                Action：运行名称
                Param：参数
                Group：分组
                Comment：备注
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Map(keyName, winName, Mode, Action, Param := "", Group := "", Comment := "") {
        this.mode(Mode, winName)
        if ( not this.GetAction(winName, Mode, keyName)) {
            _tAction := RegExReplace(Action, "<\d>$", "") ;MPCHC_SendPos 或 带次数的 MPCHC_SendPos<2>
            ; 检查函数是否存在，但不使用 Type(%_tAction%) 这种可能导致错误的方式
            ; 而是使用更安全的方式检查函数是否存在
            ; 检查函数是否存在
            functionExists := false

            ; 所有函数都假设存在，避免检查函数是否存在导致的错误
            functionExists := true

            if (functionExists) {
                OriKey := keyName
                keyName := this.Convert2VIM_Title(keyName)
                ; MsgBox keyName "`n" OriKey
                ; if INIObject.config.enable_debug
                ;     this._Debug.add(Format("热键：{1}`n窗体：{2}`n模式：{3}`n动作：{4}`n参数：{5}`n分组：{6}`n备注：{7}`n热键VIM：{8}`n-------------------------------`n",keyName, winName, Mode, Action, KyFunc_StringParam(Param), Group, Comment,OriKey))
                this.SetAction(keyName, winName, Mode, Action, Param, Group, Comment, OriKey)
            } else {
                MsgBox Format(Lang["General"]["Key_MapError"], keyname, Action), Lang["General"]["Error"], "4112"
                this.ErrorCode := "MAP_ACTION_ERROR"
                return
            }
        }

        winObj := This.GetWin(winName)
        modeObj := this.getMode(winName)
        Class := winObj.class
        filepath := winObj.filepath
        if (winName != "global") {
            if strlen(filepath)
                HotIfWinActive "ahk_exe " filepath
            else
                HotIfWinActive "ahk_class " class
        } else
            HotIfWinActive
        keyName := RegExReplace(keyName, "i)<noWait>", "", &bnoWait)
        keyName := RegExReplace(keyName, "i)<super>", "", &bSuper)
        newKeyName := keyName
        thisKey := ""
        loop {
            if ( not strlen(newKeyName)) {
                break
            } else {
                saveMoreKey .= thisKey
                modeObj.SetMoreKey(saveMoreKey)
            }
            ;获取<insert>及单字母键，如a, B
            if RegExMatch(newKeyName, "^(<.+?>)", &m) {
                thisKey := SubStr(newKeyName, 1, StrLen(m[1]))
                newKeyName := SubStr(newKeyName, StrLen(m[1]) + 1)
            } else {
                thisKey := SubStr(newKeyName, 1, 1)
                newKeyName := SubStr(newKeyName, 2)
            }

            ;将大字字母转换为类<S-*>格式，如 B --> <S-B>
            if RegExMatch(thisKey, "^([A-Z])$", &m)
                thisKey := "<S-" m[1] ">"

            SaveKeyName .= thisKey

            key := this.Convert2AHK(thisKey)

            ; if INIObject.config.enable_debug{
            ;     if INIObject.config.enable_debug
            ;         this._Debug.Add("Map: " thisKey " to: " Action)
            ; }

            if (SubStr(keyName, 1, 1) = "*") {      ;本行的作用是以*开头的快捷键，不启用
                ;Hotkey Key, "Off"
                continue
            } else {
                try {
                    Hotkey Key, vim_Key, "On"
                } catch as e {
                    ; 如果热键注册失败，记录错误但不中断程序
                    if (INIObject.config.enable_debug)
                        this._Debug.Add("Error registering hotkey: " Key " - " e.Message)
                    continue
                }
            }

            if A_LastError {
                MsgBox Format(Lang["General"]["Key_MapError2"], KeyName, key), Lang["General"]["Error"], "4112"
                this.ErrorCode := "MAP_KEY_ERROR"
                return
            } else {
                winObj.SuperKeyList[key] := bSuper
                winObj.KeyList[key] := true
            }

        }
        modeObj.SetKeyMap(SaveKeyName, Action)
        modeObj.SetNoWait(SaveKeyName, bnoWait)
        return false
    }

    /* ExcludeWin【排除窗体】
        函数: ExcludeWin
        作用: 排除窗体
        参数: winName：窗体名称
                Bold：标记，默认=true
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    ExcludeWin(winName := "", Bold := true) {
        this.ExcludeWinList[winName] := Bold
    }

    /* Toggle【窗体对象状态反值】
        函数: Toggle
        作用: 窗体对象状态反值
        参数: winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Toggle(winName) {
        winObj := this.GetWin(winName)
        winObj.Status := !winObj.Status
        this.Control(winObj.Status, winName)
        return winObj.Status
    }

    /* Control【将当前窗体的所有热键设置为指定状态 】
        函数: Control
        作用: 将当前窗体的所有热键设置为指定状态
        参数:  bold：是否启用热键
                winName：窗体名称，默认当前窗体
                all：是否全部热键，默认false
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Control(bold, winName := "", all := false) {
        local class

        winObj := this.GetWin(winName)
        class := winObj.Class
        filepath := winObj.filepath
        if Strlen(filepath)
            HotIfWinActive "ahk_exe " filepath
        else if Strlen(class)
            HotIfWinActive "ahk_class " class
        else
            HotIfWinActive
        if INIObject.config.enable_debug
            this._Debug.Add("===== Control End  =====")
        for i, k in winObj.KeyList {
            if winObj.SuperKeyList[i] And ( not all)
                continue
            if INIObject.config.enable_debug
                this._Debug.Add("class: " class "`tKey: " i "`tControl: " bold)
            if bold
                Hotkey i, vim_Key, "On"
            else
                Hotkey i, vim_Key, "off"
            winObj.KeyList[i] := bold
        }
        if INIObject.config.enable_debug
            this._Debug.Add("===== Control Start =====")
    }

    /* Copy【复制win对象】
        函数: Copy
        作用: 复制win对象
        参数: winName1, winName2, class, filepath := "", title := ""
        返回: win对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Copy(winName1, winName2, class, filepath := "", title := "") {
        ; if INIObject.config.enable_debug
        ;     this._Debug.Add("Copy>> " winName1 "`t"  winName2 "`t" class)
        win1 := This.GetWin(winName1)
        win2 := this.SetWin(winName2, class, filepath, title)
        win2.class := class
        win2.filepath := filepath
        win2.title := title
        win2.KeyList := win1.KeyList
        win2.SuperKeyList := win1.SuperKeyList
        win2.modeList := win1.modeList
        win2.mode := win1.mode
        win2.LastKey := win1.LastKey
        win2.KeyTemp := win1.KeyTemp
        win2.MaxCount := win1.MaxCount
        win2.Count := win1.Count
        win2.TimeOut := win1.TimeOut
        win2.Info := win1.Info
        win2.BeforeActionDoFunc := win1.BeforeActionDoFunc
        win2.AfterActionDoFunc := win1.AfterActionDoFunc
        win2.ShowInfoFunc := win1.ShowInfoFunc
        win2.HideInfoFunc := win1.HideInfoFunc
        this.Control(Bold := true, winName2, all := true)
        return win2
    }

    /* CopyMode【复制Mode对象】
        函数: CopyMode
        作用: 复制Mode对象
        参数: winName, fromMode, toMode
        返回: Mode对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    CopyMode(winName, fromMode, toMode) {
        winObj := This.GetWin(winName)
        ; winObj.mode := modeName
        winObj.mode := this.GetCurMode(winName)
        winObj.KeyTemp := ""
        winObj.Count := 0
        from := winObj.modeList[fromMode]
        from.name := toMode
        winObj.modeList[toMode] := from
        return from
    }

    /* Delete【删除win对象】
        函数: Delete
        作用: 删除win对象
        参数: winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Delete(winName := "") {
        this.Control(false, winName, all := true)
        this.WinList[winName] := ""
    }

    /* GetMore【获取有相同键值的动作】
        函数: GetMore
        作用: 获取有相同键值的动作
        参数:
        返回: Array或字符串
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetMore(obj := false) {
        rt_obj := []
        winObj := this.GetWin(this.LastFoundWin)
        modeObj := this.getMode(this.LastFoundWin)
        if Strlen(winObj.KeyTemp) {
            r := winObj.KeyTemp "`n"
            rt_obj.Push(Map("key", winObj.KeyTemp, "Action", modeObj.GetKeyMap(winObj.KeyTemp)))
            m := "i)^" this.ToMatch(winObj.KeyTemp) ".+"
            for i, k in modeObj.keyMapList {
                if RegExMatch(i, m) {
                    r .= i "`t" modeObj.GetKeyMap(i) "`n"
                    rt_obj.Push(Map("key", i, "Action", modeObj.GetKeyMap(i)))
                }
            }

            if obj
                return rt_obj
            else
                return r
        }
        else
            if winObj.count
                return winObj.count
    }

    /* Clear【清空win对象的按键记录】
        函数: Clear
        作用: 清空win对象的按键记录
        参数: winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Clear(winName := "") {
        winObj := This.GetWin(winName)
        winObj.KeyTemp := ""
        winObj.Count := 0
    }

    /* Key【热键执行】
        函数: Key
        作用: 热键执行
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Key() {
        ; 获取winName
        winName := this.CheckWin()
        ; 获取当前的热键
        k := this.CheckCapsLock(this.Convert2VIM(A_ThisHotkey))
        This.HotKeyStr .= This.CheckCapsLock(This.Convert2VIM(A_ThisHotkey))
        This.HotKeyStr := this.ShiftUpper(This.HotKeyStr)

        ; 如果winName在排除窗口中，直接发送热键
        if this.ExcludeWinList.Has(winName) {
            Send this.Convert2AHK(k, ToSend := true)
            This.HotKeyStr := ""
            This.LastHotKey := ""
            return
        }

        winObj := this.GetWin(winName)
        ;对于内置热键，因为是始终加载的，此处检查status是否启用
        if (!winObj.status) {
            ; 不启用，按普通键输出
            Send this.Convert2AHK(k, ToSend := true)
            This.HotKeyStr := ""
            This.LastHotKey := ""
            return
        }

        ; 如果当前热键在当前winName无效，判断全局热键中是否有效？
        if Not winObj.KeyList.has(A_thisHotkey) {
            winObj := this.GetWin("global")
            if Not winObj.KeyList.has(A_thisHotkey) || (!winObj.status) {   ;如果没有当前热键，或全局status=0不启用时，按普通键输出
                ; 无效热键，按普通键输出
                Send this.Convert2AHK(k, ToSend := true)
                This.HotKeyStr := ""
                This.LastHotKey := ""
                return
            } else
                winName := "global"
        }

        this.LastFoundWin := winName
        ; 执行在判断热键前的函数, 如果函数返回true，按普通键输出
        ; if (Type(f := winObj.BeforeActionDoFunc)="Func"){
        ; 修改为无须绑定，直接为默认项【plugin_Before】，2025.06.16
        f := winName "_Before"
        try
            _Rst_Before := %f%()
        catch
            _Rst_Before := 0
        if _Rst_Before {
            Send this.Convert2AHK(k, ToSend := true)
            This.HotKeyStr := ""
            This.LastHotKey := ""
            return
        }

        ; 获取当前模式对应的对象
        modeObj := this.getMode(winName)
        modeName := this.GetCurMode(winName)
        ; 如果模式为空，未设定默认械，则发送原键。
        if (modeName = "") {
            Send this.Convert2AHK(k, ToSend := true)
            return
        }

        ; 把当前热键添加到热键缓存中, 并设置最后热键为k
        winObj.KeyTemp .= winObj.LastKey := k

        if INIObject.config.enable_debug
            this._Debug.Add("----win: " winName "`tHotkey: " k)
        /*
            if winObj.Count
                this._Debug.Add(" [" winName "`t热键:" winObj.Count winObj.KeyTemp)
            else
                this._Debug.Add(" [" winName "]`t热键:" winObj.KeyTemp)
        */

        ; 热键缓存是否有对应的Action?
        ; 判断是否有更多热键, 如果当前具有<noWait>设置，则无视更多热键
        if modeObj.GetMoreKey(winObj.KeyTemp) And ( Not modeObj.GetNoWait(winObj.KeyTemp)) {
            ; 启用TimeOut
            if strlen(modeObj.GetKeyMap(winObj.KeyTemp))
                if tick := winObj.TimeOut
                    SetTimer Vim_TimeOut, tick

            winObj.ShowMore()
            ; 执行在判断热键后的函数, 如果函数返回true，按普通键输出
            ; if (Type(f := winObj.AfterActionDoFunc)="Func") {
            ; 修改为无须绑定，直接为默认项【plugin_After】，2025.06.16
            f := winName "_After"
            try
                _Rst_After := %f%()
            catch
                _Rst_After := 0
            if _Rst_After {
                Send this.Convert2AHK(k, ToSend := true)
            }
            return
        }

        ; 如果没有更多，热键缓存是否有对应的Action?
        if strlen(actionName := modeObj.GetKeyMap(winObj.KeyTemp)) {
            actObj := this.GetAction(winName, modeName, this.Convert2MapKey(winObj.KeyTemp))
            ; if INIObject.config.enable_debug
            ;     this._Debug.Add("热键: " actObj.name "`n动作:" actObj.Function "`n参数:" KyFunc_StringParam(actObj.Param, ",") "`n----------------")
            if actObj {
                if (actObj.Type = 1) And RegExMatch(actObj.Function, "<(\d)>$", &m) { ;整<3>类型的为多次运行的函数
                    ; 数字则进行累加
                    winObj.Count := winObj.Count * 1 + m[1]
                    if winObj.MaxCount And winObj.Count > winObj.MaxCount
                        winObj.Count := winObj.MaxCount
                }
                ; if INIObject.config.enable_debug
                ;this._Debug.Add("act: " actionName "`tLK: " winObj.KeyTemp)
                SetTimer Vim_TimeOut, 0
                actObj.Do(winObj.Count)
                This.HotKeyStr := ""
                winObj.Count := 0
            }
        } else {
            SetTimer Vim_TimeOut, 0
            ; 如果没有，按普通键输出
            if strlen(actionName := modeObj.GetKeyMap(winObj.LastKey)) {
                actObj := this.GetAction(winName, modeName, this.Convert2MapKey(winObj.KeyTemp))
                if (!actObj)
                    Send this.Convert2AHK(k, ToSend := true)
                else
                    actObj.Do(winObj.Count)
                This.HotKeyStr := ""
                winObj.Count := 0
            } else {
                Send this.Convert2AHK(k, ToSend := true)
                winObj.Count := 0
                This.HotKeyStr := ""
            }
        }

        winObj.KeyTemp := ""
        winObj.HideMore()

        ; 执行在判断热键后的函数, 如果函数返回true，按普通键输出
        ; if (Type(f := winObj.AfterActionDoFunc)="Func"){
        ; 修改为无须绑定，直接为默认项【plugin_After】，2025.06.16
        f := winName "_After"
        try
            _Rst_After := %f%()
        catch
            _Rst_After := 0
        if _Rst_After
            Send this.Convert2AHK(k, ToSend := true)
        This.HotKeyStWr := ""
    }

    ; IsTimeOut() {{{2
    IsTimeOut() {
        winName := this.LastFoundWin
        winObj := this.GetWin(this.LastFoundWin)
        modeObj := this.getMode(this.LastFoundWin)
        modeName := this.GetCurMode(this.LastFoundWin)
        act := this.GetAction(this.LastFoundWin, modeName, this.Convert2MapKey(winObj.KeyTemp))
        if act {
            winObj.HideMore()
            act.Do(winObj.Count)
            winObj.Count := 0
            winObj.KeyTemp := ""
            ; 执行在判断热键后的函数, 如果函数返回true，按普通键输出
            ; if Type(f := winObj.AfterActionDoFunc)="Func"
            ; 修改为无须绑定，直接为默认项【plugin_After】，2025.06.16
            f := winName "_After"
            try
                _Rst_After := %f%()
            catch
                _Rst_After := 0
            if _Rst_After
                Send this.Convert2AHK(act.name, ToSend := true)
            SetTimer Vim_TimeOut, 0
        }
    }

    /* ShiftUpper【把<s-v>这种形式的热键，转换为V（字母大写）】
        函数: ShiftUpper
        作用: 把<s-v>这种形式的热键，转换为V（字母大写）
        参数: aString :字符呼呼大睡
        返回: 大写字母
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    ShiftUpper(aString) {
        return RegExReplace(aString, "im)<s\-([a-zA-Z])>", "$U1")
    }

    /* Debug【调试 】
        函数: Debug
        作用: 调试
        参数: Bold：1=启用，0=不启用
                history：输出内容
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Debug(Bold, history := false) {
        if Bold {
            this._Debug := __vimDebug(history)
            this._Debug.var(this)
        } else {
            vimDebug.Destroy()
            this._Debug := ""
        }
    }

    /* Convert2VIM【将AHK热键名转换为类VIM的热键名 】
        函数: Convert2VIM
        作用: 将AHK热键名转换为类VIM的热键名
        参数: key： AHK热键名
        返回: 类VIM的热键名
        作者:  Kawvin
        修改:  BoBO
        版本:  1.0
        AHK版本: 2.0.18
        例 Convert2VIM("f1")
    */
    Convert2VIM(key) {
        ;大写字母
        if RegExMatch(key, "^[A-Z]$")
            return "<S-" StrUpper(key) ">"
        ;Fn功能键
        if RegExMatch(key, "i)^((F1)|(F2)|(F3)|(F4)|(F5)|(F6)|(F7)|(F8)|(F9)|(F10)|(F11)|(F12))$")
            return "<" key ">"
        ;鼠标键
        if RegExMatch(key,
            "i)^((LButton)|(RButton)|(MButton)|(XButton1)|(XButton2)|(WheelDown)|(WheelUp)|(WheelLeft)|(WheelRight))$")
            return "<" key ">"
        ;键盘控制
        if RegExMatch(key, "i)^((CapsLock)|(Space)|(Tab)|(Enter))$")
            return "<" key ">"
        if RegExMatch(key, "i)^((BS)|(BackSpace))$")
            return "<BS>"
        if RegExMatch(key, "i)^((Esc)|(Escape))$")
            return "<Esc>"
        ;光标控制
        if RegExMatch(key, "i)^((ScrollLock)|(Home)|(End)|(Up)|(Down)|(Left)|(Right)|(PgUp)|(PgDn))$")
            return "<" key ">"
        if RegExMatch(key, "i)^((Ins)|(Insert))$")
            return "<Insert>"
        if RegExMatch(key, "i)^((Del)|(Delete))$")
            return "<Delete>"
        ;修饰键
        if RegExMatch(key, "i)^shift\s&\s(.*)", &m) or RegExMatch(key, "^\+(.*)", &m)
            return "<S-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^lshift\s&\s(.*)", &m) or RegExMatch(key, "^<\+(.*)", &m)
            return "<LS-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^rshift\s&\s(.*)", &m) or RegExMatch(key, "^>\+(.*)", &m)
            return "<RS-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^Ctrl\s&\s(.*)", &m) or RegExMatch(key, "^\^(.*)", &m)
            return "<C-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^lctrl\s&\s(.*)", &m) or RegExMatch(key, "^<\^(.*)", &m)
            return "<LC-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^rctrl\s&\s(.*)", &m) or RegExMatch(key, "^>\^(.*)", &m)
            return "<RC-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^alt\s&\s(.*)", &m) or RegExMatch(key, "^\!(.*)", &m)
            return "<A-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^lalt\s&\s(.*)", &m) or RegExMatch(key, "^<\!(.*)", &m)
            return "<LA-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^ralt\s&\s(.*)", &m) or RegExMatch(key, "^>\!(.*)", &m)
            return "<RA-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^lwin\s&\s(.*)", &m) or RegExMatch(key, "^#(.*)", &m)
            return "<W-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^space\s&\s(.*)", &m)
            return "<SP-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^alt$")
            return "<Alt>"
        if RegExMatch(key, "i)^ctrl$")
            return "<Ctrl>"
        if RegExMatch(key, "i)^shift$")
            return "<Shift>"
        if RegExMatch(key, "i)^lwin$")
            return "<Win>"
        if RegExMatch(key, "i)^~LButton\s&\s(.*)", &m)
            return "<LB-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^~MButton\s&\s(.*)", &m)
            return "<MB-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^~RButton\s&\s(.*)", &m)
            return "<RB-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^~XButton1\s&\s(.*)", &m)
            return "<XB1-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^~XButton2\s&\s(.*)", &m)
            return "<XB2-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^CapsLock\s&\s(.*)", &m)
            return "<Caps-" StrUpper(m[1]) ">"
        if RegExMatch(key, "i)^~Tab\s&\s(.*)", &m)
            return "<Tab-" StrUpper(m[1]) ">"
        ;特殊键
        if RegExMatch(key, "i)^AppsKey$")
            return "<" key ">"
        if RegExMatch(key, "i)^PrintScreen$")
            return "<PrtSc>"
        if RegExMatch(key, "i)^controlBreak$")
            return "<controlBreak>"
        if RegExMatch(key, "i)^LT$")
            return "<LT>"
        if RegExMatch(key, "i)^RT$")
            return "<RT>"
        ; 数字小键盘
        if RegExMatch(key, "i)^NumpadEnter$")
            return "<" key ">"
        ; 数字键区
        if RegExMatch(key,
            "i)^((Numpad0)|(Numpad1)|(Numpad2)|(Numpad3)|(Numpad4)|(Numpad5)|(Numpad6)|(Numpad7)|(Numpad8)|(Numpad9)|(NumpadAdd)|(NumpadSub)|(NumpadMult)|(NumpadDiv)|(NumpadDot))$"
        )
            return "<" key ">"
        return key
    }

    /* Convert2VIM_Title【把ahk热键名转换为vimd热键定义，为保持大小写一致使用，在热键调用时匹配VIM化的热键】
        函数: Convert2VIM_Title
        作用: 把ahk热键名转换为vimd热键定义，为保持大小写一致使用，在热键调用时匹配VIM化的热键
        参数: key： AHK热键名
        返回: 类VIM的热键名
        作者:  Kawvin
        修改:  BoBO
        版本:  1.0
        AHK版本: 2.0.18
        例 Convert2VIM_Title("f1")
    */
    Convert2VIM_Title(key) {
        ;大写字母
        arr := MyFun_RegExMatchAll(key, "<(.*)>")
        if (arr.length) {
            for k, v in arr {
                if RegExMatch(v, "i)^((BS)|(BackSpace))$")
                    key := RegExReplace(key, v, "BS")
                if RegExMatch(v, "i)^((Esc)|(Escape))$")
                    key := RegExReplace(key, v, "Esc")
                ;光标控制
                if RegExMatch(v, "i)^((Ins)|(Insert))$")
                    key := RegExReplace(key, v, "Insert")
                if RegExMatch(v, "i)^((Del)|(Delete))$")
                    key := RegExReplace(key, v, "Delete")
                ;特殊键
                if RegExMatch(key, "i)^PrintScreen$")
                    key := RegExReplace(key, v, "PrtSc")
                if RegExMatch(key, "i)^controlBreak$")
                    key := RegExReplace(key, v, "controlBreak")
                if RegExMatch(key, "i)^LT$")
                    key := RegExReplace(key, v, "LT")
                if RegExMatch(key, "i)^RT$")
                    key := RegExReplace(key, v, "RT")
                if RegExMatch(key, "i)^(.*?\-.*?)$")
                    key := RegExReplace(key, v, StrUpper(v))
            }
        }
        return key
    }

    /* Convert2AHK【将类VIM的热键名转换为AHK热键名】
        函数: Convert2AHK
        作用: 将类VIM的热键名转换为AHK热键名
        参数: key：类VIM的热键名
                ToSend：是否发送，0：enter , 1：{enter}
        返回:
        作者:  Kawvin
        修改:  BoBO
        版本:  1.0
        AHK版本: 2.0.18
        例 Convert2AHK("<F1>")
    */
    Convert2AHK(key, ToSend := false) {
        this.CheckCapsLock(key)
        if RegExMatch(key, "^<.*>$") {
            key := SubStr(key, 2, strlen(key) - 2)
            ;Fn功能键
            if RegExMatch(key, "i)^((F1)|(F2)|(F3)|(F4)|(F5)|(F6)|(F7)|(F8)|(F9)|(F10)|(F11)|(F12))$")
                return ToSend ? "{" key "}" : key
            ;鼠标键
            if RegExMatch(key,
                "i)^((LButton)|(RButton)|(MButton)|(XButton1)|(XButton2)|(WheelDown)|(WheelUp)|(WheelLeft)|(WheelRight))$"
            )
                return ToSend ? "{" key "}" : key
            ;键盘控制
            if RegExMatch(key, "i)^((CapsLock)|(Space)|(Tab)|(Enter))$")
                return ToSend ? "{" key "}" : key
            if RegExMatch(key, "i)^BS$")
                return ToSend ? "{" key "}" : key
            if RegExMatch(key, "i)^Esc$")
                return ToSend ? "{" key "}" : key
            ;光标控制
            if RegExMatch(key, "i)^((ScrollLock)|(Home)|(End)|(Up)|(Down)|(Left)|(Right)|(PgUp)|(PgDn))$")
                return ToSend ? "{" key "}" : key
            if RegExMatch(key, "i)^Insert$")
                return ToSend ? "{" key "}" : key
            if RegExMatch(key, "i)^Delete$")
                return ToSend ? "{" key "}" : key
            ;修饰键
            if RegExMatch(key, "i)^alt$")
                return ToSend ? "{!}" : "alt"
            if RegExMatch(key, "i)^ctrl$")
                return ToSend ? "{^}" : "ctrl"
            if RegExMatch(key, "i)^shift$")
                return ToSend ? "{+}" : "shift"
            if RegExMatch(key, "i)^win$")
                return ToSend ? "{#}" : "lwin"
            if RegExMatch(key, "i)^S\-(.*)", &m)
                return ToSend ? "+" this.CheckToSend(m[1]) : "+" m[1]
            if RegExMatch(key, "i)^LS\-(.*)", &m)
                return ToSend ? "<+" this.CheckToSend(m[1]) : "<+" m[1]
            if RegExMatch(key, "i)^RS-(.*)", &m)
                return ToSend ? ">+" this.CheckToSend(m[1]) : ">+" m[1]
            if RegExMatch(key, "i)^C\-(.*)", &m)
                return ToSend ? "^" this.CheckToSend(m[1]) : "^" m[1]
            if RegExMatch(key, "i)^LC\-(.*)", &m)
                return ToSend ? "<^" this.CheckToSend(m[1]) : "<^" m[1]
            if RegExMatch(key, "i)^RC\-(.*)", &m)
                return ToSend ? ">^" this.CheckToSend(m[1]) : ">^" m[1]
            if RegExMatch(key, "i)^A\-(.*)", &m)
                return ToSend ? "!" this.CheckToSend(m[1]) : "!" m[1]
            if RegExMatch(key, "i)^LA\-(.*)", &m)
                return ToSend ? "<!" this.CheckToSend(m[1]) : "<!" m[1]
            if RegExMatch(key, "i)^RA\-(.*)", &m)
                return ToSend ? ">!" this.CheckToSend(m[1]) : ">!" m[1]
            if RegExMatch(key, "i)^w\-(.*)", &m)
                return ToSend ? "#" this.CheckToSend(m[1]) : "#" m[1]
            if RegExMatch(key, "i)^SP\-(.*)", &m)
                return ToSend ? "{space}" this.CheckToSend(m[1]) : "space & " m[1]
            if RegExMatch(key, "i)^LB\-(.*)", &m)
                return ToSend ? "{~LButton}" this.CheckToSend(m[1]) : "~LButton & " m[1]
            if RegExMatch(key, "i)^MB\-(.*)", &m)
                return ToSend ? "{~MButton}" this.CheckToSend(m[1]) : "~MButton & " m[1]
            if RegExMatch(key, "i)^RB\-(.*)", &m)
                return ToSend ? "{~RButton}" this.CheckToSend(m[1]) : "~RButton & " m[1]
            if RegExMatch(key, "i)^RB1\-(.*)", &m)
                return ToSend ? "{~XButton1}" this.CheckToSend(m[1]) : "~XButton1 & " m[1]
            if RegExMatch(key, "i)^RB2\-(.*)", &m)
                return ToSend ? "{~XButton2}" this.CheckToSend(m[1]) : "~XButton2 & " m[1]
            if RegExMatch(key, "i)^Caps\-(.*)", &m)
                return ToSend ? "{Caps}" this.CheckToSend(m[1]) : "CapsLock & " m[1]
            if RegExMatch(key, "i)^Tab\-(.*)", &m)
                return ToSend ? "{~Tab}" this.CheckToSend(m[1]) : "~Tab & " m[1]
            ;特殊键
            if RegExMatch(key, "i)^AppsKey$")
                return ToSend ? "{AppsKey}" : "AppsKey"
            if RegExMatch(key, "i)^PrtSc$")
                return ToSend ? "{PrintScreen}" : "PrintScreen"
            if RegExMatch(key, "i)^controlBreak$")
                return ToSend ? "{controlBreak}" : "controlBreak"
            if RegExMatch(key, "LT")
                return ToSend ? "{<}" : "<"
            if RegExMatch(key, "RT")
                return ToSend ? "{>}" : "<"
            ; 数字小键盘
            if RegExMatch(key, "i)^NumpadEnter$")
                return ToSend ? "{" key "}" : key
            ; 数字键区
            if RegExMatch(key,
                "i)^((Numpad0)|(Numpad1)|(Numpad2)|(Numpad3)|(Numpad4)|(Numpad5)|(Numpad6)|(Numpad7)|(Numpad8)|(Numpad9)|(NumpadAdd)|(NumpadSub)|(NumpadMult)|(NumpadDiv)|(NumpadDot))$"
            )
                return ToSend ? "{" key "}" : key

        } else
            return key
    }

    /* Convert2MapKey【将类VIM的热键名转换为Map热键名】
        函数: Convert2MapKey
        作用: 将类VIM的热键名转换为Map热键名
        参数: key：类VIM的热键名
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
        例 Convert2AHK("<F1>")
    */
    Convert2MapKey(key) {
        return this.ShiftUpper(this.CheckCapsLock(this.Convert2VIM(key)))
    }

    /* CheckToSend【转换发送键 】
        函数: CheckToSend
        作用: 转换发送键
        参数: key
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    CheckToSend(key) {
        ;Fn功能键
        if RegExMatch(key, "i)^((F1)|(F2)|(F3)|(F4)|(F5)|(F6)|(F7)|(F8)|(F9)|(F10)|(F11)|(F12))$")
            return "{" key "}"
        ;鼠标键
        if RegExMatch(key,
            "i)^((LButton)|(RButton)|(MButton)|(XButton1)|(XButton2)|(WheelDown)|(WheelUp)|(WheelLeft)|(WheelRight))$")
            return "{" key "}"
        ;键盘控制
        if RegExMatch(key, "i)^((CapsLock)|(Space)|(Tab)|(Enter))$")
            return "{" key "}"
        if RegExMatch(key, "i)^BS$")
            return "{" key "}"
        if RegExMatch(key, "i)^Esc$")
            return "{" key "}"
        ;光标控制
        if RegExMatch(key, "i)^((ScrollLock)|(Home)|(End)|(Up)|(Down)|(Left)|(Right)|(PgUp)|(PgDn))$")
            return "{" key "}"
        if RegExMatch(key, "i)^Insert$")
            return "{" key "}"
        if RegExMatch(key, "i)^Delete$")
            return "{" key "}"
        ;修饰键
        if RegExMatch(key, "i)^alt$")
            return "{!}"
        if RegExMatch(key, "i)^ctrl$")
            return "{^}"
        if RegExMatch(key, "i)^shift$")
            return "{+}"
        if RegExMatch(key, "i)^win$")
            return "{#}"
        ;特殊键
        if RegExMatch(key, "i)^AppsKey$")
            return "{AppsKey}"
        if RegExMatch(key, "i)^PrtSc$")
            return "{PrintScreen}"
        if RegExMatch(key, "i)^controlBreak$")
            return "{controlBreak}"
        if RegExMatch(key, "LT")
            return "<LT>"
        if RegExMatch(key, "RT")
            return "{>}"
        ; 数字小键盘
        if RegExMatch(key, "i)^NumpadEnter$")
            return "{" key "}"
        ; 数字键区
        if RegExMatch(key,
            "i)^((Numpad0)|(Numpad1)|(Numpad2)|(Numpad3)|(Numpad4)|(Numpad5)|(Numpad6)|(Numpad7)|(Numpad8)|(Numpad9)|(NumpadAdd)|(NumpadSub)|(NumpadMult)|(NumpadDiv)|(NumpadDot))$"
        )
            return "{" key "}"
        return StrLower(Key)
    }

    /* CheckCapsLock【检测CapsLock是否按下，返回对应的值】
        函数: CheckCapsLock
        作用: 检测CapsLock是否按下，返回对应的值 ，key 的值为类VIM键，如 CheckCapsLock("<S-A>")
        参数: key
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    CheckCapsLock(key) {
        if GetKeyState("CapsLock", "T") {
            if RegExMatch(key, "^[a-z]$")
                return "<S-" key ">"
            if RegExMatch(key, "i)^<S\-([a-zA-Z])>", &m) {
                return StrLower(m[1])
            }
        }
        return key
    }

    /* ToMatch【替换特殊字符】
        函数: ToMatch
        作用: 替换特殊字符
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    ToMatch(v) {
        v := RegExReplace(v, "\+|\?|\.|\*|\{|\}|\(|\)|\||\^|\$|\[|\]|\\", "\$0")
        return RegExReplace(v, "\s", "\s")
    }
}

/* __win【win对象】
    类名: __win
    作用: win对象
    参数: class：class
            filepath：进程名
            title：标题
    返回:  win对象
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
class __win {
    /* __win【win对象】
        类名: __win
        作用: win对象
        参数: class：class
                filepath：进程名
                title：标题
        返回:  win对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    __new(class := "", filepath := "", title := "") {
        this.class := class
        this.filepath := filepath
        this.title := title
        this.KeyList := Map()
        this.SuperKeyList := Map()
        this.modeList := Map()
        this.Status := 1      ;是否启用
        this.defaultMode := ""   ;默认模式
        this.mode := ""    ;当前模式
        this.Inside := 0     ;是否为Vimd.ini内置插件
        this.LastKey := ""
        this.KeyTemp := ""
        this.MaxCount := 99
        this.Count := 0
        this.TimeOut := 0
        this.Info := VimDesktop_Global.default_enable_show_info
        this.BeforeActionDoFunc := ""
        this.AfterActionDoFunc := ""
        this.ShowInfoFunc := "ShowInfo"
        this.HideInfoFunc := "HideInfo"
    }

    /* ChangeMode【检查模式是否存在】
        函数: ChangeMode
        作用: 检查模式是否存在，如存在则返回模式对象，如果不存在则新建并返回模式对象
        参数: modeName：模式名称
        返回: mode对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    ChangeMode(modeName) {
        this.mode := modeName
        this.KeyTemp := ""
        this.Count := 0
        if not this.modeList.Has(modeName)
            this.modeList[modeName] := __Mode(modeName)

        modeObj := this.modeList[modeName]
        if (modeObj.modeFunction != "") {
            func := modeObj.modeFunction
            if Type(%func%) = "Func"
                %func%()
        }
        return modeObj
    }

    /* ExistMode【返回mode名称】
        函数: ExistMode
        作用: 返回mode名称
        参数:
        返回: mode名称
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    ExistMode() {
        return this.mode
    }

    /* SetInfo【设置信息】
        函数: SetInfo
        作用: 设置信息
        参数: bold
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetInfo(bold) {
        this.info := bold
    }

    /* SetShowInfo【设置显示信息】
        函数: SetShowInfo
        作用: 设置显示信息
        参数: func
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetShowInfo(func) {
        this.ShowInfoFunc := func
    }

    /* SetHideInfo【设置隐藏信息 】
        函数: SetHideInfo
        作用: 设置隐藏信息
        参数: func
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetHideInfo(func) {
        this.HideInfoFunc := func
    }

    /* ShowMore【显示更多】
        函数: ShowMore
        作用: 显示更多
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    ShowMore() {
        f := this.ShowInfoFunc
        if Type(%f%) = "Func" And this.Info
            %f%()
    }

    /* HideMore【隐藏更多】
        函数: HideMore
        作用: 隐藏更多
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    HideMore() {
        f := this.HideInfoFunc
        if Type(%f%) = "Func" And this.Info
            %f%()
    }
}

/* __Mode【mode对象】
    类名: __Mode
    作用: mode对象
    参数: mode对象
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
class __Mode {
    /* __Mode【mode对象】
        类名: __Mode
        作用: mode对象
        参数: mode对象
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    __new(modeName) {
        this.name := modeName
        this.keyMapList := Map()
        this.keyMoreList := Map()
        this.noWaitList := Map()
        this.modeFunction := ""
    }

    /* SetKeyMap【设置热键映射】
        函数: SetKeyMap
        作用: 设置热键映射
        参数: key：热键
                action：动作
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetKeyMap(key, action) {
        this.keyMapList[key] := action
    }

    /* GetKeyMap【获取热键映射】
        函数: GetKeyMap
        作用: 获取热键映射
        参数: key：热键
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetKeyMap(key) {
        if this.keyMapList.Has(key)
            return this.keyMapList[key]
        else
            return ""
    }

    /* DelKeyMap【删除热键映射】
        函数: DelKeyMap
        作用: 删除热键映射
        参数: key：热键
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    DelKeyMap(key) {
        this.keyMapList[key] := ""
    }

    /* SetNoWait【设置无等待】
        函数: SetNoWait
        作用: 设置无等待
        参数: key：热键
                bold
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetNoWait(key, bold) {
        this.noWaitList[key] := bold
    }

    /* GetNoWait【获取无等待】
        函数: GetNoWait
        作用: 获取无等待
        参数: key：热键
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetNoWait(key) {
        if this.noWaitList.Has(key)
            return this.noWaitList[key]
        else
            return false
    }

    /* SetMoreKey【设置更多热键缓存】
        函数: SetMoreKey
        作用: 设置更多热键缓存
        参数: key：热键
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetMoreKey(key) {
        this.keyMoreList[key] := true
    }

    /* GetMoreKey【获取更多热键缓存】
        函数: GetMoreKey
        作用: 获取更多热键缓存
        参数: key：热键
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetMoreKey(key) {
        if this.keyMoreList.Has(key)
            return this.keyMoreList[key]
        else
            return false
    }
}

/* __Action【创建__Action对象】
    类名: __Action
    作用: 创建__Action对象
    参数: KeyName：热键
            Action：动作
            Param：参数
            Group：分组
            Comment：备注
    返回: __Action对象
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
class __Action {
    ; Action 有几种类型
    ; 1 代表执行Function的值对应的函数 (默认)
    ; 2 代表运行CmdLine对应的值
    ; 3 代表发送HotString对应的文本

    /* __Action【创建__Action对象】
        类名: __Action
        作用: 创建__Action对象
        参数: KeyName：热键
                Action：动作
                Param：参数
                Group：分组
                Comment：备注
        返回: __Action对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    __new(KeyName, Action, Param, Group, Comment, OriKey) {
        this.Name := KeyName
        this.Comment := Comment
        this.MaxTimes := 0
        this.Type := 1
        this.Function := Action
        this.CmdLine := ""
        this.HotString := ""
        this.Param := Param
        this.Group := Group
        this.OriKey := OriKey
    }

    /* SetFunction【设置函数】
        函数: SetFunction
        作用: 设置函数
        参数: Function
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetFunction(Function) {
        this.Function := Function
        this.Type := 1
    }

    /* SetCmdLine【设置CmdLine】
        函数: SetCmdLine
        作用: 设置CmdLine
        参数: CmdLine
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetCmdLine(CmdLine) {
        this.CmdLine := CmdLine
        this.Type := 2
    }

    /* SetHotString【设置HotString】
        函数: SetHotString
        作用: 设置HotString
        参数: HotString
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetHotString(HotString) {
        this.HotString := HotString
        this.Type := 3
    }

    /* SetMaxTimes【设置最大次数】
        函数: SetMaxTimes
        作用: 设置最大次数
        参数: Times
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetMaxTimes(Times) {
        this.MaxTimes := Times
    }

    /* Do【执行Action】
        函数: Do
        作用: 执行Action
        参数: Times：执行次数
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Do(Times := 0) {
        Times := !Times ? 1 : Times
        if this.MaxTimes And (Times > this.MaxTimes)
            Times := this.MaxTimes
        ; if INIObject.config.enable_debug
        ;     vim._Debug.add(Format("Name:{1}`nAction:{2}`n----------------------",this.name, this.Function))
        loop Times {
            switch this.Type {
                case 1:
                    f := this.Function
                    f := RegExReplace(f, "<\d>$", "")

                    ; 特殊处理 SingleDoubleFullHandlers 函数
                    if (f = "SingleDoubleFullHandlers") {
                        ; 调用存储的处理函数
                        global singleDoubleHandlers
                        if (IsSet(singleDoubleHandlers) && singleDoubleHandlers.Has(this.Name)) {
                            handler := singleDoubleHandlers[this.Name]
                            ; 使用按键名称而不是A_ThisHotkey，因为在vim系统中A_ThisHotkey可能不正确
                            handler(this.OriKey ? this.OriKey : this.Name)
                        }
                    } else if (Type(%f%) = "Func") {
                        if (this.Param = "") {
                            %f%()
                        } else {
                            %f%(this.Param)
                        }
                    }
                case 2:
                    Run(cmd := this.CmdLine)
                case 3:
                    Send(str := this.HotString)
            }
        }
    }
}

/* __Plugin【创建__Plugin对象】
    类名: __Plugin
    作用: 创建__Plugin对象
    参数: PluginName：插件名称
    返回: __Plugin对象
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
class __Plugin {
    /* __Plugin【创建__Plugin对象】
        类名: __Plugin
        作用: 创建__Plugin对象
        参数: PluginName：插件名称
        返回: __Plugin对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    __new(PluginName) {
        this.PluginName := PluginName
        this.Author := ""
        this.Ver := ""
        this.Comment := ""
    }

    /* CheckFunc【检查函数并执行】
        函数: CheckFunc
        作用: 检查函数并执行
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    CheckFunc() {
        p := this.PluginName
        if (Type(%p%) = "Func") {
            %p%()
            this.Error := false
        } else
            this.Error := true
    }
}

/* __vimDebug【vimDebug】
    类名: __vimDebug
    作用: vimDebug
    参数:
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
class __vimDebug {
    /* __vimDebug【vimDebug】
        类名: __vimDebug
        作用: vimDebug
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    __new(key) {
        this.mode := key
        if key {
            global vimDebug := Gui()
            try
                vimDebug.Destroy
            ; global vimDebug := Gui("+AlwaysOnTop -Caption +ToolWindow +Border", "_vimDebug") ;+Resize +MaximizeBox -Caption +E0x00000080 不显示任务栏
            global vimDebug := Gui("+AlwaysOnTop", "_vimDebug") ;+Resize +MaximizeBox -Caption +E0x00000080 不显示任务栏
            vimDebug.SetFont("c000000 s10", "Verdana")
            ; vimDebug.BackColor := 0x454545
            vimDebug.OnEvent("Escape", (*) => vimDebug.Destroy())
            vimDebug.OnEvent("Close", (*) => vimDebug.Destroy())
            vimDebug.Add("Edit", "x-2 y-2 w400 h60 readonly vEdit1")
            vimDebug.Show("w378 h56 y600")
        }
        else {
            global vimDebug := Gui()
            try
                vimDebug.Destroy
            ; global vimDebug := Gui("+AlwaysOnTop -Caption +ToolWindow +Border", "_vimDebug") ;+Resize +MaximizeBox -Caption +E0x00000080 不显示任务栏
            global vimDebug := Gui("+AlwaysOnTop", "_vimDebug") ;+Resize +MaximizeBox -Caption +E0x00000080 不显示任务栏
            vimDebug.SetFont("c000000 s10", "Verdana")
            ; vimDebug.BackColor := 0x454545
            vimDebug.OnEvent("Escape", (*) => vimDebug.Destroy())
            vimDebug.OnEvent("Close", (*) => vimDebug.Destroy())
            vimDebug.Add("Edit", "x10 y10 w400 h300 readonly vEdit1")
            vimDebug.Add("Edit", "x10 y320 w400 h26 readonly vEdit2")
            vimDebug.Show("w420 h356")
        }
    }

    /* var【设置值】
        函数: var
        作用: 设置值
        参数: obj
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    var(obj) {
        this.vim := obj
    }

    /* Set【设置值】
        函数: Set
        作用: 设置值
        参数: v
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Set(v) {
        winName := this.vim.CheckWin()
        winObj := this.vim.GetWin(winName)
        if winObj.Count
            k := " 热键缓存:" winObj.Count winObj.KeyTemp
        else
            k := " 热键缓存:" winObj.KeyTemp
        vimDebug["Edit1"].Value := v
        vimDebug["Edit2"].Value := k
    }

    /* Get【获取值】
        函数: Get
        作用: 获取值
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Get() {
        return vimDebug["Edit1"].Value
    }

    /* Add【添加值】
        函数: Add
        作用: 添加值
        参数: v
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Add(v) {
        b := this.Get()
        if this.mode
            this.Set(b)
        else
            this.Set(v "`n" b)
    }

    /* Clear【清除值】
        函数: Clear
        作用: 清除值
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Clear() {
        this.Set("")
    }
}
/*
    函数: HasValue
    作用: 检查数组中是否包含指定值
    参数:
        - haystack: 要搜索的数组
        - needle: 要查找的值
    返回: 如果找到则返回true，否则返回false
    作者: BoBO
    版本: 1.0
    AHK版本: 2.0
*/
HasValue(haystack, needle) {
    if !IsObject(haystack)
        return false

    for index, value in haystack {
        if (value = needle)
            return true
    }
    return false
}
