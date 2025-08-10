#Requires AutoHotkey v2.0
;@Ahk2Exe-SetVersion 1.0
;@Ahk2Exe-SetName QuickSwitchMu
;@Ahk2Exe-SetDescription Use opened file manager folders in File dialogs.
;@Ahk2Exe-SetCopyright NotNull

/*
QuickSwitchV2_BoBO
By: BoBO
V1版本地址:
*/

; ============================================================================
; 初始化
; ============================================================================

#Warn
SendMode("Input")
SetWorkingDir(A_ScriptDir)
#SingleInstance Force

; 全局变量
global g_Config := {}
global g_CurrentDialog := {
    WinID: "",
    Type: "",
    FingerPrint: "",
    Action: ""
}
global g_MenuItems := []  ; Array to store menu items for quick access
global g_MenuActive := false  ; Flag to track if menu is active

; Initialize configuration
InitializeConfig()

; Register hotkey from configuration
RegisterHotkey()

; Start main loop
MainLoop()

; ============================================================================
; 配置管理
; ============================================================================

InitializeConfig() {
    ; 获取脚本名称用于配置文件
    SplitPath(A_ScriptFullPath, , , , &name_no_ext)
    g_Config.IniFile := name_no_ext . ".ini"
    g_Config.TempFile := EnvGet("TEMP") . "\dopusinfo.xml"

    ; 如果配置文件不存在，创建默认配置文件
    if (!FileExist(g_Config.IniFile)) {
        CreateDefaultIniFile()
    }

    ; 从INI文件加载配置
    LoadConfiguration()

    ; 清理临时文件
    try FileDelete(g_Config.TempFile)
}

CreateDefaultIniFile() {
    ; 创建默认的INI配置文件
    ; 使用字符串连接的方式创建配置内容
    try {
        ; 写入各个配置段
        IniWrite("^q", g_Config.IniFile, "Settings", "Hotkey")
        
        IniWrite("C0C59C", g_Config.IniFile, "Display", "MenuColor")
        IniWrite("16", g_Config.IniFile, "Display", "IconSize")
        IniWrite("100", g_Config.IniFile, "Display", "MenuPosX")
        IniWrite("100", g_Config.IniFile, "Display", "MenuPosY")
        
        IniWrite("1", g_Config.IniFile, "QuickAccess", "EnableQuickAccess")
        IniWrite("123456789abcdefghijklmnopqrstuvwxyz", g_Config.IniFile, "QuickAccess", "QuickAccessKeys")
        
        IniWrite("1", g_Config.IniFile, "FileManagers", "TotalCommander")
        IniWrite("1", g_Config.IniFile, "FileManagers", "Explorer")
        IniWrite("1", g_Config.IniFile, "FileManagers", "XYplorer")
        IniWrite("1", g_Config.IniFile, "FileManagers", "DirectoryOpus")
        
        IniWrite("1", g_Config.IniFile, "CustomPaths", "EnableCustomPaths")
        IniWrite("收藏路径", g_Config.IniFile, "CustomPaths", "MenuTitle")
        IniWrite("桌面|%USERPROFILE%\Desktop", g_Config.IniFile, "CustomPaths", "Path1")
        IniWrite("文档|%USERPROFILE%\Documents", g_Config.IniFile, "CustomPaths", "Path2")
        IniWrite("下载|%USERPROFILE%\Downloads", g_Config.IniFile, "CustomPaths", "Path3")
        IniWrite("图片|%USERPROFILE%\Pictures", g_Config.IniFile, "CustomPaths", "Path4")
        IniWrite("项目文件夹|D:\Projects", g_Config.IniFile, "CustomPaths", "Path5")
        IniWrite("C:\Windows\System32", g_Config.IniFile, "CustomPaths", "Path6")
        
        IniWrite("1", g_Config.IniFile, "RecentPaths", "EnableRecentPaths")
        IniWrite("最近打开", g_Config.IniFile, "RecentPaths", "MenuTitle")
        IniWrite("10", g_Config.IniFile, "RecentPaths", "MaxRecentPaths")
        
        IniWrite("1", g_Config.IniFile, "Dialogs", "blender.exe___Blender File View")
        
        ; 添加配置文件注释（通过在文件开头添加注释）
        configComment := "; QuickSwitchMu 配置文件`n"
        . "; 此文件包含 QuickSwitchMu 的所有设置选项`n"
        . "; 主快捷键设置支持 AutoHotkey 的所有快捷键格式`n"
        . "; 例如: ^q (Ctrl+Q), ^j (Ctrl+J), !q (Alt+Q), #q (Win+Q)`n"
        . "; 文件管理器支持设置: 1=启用, 0=禁用`n"
        . "; 自定义路径格式: 显示名|实际路径 或 直接路径`n"
        . "; 支持环境变量如 %USERNAME%, %USERPROFILE% 等`n`n"
        
        ; 读取现有内容并在前面添加注释
        existingContent := FileRead(g_Config.IniFile, "UTF-16")
        FileDelete(g_Config.IniFile)
        FileAppend(configComment . existingContent, g_Config.IniFile, "UTF-16")
        
    } catch as e {
        MsgBox("创建配置文件失败: " . e.message, "错误", "T5")
    }
}

LoadConfiguration() {
    ; 加载快捷键配置
    g_Config.Hotkey := IniRead(g_Config.IniFile, "Settings", "Hotkey", "^q")

    ; 加载显示设置
    g_Config.MenuColor := IniRead(g_Config.IniFile, "Display", "MenuColor", "C0C59C")
    g_Config.IconSize := IniRead(g_Config.IniFile, "Display", "IconSize", "16")
    g_Config.MenuPosX := IniRead(g_Config.IniFile, "Display", "MenuPosX", "100")
    g_Config.MenuPosY := IniRead(g_Config.IniFile, "Display", "MenuPosY", "100")

    ; 加载快速访问设置
    g_Config.EnableQuickAccess := IniRead(g_Config.IniFile, "QuickAccess", "EnableQuickAccess", "1")
    g_Config.QuickAccessKeys := IniRead(g_Config.IniFile, "QuickAccess", "QuickAccessKeys",
        "123456789abcdefghijklmnopqrstuvwxyz")

    ; 加载文件管理器设置
    g_Config.SupportTC := IniRead(g_Config.IniFile, "FileManagers", "TotalCommander", "1")
    g_Config.SupportExplorer := IniRead(g_Config.IniFile, "FileManagers", "Explorer", "1")
    g_Config.SupportXY := IniRead(g_Config.IniFile, "FileManagers", "XYplorer", "1")
    g_Config.SupportOpus := IniRead(g_Config.IniFile, "FileManagers", "DirectoryOpus", "1")

    ; 加载自定义路径设置
    g_Config.EnableCustomPaths := IniRead(g_Config.IniFile, "CustomPaths", "EnableCustomPaths", "1")
    g_Config.CustomPathsTitle := IniRead(g_Config.IniFile, "CustomPaths", "MenuTitle", "收藏路径")

    ; 加载最近路径设置
    g_Config.EnableRecentPaths := IniRead(g_Config.IniFile, "RecentPaths", "EnableRecentPaths", "1")
    g_Config.RecentPathsTitle := IniRead(g_Config.IniFile, "RecentPaths", "MenuTitle", "最近打开")
    g_Config.MaxRecentPaths := IniRead(g_Config.IniFile, "RecentPaths", "MaxRecentPaths", "10")

    ; Total Commander 消息代码
    g_Config.TC_CopySrcPath := 2029
    g_Config.TC_CopyTrgPath := 2030
}

RegisterHotkey() {
    ; 不再注册全局热键，改为在文件对话框中动态注册
    ; 全局热键会在 ProcessFileDialog() 中根据需要注册
}

ToggleMenu(*) {
    global g_MenuActive, g_CurrentDialog

    ; 检查当前激活窗口是否为文件对话框
    currentWinID := WinExist("A")
    if (currentWinID != g_CurrentDialog.WinID) {
        ; 如果当前窗口不是文件对话框，不显示菜单
        return
    }

    ; 简单直接显示菜单，不做复杂的切换逻辑
    ; 菜单会在用户点击外部区域或按ESC时自动关闭
    ShowMenu()
}

CleanupGlobals() {
    global g_Config, g_CurrentDialog, g_MenuItems, g_MenuActive
    
    ; 取消注册热键
    try {
        Hotkey(g_Config.Hotkey, "Off")
    } catch {
        ; 忽略错误
    }
    
    try {
        Hotkey("^q", "Off")
    } catch {
        ; 忽略错误
    }

    ; 重置全局变量
    g_CurrentDialog.WinID := ""
    g_CurrentDialog.Type := ""
    g_CurrentDialog.FingerPrint := ""
    g_CurrentDialog.Action := ""
    g_MenuItems := []
    g_MenuActive := false
}

; ============================================================================
; 主循环
; ============================================================================

MainLoop() {
    ; Check OS compatibility
    if !IsOSSupported() {
        MsgBox(A_OSVersion . " is not supported.")
        ExitApp()
    }

    ; Main event loop
    loop {
        ; 获取当前激活窗口
        g_CurrentDialog.WinID := WinExist("A")

        ; 检查窗口ID是否有效
        if (!g_CurrentDialog.WinID) {
            Sleep(100)
            continue
        }

        try {
            winClass := WinGetClass("ahk_id " . g_CurrentDialog.WinID)
            exeName := WinGetProcessName("ahk_id " . g_CurrentDialog.WinID)
            winTitle := WinGetTitle("ahk_id " . g_CurrentDialog.WinID)
        } catch {
            ; 如果获取窗口信息失败，继续下一次循环
            Sleep(100)
            continue
        }

        ; 检查是否为标准文件对话框或Blender文件视图窗口
        isStandardDialog := (winClass = "#32770")
        isBlenderFileView := (winClass = "GHOST_WindowClass" and exeName = "blender.exe" and InStr(winTitle,
            "Blender File View"))

        if (isStandardDialog || isBlenderFileView) {
            g_CurrentDialog.Type := DetectFileDialog(g_CurrentDialog.WinID)
            if g_CurrentDialog.Type {
                ProcessFileDialog()

                ; 等待对话框关闭
                WinWaitNotActive("ahk_id " . g_CurrentDialog.WinID)
                CleanupGlobals()
            }
        }

        Sleep(100)
    }
}

ProcessFileDialog() {
    ; Get dialog fingerprint
    ahk_exe := WinGetProcessName("ahk_id " . g_CurrentDialog.WinID)
    window_title := WinGetTitle("ahk_id " . g_CurrentDialog.WinID)
    g_CurrentDialog.FingerPrint := ahk_exe . "___" . window_title

    ; 为当前文件对话框注册热键
    try {
        Hotkey(g_Config.Hotkey, ToggleMenu, "On")
    } catch as e {
        ; 如果快捷键注册失败，使用默认快捷键
        try {
            Hotkey("^q", ToggleMenu, "On")
        }
    }

    ; Check dialog action from INI
    g_CurrentDialog.Action := IniRead(g_Config.IniFile, "Dialogs", g_CurrentDialog.FingerPrint, "")

    if (g_CurrentDialog.Action = "1") {
        ; AutoSwitch mode
        folderPath := GetActiveFileManagerFolder(g_CurrentDialog.WinID)

        if IsValidFolder(folderPath) {
            ; AutoSwitch成功：记录路径并切换到文件夹，不显示菜单
            RecordRecentPath(folderPath)
            FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
        } else {
            ; AutoSwitch失败：作为备选方案，显示菜单
            ShowMenu()
        }
    } else if (g_CurrentDialog.Action = "0") {
        ; Never here mode - do nothing
    } else {
        ; Show menu mode - 不自动显示菜单，等待用户按热键
    }
}

; ============================================================================
; 对话框检测和路径注入
; ============================================================================

DetectFileDialog(winID) {
    winClass := WinGetClass("ahk_id " . winID)

    ; 直接识别Blender窗口
    if (winClass = "GHOST_WindowClass") {
        return "GENERAL"
    }

    controlList := WinGetControls("ahk_id " . winID)

    hasSysListView := false
    hasToolbar := false
    hasDirectUI := false
    hasEdit := false

    for control in controlList {
        switch control {
            case "SysListView321":
                hasSysListView := true
            case "ToolbarWindow321":
                hasToolbar := true
            case "DirectUIHWND1":
                hasDirectUI := true
            case "Edit1":
                hasEdit := true
        }
    }

    if (hasDirectUI && hasToolbar && hasEdit) {
        return "GENERAL"
    } else if (hasSysListView && hasToolbar && hasEdit) {
        return "SYSLISTVIEW"
    }
    return false
}

FeedDialog(winID, folderPath, dialogType) {
    ; 检查是否为 Blender 窗口，使用特殊处理
    try {
        exeName := WinGetProcessName("ahk_id " . winID)
        winTitle := WinGetTitle("ahk_id " . winID)
        if (exeName = "blender.exe" && InStr(winTitle, "Blender File View")) {
            ; FeedDialogBlender(winID, folderPath)
            FeedDialogGeneral(winID, folderPath)
            return
        }
    } catch {
        ; 如果检测失败，继续使用通用方法
    }
    
    switch dialogType {
        case "GENERAL":
            FeedDialogGeneral(winID, folderPath)
        case "SYSLISTVIEW":
            FeedDialogSysListView(winID, folderPath)
    }
}

FeedDialogGeneral(winID, folderPath) {
    WinActivate("ahk_id " . winID)
    Sleep(200)
    ; Method 1: Try using Ctrl+L to access address bar
    try {
        ; Save current clipboard
        oldClipboard := A_Clipboard
        A_Clipboard := folderPath
        ClipWait(1, 0)  ; Wait for clipboard to be ready

        SendInput("^l")
        Sleep(300)
        SendInput("^v")  ; Paste from clipboard instead of typing
        Sleep(100)
        SendInput("{Enter}")
        Sleep(500)

        ; Restore original clipboard
        A_Clipboard := oldClipboard

        ; Focus back to filename field
        try ControlFocus("Edit1", "ahk_id " . winID)

        return
    }

    ; Method 2: Try setting path directly to Edit1 (fallback)
    try {
        ; Save original filename
        originalText := ControlGetText("Edit1", "ahk_id " . winID)

        ; Set folder path with backslash
        folderWithSlash := RTrim(folderPath, "\") . "\"
        ControlSetText(folderWithSlash, "Edit1", "ahk_id " . winID)
        Sleep(100)
        ControlSend("Edit1", "{Enter}", "ahk_id " . winID)
        Sleep(200)

        ; Restore original filename
        if (originalText != "" && !InStr(originalText, "\")) {
            ControlSetText(originalText, "Edit1", "ahk_id " . winID)
        }
        Sleep(200)

    }
}

FeedDialogSysListView(winID, folderPath) {
    WinActivate("ahk_id " . winID)
    Sleep(50)

    try {
        ; Save original filename
        originalText := ControlGetText("Edit1", "ahk_id " . winID)

        ; Ensure folder path ends with backslash
        folderWithSlash := RTrim(folderPath, "\") . "\"

        ; Set folder path
        ControlSetText(folderWithSlash, "Edit1", "ahk_id " . winID)
        Sleep(100)
        ControlFocus("Edit1", "ahk_id " . winID)
        ControlSend("Edit1", "{Enter}", "ahk_id " . winID)
        Sleep(200)

        ; Restore original filename if it wasn't a path
        if (originalText != "" && !InStr(originalText, "\") && !InStr(originalText, "/")) {
            ControlSetText(originalText, "Edit1", "ahk_id " . winID)
        } else {
            ; Clear the filename field
            ControlSetText("", "Edit1", "ahk_id " . winID)
        }
    } catch {
        ; Fallback: try simple method
        try {
            ControlSetText(folderPath, "Edit1", "ahk_id " . winID)
            ControlSend("Edit1", "{Enter}", "ahk_id " . winID)
        }
    }
    Send("{Enter}")
}

FeedDialogBlender(winID, folderPath) {
    ; Blender 文件对话框的特殊处理
    ; 避免使用可能导致窗口关闭的快捷键

    ; WinActivate("ahk_id " . winID) 这句使用会意外关闭对话框所以做了特殊处理

    Sleep(300)  ; 给 Blender 更多时间来响应

    oldClipboard := A_Clipboard

    A_Clipboard := folderPath

    ClipWait(1, 0)  ; Wait for clipboard to be ready

    SendInput("^l")
    Sleep(300)
    SendInput("^v")  ; Paste from clipboard instead of typing
    Sleep(100)
    SendInput("{Enter}")
    Sleep(500)

    ; Restore original clipboard
    A_Clipboard := oldClipboard

    ; Focus back to filename field
    ; try ControlFocus("Edit1", "ahk_id " . winID)

    return
    
;     try {
;         ; 方法1：尝试直接在路径栏输入路径
;         ; 首先尝试点击路径栏区域（通常在窗口顶部）
;         WinGetPos(&winX, &winY, &winWidth, &winHeight, "ahk_id " . winID)
        
;         ; 点击路径栏区域（估算位置）
;         pathBarX := winX + winWidth * 0.5  ; 窗口中央
;         pathBarY := winY + 60  ; 估算路径栏位置
        
;         Click(pathBarX, pathBarY)
;         Sleep(200)
        
;         ; 选择所有内容并替换
;         SendInput("^a")
;         Sleep(100)
        
;         ; 保存剪贴板并设置新路径
;         oldClipboard := A_Clipboard
;         A_Clipboard := folderPath
;         ClipWait(1, 0)
        
;         SendInput("^v")
;         Sleep(200)
;         SendInput("{Enter}")
;         Sleep(300)
        
;         ; 恢复剪贴板
;         A_Clipboard := oldClipboard
        
;     } catch {
;         ; 方法2：备用方案 - 尝试使用键盘导航
;         try {
;             ; 使用 Tab 键导航到路径输入区域
;             SendInput("{Tab}")
;             Sleep(100)
;             SendInput("{Tab}")
;             Sleep(100)
            
;             ; 选择所有并输入新路径
;             SendInput("^a")
;             Sleep(100)
            
;             oldClipboard := A_Clipboard
;             A_Clipboard := folderPath
;             ClipWait(1, 0)
            
;             SendInput("^v")
;             Sleep(200)
;             SendInput("{Enter}")
;             Sleep(300)
            
;             A_Clipboard := oldClipboard
            
;         } catch {
;             ; 方法3：最后的备用方案 - 什么都不做，避免破坏窗口
;             ; 这样至少不会关闭 Blender 窗口
;         }
;     }
}

; ============================================================================
; 菜单系统
; ============================================================================

ShowMenu() {
    global g_MenuItems, g_MenuActive

    ; Set menu as active
    g_MenuActive := true

    ; Clear previous menu items
    g_MenuItems := []

    ; Create context menu
    contextMenu := Menu()
    contextMenu.Add("QuickSwitchV2 Menu", (*) => "")
    contextMenu.Default := "QuickSwitchV2 Menu"
    contextMenu.Disable("QuickSwitchV2 Menu")

    hasMenuItems := false

    ; Scan for file manager windows
    if g_Config.SupportTC = "1" {
        hasMenuItems := AddTotalCommanderFolders(contextMenu) || hasMenuItems
    }
    if g_Config.SupportExplorer = "1" {
        hasMenuItems := AddExplorerFolders(contextMenu) || hasMenuItems
    }
    if g_Config.SupportXY = "1" {
        hasMenuItems := AddXYplorerFolders(contextMenu) || hasMenuItems
    }
    if g_Config.SupportOpus = "1" {
        hasMenuItems := AddOpusFolders(contextMenu) || hasMenuItems
    }

    ; Add custom paths if enabled
    if g_Config.EnableCustomPaths = "1" {
        hasMenuItems := AddCustomPaths(contextMenu) || hasMenuItems
    }

    ; Add recent paths if enabled
    if g_Config.EnableRecentPaths = "1" {
        hasMenuItems := AddRecentPaths(contextMenu) || hasMenuItems
    }

    ; Add send to file manager options
    AddSendToFileManagerMenu(contextMenu)

    ; Always add settings menu, even if no file managers found
    AddSettingsMenu(contextMenu)

    ; Configure menu appearance
    contextMenu.Color := g_Config.MenuColor

    ; Setup quick access hotkeys if enabled
    if g_Config.EnableQuickAccess = "1" && g_MenuItems.Length > 0 {
        SetupQuickAccessHotkeys()
    }

    ; Show menu
    try {
        contextMenu.Show(Integer(g_Config.MenuPosX), Integer(g_Config.MenuPosY))
    } catch as e {
        ; Fallback to default position if config values are invalid
        contextMenu.Show(100, 100)
    }

    ; Set menu as inactive after showing (menu will close automatically when user clicks elsewhere)
    SetTimer(() => g_MenuActive := false, -100)
}

; ============================================================================
; 文件管理器检测
; ============================================================================

GetActiveFileManagerFolder(winID) {
    ; 改进的逻辑：根据窗口的Z-order（活动顺序）来选择最合适的文件管理器
    ; 而不是按照固定的优先级顺序

    allWindows := WinGetList()
    fileManagerCandidates := []

    ; 收集所有可用的文件管理器窗口及其路径
    for id in allWindows {
        try {
            winClass := WinGetClass("ahk_id " . id)
            
            ; 检查Total Commander
            if (g_Config.SupportTC = "1" && winClass = "TTOTAL_CMD") {
                folderPath := GetTCActiveFolder(id)
                if IsValidFolder(folderPath) {
                    fileManagerCandidates.Push({id: id, path: folderPath, type: "TC"})
                }
            }
            ; 检查Windows Explorer
            else if (g_Config.SupportExplorer = "1" && winClass = "CabinetWClass") {
                for explorerWindow in ComObject("Shell.Application").Windows {
                    try {
                        if (id = explorerWindow.hwnd) {
                            explorerPath := explorerWindow.Document.Folder.Self.Path
                            if IsValidFolder(explorerPath) {
                                fileManagerCandidates.Push({id: id, path: explorerPath, type: "Explorer"})
                            }
                        }
                    } catch {
                        continue
                    }
                }
            }
            ; 检查XYplorer
            else if (g_Config.SupportXY = "1" && winClass = "ThunderRT6FormDC") {
                folderPath := GetXYActiveFolder(id)
                if IsValidFolder(folderPath) {
                    fileManagerCandidates.Push({id: id, path: folderPath, type: "XY"})
                }
            }
            ; 检查Directory Opus
            else if (g_Config.SupportOpus = "1" && winClass = "dopus.lister") {
                folderPath := GetOpusActiveFolder(id)
                if IsValidFolder(folderPath) {
                    fileManagerCandidates.Push({id: id, path: folderPath, type: "Opus"})
                }
            }
        } catch {
            continue
        }
    }

    ; 如果没有找到任何文件管理器，返回空
    if (fileManagerCandidates.Length = 0) {
        return ""
    }

    ; 如果只有一个候选，直接返回
    if (fileManagerCandidates.Length = 1) {
        return fileManagerCandidates[1].path
    }

    ; 多个候选时，选择Z-order最高的（最近活动的）
    ; WinGetList() 返回的窗口列表已经按Z-order排序，第一个是最前面的
    return fileManagerCandidates[1].path
}

GetTCActiveFolder(winID) {
    clipSaved := ClipboardAll()
    A_Clipboard := ""

    ; 方法1：使用PostMessage + ClipWait (基于V1代码修复)
    try {
        PostMessage(1075, g_Config.TC_CopySrcPath, 0, , "ahk_id " . winID)

        if ClipWait(1) {
            if (A_Clipboard != "") {
                folderPath := A_Clipboard
                A_Clipboard := clipSaved
                return folderPath
            }
        }
    } catch {
        ; 忽略错误，继续尝试其他方法
    }

    ; 方法2：尝试目标路径 (右窗格)
    A_Clipboard := ""
    try {
        PostMessage(1075, g_Config.TC_CopyTrgPath, 0, , "ahk_id " . winID)

        if ClipWait(1) {
            if (A_Clipboard != "") {
                folderPath := A_Clipboard
                A_Clipboard := clipSaved
                return folderPath
            }
        }
    } catch {
        ; 忽略错误，继续尝试其他方法
    }

    ; 方法3：备选方案 - 使用SendMessage
    A_Clipboard := ""
    try {
        result := SendMessage(1075, g_Config.TC_CopySrcPath, 0, , "ahk_id " . winID)
        Sleep(200)

        if (result != 0 && A_Clipboard != "") {
            folderPath := A_Clipboard
            A_Clipboard := clipSaved
            return folderPath
        }
    } catch {
        ; 忽略错误
    }

    A_Clipboard := clipSaved
    return ""
}

GetXYActiveFolder(winID) {
    clipSaved := ClipboardAll()
    A_Clipboard := ""

    SendXYplorerMessage(winID, "::copytext get('path', a);")
    ClipWait(0)

    result := A_Clipboard
    A_Clipboard := clipSaved
    return result
}



GetOpusActiveFolder(winID) {
    thisPID := WinGetPID("ahk_id " . winID)
    dopusExe := GetModuleFileName(thisPID)

    RunWait('"' . dopusExe . '\..\dopusrt.exe" /info "' . g_Config.TempFile . '",paths', , , &dummy)
    Sleep(100)

    try {
        opusInfo := FileRead(g_Config.TempFile)
        FileDelete(g_Config.TempFile)

        if RegExMatch(opusInfo, 'lister="' . winID . '".*tab_state="1".*>(.*)</path>', &match) {
            return match[1]
        }
    }

    return ""
}

; ============================================================================
; 菜单功能
; ============================================================================

AddTotalCommanderFolders(contextMenu) {
    added := false
    allWindows := WinGetList()

    for winID in allWindows {
        try {
            winClass := WinGetClass("ahk_id " . winID)
            if (winClass = "TTOTAL_CMD") {
                thisPID := WinGetPID("ahk_id " . winID)
                tcExe := GetModuleFileName(thisPID)

                ; 获取 源路径
                clipSaved := ClipboardAll()
                A_Clipboard := ""

                SendMessage(1075, g_Config.TC_CopySrcPath, 0, , "ahk_id " . winID)
                Sleep(50)  ; Wait for clipboard update
                if (A_Clipboard != "" && IsValidFolder(A_Clipboard)) {
                    folderPath := A_Clipboard
                    AddMenuItemWithQuickAccess(contextMenu, folderPath, tcExe, 0)
                    added := true
                }

                ; 获取 目标路径
                SendMessage(1075, g_Config.TC_CopyTrgPath, 0, , "ahk_id " . winID)
                Sleep(50)  ; Wait for clipboard update
                if (A_Clipboard != "" && IsValidFolder(A_Clipboard)) {
                    folderPath := A_Clipboard
                    AddMenuItemWithQuickAccess(contextMenu, folderPath, tcExe, 0)
                    added := true
                }

                A_Clipboard := clipSaved
            }
        }
    }

    return added
}

AddExplorerFolders(contextMenu) {
    added := false
    allWindows := WinGetList()

    for winID in allWindows {
        try {
            winClass := WinGetClass("ahk_id " . winID)
            if (winClass = "CabinetWClass") {
                for explorerWindow in ComObject("Shell.Application").Windows {
                    try {
                        if (winID = explorerWindow.hwnd) {
                            explorerPath := explorerWindow.Document.Folder.Self.Path
                            if IsValidFolder(explorerPath) {
                                AddMenuItemWithQuickAccess(contextMenu, explorerPath, "shell32.dll", 5)
                                added := true
                            }
                        }
                    }
                }
            }
        }
    }

    return added
}

AddXYplorerFolders(contextMenu) {
    added := false
    allWindows := WinGetList()

    for winID in allWindows {
        try {
            winClass := WinGetClass("ahk_id " . winID)
            if (winClass = "ThunderRT6FormDC") {
                thisPID := WinGetPID("ahk_id " . winID)
                xyExe := GetModuleFileName(thisPID)

                clipSaved := ClipboardAll()
                A_Clipboard := ""

                ; Get active path
                SendXYplorerMessage(winID, "::copytext get('path', a);")
                if IsValidFolder(A_Clipboard) {
                    folderPath := A_Clipboard
                    AddMenuItemWithQuickAccess(contextMenu, folderPath, xyExe, 0)
                    added := true
                }

                ; Get inactive path
                SendXYplorerMessage(winID, "::copytext get('path', i);")
                if IsValidFolder(A_Clipboard) {
                    folderPath := A_Clipboard
                    AddMenuItemWithQuickAccess(contextMenu, folderPath, xyExe, 0)
                    added := true
                }

                A_Clipboard := clipSaved
            }
        }
    }

    return added
}

AddOpusFolders(contextMenu) {
    added := false
    allWindows := WinGetList()

    for winID in allWindows {
        try {
            winClass := WinGetClass("ahk_id " . winID)
            if (winClass = "dopus.lister") {
                thisPID := WinGetPID("ahk_id " . winID)
                dopusExe := GetModuleFileName(thisPID)

                ; Get Opus info
                RunWait('"' . dopusExe . '\..\dopusrt.exe" /info "' . g_Config.TempFile . '",paths', , , &dummy)
                Sleep(100)

                try {
                    opusInfo := FileRead(g_Config.TempFile)
                    FileDelete(g_Config.TempFile)

                    ; Parse active and passive paths
                    if RegExMatch(opusInfo, 'lister="' . winID . '".*tab_state="1".*>(.*)</path>', &match) {
                        folderPath := match[1]
                        if IsValidFolder(folderPath) {
                            AddMenuItemWithQuickAccess(contextMenu, folderPath, dopusExe, 0)
                            added := true
                        }
                    }

                    if RegExMatch(opusInfo, 'lister="' . winID . '".*tab_state="2".*>(.*)</path>', &match) {
                        folderPath := match[1]
                        if IsValidFolder(folderPath) {
                            AddMenuItemWithQuickAccess(contextMenu, folderPath, dopusExe, 0)
                            added := true
                        }
                    }
                }
            }
        }
    }

    return added
}

AddCustomPaths(contextMenu) {
    added := false

    ; Create submenu for custom paths
    customPathsMenu := Menu()

    ; Read all custom paths from INI file
    customPaths := []

    ; Try to read custom paths (Path1, Path2, etc.)
    loop 20 {  ; Support up to 20 custom paths
        pathKey := "Path" . A_Index
        pathValue := IniRead(g_Config.IniFile, "CustomPaths", pathKey, "")

        if (pathValue != "") {
            ; Parse path entry: "DisplayName|ActualPath" or just "ActualPath"
            if InStr(pathValue, "|") {
                parts := StrSplit(pathValue, "|", " `t")
                if (parts.Length >= 2) {
                    displayName := parts[1]
                    actualPath := parts[2]
                } else {
                    displayName := pathValue
                    actualPath := pathValue
                }
            } else {
                ; If no display name specified, use folder name
                SplitPath(pathValue, &folderName)
                displayName := folderName != "" ? folderName : pathValue
                actualPath := pathValue
            }

            ; Expand environment variables in path
            expandedPath := ExpandEnvironmentVariables(actualPath)

            ; Validate path exists
            if IsValidFolder(expandedPath) {
                customPaths.Push({ display: displayName, path: expandedPath })
                added := true
            }
        }
    }

    ; Add custom paths to submenu
    if (customPaths.Length > 0) {
        for pathInfo in customPaths {
            customPathsMenu.Add(pathInfo.display, FolderChoiceHandler.Bind(pathInfo.path))
            ; Set folder icon
            try customPathsMenu.SetIcon(pathInfo.display, "shell32.dll", 4, g_Config.IconSize)
        }

        ; Add submenu to main menu
        contextMenu.Add()
        contextMenu.Add(g_Config.CustomPathsTitle, customPathsMenu)
        try contextMenu.SetIcon(g_Config.CustomPathsTitle, "shell32.dll", 43, g_Config.IconSize)
    }

    return added
}

AddRecentPaths(contextMenu) {
    added := false

    ; Create submenu for recent paths
    recentPathsMenu := Menu()

    ; Read recent paths from INI file
    recentPaths := []
    maxPaths := Integer(g_Config.MaxRecentPaths)

    ; Try to read recent paths (Recent1, Recent2, etc.)
    loop maxPaths {
        recentKey := "Recent" . A_Index
        recentValue := IniRead(g_Config.IniFile, "RecentPaths", recentKey, "")

        if (recentValue != "") {
            ; Parse recent entry: "Timestamp|Path"
            if InStr(recentValue, "|") {
                parts := StrSplit(recentValue, "|", " `t")
                if (parts.Length >= 2) {
                    timestamp := parts[1]
                    pathValue := parts[2]
                } else {
                    pathValue := recentValue
                }
            } else {
                pathValue := recentValue
            }

            ; Validate path exists
            if IsValidFolder(pathValue) {
                recentPaths.Push(pathValue)
                added := true
            }
        }
    }

    ; Add recent paths to submenu
    if (recentPaths.Length > 0) {
        for pathValue in recentPaths {
            ; Use full path as display text
            recentPathsMenu.Add(pathValue, RecentPathChoiceHandler.Bind(pathValue))
            ; Set folder icon
            try recentPathsMenu.SetIcon(pathValue, "shell32.dll", 4, g_Config.IconSize)
        }

        ; Add submenu to main menu
        contextMenu.Add()
        contextMenu.Add(g_Config.RecentPathsTitle, recentPathsMenu)
        try contextMenu.SetIcon(g_Config.RecentPathsTitle, "shell32.dll", 269, g_Config.IconSize)
    }

    return added
}

AddSendToFileManagerMenu(contextMenu) {
    ; Get current dialog path
    currentPath := GetCurrentDialogPath()

    if (currentPath != "") {
        ; Add separator and send to file manager options
        contextMenu.Add()
        contextMenu.Add("发送路径到...", (*) => "")
        contextMenu.Disable("发送路径到...")

        ; Add send to Total Commander option
        if g_Config.SupportTC = "1" {
            contextMenu.Add("发送到 Total Commander", SendToTCHandler.Bind(currentPath))
            try contextMenu.SetIcon("发送到 Total Commander", "shell32.dll", 5, g_Config.IconSize)
        }

        ; Add send to Explorer option
        if g_Config.SupportExplorer = "1" {
            contextMenu.Add("发送到 资源管理器", SendToExplorerHandler.Bind(currentPath))
            try contextMenu.SetIcon("发送到 资源管理器", "shell32.dll", 4, g_Config.IconSize)
        }
    }
}

AddSettingsMenu(contextMenu) {
    contextMenu.Add()
    ; contextMenu.Add("Settings for this dialog", (*) => "")
    ; contextMenu.Disable("Settings for this dialog")

    contextMenu.Add("自动跳转", AutoSwitchHandler)
    ; contextMenu.Add("Never here", NeverHandler)
    contextMenu.Add("Not now", NotNowHandler)

    ; Set current selection
    switch g_CurrentDialog.Action {
        case "1":
            contextMenu.Check("自动跳转")
        case "0":
            ; contextMenu.Check("Never here")
        default:
            contextMenu.Check("Not now")
    }
}

; ============================================================================
; QUICK ACCESS FUNCTIONS
; ============================================================================

AddMenuItemWithQuickAccess(contextMenu, folderPath, iconPath := "", iconIndex := 0) {
    ; Add to menu items array for quick access
    g_MenuItems.Push(folderPath)

    ; Create display text with quick access shortcut if enabled
    displayText := folderPath
    if g_Config.EnableQuickAccess = "1" && g_MenuItems.Length <= StrLen(g_Config.QuickAccessKeys) {
        shortcutKey := SubStr(g_Config.QuickAccessKeys, g_MenuItems.Length, 1)
        displayText := "[" "&" . shortcutKey . "] " . folderPath
    }

    ; Add menu item
    contextMenu.Add(displayText, FolderChoiceHandler.Bind(folderPath))

    ; Set icon if provided
    if iconPath != "" {
        try contextMenu.SetIcon(displayText, iconPath, iconIndex, g_Config.IconSize)
    }
}

SetupQuickAccessHotkeys() {
    ; Setup hotkeys for each menu item
    loop g_MenuItems.Length {
        if A_Index > StrLen(g_Config.QuickAccessKeys)
            break

        key := SubStr(g_Config.QuickAccessKeys, A_Index, 1)

    }
}

; ============================================================================
; MENU HANDLERS
; ============================================================================

FolderChoiceHandler(folderPath, *) {
    if IsValidFolder(folderPath) && g_CurrentDialog.WinID != "" {
        ; Record this path as recently used
        RecordRecentPath(folderPath)
        ; Navigate to the folder
        FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
    }
}

RecentPathChoiceHandler(folderPath, *) {
    if IsValidFolder(folderPath) && g_CurrentDialog.WinID != "" {
        ; Record this path as recently used (move to top)
        RecordRecentPath(folderPath)
        ; Navigate to the folder
        FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
    }
}

AutoSwitchHandler(*) {
    ; 写入配置文件，设置为AutoSwitch模式
    IniWrite("1", g_Config.IniFile, "Dialogs", g_CurrentDialog.FingerPrint)
    g_CurrentDialog.Action := "1"

    ; 获取活动文件管理器的文件夹路径
    folderPath := GetActiveFileManagerFolder(g_CurrentDialog.WinID)

    if IsValidFolder(folderPath) {
        ; 切换到文件夹
        FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
    }
}

NeverHandler(*) {
    IniWrite("0", g_Config.IniFile, "Dialogs", g_CurrentDialog.FingerPrint)
    g_CurrentDialog.Action := "0"
}

NotNowHandler(*) {
    try IniDelete(g_Config.IniFile, "Dialogs", g_CurrentDialog.FingerPrint)
    g_CurrentDialog.Action := ""
}

; ============================================================================
; SEND TO FILE MANAGER FUNCTIONS
; ============================================================================

GetCurrentDialogPath() {
    ; Get current dialog path based on V1 code logic
    try {
        ; Get all text from the dialog window
        winText := WinGetText("ahk_id " . g_CurrentDialog.WinID)

        ; Parse the text to find address line (基于V1代码的逻辑)
        lines := StrSplit(winText, "`n", "`r")
        for line in lines {
            ; Look for address line (支持中英文)
            if RegExMatch(line, "^地址: (.+)", &match) {
                return Trim(match[1])
            }
            if RegExMatch(line, "^Address: (.+)", &match) {
                return Trim(match[1])
            }
            if RegExMatch(line, "^Location: (.+)", &match) {
                return Trim(match[1])
            }
        }

        ; Alternative method: try to get path from Edit1 control
        try {
            editText := ControlGetText("Edit1", "ahk_id " . g_CurrentDialog.WinID)
            if (editText != "" && InStr(editText, "\")) {
                ; Extract directory from full path
                SplitPath(editText, , &dir)
                if IsValidFolder(dir) {
                    return dir
                }
            }
        }

        ; Alternative method: try to get path from address bar controls
        controlList := WinGetControls("ahk_id " . g_CurrentDialog.WinID)
        for control in controlList {
            if InStr(control, "Edit") {
                try {
                    controlText := ControlGetText(control, "ahk_id " . g_CurrentDialog.WinID)
                    if (controlText != "" && InStr(controlText, "\") && IsValidFolder(controlText)) {
                        return controlText
                    }
                }
            }
        }

    } catch {
        ; If all methods fail, return empty
    }

    return ""
}

SendToTCHandler(dialogPath, *) {

    try {

        tcWindow := WinExist("ahk_class TTOTAL_CMD")

        if (tcWindow) {

            WinActivate("ahk_class TTOTAL_CMD")
            Sleep(100)


            PostMessage(1075, 3001, 0, , "ahk_class TTOTAL_CMD")
            Sleep(100)


            ControlSetText("cd " . dialogPath, "Edit1", "ahk_class TTOTAL_CMD")
            Sleep(400)
            ControlSend("Edit1", "{Enter}", "ahk_class TTOTAL_CMD")

            RecordRecentPath(dialogPath)
        } else {
            MsgBox("未找到 Total Commander 窗口", "发送路径", "T3")
        }
    } catch as e {
        MsgBox("发送路径到 Total Commander 失败: " . e.message, "错误", "T5")
    }
}

SendToExplorerHandler(dialogPath, *) {

    try {

        Run("explorer.exe `"" . dialogPath . "`"")


        RecordRecentPath(dialogPath)
    } catch as e {
        MsgBox("发送路径到资源管理器失败: " . e.message, "错误", "T5")
    }
}

; ============================================================================
; RECENT PATHS FUNCTIONS
; ============================================================================

RecordRecentPath(folderPath) {
    ; Record a path as recently used
    if (!IsValidFolder(folderPath)) {
        return
    }

    maxPaths := Integer(g_Config.MaxRecentPaths)
    currentTime := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
    newEntry := currentTime . "|" . folderPath

    ; Read existing recent paths
    existingPaths := []
    loop maxPaths {
        recentKey := "Recent" . A_Index
        recentValue := IniRead(g_Config.IniFile, "RecentPaths", recentKey, "")

        if (recentValue != "") {
            ; Parse existing entry
            if InStr(recentValue, "|") {
                parts := StrSplit(recentValue, "|", " `t")
                if (parts.Length >= 2) {
                    existingPath := parts[2]
                } else {
                    existingPath := recentValue
                }
            } else {
                existingPath := recentValue
            }

            ; Only keep if it's different from the new path and still exists
            if (existingPath != folderPath && IsValidFolder(existingPath)) {
                existingPaths.Push(recentValue)
            }
        }
    }

    ; Write new entry at top, followed by existing entries
    IniWrite(newEntry, g_Config.IniFile, "RecentPaths", "Recent1")

    ; Shift existing entries down
    entryIndex := 2
    for existingEntry in existingPaths {
        if (entryIndex > maxPaths) {
            break
        }
        IniWrite(existingEntry, g_Config.IniFile, "RecentPaths", "Recent" . entryIndex)
        entryIndex++
    }

    ; Clear any remaining entries
    while (entryIndex <= maxPaths) {
        try IniDelete(g_Config.IniFile, "RecentPaths", "Recent" . entryIndex)
        entryIndex++
    }
}

; ============================================================================
; UTILITY FUNCTIONS
; ============================================================================

IsOSSupported() {
    unsupportedOS := ["WIN_VISTA", "WIN_2003", "WIN_XP", "WIN_2000"]
    return !HasValue(unsupportedOS, A_OSVersion)
}

IsValidFolder(path) {
    return (path != "" && StrLen(path) < 259 && InStr(FileExist(path), "D"))
}

ExpandEnvironmentVariables(path) {
    ; Expand environment variables like %USERNAME%, %USERPROFILE%, etc.
    try {
        ; Use Windows API to expand environment variables
        size := DllCall("ExpandEnvironmentStrings", "Str", path, "Ptr", 0, "UInt", 0)
        if (size > 0) {
            pathBuffer := Buffer(size * 2)
            result := DllCall("ExpandEnvironmentStrings", "Str", path, "Ptr", pathBuffer, "UInt", size)
            if (result > 0) {
                return StrGet(pathBuffer)
            }
        }
    } catch {
        ; If expansion fails, return original path
    }
    return path
}

GetModuleFileName(pid) {
    hProcess := DllCall("OpenProcess", "uint", 0x10 | 0x400, "int", false, "uint", pid)
    if (!hProcess) {
        return ""
    }

    nameSize := 255
    name := Buffer(nameSize * 2)

    result := DllCall("psapi.dll\GetModuleFileNameExW", "uint", hProcess, "uint", 0, "ptr", name, "uint", nameSize)
    DllCall("CloseHandle", "ptr", hProcess)

    return result ? StrGet(name) : ""
}

SendXYplorerMessage(xyHwnd, message) {
    size := StrLen(message)
    data := Buffer(size * 2)
    StrPut(message, data, "UTF-16")

    copyData := Buffer(A_PtrSize * 3)
    NumPut("Ptr", 4194305, copyData, 0)
    NumPut("UInt", size * 2, copyData, A_PtrSize)
    NumPut("Ptr", data.Ptr, copyData, A_PtrSize * 2)

    DllCall("User32.dll\SendMessageW", "Ptr", xyHwnd, "UInt", 74, "Ptr", 0, "Ptr", copyData, "Ptr")
}



HasValue(haystack, needle) {
    for value in haystack {
        if (value = needle) {
            return true
        }
    }
    return false
}
