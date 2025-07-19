#singleinstance off
#Include %A_ScriptDir%\lib\Class_ImageButton.ahk
#NoTrayIcon
now:=A_TickCount
kk:=0
GoSub, getParams
Return

; process command line parameters -- DEBUG: optional (see above)
getParams:
  If 0 > 0
     Loop, %0% ; for each parameter
     {
        param := %A_Index%
				if kk
				ico=%param%
				else
				Address=`"%param%`"
				kk++
			}

gui launch: New , , Q_launch%now%
Gui launch: +AlwaysOnTop +ToolWindow  ;-Caption 
gui launch: Color, EEAA99
;gui launch: Add, picture,w30 h30, %ico%
Gui launch: Add, Button, vBT4 gopenlink x0 y0 w60 h60 hwndHBT4

ext:=SubStr(ico, -2)
;假设变量ico已经被赋值为一个文件路径
if ext != "ico" and ext != "ICO" ;如果ico的后缀名不是ico
{
    if ext in exe,dll,EXE,DLL ;如果ico的扩展名是exe或dll
    {
			ico:=LoadPicture(ico,"Icon1")
    }
}

Opt1 := [0, ico]                                          ; normal image
;Opt2 := {2: ico}                         ; hot image (object syntax)
If !ImageButton.Create(HBT4, Opt1) ;, Opt2)
   ToolTip, 0, ImageButton Error Btn4, % ImageButton.LastError
gui launch: Show, w60 h60
WinSet, TransColor, EEAA99 200, Q_launch%now%
WinSet, ExStyle, +0x08000000,Q_launch%now%
return

launchGuiClose:
ExitApp

openlink:
{
	run %Address%
}
return