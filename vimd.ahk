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

global VimDesktop_Global:=Object()
global Vim:=Object()
global INIObject:=Object()
global Lang:=Object()

VimDesktop_Global.ConfigPath:=A_ScriptDir "\Custom\vimd.ini"
VimDesktop_Global.Editor:=FileExist("D:\Program Files\Microsoft VS Code\Code.exe") ? "D:\Program Files\Microsoft VS Code\Code.exe" : "NotePad.exe"
VimDesktop_Global.default_enable_show_info :=""
VimDesktop_Global.WshShell:=""
VimDesktop_Global.__vimLastAction:=""
VimDesktop_Global.showToolTipStatus:=0
VimDesktop_Global.Current_KeyMap:=""

INIObject:=EasyINI(VimDesktop_Global.ConfigPath)
LangString:=FileRead(A_ScriptDir "\lang\" INIObject.config.lang ".json", "UTF-8")
Lang:=JSON.parse(LangString)

Try
	TraySetIcon(".\Custom\vimd.ico")

VimDesktop_TrayMenuCreate() ; 生成托盘菜单 
VimDesktop_Run()

VimDesktop_TrayMenuCreate(){
    global VimDesktop_TrayMenu
    VimDesktop_TrayMenu := A_TrayMenu
    VimDesktop_TrayMenu.delete()
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Manager"], VimDesktop_TrayHandler)
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Setting"], VimDesktop_TrayHandler)
    VimDesktop_TrayMenu.Add() ; 添加分隔符
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["EditCustom"], VimDesktop_TrayHandler)
    VimDesktop_TrayMenu.Add() ; 添加分隔符
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Reload"], (*)=>Reload())
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Exit"], (*)=>ExitApp())
    VimDesktop_TrayMenu.ClickCount := 2
    VimDesktop_TrayMenu.default:=Lang["TrayMenu"]["Default"]
    A_IconTip:="VimDesktop`n版本:vII_1.0(By_Kawvin)"
}

VimDesktop_TrayHandler(Item, *){
    switch Item
    {
        case Lang["TrayMenu"]["Manager"]:
            VimDConfig_KeyMapEdit()
        case Lang["TrayMenu"]["Setting"]:
            run VimDesktop_Global.ConfigPath
        case Lang["TrayMenu"]["EditCustom"]:
            try
                run Format("{1} .\Custom\Custom.ahk", VimDesktop_Global.Editor)
    }
}

#Include .\core\Main.ahk
#Include .\core\class_vim.ahk
#Include .\core\VimDConfig.ahk
#Include .\Lib\class_Json.ahk
#Include .\lib\class_EasyINI.ahk
#Include .\lib\DynamicFileMenu.ahk
#Include .\lib\SingleDoubleLongPress.ahk
#Include .\lib\ToolTipOptions.ahk
#Include .\lib\Run.ahk
#Include .\lib\Script.ahk
#Include .\lib\Logger.ahk
#Include .\lib\vimd_API.ahk
#Include .\plugins\plugins.ahk
; 用户自定义配置
#Include *i .\custom\custom.ahk
