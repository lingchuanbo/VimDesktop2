/*
	[PluginInfo]
    PluginName=GridPlayer
    Author=Kawvin
    Version=0.1_2025.06.18
	Comment=GridPlayer播放器
*/

GridPlayer(){
	KeyArray:=Array()
	KeyArray.push({Key:"<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】"})
	KeyArray.push({Key:"<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】"})
	KeyArray.push({Key:"r", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{+c}", Comment: "倍速+0.1"})
	KeyArray.push({Key:"t", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{+c 5}", Comment: "倍速+0.5"})
	KeyArray.push({Key:"E", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{+c 10}", Comment: "倍速+1.0"})
	KeyArray.push({Key:"R", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{+x}", Comment: "倍速-0.1"})
	KeyArray.push({Key:"T", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{+x 5}", Comment: "倍速-0.5"})
	KeyArray.push({Key:"s", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "^+{Right}", Comment: "快进+5s"})
	KeyArray.push({Key:"<space>", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "^+]", Comment: "快进+15s"})
	KeyArray.push({Key:"d", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "^+'", Comment: "快进+30s"})
	KeyArray.push({Key:"S", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "^+{Left}]", Comment: "快退-5s"})
	KeyArray.push({Key:"v", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "^+[]", Comment: "快退-15s"})
	KeyArray.push({Key:"D", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "^+;", Comment: "快退-30s"})
	KeyArray.push({Key:"g", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "{space}", Comment: "播放/暂停"})
	KeyArray.push({Key:"b", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "f", Comment: "全屏"})
	; KeyArray.push({Key:"NumPad1", Mode: "VIM模式", Group: "多屏", Func: "SendKeyInput", Param: 1, Comment: "1屏同播"})
	; KeyArray.push({Key:"NumPad2", Mode: "VIM模式", Group: "多屏", Func: "SendKeyInput", Param: 2, Comment: "2屏同播"})
	; KeyArray.push({Key:"NumPad3", Mode: "VIM模式", Group: "多屏", Func: "SendKeyInput", Param: 3, Comment: "3屏同播"})
	; KeyArray.push({Key:"NumPad4", Mode: "VIM模式", Group: "多屏", Func: "SendKeyInput", Param: 4, Comment: "4屏同播"})
	; KeyArray.push({Key:"NumPad6", Mode: "VIM模式", Group: "多屏", Func: "SendKeyInput", Param: 6, Comment: "6屏同播"})
	; KeyArray.push({Key:"NumPad8", Mode: "VIM模式", Group: "多屏", Func: "SendKeyInput", Param: 8, Comment: "8屏同播"})
	; KeyArray.push({Key:"NumPad9", Mode: "VIM模式", Group: "多屏", Func: "SendKeyInput", Param: 9, Comment: "9屏同播"})
	; KeyArray.push({Key:"NumPadEnter", Mode: "VIM模式", Group: "多屏", Func: "SendKeyInput", Param: "N", Comment: "播放下一组"})
	; KeyArray.push({Key:"NumPadAdd", Mode: "VIM模式", Group: "多屏", Func: "SendKeyInput", Param: "P", Comment: "播放上一组"})

	vim.SetWin("GridPlayer", "", "GridPlayer.exe")
    vim.SetTimeOut(500, "GridPlayer")

	for k, v in KeyArray{
		if (v.Key!="")
            vim.map(v.Key, "GridPlayer", v.Mode, v.Func, v.Param, v.Group, v.Comment)
	}
}

; GridPlayer_MakePlayList(HotkeyName,GridPlayerCount*){
; 	MsgBox GridPlayerCount[1]
; 	sleep 1000
; 	SendInput "^+q"	;关闭播放列表
; 	GridPlayerApp:="D:\KawvinApps\视频相关\GridPlayer\GridPlayer.exe"
; 	GridPlayerPlayList:=""
; 	static GridPlayerIndex:=1
; 	static Last_GridPlayerCount:=1
; 	if (IsDigit(GridPlayerCount)){
; 		Last_GridPlayerCount:=GridPlayerIndex
; 	} else if (GridPlayerCount = "N"){
; 		GridPlayerIndex+=Last_GridPlayerCount
; 		if (GridPlayerIndex>GridPlayerArray.Length){
; 			MsgBox "已到播放清单尾部", "提示", "4160 T1"
; 			GridPlayerIndex-=GridPlayerCount
; 			return
; 		}
; 	} else if (GridPlayerCount = "P"){
; 		GridPlayerIndex-=Last_GridPlayerCount
; 		if (GridPlayerIndex<1)
; 			GridPlayerIndex:=1
; 	}

; 	loop Last_GridPlayerCount
; 	{
; 		if (GridPlayerArray[GridPlayerIndex-1+A_index] !=""){
; 			GridPlayerPlayList:= GridPlayerPlayList Format('"{1}" ', GridPlayerArray[GridPlayerIndex-1+A_index])
; 			; GridPlayerIndex+=1
; 		}
; 	}
; 	MyCmdLine:=Format('"{1}" {2}',GridPlayerApp,GridPlayerPlayList)
; 	; MsgBox MyCmdLine
; 	run MyCmdLine
; 	; sleep,3000
; 	WinWaitActive "ahk_class Qt5152QWindowIcon", , 3
; 	aHwnd:=WinGetID("ahk_class Qt5152QWindowIcon")
; 	; MsgBox aHwnd
; 	sleep 300
; 	wTitle:="GridPlayer [(" GridPlayerIndex "-" GridPlayerIndex-1+GridPlayerCount ")/" GridPlayerArray.length() "]"
; 	WinSetTitle "ahk_id " aHwnd, , wTitle
; }