#requires AutoHotkey v2.0

/*
    程序: TC自动扩大本侧窗口比例
    作用: TC自动扩大本侧窗口比例，可自动设置比例
    作者: Kawvin(285781427@qq.com)，一壶浊酒
    版本: 0.4_2025.06.19
    AHK版本: 2.0.18
    测试环境: Win11
    使用方法: 如果已运行，第二次运行则退出本脚本
	*/

#SingleInstance force
DetectHiddenWindows true
#NoTrayIcon
SetControlDelay 0

;如果已运行，第二次运行则退出本脚本
global RunMarkIni:= RegExReplace(A_ScriptFullPath, "\.ahk$", ".ini")
global CurrentFocusThis:=""
IsRun:=iniRead(RunMarkIni, "通用设置", "是否运行", 0)
if (IsRun=1){
	IniWrite 0, RunMarkIni, "通用设置", "是否运行"
	GoPercentX(0.5)
	ExitApp
} else {
	IniWrite 1, RunMarkIni, "通用设置", "是否运行"
}

while WinExist("ahk_class TTOTAL_CMD"){
	WinWaitActive "ahk_class TTOTAL_CMD"
	;获取控件的位置和大小
	ControlGetPos &OutX, &OutY, &wBar, &hBar, "Window1", "ahk_class TTOTAL_CMD"
	CurrentFocus:=ControlGetClassNN(ControlGetFocus("ahk_class TTOTAL_CMD"), "ahk_class TTOTAL_CMD")
	If ((wBar < hBar) && (CurrentFocusThis != CurrentFocus) && WinActive("ahk_class TTOTAL_CMD")){
		If (CurrentFocus = "LCLListBox2") {
			GoPercentX(0.7)
		} else If (CurrentFocus = "LCLListBox1") {
			GoPercentX(0.3)			
		}
	}
	If ((wBar > hBar) && (CurrentFocusThis != CurrentFocus) && WinActive("ahk_class TTOTAL_CMD")){
		If (CurrentFocus = "LCLListBox2") {
			GoPercentY(0.6)
		} else If (CurrentFocus = "LCLListBox1") {
			GoPercentY(0.4)
		}
	}
	CurrentFocusThis := CurrentFocus
}

GoPercentX(Percent:=0.5) {	;改变左右方向的比例
	;获取指定窗口的位置和大小.
	WinGetPos &OutX, &OutY, &wTC, &hTC, "ahk_class TTOTAL_CMD"
	ControlMove  Round(Percent*wTC), , , , "Window1", "ahk_class TTOTAL_CMD"
	ControlClick "Window1", "ahk_class TTOTAL_CMD"
	WinActivate "ahk_class TTOTAL_CMD"
}

GoPercentY(Percent:=0.5) {	;改变上下方向的比例
	;获取指定窗口的位置和大小.
	WinGetPos &OutX, &OutY, &wTC, &hTC, "ahk_class TTOTAL_CMD"
	ControlMove , Round(Percent*hTC), , , "Window1", "ahk_class TTOTAL_CMD"
	ControlClick "Window1", "ahk_class TTOTAL_CMD"
	WinActivate "ahk_class TTOTAL_CMD"
}



