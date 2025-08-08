#Requires AutoHotkey v2.0
;@Ahk2Exe-SetVersion 1.0
;@Ahk2Exe-SetName QuickSwitch
;@Ahk2Exe-SetDescription Use opened file manager folders in File dialogs.
;@Ahk2Exe-SetCopyright NotNull

/*
QuickSwitch V2 - Refactored Version
By: NotNull
Refactored for AHK V2 with configuration file support
*/

; ============================================================================
; INITIALIZATION
; ============================================================================

#Warn
SendMode("Input")
SetWorkingDir(A_ScriptDir)
#SingleInstance Force

; Global variables
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
; CONFIGURATION MANAGEMENT
; ============================================================================

InitializeConfig() {
    ; Get script name for config files
    SplitPath(A_ScriptFullPath, , , , &name_no_ext)
    g_Config.IniFile := name_no_ext . ".ini"
    g_Config.TempFile := EnvGet("TEMP") . "\dopusinfo.xml"

    ; Load configuration from INI file
    LoadConfiguration()

    ; Clean up temp file
    try FileDelete(g_Config.TempFile)
}

LoadConfiguration() {
    ; Load hotkey configuration
    g_Config.Hotkey := IniRead(g_Config.IniFile, "Settings", "Hotkey", "^q")

    ; Load display settings
    g_Config.MenuColor := IniRead(g_Config.IniFile, "Display", "MenuColor", "C0C59C")
    g_Config.IconSize := IniRead(g_Config.IniFile, "Display", "IconSize", "16")
    g_Config.MenuPosX := IniRead(g_Config.IniFile, "Display", "MenuPosX", "100")
    g_Config.MenuPosY := IniRead(g_Config.IniFile, "Display", "MenuPosY", "100")

    ; Load quick access settings
    g_Config.EnableQuickAccess := IniRead(g_Config.IniFile, "QuickAccess", "EnableQuickAccess", "1")
    g_Config.QuickAccessKeys := IniRead(g_Config.IniFile, "QuickAccess", "QuickAccessKeys",
        "123456789abcdefghijklmnopqrstuvwxyz")

    ; Load file manager settings
    g_Config.SupportTC := IniRead(g_Config.IniFile, "FileManagers", "TotalCommander", "1")
    g_Config.SupportExplorer := IniRead(g_Config.IniFile, "FileManagers", "Explorer", "1")
    g_Config.SupportXY := IniRead(g_Config.IniFile, "FileManagers", "XYplorer", "1")
    g_Config.SupportOpus := IniRead(g_Config.IniFile, "FileManagers", "DirectoryOpus", "1")

    ; Total Commander message codes
    g_Config.TC_CopySrcPath := 2029
    g_Config.TC_CopyTrgPath := 2030
}

RegisterHotkey() {
    ; Register the hotkey from configuration
    try {
        Hotkey(g_Config.Hotkey, ToggleMenu, "On")
    } catch as e {
        ; If hotkey registration fails, show error and use default
        MsgBox("Failed to register hotkey '" . g_Config.Hotkey . "': " . e.message . "`nUsing default Ctrl+Q")
        try {
            Hotkey("^q", ToggleMenu, "On")
            g_Config.Hotkey := "^q"
        }
    }
}

ToggleMenu(*) {
    ; 简单直接显示菜单，不做复杂的切换逻辑
    ; 菜单会在用户点击外部区域或按ESC时自动关闭
    ShowMenu()
}

; ============================================================================
; MAIN LOOP
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

    ; Check dialog action from INI
    g_CurrentDialog.Action := IniRead(g_Config.IniFile, "Dialogs", g_CurrentDialog.FingerPrint, "")

    if (g_CurrentDialog.Action = "1") {
        ; AutoSwitch mode
        folderPath := GetActiveFileManagerFolder(g_CurrentDialog.WinID)

        if IsValidFolder(folderPath) {
            ; AutoSwitch成功：直接切换到文件夹，不显示菜单
            FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
        } else {
            ; AutoSwitch失败：作为备选方案，显示菜单
            ShowMenu()
        }
    } else if (g_CurrentDialog.Action = "0") {
        ; Never here mode - do nothing
    } else {
        ; Show menu mode
        ShowMenu()
    }
}

; ============================================================================
; DIALOG DETECTION AND FEEDING
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
    switch dialogType {
        case "GENERAL":
            ; MsgBox("1")
            FeedDialogGeneral(winID, folderPath)
        case "SYSLISTVIEW":
            ; MsgBox("2")
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

; ============================================================================
; MENU SYSTEM
; ============================================================================

ShowMenu() {
    global g_MenuItems, g_MenuActive

    ; Set menu as active
    g_MenuActive := true

    ; Clear previous menu items
    g_MenuItems := []

    ; Create context menu
    contextMenu := Menu()
    contextMenu.Add("QuickSwitch Menu", (*) => "")
    contextMenu.Default := "QuickSwitch Menu"
    contextMenu.Disable("QuickSwitch Menu")

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

AddTotalCommanderFolders(contextMenu) {
    added := false
    allWindows := WinGetList()

    for winID in allWindows {
        try {
            winClass := WinGetClass("ahk_id " . winID)
            if (winClass = "TTOTAL_CMD") {
                thisPID := WinGetPID("ahk_id " . winID)
                tcExe := GetModuleFileName(thisPID)

                ; Get source path
                clipSaved := ClipboardAll()
                A_Clipboard := ""

                SendMessage(1075, g_Config.TC_CopySrcPath, 0, , "ahk_id " . winID)
                Sleep(50)  ; Wait for clipboard update
                if (A_Clipboard != "" && IsValidFolder(A_Clipboard)) {
                    folderPath := A_Clipboard
                    AddMenuItemWithQuickAccess(contextMenu, folderPath, tcExe, 0)
                    added := true
                }

                ; Get target path
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

AddSettingsMenu(contextMenu) {
    contextMenu.Add()
    contextMenu.Add("Settings for this dialog", (*) => "")
    contextMenu.Disable("Settings for this dialog")

    contextMenu.Add("Allow AutoSwitch", AutoSwitchHandler)
    contextMenu.Add("Never here", NeverHandler)
    contextMenu.Add("Not now", NotNowHandler)

    ; Set current selection
    switch g_CurrentDialog.Action {
        case "1":
            contextMenu.Check("Allow AutoSwitch")
        case "0":
            contextMenu.Check("Never here")
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
        try {
            ; Use Ctrl+key to avoid conflicts and menu issues
            ; hotkeyCombo := "^" . key  ; ^ means Ctrl
            ; Hotkey(hotkeyCombo, QuickAccessHandler.Bind(A_Index), "On")
            ; Debug: Show which hotkeys are being set up
            ; ToolTip("Setting up hotkey: " . key . " for index " . A_Index, 0, 20 * A_Index)
            SetTimer(() => ToolTip(, 0, 20 * A_Index), -500)  ; Clear after 0.5 seconds
        } catch as e {
            ; Debug: Show if hotkey setup failed
            ; ToolTip("Failed to set hotkey: " . key . " - " . e.message, 0, 20 * A_Index)
            SetTimer(() => ToolTip(, 0, 20 * A_Index), -1000)
        }
    }
}

QuickAccessHandler(index, *) {
    ; Debug: Show that hotkey was pressed
    ToolTip("Hotkey pressed: " . index, 0, 0)
    SetTimer(() => ToolTip(), -1000)  ; Clear tooltip after 1 second

    ; Close any open menu first
    try {
        SendInput("{Esc}")
        Sleep(50)
    }

    ; Get the folder path for this index
    if index <= g_MenuItems.Length {
        folderPath := g_MenuItems[index]
        if IsValidFolder(folderPath) && g_CurrentDialog.WinID != "" {
            ; Clean up hotkeys before feeding dialog

            FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
        }
    }
}

; ============================================================================
; MENU HANDLERS
; ============================================================================

FolderChoiceHandler(folderPath, *) {
    if IsValidFolder(folderPath) && g_CurrentDialog.WinID != "" {
        FeedDialog(g_CurrentDialog.WinID, folderPath, g_CurrentDialog.Type)
    }
}

FolderChoice(itemName, itemPos, menu) {
    if IsValidFolder(itemName) {
        FeedDialog(g_CurrentDialog.WinID, itemName, g_CurrentDialog.Type)
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
; UTILITY FUNCTIONS
; ============================================================================

IsOSSupported() {
    unsupportedOS := ["WIN_VISTA", "WIN_2003", "WIN_XP", "WIN_2000"]
    return !HasValue(unsupportedOS, A_OSVersion)
}

IsValidFolder(path) {
    return (path != "" && StrLen(path) < 259 && InStr(FileExist(path), "D"))
}

GetActiveFileManagerFolder(winID) {
    ; 使用和菜单相同的逻辑：扫描所有窗口找到文件管理器
    ; 这样确保AutoSwitch和菜单的行为一致

    allWindows := WinGetList()

    ; 优先检查Total Commander
    if g_Config.SupportTC = "1" {
        for id in allWindows {
            try {
                winClass := WinGetClass("ahk_id " . id)
                if (winClass = "TTOTAL_CMD") {
                    folderPath := GetTCActiveFolder(id)
                    if IsValidFolder(folderPath) {
                        return folderPath
                    }
                }
            } catch {
                continue
            }
        }
    }

    ; 检查Windows Explorer
    if g_Config.SupportExplorer = "1" {
        for id in allWindows {
            try {
                winClass := WinGetClass("ahk_id " . id)
                if (winClass = "CabinetWClass") {
                    for explorerWindow in ComObject("Shell.Application").Windows {
                        try {
                            if (id = explorerWindow.hwnd) {
                                explorerPath := explorerWindow.Document.Folder.Self.Path
                                if IsValidFolder(explorerPath) {
                                    return explorerPath
                                }
                            }
                        } catch {
                            continue
                        }
                    }
                }
            } catch {
                continue
            }
        }
    }

    ; 检查XYplorer
    if g_Config.SupportXY = "1" {
        for id in allWindows {
            try {
                winClass := WinGetClass("ahk_id " . id)
                if (winClass = "ThunderRT6FormDC") {
                    folderPath := GetXYActiveFolder(id)
                    if IsValidFolder(folderPath) {
                        return folderPath
                    }
                }
            } catch {
                continue
            }
        }
    }

    ; 检查Directory Opus
    if g_Config.SupportOpus = "1" {
        for id in allWindows {
            try {
                winClass := WinGetClass("ahk_id " . id)
                if (winClass = "dopus.lister") {
                    folderPath := GetOpusActiveFolder(id)
                    if IsValidFolder(folderPath) {
                        return folderPath
                    }
                }
            } catch {
                continue
            }
        }
    }

    return ""
}

; 检查窗口是否可见的辅助函数
IsWindowVisible(winID) {
    try {
        ; 检查窗口是否最小化
        if (WinGetMinMax("ahk_id " . winID) = -1)
            return false

        ; 检查窗口是否有可见区域
        WinGetPos(&x, &y, &w, &h, "ahk_id " . winID)
        return (w > 0 && h > 0)
    } catch {
        return false
    }
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

GetExplorerActiveFolder(winID) {
    for explorerWindow in ComObject("Shell.Application").Windows {
        try {
            if (winID = explorerWindow.hwnd) {
                return explorerWindow.Document.Folder.Self.Path
            }
        }
    }
    return ""
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

CleanupGlobals() {
    g_CurrentDialog.WinID := ""
    g_CurrentDialog.Type := ""
    g_CurrentDialog.FingerPrint := ""
    g_CurrentDialog.Action := ""
}

HasValue(haystack, needle) {
    for value in haystack {
        if (value = needle) {
            return true
        }
    }
    return false
}
