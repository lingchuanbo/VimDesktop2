#requires AutoHotkey v2.0
#SingleInstance Force
Persistent true
; SetCapsLockState "AlwaysOff"
CoordMode "Tooltip", "Screen"
CoordMode "Mouse", "Screen"
CoordMode "Menu", "Window"
SetControlDelay -1
SetKeyDelay -1
DetectHiddenWindows "on"
FileEncoding "UTF-8"
SendMode "Input"

global VimDesktop_Global := Object()
global Vim := Object()
global INIObject := Object()
global PluginConfigs := Object()
global Lang := Object()
global VimDesktop_ExtensionPIDs := Map() ; 存储扩展功能的进程ID

VimDesktop_Global.ConfigPath := A_ScriptDir "\Custom\vimd.ini"
VimDesktop_Global.Editor := FileExist("D:\Program Files\Microsoft VS Code\Code.exe") ?
    "D:\Program Files\Microsoft VS Code\Code.exe" : "NotePad.exe"
VimDesktop_Global.default_enable_show_info := ""
VimDesktop_Global.WshShell := ""
VimDesktop_Global.__vimLastAction := ""
VimDesktop_Global.showToolTipStatus := 0
VimDesktop_Global.Current_KeyMap := ""

INIObject := EasyINI(VimDesktop_Global.ConfigPath)
; 从配置文件读取 default_enable_show_info 设置
VimDesktop_Global.default_enable_show_info := INIObject.config.default_enable_show_info
VimDesktop_LoadPluginConfigs() ; 加载插件配置
LangString := FileRead(A_ScriptDir "\lang\" INIObject.config.lang ".json", "UTF-8")
Lang := JSON.parse(LangString)

try
    TraySetIcon(".\Custom\vimd.ico")

; 智能加载插件配置
VimDesktop_LoadPluginConfigs() {
    global PluginConfigs

    pluginsDir := A_ScriptDir "\plugins"

    ; 如果plugins目录不存在，直接返回
    if (!DirExist(pluginsDir)) {
        return
    }

    ; 遍历plugins目录下的所有子目录
    loop files, pluginsDir "\*", "D" {
        pluginName := A_LoopFileName
        pluginDir := A_LoopFileFullPath

        ; 查找同名的ini文件（支持多种命名方式）
        possibleConfigFiles := [
            pluginDir "\" pluginName ".ini",           ; 如：Everything\Everything.ini
            pluginDir "\" StrLower(pluginName) ".ini", ; 如：Everything\everything.ini
            pluginDir "\config.ini",                   ; 通用配置文件名
            pluginDir "\plugin.ini"                    ; 通用插件配置文件名
        ]

        ; 尝试加载找到的第一个配置文件
        for configPath in possibleConfigFiles {
            if (FileExist(configPath)) {
                try {
                    PluginConfigs.%pluginName% := EasyIni(configPath)

                    ; 调试信息：成功加载插件配置
                    if (INIObject.config.enable_debug) {
                        MsgBox("成功加载插件配置：" pluginName " - " configPath, "调试信息", "OK T2")
                    }
                    break ; 找到并加载成功后跳出循环
                } catch Error as e {
                    ; 如果加载失败，记录错误但继续尝试其他文件
                    if (INIObject.config.enable_debug) {
                        MsgBox("加载插件配置失败：" pluginName " - " configPath " - " e.Message, "调试信息", "OK Icon!")
                    }
                }
            }
        }
    }
}

VimDesktop_TrayMenuCreate() ; 生成托盘菜单

VimDesktop_AutoStartExtensions() ; 自动启动扩展功能

VimDesktop_Run()

VimDesktop_TrayMenuCreate() {
    global VimDesktop_TrayMenu
    VimDesktop_TrayMenu := A_TrayMenu
    VimDesktop_TrayMenu.delete()
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Manager"], VimDesktop_TrayHandler)
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Setting"], VimDesktop_TrayHandler)
    VimDesktop_TrayMenu.Add() ; 添加分隔符

    ; 添加扩展功能子菜单
    extensionsMenu := Menu()
    extensionCount := 0

    try {
        ; 读取扩展功能配置
        if (INIObject.HasOwnProp("extensions")) {
            for key, value in INIObject.extensions.OwnProps() {
                if (key != "__Class" && key != "EasyIni_KeyComment" && key != "EasyIni_SectionComment") {
                    ; 解析配置值（脚本路径|自动启动标志）
                    configParts := StrSplit(value, "|")
                    scriptPath := configParts[1]
                    autoStart := (configParts.Length > 1) ? configParts[2] : "0"

                    ; 添加菜单项，显示自动启动状态
                    menuText := key . (autoStart = "1" ? " ●" : "")
                    extensionsMenu.Add(menuText, VimDesktop_ExtensionHandler)
                    extensionCount++
                }
            }
        }
    } catch Error as e {
        ; 如果出错，添加错误提示
        extensionsMenu.Add("配置读取错误", (*) => MsgBox("错误：" e.Message, "配置错误", "OK Icon!"))
    }

    ; 如果没有找到任何扩展功能，添加提示项
    if (extensionCount == 0) {
        extensionsMenu.Add("暂无扩展功能", (*) => MsgBox("请在配置文件的[extensions]节中添加扩展功能", "提示", "OK"))
    }

    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Extensions"], extensionsMenu)
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["EditCustom"], VimDesktop_TrayHandler)
    VimDesktop_TrayMenu.Add() ; 添加分隔符
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Reload"], (*) => Reload())
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Exit"], VimDesktop_ExitHandler)
    VimDesktop_TrayMenu.ClickCount := 2
    VimDesktop_TrayMenu.default := Lang["TrayMenu"]["Default"]
    A_IconTip := "VimDesktopV2_BoBO`n版本:1.1(By_Kawvin Mod_BoBO)"
}

; 自动启动扩展功能
VimDesktop_AutoStartExtensions() {
    global VimDesktop_ExtensionPIDs ; 使用全局的进程ID映射表
    
    try {
        if (INIObject.HasOwnProp("extensions")) {
            autoStartCount := 0
            for key, value in INIObject.extensions.OwnProps() {
                if (key != "__Class" && key != "EasyIni_KeyComment" && key != "EasyIni_SectionComment") {
                    ; 解析配置值（脚本路径|自动启动标志）
                    configParts := StrSplit(value, "|")
                    scriptPath := configParts[1]
                    autoStart := (configParts.Length > 1) ? configParts[2] : "0"

                    ; 如果设置为自动启动
                    if (autoStart = "1") {
                        fullScriptPath := A_ScriptDir scriptPath

                        ; 检查文件是否存在
                        if (FileExist(fullScriptPath)) {
                            try {
                                ; 根据文件扩展名选择执行方式
                                if (InStr(scriptPath, ".exe")) {
                                    ; 直接运行exe文件
                                    pid := Run(Format('"{1}"', fullScriptPath), , , &processId)
                                    VimDesktop_ExtensionPIDs[key] := processId
                                } else {
                                    ; 使用AutoHotkey运行ahk文件
                                    ahkPath := A_ScriptDir "\Apps\AutoHotkey.exe"
                                    pid := Run(Format('"{1}" "{2}"', ahkPath, fullScriptPath), , , &processId)
                                    VimDesktop_ExtensionPIDs[key] := processId
                                }
                                autoStartCount++
                            } catch Error as runError {
                                if (INIObject.config.enable_debug) {
                                    MsgBox("启动扩展功能失败：" key " - " runError.Message, "调试信息", "OK Icon!")
                                }
                            }
                        }
                    }
                }
            }

            ; 如果有自动启动的扩展，显示提示（可选）
            if (autoStartCount > 0 && VimDesktop_Global.default_enable_show_info) {
                ; 使用延时显示，避免阻塞主程序启动
                SetTimer(VimDesktop_ShowAutoStartInfo.Bind(autoStartCount), -1000) ; 1秒后显示
            }
        }
    } catch Error as e {
        ; 自动启动失败不影响主程序运行，只记录错误
        if (INIObject.config.enable_debug) {
            MsgBox("自动启动扩展功能时出错：" e.Message, "调试信息", "OK Icon!")
        }
    }
}

; 显示自动启动信息
VimDesktop_ShowAutoStartInfo(count) {
    try {
        ; 这里可以使用你的提示系统显示信息
        ; MsgBox("已自动启动 " count " 个扩展功能", "提示", "OK T2")
    } catch {
        ; 忽略显示错误
    }
}

#y:: Reload()

VimDesktop_TrayHandler(Item, *) {
    switch Item {
        case Lang["TrayMenu"]["Manager"]:
            VimDConfig_KeyMapEdit()
        case Lang["TrayMenu"]["Setting"]:
            run VimDesktop_Global.ConfigPath
        case Lang["TrayMenu"]["EditCustom"]:
            try
                run Format("{1} .\Custom\Custom.ahk", VimDesktop_Global.Editor)
    }
}

; 扩展功能处理函数
VimDesktop_ExtensionHandler(ItemName, *) {
    try {
        ; 移除菜单项中的自动启动标识符（●）
        cleanItemName := StrReplace(ItemName, " ●", "")

        ; 从配置中获取对应的脚本路径
        if (INIObject.HasOwnProp("extensions") && INIObject.extensions.HasOwnProp(cleanItemName)) {
            configValue := INIObject.extensions.%cleanItemName%

            ; 解析配置值（脚本路径|自动启动标志）
            configParts := StrSplit(configValue, "|")
            scriptPath := configParts[1]

            ; 构建完整路径
            fullScriptPath := A_ScriptDir scriptPath

            ; 检查文件是否存在
            if (FileExist(fullScriptPath)) {
                ; 根据文件扩展名选择执行方式
                if (InStr(scriptPath, ".exe")) {
                    ; 直接运行exe文件
                    Run(Format('"{1}"', fullScriptPath))
                } else {
                    ; 使用AutoHotkey运行ahk文件
                    ahkPath := A_ScriptDir "\Apps\AutoHotkey.exe"
                    Run(Format('"{1}" "{2}"', ahkPath, fullScriptPath))
                }
            } else {
                MsgBox("文件不存在：" fullScriptPath, "错误", "OK Icon!")
            }
        }
    } catch Error as e {
        MsgBox("执行扩展功能时出错：" e.Message, "错误", "OK Icon!")
    }
}

; 退出处理函数 - 关闭所有自动启动的扩展功能
VimDesktop_ExitHandler(*) {
    try {
        ; 关闭所有自动启动的扩展功能进程
        if (IsSet(VimDesktop_ExtensionPIDs)) {
            for extensionName, pid in VimDesktop_ExtensionPIDs {
                try {
                    ; 尝试优雅关闭进程
                    if (ProcessExist(pid)) {
                        ProcessClose(pid)
                        ; 等待一小段时间让进程正常关闭
                        Sleep(100)
                        
                        ; 如果进程仍然存在，强制终止
                        if (ProcessExist(pid)) {
                            Run("taskkill /F /PID " pid, , "Hide")
                        }
                    }
                } catch {
                    ; 忽略关闭进程时的错误，继续处理下一个
                }
            }
        }
        
        ; 清理临时文件
        try {
            FileDelete(A_Temp "\vimd_auto.ini")
        } catch {
            ; 忽略删除临时文件的错误
        }
        
    } catch Error as e {
        ; 即使清理失败也要退出程序
        if (INIObject.config.enable_debug) {
            MsgBox("清理扩展功能时出错：" e.Message, "调试信息", "OK Icon!")
        }
    }
    
    ; 退出主程序
    ExitApp()
}

VimDesktop_ThemeHandler(ItemName, ItemPos, MyMenu) {
    global VimDesktop_TrayMenu

    ; 取消所有选中状态
    MyMenu.Uncheck("明亮模式 ⚪")
    MyMenu.Uncheck("暗黑模式 ⚫")
    MyMenu.Uncheck("跟随系统 🔄")

    ; 选中当前项
    MyMenu.Check(ItemName)

    ; 根据选择设置主题
    switch ItemName {
        case "明亮模式 ⚪":
            ; 设置为明亮模式
            WindowsTheme.SetAppMode(false)
            ; 更新配置文件
            INIObject.config.theme_mode := "light"
            INIObject.save()

        case "暗黑模式 ⚫":
            ; 设置为暗黑模式
            WindowsTheme.SetAppMode(true)
            ; 更新配置文件
            INIObject.config.theme_mode := "dark"
            INIObject.save()

        case "跟随系统 🔄":
            ; 设置为跟随系统
            WindowsTheme.SetAppMode("Default")
            ; 更新配置文件
            INIObject.config.theme_mode := "system"
            INIObject.save()
    }
}

#Include .\core\Main.ahk
#Include .\core\class_vim.ahk
#Include .\core\VimDConfig.ahk
#Include .\Lib\Class_JSON.Ahk
#Include .\lib\class_EasyIni.ahk
#Include .\lib\DynamicFileMenu.ahk
#Include .\lib\MD_Gen.ahk
#Include .\lib\SingleDoubleLongPress.ahk
#Include .\lib\ToolTipOptions.ahk
#Include .\lib\BTT.ahk
#Include .\lib\IME.ahk
#Include .\lib\UIA.ahk
#Include .\lib\UIA_Browser.ahk
#Include .\lib\AutoIMESwitcher.ahk
#Include .\lib\ToolTipManager.ahk
#Include .\lib\Run.ahk
#Include .\lib\Script.ahk
#Include .\lib\Logger.ahk
#Include .\lib\vimd_API.ahk
#Include .\lib\WindowsTheme.ahk
#Include .\lib\MemoryOptimizer.ahk
#Include .\lib\RegisterPluginKeys.ahk
#Include .\plugins\plugins.ahk
; 用户自定义配置
#Include *i .\custom\custom.ahk