#SingleInstance force
#HotkeyInterval 5000
#MaxHotkeysPerInterval 2000
#Include %A_ScriptDir%/ahks/lib/ImagePut.ahk
#WinActivateForce
#NoTrayIcon

try
  FileMoveDir, Data\dog, Data\%A_UserName%, R
catch
  sleep,1

DetectHiddenWindows,on
CoordMode,mouse,screen
global pagenow
WinSetTitle, Program Manager ahk_class Progman, , 桌面
return

;win+n 打开ahk储存文件夹
#n::
{
    WinClose,CLaunch ahk_exe clahk.exe
		gosub, readname
		run %A_ScriptDir%\claunch.exe /n /m /l /p%pagenow%
  run %A_ScriptDir%/ahks
}
return

;win+f 悬浮鼠标下按钮
F12::
{
  MouseGetPos, , , id
  WinGet, exename, ProcessName , ahk_id %id%
  if (exename = "claunch.exe")
  {
  Click,Right
  sleep,200
  SendInput,{Up}{enter}
  sleep,5
  SendInput,{tab}
  clipboard:=""
  sendinput,^c
  ClipWait
  runpath=`"%clipboard%`"
  SendInput,!i
  sendinput,{tab}{tab}
  clipboard:=""
  sendinput,^c
  ClipWait,t1
  runico=`"%clipboard%`"
  sendinput,!{F4}
  sendinput,!{F4}
  ;msgbox,% runpath runico
  run "悬浮按钮.exe" %runpath% %runico%
  }
}
return

;截图后在claunch界面双击右键，快速换图标
~RButton::
if (A_PriorHotkey = "~RButton") and (A_TimeSincePriorHotkey < 500)
{
  MouseGetPos, , , id
  WinGet, exename, ProcessName , ahk_id %id%
  ;MsgBox,% exename
    
  if (exename = "claunch.exe")
  {
  nownow=%A_Now%
  try
    imageputfile(ClipboardAll,A_ScriptDir "/png转ico自动/png/" nownow ".png")
  catch
    sleep,1
  SendInput,{Up}{enter}
  sleep,5
  SendInput,!i
  sleep,30
  RunWait, %A_ScriptDir%/png转ico自动/png2ico.bat ,%A_ScriptDir%/png转ico自动/, Hide,
  clipboard=%A_ScriptDir%\png转ico自动\ico\%nownow%.ico
  return
  }
}
return

;鼠标侧键1为触发键，单击为一次性模式，略微长按为锁定模式，双击为打开常用页面
^MButton::
; XButton1::
if (A_PriorHotkey = "XButton1") and (A_TimeSincePriorHotkey < 800)
{
  run %A_ScriptDir%\claunch.exe /m /p1
  return
}
	KeyWait, MButton ;xbutton1
	If (A_TimeSinceThisHotkey < 200)
		{
    WinClose,CLaunch ahk_exe clahk.exe
		gosub, readname
		run %A_ScriptDir%\claunch.exe /n /m /p%pagenow%
		}
	Else
{
gosub,readname
if WinExist("CLaunch ahk_exe clahk.exe")
  WinClose,CLaunch ahk_exe clahk.exe
  nowid:=WinExist("A")
  run %A_ScriptDir%\clahk.exe /n /m /l /p%pagenow% /b4:7 ;可自行根据需求更改按钮数量排布
  WinWait,CLaunch ahk_exe clahk.exe
  WinSet, ExStyle, +0x08000000,CLaunch ahk_exe clahk.exe
  sleep,400
  WinActivate,ahk_id %nowid%
}
return

readname:
; 读取claunch.ini文件中的所有name信息，并存储在一个数组中
names := Array()
loop
{
notfind:="notfind"
nowpage:="page" . Format("{:03}", A_index-1)
IniRead, name, Data/%A_UserName%/CLaunch.ini, %nowpage%, Name ,% notfind
if name=notfind
  break
names.Push(name)
}
; 获取当前激活窗口的信息
WinGetActiveTitle, title
WinGetClass, class, A
WinGet, exe, ProcessName, A
exe := StrReplace(exe, ".exe")

; 与claunch.ini中的所有name信息依次比较，如果一致，则将对应的page编号赋值给变量pagenow
pagenow := 1 ; 如果没有匹配的name，pagenow为1
Loop, % names.MaxIndex()
{
    name := names[A_Index]
    If (name = exe or name = "c " . class or name = "t " . title)
    {
        pagenow := A_Index ; page编号从1开始
        Break
    }
}
;MsgBox, % "当前激活窗口的信息为：" . "`n" . "标题：" . title . "`n" . "类名：" . class . "`n" . "进程名：" . exe . "`n" . "匹配的page编号为：" . pagenow
return

OnExit:
WinSetTitle, 桌面 ahk_class Progman, , Program Manager