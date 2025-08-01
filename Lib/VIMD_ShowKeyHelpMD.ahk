#Requires AutoHotkey v2.0

/*
函数: VIMD_ShowKeyHelpMD
作用: 使用Markdown解析器显示指定插件中定义的所有按键绑定，提供美观的界面
参数: pluginName - 插件名称，如果为空则使用当前窗口
返回: 无
作者: BoBO
版本: 1.0
AHK版本: 2.0
*/
VIMD_ShowKeyHelpMD(param := "") {
    global vim

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

    ; 显示Markdown GUI
    ShowMarkdownGUI(markdownContent, win " - " (mode ? mode : modeObj.name) " 按键列表")
}

/*
函数: BuildMarkdownContent
作用: 构建按键帮助的Markdown内容
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

    ; 构建一组一列的HTML内容 - 每列400px宽度
    markdown := "<h1>" win " - " (mode ? mode : modeObj.name) "</h1>`n"
    markdown .= "<div class='container'>`n"

    ; 调试：显示分组数量
    ; MsgBox("分组数量: " groupedKeys.Count)

    ; 按分组显示按键 - 每组一列
    for group, keys in groupedKeys {
        ; 开始一个新列
        markdown .= "<div class='column'>`n"

        ; 添加分组标题
        markdown .= "<h2>" group "</h2>`n"

        ; 创建表格
        markdown .= "<table>`n"
        markdown .= "<thead>`n<tr><th>按键</th><th>功能描述</th></tr>`n</thead>`n"
        markdown .= "<tbody>`n"

        ; 添加该分组下的所有按键
        for _, keyInfo in keys {
            ; 简化转义，只处理HTML特殊字符
            key := StrReplace(StrReplace(StrReplace(keyInfo.key, "&", "&amp;"), "<", "&lt;"), ">", "&gt;")
            comment := StrReplace(StrReplace(StrReplace(keyInfo.comment, "&", "&amp;"), "<", "&lt;"), ">", "&gt;")

            markdown .= "<tr><td><code>" key "</code></td><td>" comment "</td></tr>`n"
        }

        markdown .= "</tbody>`n</table>`n"
        markdown .= "</div>`n"  ; 结束列
    }

    markdown .= "</div>`n"  ; 结束容器

    return markdown
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
函数: EscapeMarkdown
作用: 转义Markdown特殊字符
参数: text - 要转义的文本
返回: 转义后的文本
*/
EscapeMarkdown(text) {
    ; 转义Markdown中的特殊字符
    text := StrReplace(text, "|", "\|")
    text := StrReplace(text, "*", "\*")
    text := StrReplace(text, "_", "\_")
    text := StrReplace(text, "#", "\#")
    text := StrReplace(text, "[", "\[")
    text := StrReplace(text, "]", "\]")
    text := StrReplace(text, "(", "\(")
    text := StrReplace(text, ")", "\)")
    return text
}

/*
函数: ShowMarkdownGUI
作用: 显示Markdown内容的GUI界面
参数: markdownContent - Markdown内容, title - 窗口标题
返回: 无
*/
ShowMarkdownGUI(markdownContent, title) {
    static keyHelpGui := 0
    static ieControl := 0

    ; 如果已经有一个活动的GUI，先关闭它
    if (keyHelpGui != 0) {
        try {
            keyHelpGui.Destroy()
        }
        keyHelpGui := 0
        ieControl := 0
        return
    }

    ; 创建GUI窗口 - 1520x700画布
    keyHelpGui := Gui("+Resize +MinSize1000x600", title)
    keyHelpGui.SetFont("s10", "Microsoft YaHei UI")

    ; 添加ESC键关闭功能
    keyHelpGui.OnEvent("Escape", (*) => CloseGUI())

    ; 添加ActiveX控件（Internet Explorer）- 1520x700布局
    try {
        ieControlGui := keyHelpGui.Add("ActiveX", "w1520 h700 vIE", "{8856F961-340A-11D0-A96B-00C04FD705A2}")
        ieControl := ieControlGui.Value
    } catch {
        MsgBox("ActiveX控件初始化失败。`n请确保您的系统已安装Internet Explorer组件。", "错误", "Icon!")
        return
    }

    ; 设置CSS样式
    cssStyle := GetMarkdownCSS()

    ; 配置MD解析器选项 - 统一字体大小为12
    options := {
        css: cssStyle,
        font_name: "Microsoft YaHei UI",
        font_size: 12,
        font_weight: 400,
        line_height: "1.4"
    }

    ; 直接使用HTML内容，不需要MD解析器
    try {
        ; 先验证HTML内容
        if (!markdownContent || StrLen(markdownContent) = 0) {
            MsgBox("HTML内容为空", "错误", "Icon!")
            return
        }

        ; 构建完整的HTML文档
        htmlOutput := "<!DOCTYPE html><html><head><meta charset='UTF-8'><style>" cssStyle "</style></head><body>" markdownContent "</body></html>"

        ; 验证HTML输出
        if (!htmlOutput || StrLen(htmlOutput) = 0) {
            MsgBox("HTML生成失败", "错误", "Icon!")
            return
        }

    } catch as e {
        ; 显示详细错误信息
        debugContent := StrLen(markdownContent) > 100 ? SubStr(markdownContent, 1, 100) "..." : markdownContent
        MsgBox("HTML生成失败:`n错误: " e.Message "`n`n内容预览:`n" debugContent, "错误", "Icon!")
        return
    }

    ; 将HTML加载到IE控件中
    try {
        ieControl.Navigate("about:blank")
        ; 等待页面加载完成
        while ieControl.ReadyState != 4 || ieControl.Document.readyState != "complete" || ieControl.Busy
            Sleep(50)
        ieControl.Document.Write(htmlOutput)
    } catch as e {
        MsgBox("HTML加载失败: " e.Message, "错误", "Icon!")
        return
    }

    ; 添加按钮
    buttonPanel := keyHelpGui.Add("Text", "w800 h40 Background0xF0F0F0")
    closeBtn := keyHelpGui.Add("Button", "x720 y610 w70 h25", "关闭")
    exportBtn := keyHelpGui.Add("Button", "x640 y610 w70 h25", "导出")

    ; 按钮事件
    closeBtn.OnEvent("Click", (*) => CloseGUI())
    exportBtn.OnEvent("Click", (*) => ExportMarkdown(markdownContent, title))

    ; GUI事件
    keyHelpGui.OnEvent("Close", (*) => CloseGUI())
    keyHelpGui.OnEvent("Size", OnResize)

    ; 获取屏幕尺寸并居中显示 - 1520x700画布
    MonitorGetWorkArea(1, &left, &top, &right, &bottom)
    screenWidth := right - left
    screenHeight := bottom - top

    ; 1520x700画布布局
    guiWidth := Min(1520, screenWidth * 0.9)
    guiHeight := Min(700, screenHeight * 0.8)
    xPos := (screenWidth - guiWidth) / 2
    yPos := (screenHeight - guiHeight) / 2

    ; 显示GUI
    keyHelpGui.Show("x" xPos " y" yPos " w" guiWidth " h" guiHeight)

    ; 窗口大小调整事件
    OnResize(thisGui, minMax, width, height) {
        if (minMax = -1)  ; 窗口最小化
            return

        ; 调整IE控件大小
        ieControlGui.Move(0, 0, width, height - 45)

        ; 调整按钮位置
        buttonPanel.Move(0, height - 40, width, 40)
        closeBtn.Move(width - 80, height - 35, 70, 25)
        exportBtn.Move(width - 160, height - 35, 70, 25)
    }

    ; 清理GUI的函数
    CloseGUI() {
        keyHelpGui.Destroy()
        keyHelpGui := 0
        ieControl := 0
    }
}

/*
函数: GetMarkdownCSS
作用: 获取Markdown显示的CSS样式
返回: CSS样式字符串
*/
GetMarkdownCSS() {
    css := ""

    ; 基础样式 - 1520x700适配，统一字体大小12
    css .= "body {"
    css .= "font-family: 'Microsoft YaHei UI', 'Segoe UI', sans-serif;"
    css .= "font-size: 12px;"
    css .= "line-height: 1.4;"
    css .= "color: #2c3e50;"
    css .= "max-width: 100%;"
    css .= "margin: 0;"
    css .= "padding: 15px;"
    css .= "background: #f8f9fa;"
    css .= "min-height: 100vh;"
    css .= "}"

    ; 容器样式 - 简单的清除浮动
    css .= ".container {"
    css .= "width: 100%;"
    css .= "overflow: hidden;"
    css .= "padding: 10px;"
    css .= "}"

    ; 列样式 - 使用float实现多列
    css .= ".column {"
    css .= "float: left;"
    css .= "width: 400px;"
    css .= "background: #ffffff;"
    css .= "border-radius: 8px;"
    css .= "box-shadow: 0 2px 8px rgba(0,0,0,0.08);"
    css .= "padding: 15px;"
    css .= "margin-right: 20px;"
    css .= "margin-bottom: 20px;"
    css .= "}"

    ; 主标题样式 - 紧凑设计
    css .= "h1 {"
    css .= "color: #2c3e50;"
    css .= "font-size: 20px;"
    css .= "font-weight: 500;"
    css .= "text-align: center;"
    css .= "margin: 0 0 20px 0;"
    css .= "padding: 15px;"
    css .= "background: #ffffff;"
    css .= "border-radius: 8px;"
    css .= "box-shadow: 0 2px 8px rgba(0,0,0,0.08);"
    css .= "border-left: 4px solid #3498db;"
    css .= "}"

    ; 分组标题样式 - 紧凑版
    css .= "h2 {"
    css .= "color: #34495e;"
    css .= "font-size: 16px;"
    css .= "font-weight: 600;"
    css .= "margin: 0 0 10px 0;"
    css .= "padding: 8px 12px;"
    css .= "background: #e74c3c;"
    css .= "color: #ffffff;"
    css .= "border-radius: 6px;"
    css .= "text-align: center;"
    css .= "}"

    ; 表格样式 - 紧凑设计
    css .= "table {"
    css .= "width: 100%;"
    css .= "border-collapse: collapse;"
    css .= "margin: 8px 0 15px 0;"
    css .= "background: #ffffff;"
    css .= "border-radius: 6px;"
    css .= "overflow: hidden;"
    css .= "box-shadow: 0 1px 6px rgba(0,0,0,0.08);"
    css .= "break-inside: avoid;"
    css .= "page-break-inside: avoid;"
    css .= "font-size: 12px;"
    css .= "}"

    ; 表头样式 - 紧凑专业
    css .= "th {"
    css .= "background: #34495e;"
    css .= "color: #ffffff;"
    css .= "font-weight: 500;"
    css .= "padding: 10px 12px;"
    css .= "text-align: center;"
    css .= "font-size: 12px;"
    css .= "border: none;"
    css .= "}"

    ; 表格单元格样式 - 紧凑
    css .= "td {"
    css .= "padding: 8px 12px;"
    css .= "border-bottom: 1px solid #ecf0f1;"
    css .= "vertical-align: middle;"
    css .= "font-size: 12px;"
    css .= "line-height: 1.3;"
    css .= "}"

    ; 第一列（按键列）居中对齐
    css .= "td:first-child {"
    css .= "text-align: center;"
    css .= "font-weight: 600;"
    css .= "width: 80px;"
    css .= "}"

    ; 表格行样式
    css .= "tr:nth-child(even) {"
    css .= "background-color: #f8f9fa;"
    css .= "}"

    css .= "tr:hover {"
    css .= "background-color: #e8f4fd;"
    css .= "}"

    ; 按键代码样式 - 12px字体
    css .= "code {"
    css .= "background: #3498db;"
    css .= "color: #ffffff;"
    css .= "padding: 4px 10px;"
    css .= "border-radius: 12px;"
    css .= "font-family: 'Consolas', 'Monaco', monospace;"
    css .= "font-size: 12px;"
    css .= "font-weight: 600;"
    css .= "display: inline-block;"
    css .= "min-width: 50px;"
    css .= "text-align: center;"
    css .= "}"

    ; 滚动条美化 - 细版
    css .= "::-webkit-scrollbar {"
    css .= "width: 6px;"
    css .= "}"

    css .= "::-webkit-scrollbar-track {"
    css .= "background: #ecf0f1;"
    css .= "border-radius: 3px;"
    css .= "}"

    css .= "::-webkit-scrollbar-thumb {"
    css .= "background: #bdc3c7;"
    css .= "border-radius: 3px;"
    css .= "}"

    css .= "::-webkit-scrollbar-thumb:hover {"
    css .= "background: #95a5a6;"
    css .= "}"

    ; 防止分组在列中间断开
    css .= "h2, table {"
    css .= "-webkit-column-break-inside: avoid;"
    css .= "column-break-inside: avoid;"
    css .= "break-inside: avoid;"
    css .= "}"

    ; 确保分组标题和表格在一起
    css .= "h2 + table {"
    css .= "margin-top: 5px;"
    css .= "}"

    return css
}

/*
函数: ExportMarkdown
作用: 导出Markdown内容到文件
参数: content - Markdown内容, title - 文件标题
返回: 无
*/
ExportMarkdown(content, title) {
    ; 生成文件名
    safeTitle := RegExReplace(title, '[<>:"/\\|?*]', "_")
    fileName := safeTitle "_" FormatTime(, "yyyyMMdd_HHmmss") ".md"

    ; 选择保存位置
    filePath := FileSelect("S", A_Desktop "\" fileName, "保存Markdown文件", "Markdown文件 (*.md)")

    if (filePath) {
        try {
            FileAppend(content, filePath, "UTF-8")
            MsgBox("文件已成功保存到:`n" filePath, "导出成功", "Icon!")
        } catch as e {
            MsgBox("保存文件失败: " e.Message, "错误", "Icon!")
        }
    }
}
