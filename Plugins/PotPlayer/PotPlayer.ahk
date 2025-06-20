/*
[PluginInfo]
PluginName=PotPlayer
Author=Kawvin
Version=0.1_2025.06.13
Comment=PotPlayer播放器
*/

global PotPlayer_DelArray:=[]

PotPlayer(){
	KeyArray:=Array()
	KeyArray.push({Key:"<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】"})

	KeyArray.push({Key:"<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】"})
	KeyArray.push({Key:"z", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "{up}", Comment: "声音增大"})
	KeyArray.push({Key:"Z", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "{down}", Comment: "声音减小"})
	KeyArray.push({Key:"x", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "{Volume_Up 2}", Comment: "系统声音增大"})
	KeyArray.push({Key:"X", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "{Volume_Down 2}", Comment: "系统声音减小"})
	KeyArray.push({Key:"<capslock>", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "{Volume_Mute}", Comment: "系统声音静音"})
    
	KeyArray.push({Key:"g", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "{space}", Comment: "播放_暂停"})
	KeyArray.push({Key:"w", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "{PgDn}", Comment: "播放下一个"})
	KeyArray.push({Key:"W", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "{PgUp}", Comment: "播放上一个"})
	KeyArray.push({Key:"s", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "{right}", Comment: "快进2s"})
	KeyArray.push({Key:"S", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "{left}", Comment: "快退2s"})
	KeyArray.push({Key:"<space>", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "^{right}", Comment: "快进15s"})
	KeyArray.push({Key:"v", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "^{left}", Comment: "快退15s"})
	KeyArray.push({Key:"f", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "+{right}", Comment: "快进1m"})
	KeyArray.push({Key:"F", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "+{left}", Comment: "快退1m"})
	KeyArray.push({Key:"d", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "^!{right}", Comment: "快进5m"})
	KeyArray.push({Key:"D", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "^!{left}", Comment: "快退5m"})
    
	KeyArray.push({Key:"r", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{c}", Comment: "倍速_加0.1"})
	KeyArray.push({Key:"R", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{x}", Comment: "倍速_减0.1"})
	KeyArray.push({Key:"t", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{c 5}", Comment: "倍速_加0.5"})
	KeyArray.push({Key:"T", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{x 5}", Comment: "倍速_减0.5"})
	KeyArray.push({Key:"E", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{c 10}", Comment: "倍速_加1"})
	KeyArray.push({Key:"e", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{z}", Comment: "倍速_正常"})
    
	; KeyArray.push({Key:"a", Mode: "VIM模式", Group: "删除", Func: "PotPlayer_标记", Param: "", Comment: "标记"})
	; KeyArray.push({Key:"A", Mode: "VIM模式", Group: "删除", Func: "PotPlayer_删除标记", Param: "", Comment: "删除标记"})
	; KeyArray.push({Key:"C", Mode: "VIM模式", Group: "删除", Func: "PotPlayer_删除当前", Param: "", Comment: "删除当前"})
	; KeyArray.push({Key:"B", Mode: "VIM模式", Group: "删除", Func: "PotPlayer_删除当前所在文件夹", Param: "", Comment: "删除当前所在文件夹"})

	KeyArray.push({Key:"Q", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "!{f4}", Comment: "关闭程序"})
	KeyArray.push({Key:"b", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "{Enter}", Comment: "全屏"})
	KeyArray.push({Key:"<esc>", Mode: "VIM模式", Group: "控制", Func: "PotPlayer_隐藏程序", Param: "", Comment: "隐藏程序"})
	; KeyArray.push({Key:"*SS", Mode: "VIM模式", Group: "控制", Func: "PotPlayer_显示程序", Param: "", Comment: "显示程序"})
	KeyArray.push({Key:"q", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "!k", Comment: "旋转"})
	KeyArray.push({Key:"l", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "l", Comment: "打开关闭列表"})

	; KeyArray.push({Key:"<F1>", Mode: "VIM模式", Group: "存档", Func: "PotPlayer_打开存档1", Param: "", Comment: "打开存档1"})
	; KeyArray.push({Key:"<F2>", Mode: "VIM模式", Group: "存档", Func: "PotPlayer_保存存档1", Param: "", Comment: "保存存档1"})
	; KeyArray.push({Key:"<F3>", Mode: "VIM模式", Group: "存档", Func: "PotPlayer_打开存档2", Param: "", Comment: "打开存档2"})
	; KeyArray.push({Key:"<F4>", Mode: "VIM模式", Group: "存档", Func: "PotPlayer_保存存档2", Param: "", Comment: "保存存档2"})

    KeyArray.push({Key:"1", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "1", Comment: "缩放50%"})
    KeyArray.push({Key:"2", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "2", Comment: "缩放100%"})
    KeyArray.push({Key:"3", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "4", Comment: "缩放200%"})
    KeyArray.push({Key:"4", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "!4", Comment: "缩放25%"})
    
    vim.SetWin("PotPlayer", "", "PotPlayerMini64.exe")
    vim.SetTimeOut(300, "PotPlayer")
	for k, v in KeyArray{
        if (v.Key!="")
            vim.map(v.Key, "PotPlayer", v.Mode, v.Func, v.Param, v.Group, v.Comment)
	}
}

PotPlayer_隐藏程序(){
    try
        WinMinimize "ahk_class PotPlayer"
    try
        WinMinimize "ahk_class PotPlayer64"
    sleep 50
    try
        WinHide "ahk_class PotPlayer"
    try
        WinHide "ahk_class PotPlayer64"
}

PotPlayer_显示程序(){
    try
        WinShow "ahk_class PotPlayer"
    try
        WinShow "ahk_class PotPlayer64"
}

/*
PotPlayer_删除当前(){
    Title:=WinGetTitle("A")
    PotTitle:=StrReplace(Title," - PotPlayer")
    str:="file:" PotTitle " ext:mkv;mp4;avi;rm;rmvb;ts;flv <Y:|Z:|F:|D:>"
    dPath:=EveryFindPath(str)
    MsgBox dPath
    ; try
    ;     FileDelete dPath
    MsgBox "已删除", "PotPlayer提示", "4160 T0.5"
}

PotPlayer_删除当前所在文件夹(){
    Title:=WinGetTitle("A")
    PotTitle:=StrReplace(Title," - PotPlayer")
    MsgRst:=MsgBox("确认删除" PotTitle "所在文件夹？", "询问", "4132")
    if (MsgRst="No") {
        Return
    }
    dPath:=EveryFindPath(PotTitle)
    SplitPath dPath,&MyOutFileName,&MyOutDir,&MyOutExt,&MyOutNameNoExt,&MyOutDrive
    MsgBox MyOutDir
    ; try
    ;     DirDelete  MyOutDir, 1
    MsgBox "已删除文件夹", "PotPlayer提示", "4160 T0.5"
}

PotPlayer_删除标记(){
    global tGui := Gui("+AlwaysOnTop", "PotPlayer删除")
    tGui.OnEvent("Escape", (*) => tGui.Destroy())
    tGui.OnEvent("Close",  (*) => tGui.Destroy())
    tGui.SetFont("s10", "Consolas")	;等宽字体
    LV1:=tGui.Add("ListView", "x10 y10 w500 h300 Checked vLV1", ["文件名","路径"])
    tGui.GetPos(&X, &Y, &Width, &Height)	;检索窗口的位置和大小
    tGui.Add("Button", "xm y+20 w80 h30 Default", "确定").OnEvent("Click", PotPlayer_删除)
    loop PotPlayer_DelArray.Length
    {
        TemFile:=PotPlayer_DelArray[A_Index]
        LV1.Add("check",TemFile*)
    }
    LV1.ModifyCol(1, 350)
	LV1.ModifyCol(2, 450)
    tGui.Show()
}

PotPlayer_删除(*){  
    RowNumber := 0  ; 这样使得首次循环从列表的顶部开始搜索.
    LV1:=tGui["LV1"]
    Loop
    {
        RowNumber := LV1.GetNext(RowNumber,"Checked")  ; 在前一次找到的位置后继续搜索.
        if not RowNumber  ; 上面返回零, 所以选择的行已经都找到了.
            break
        sFileName:=LV1.GetText(RowNumber,1)
        sFileDir:=LV1.GetText(RowNumber,2)
        dPath:=sFileDir "\" sFileName
        If(!FileExist(dPath)){
            dPath:=EveryFindPath(sFileName)
            SplitPath dPath, &MyOutFileName, &LastPath, &MyOutExt, &MyOutNameNoExt, &MyOutDrive
        }
        try
            ; FileDelete dPath
            MsgBox dPath
    }
    PotPlayer_DelArray:=[]
    try
        tGui.Destroy()
    MsgBox "已全部删除!", "提示", "4160 T0.5"
}

PotPlayer_标记(){
    dPath:=PotPlayer_GetCurFilePath()
    SplitPath dPath, &KyOutFileName, &KyOutDir, &KyOutExtension, &KyOutNameNoExt, &KyOutDrive

    PotPlayer_DelArray.push([KyOutFileName,KyOutDir])

    ; Title:=WinGetTitle("A")
    ; PotTitle:=StrReplace(Title," - PotPlayer")
    ; dPath:=EveryFindPath(PotTitle)
    ; PotPlayer_DelArray.push(PotTitle)
    MsgBox "已添加", "PotPlayer提示", "4160 T0.5"
}

PotPlayer_打开存档1(){
    SendInput "^!["
}

PotPlayer_打开存档2(){
    SendInput "^!]"
}

PotPlayer_保存存档1(){
    Sleep 300
    dPath:=PotPlayer_GetCurFilePath()
    ; MsgBox "dPath : " dPath
    if (dPath!="") {
        PotPlayerINI:=A_ScriptDir "\Custom\PotPlayer.ini"
        IniWrite dPath, PotPlayerINI, "历史记录", "最后打开1"
        MsgBox "已保存", "提示", "4160 T0.5"
    }
}

PotPlayer_保存存档2(){
    Sleep 300
    dPath:=PotPlayer_GetCurFilePath()
    ; MsgBox "dPath : " dPath
    dPath:=PotPlayer_GetCurFilePath()
    if (dPath!="") {
        PotPlayerINI:=A_ScriptDir "\Custom\PotPlayer.ini"
        IniWrite dPath, PotPlayerINI, "历史记录", "最后打开2"
        MsgBox "已保存", "提示", "4160 T0.5"
    }
}

PotPlayer_GetCurFilePath(){
    ;~ Sleep,500
    WinActivate "ahk_class PotPlayer64"
    Sleep 300
    title:=WinGetTitle("A")
    _title:=StrReplace(title," - PotPlayer")
    PostMessage 0x111,10158, 0, , "A"
    WinWaitActive "ahk_class #32770",,3
    If WinActive("ahk_class #32770"){
        sleep 100
        str:=WinGetText("A")
    }
    WinClose
    RegExMatch(str, "m)^地址:(.*?)$", &_thePath)
    Rst_dPath:=Trim(_thePath[1]) "\" _title
    return Rst_dPath
}

*/

