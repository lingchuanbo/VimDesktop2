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
    static ieControlGui := 0

    ; 如果已经有一个活动的GUI，先彻底清理它
    if (keyHelpGui != 0) {
        ; 先清理IE控件
        if (ieControl) {
            try {
                ieControl.Document.Write("")
                ieControl.Document.Close()
                ieControl.Navigate("about:blank")
                ; 等待清理完成
                loop 5 {
                    if (ieControl.ReadyState = 4)
                        break
                    Sleep(30)
                }
                ieControl := 0
            } catch {
                ; 忽略清理错误
            }
        }

        if (ieControlGui) {
            ieControlGui := 0
        }

        try {
            keyHelpGui.Destroy()
        }
        keyHelpGui := 0

        ; 强制内存清理
        try {
            DllCall("kernel32.dll\SetProcessWorkingSetSize", "ptr", -1, "uptr", -1, "uptr", -1)
        }

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

        ; 写入HTML内容
        ieControl.Document.Write(htmlOutput)
        ieControl.Document.Close()

        ; 清空HTML变量释放内存
        htmlOutput := ""
        markdownContent := ""

    } catch as e {
        MsgBox("HTML加载失败: " e.Message, "错误", "Icon!")
        return
    }

    ; 移除按钮，只保留ESC键关闭功能

    ; GUI事件
    keyHelpGui.OnEvent("Close", (*) => CloseGUI())
    keyHelpGui.OnEvent("Size", OnResize)

    ; 获取屏幕尺寸并居中显示 - 1520x700画布
    MonitorGetWorkArea(1, &left, &top, &right, &bottom)
    screenWidth := right - left
    screenHeight := bottom - top

    ; 1520x700画布布局
    guiWidth := Min(600, screenWidth * 0.9)
    guiHeight := Min(300, screenHeight * 0.8)
    xPos := (screenWidth - guiWidth) / 2
    yPos := (screenHeight - guiHeight) / 2

    ; 显示GUI
    keyHelpGui.Show("x" xPos " y" yPos " w" guiWidth " h" guiHeight)

    ; 窗口大小调整事件
    OnResize(thisGui, minMax, width, height) {
        if (minMax = -1)  ; 窗口最小化
            return

        ; 调整IE控件大小，占满整个窗口
        ieControlGui.Move(0, 0, width, height)
    }

    ; 清理GUI的函数 - 优化内存管理
    CloseGUI() {
        ; 清理IE控件内容和事件
        if (ieControl) {
            try {
                ; 清空文档内容
                ieControl.Document.Write("")
                ieControl.Document.Close()

                ; 导航到空白页释放资源
                ieControl.Navigate("about:blank")

                ; 等待导航完成
                loop 10 {
                    if (ieControl.ReadyState = 4)
                        break
                    Sleep(50)
                }

                ; 清空引用
                ieControl := 0
            } catch {
                ; 忽略清理过程中的错误
            }
        }

        ; 清理GUI控件引用
        if (ieControlGui) {
            try {
                ieControlGui := 0
            } catch {
                ; 忽略清理过程中的错误
            }
        }

        ; 销毁GUI窗口
        if (keyHelpGui) {
            try {
                keyHelpGui.Destroy()
            } catch {
                ; 忽略清理过程中的错误
            }
            keyHelpGui := 0
        }

        ; 延迟强制垃圾回收，确保IE控件完全释放
        DelayedCleanup() {
            try {
                ; 调用Windows API强制内存清理
                DllCall("kernel32.dll\SetProcessWorkingSetSize", "ptr", -1, "uptr", -1, "uptr", -1)
                ; 额外的内存清理
                DllCall("kernel32.dll\EmptyWorkingSet", "ptr", -1)
            } catch {
                ; 忽略API调用错误
            }
        }
        SetTimer(DelayedCleanup, -500)  ; 500ms后执行一次
    }
}

/*
函数: GetMarkdownCSS
作用: 获取Markdown显示的CSS样式
返回: CSS样式字符串
*/
GetMarkdownCSS() {
    global INIObject
    css := ""

    ; 根据主题模式获取颜色配置
    try {
        themeMode := INIObject.config.theme_mode
    } catch {
        themeMode := "light"  ; 默认明亮主题
    }

    ; 根据主题设置颜色变量
    if (themeMode = "dark") {
        ; 暗黑主题颜色
        bgColor := "#1a1a1a"
        cardBgColor := "#2d2d2d"
        textColor := "#e0e0e0"
        titleColor := "#ffffff"
        borderColor := "#404040"
        hoverColor := "#3a3a3a"
    } else if (themeMode = "system") {
        ; 跟随系统主题
        try {
            isDarkMode := RegRead("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize",
                "AppsUseLightTheme")
            if (isDarkMode = 0) {
                ; 系统是暗黑模式
                bgColor := "#1a1a1a"
                cardBgColor := "#2d2d2d"
                textColor := "#e0e0e0"
                titleColor := "#ffffff"
                borderColor := "#404040"
                hoverColor := "#3a3a3a"
            } else {
                ; 系统是明亮模式
                bgColor := "#f8f9fa"
                cardBgColor := "#ffffff"
                textColor := "#2c3e50"
                titleColor := "#2c3e50"
                borderColor := "#ecf0f1"
                hoverColor := "#e8f4fd"
            }
        } catch {
            ; 无法读取系统设置，默认明亮主题
            bgColor := "#f8f9fa"
            cardBgColor := "#ffffff"
            textColor := "#2c3e50"
            titleColor := "#2c3e50"
            borderColor := "#ecf0f1"
            hoverColor := "#e8f4fd"
        }
    } else {
        ; 明亮主题颜色（默认）
        bgColor := "#f8f9fa"
        cardBgColor := "#ffffff"
        textColor := "#2c3e50"
        titleColor := "#2c3e50"
        borderColor := "#ecf0f1"
        hoverColor := "#e8f4fd"
    }

    ; 基础样式 - 1520x700适配，统一字体大小12
    css .= "body {"
    css .= "font-family: 'Microsoft YaHei UI', 'Segoe UI', sans-serif;"
    css .= "font-size: 12px;"
    css .= "line-height: 1.4;"
    css .= "color: " textColor ";"
    css .= "max-width: 100%;"
    css .= "margin: 0;"
    css .= "padding: 15px;"
    css .= "background: " bgColor ";"
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
    css .= "background: " cardBgColor ";"
    css .= "border-radius: 8px;"
    css .= "box-shadow: 0 2px 8px rgba(0,0,0,0.08);"
    css .= "padding: 15px;"
    css .= "margin-right: 20px;"
    css .= "margin-bottom: 20px;"
    css .= "}"

    ; 主标题样式 - 紧凑设计
    css .= "h1 {"
    css .= "color: " titleColor ";"
    css .= "font-size: 20px;"
    css .= "font-weight: 500;"
    css .= "text-align: center;"
    css .= "margin: 0 0 20px 0;"
    css .= "padding: 15px;"
    css .= "background: " cardBgColor ";"
    css .= "border-radius: 8px;"
    css .= "box-shadow: 0 2px 8px rgba(0,0,0,0.08);"
    css .= "border-left: 4px solid #3498db;"
    css .= "}"

    ; 分组标题样式 - 紧凑版
    css .= "h2 {"
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
    css .= "background: " cardBgColor ";"
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
    css .= "border-bottom: 1px solid " borderColor ";"
    css .= "vertical-align: middle;"
    css .= "font-size: 12px;"
    css .= "line-height: 1.3;"
    css .= "color: " textColor ";"
    css .= "}"

    ; 第一列（按键列）居中对齐
    css .= "td:first-child {"
    css .= "text-align: center;"
    css .= "font-weight: 600;"
    css .= "width: 80px;"
    css .= "}"

    ; 表格行样式
    css .= "tr:nth-child(even) {"
    css .= "background-color: " (themeMode = "dark" ? "#333333" : "#f8f9fa") ";"
    css .= "}"

    css .= "tr:hover {"
    css .= "background-color: " hoverColor ";"
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

    ; 滚动条美化 - 根据主题动态调整颜色
    css .= "::-webkit-scrollbar {"
    css .= "width: 8px;"
    css .= "}"

    ; 根据主题直接设置滚动条颜色
    if (themeMode = "dark") {
        css .= "::-webkit-scrollbar-track {"
        css .= "background: #2a2a2a;"
        css .= "border-radius: 4px;"
        css .= "}"

        css .= "::-webkit-scrollbar-thumb {"
        css .= "background: #555555;"
        css .= "border-radius: 4px;"
        css .= "transition: background 0.2s ease;"
        css .= "}"

        css .= "::-webkit-scrollbar-thumb:hover {"
        css .= "background: #777777;"
        css .= "}"

        css .= "::-webkit-scrollbar-corner {"
        css .= "background: #2a2a2a;"
        css .= "}"
    } else {
        css .= "::-webkit-scrollbar-track {"
        css .= "background: #f0f0f0;"
        css .= "border-radius: 4px;"
        css .= "}"

        css .= "::-webkit-scrollbar-thumb {"
        css .= "background: #c0c0c0;"
        css .= "border-radius: 4px;"
        css .= "transition: background 0.2s ease;"
        css .= "}"

        css .= "::-webkit-scrollbar-thumb:hover {"
        css .= "background: #a0a0a0;"
        css .= "}"

        css .= "::-webkit-scrollbar-corner {"
        css .= "background: #f0f0f0;"
        css .= "}"
    }

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
