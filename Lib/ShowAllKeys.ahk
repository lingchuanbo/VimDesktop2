#Requires AutoHotkey v2.0

/*
函数: ShowAllKeys
作用: 显示指定插件中定义的所有按键绑定
参数: pluginName - 插件名称
返回: 无
作者: BoBO
版本: 9.0_2025.07.18
*/
ShowAllKeys(pluginName) {
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
                groupedKeys[group].Push({key: key, comment: comment})
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
函数: ShowAllKeysWithMsgBox
作用: 使用MsgBox显示按键列表（备用方案）
参数: pluginName - 插件名称
返回: 无
*/
ShowAllKeysWithMsgBox(pluginName) {
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
                groupedKeys[group].Push({key: key, comment: comment})
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