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

; ===== 所有模块（仅定义，无顶层副作用） =====
#Include .\core\Main.ahk
#Include .\core\Main.CommandHandlers.ahk
#Include .\core\Main.PluginHotKeys.ahk
#Include .\core\Main.PluginBootstrap.ahk
#Include .\core\Main.RuntimeConfig.ahk
#Include .\core\VimDConfig.ahk
#Include .\core\Tray.ahk
#Include .\core\Extensions.ahk
#Include .\core\HotReload.ahk
#Include ..\libs\PathResolver.ahk
#Include ..\libs\AppContext.ahk
#Include ..\libs\PluginCatalog.ahk
#Include ..\libs\Class_JSON.Ahk
#Include ..\libs\class_EasyIni.ahk
#Include ..\libs\ConfigService.ahk
#Include ..\libs\ConfigService.ChangeTracker.ahk
#Include ..\libs\ConfigService.SchemaRegistry.ahk
#Include ..\libs\DynamicFileMenu.ahk
#Include ..\libs\MD_Gen.ahk
#Include ..\libs\SingleDoubleLongPress.ahk
#Include ..\libs\ToolTipOptions.ahk
#Include ..\libs\BTT.ahk
#Include ..\libs\IME.ahk
#Include ..\libs\UIA.ahk
#Include ..\libs\AutoIMESwitcher.ahk
#Include ..\libs\ToolTipManager.ahk
#Include ..\libs\run.ahk
#Include ..\libs\Script.ahk
#Include ..\libs\Logger.ahk
#Include ..\libs\vimd_API.ahk
#Include ..\libs\WindowsTheme.ahk
#Include ..\libs\MemoryOptimizer.ahk
#Include ..\libs\RegisterPluginKeys.ahk
#Include ..\libs\VimD_Debug.ahk
#Include ..\plugins\plugins.ahk
; 用户自定义配置
#Include *i ..\config\Custom.ahk

; ===== 全局变量声明 =====
global App := AppContext.Create()
global VimDesktop_Global := App.Runtime
global INIObject := App.INIObject
global PluginConfigs := App.PluginConfigs
global Lang := App.Lang
global VimDesktop_ExtensionPIDs := App.ExtensionPIDs ; 存储扩展功能的进程ID
global VimDesktop_ExtensionAutoStartPaths := App.ExtensionAutoStartPaths ; 存储自动启动扩展的路径
global VimDesktop_ConfigHotReloadIntervalMs := App.ConfigHotReloadIntervalMs

global MAIN_PLUGIN_SCAN_INTERVAL_MS := 30000
global MAIN_MEMORY_OPT_INTERVAL_MS := 300000
global MAIN_CMD_CACHE_MAX := 100
global MAIN_PLUGIN_SKIP_REGEX := "i)^(config|exclude|global|plugins|EasyIni_KeyComment|EasyIni_SectionComment|EasyIni_ReservedFor_m_sFile|EasyIni_TopComments|default_Mode)$"
global MAIN_PLUGIN_SETTING_REGEX := "i)^(set_class|set_file|set_time_out|set_max_count|enable_show_info|enabled|EasyIni_KeyComment)$"

; ===== 初始化 =====
INIObject := EasyINI(VimDesktop_Global.ConfigPath)
VimDesktop_Global.default_enable_show_info := INIObject.config.default_enable_show_info
ConfigService.Init(INIObject, PluginConfigs)
LangString := FileRead(PathResolver.LangPath(INIObject.config.lang ".json"), "UTF-8")
Lang := JSON.parse(LangString)
ConfigService.ValidateAndReport(INIObject.config.enable_debug = 1)

try
    TraySetIcon(PathResolver.ConfigPath("vimd.ico"))

VimDesktop_TrayMenuCreate() ; 生成托盘菜单
VimDesktop_AutoStartExtensions() ; 自动启动扩展功能

; ===== 启动核心 =====
VimDesktop_Run()
VimDesktop_StartConfigHotReload()
