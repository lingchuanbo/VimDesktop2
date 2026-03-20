#Requires AutoHotkey v2.0

; 自定义脚本总入口
; 保留此文件，兼容托盘菜单和配置界面的“编辑 Custom.ahk”入口。

#Include ..\libs\ToolTipEx.ahk

; 模块使用 *i 可选加载：
; 1. 不需要某个模块时，可以直接删除对应文件
; 2. 也可以只注释掉下面某一行 include
; 3. 仅需注意不要同时启用绑定同一热键的两个模块

; #Include *i .\custom\menu_demo.ahk
#Include *i .\custom\web_shortcuts.ahk
#Include *i .\custom\launcher.ahk
#Include *i .\custom\capture.ahk
#Include *i .\custom\close_all_exe.ahk
#Include *i .\custom\window_quick_adjust.ahk
; #Include *i .\custom\tooltip_tests.ahk
#Include *i .\custom\system_tools.ahk
