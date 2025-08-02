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
global Lang := Object()

VimDesktop_Global.ConfigPath := A_ScriptDir "\Custom\vimd.ini"
VimDesktop_Global.Editor := FileExist("D:\Program Files\Microsoft VS Code\Code.exe") ?
    "D:\Program Files\Microsoft VS Code\Code.exe" : "NotePad.exe"
VimDesktop_Global.default_enable_show_info := ""
VimDesktop_Global.WshShell := ""
VimDesktop_Global.__vimLastAction := ""
VimDesktop_Global.showToolTipStatus := 0
VimDesktop_Global.Current_KeyMap := ""

INIObject := EasyINI(VimDesktop_Global.ConfigPath)
LangString := FileRead(A_ScriptDir "\lang\" INIObject.config.lang ".json", "UTF-8")
Lang := JSON.parse(LangString)

try
    TraySetIcon(".\Custom\vimd.ico")

VimDesktop_TrayMenuCreate() ; 生成托盘菜单

VimDesktop_Run()

VimDesktop_TrayMenuCreate() {
    global VimDesktop_TrayMenu
    VimDesktop_TrayMenu := A_TrayMenu
    VimDesktop_TrayMenu.delete()
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Manager"], VimDesktop_TrayHandler)
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Setting"], VimDesktop_TrayHandler)
    VimDesktop_TrayMenu.Add() ; 添加分隔符

    ; ; 添加主题子菜单
    ; themeMenu := Menu()
    ; themeMenu.Add("明亮模式 ⚪", VimDesktop_ThemeHandler)
    ; themeMenu.Add("暗黑模式 ⚫", VimDesktop_ThemeHandler)
    ; themeMenu.Add("跟随系统 🔄", VimDesktop_ThemeHandler)

    ; 根据当前设置选中对应的主题
    ; try {
    ;     currentTheme := INIObject.config.theme_mode
    ;     if (currentTheme = "light")
    ;         themeMenu.Check("明亮模式 ⚪")
    ;     else if (currentTheme = "dark")
    ;         themeMenu.Check("暗黑模式 ⚫")y
    ;     else
    ;         themeMenu.Check("跟随系统 🔄")
    ; } catch {
    ;     themeMenu.Check("跟随系统 🔄")
    ; }

    ; VimDesktop_TrayMenu.Add("主题", themeMenu)
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["EditCustom"], VimDesktop_TrayHandler)
    VimDesktop_TrayMenu.Add() ; 添加分隔符
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Reload"], (*) => Reload())
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Exit"], (*) => ExitApp())
    VimDesktop_TrayMenu.ClickCount := 2
    VimDesktop_TrayMenu.default := Lang["TrayMenu"]["Default"]
    A_IconTip := "VimDesktop`n版本:vII_1.0(By_Kawvin)"
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
#Include .\Lib\class_Json.ahk
#Include .\lib\class_EasyINI.ahk
#Include .\lib\DynamicFileMenu.ahk
#Include .\lib\MD_Gen.ahk
#Include .\lib\SingleDoubleLongPress.ahk
#Include .\lib\ToolTipOptions.ahk
#Include .\lib\BTT_Optimized_v3.ahk
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