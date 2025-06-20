/*
[PluginInfo]
PluginName=VLCMediaPlayer
Author=Kawvin
Version=0.1_2025.06.18
Comment=VLCMediaPlayer播放器
*/

VLCMediaPlayer(){
    KeyArray:=Array()
	KeyArray.push({Key:"<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】"})

	KeyArray.push({Key:"<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】"})
	KeyArray.push({Key:"z", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "^{up}", Comment: "声音增大"})
	KeyArray.push({Key:"Z", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "^{down}", Comment: "声音减小"})
	KeyArray.push({Key:"x", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "{Volume_Up 2}", Comment: "系统声音增大"})
	KeyArray.push({Key:"X", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "{Volume_Down 2}", Comment: "系统声音减小"})
	KeyArray.push({Key:"<capslock>", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "{Volume_Mute}", Comment: "系统声音静音"})
    
	KeyArray.push({Key:"g", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "{space}", Comment: "播放_暂停"})
	KeyArray.push({Key:"w", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "n", Comment: "播放下一个"})
	KeyArray.push({Key:"W", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "p", Comment: "播放上一个"})
	KeyArray.push({Key:"s", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "+{right}", Comment: "快进5s"})
	KeyArray.push({Key:"S", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "+{left}", Comment: "快退5s"})
	KeyArray.push({Key:"<space>", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "!{right}", Comment: "快进10s"})
	KeyArray.push({Key:"v", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "!{left}", Comment: "快退10s"})
	KeyArray.push({Key:"f", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "^{right}", Comment: "快进1m"})
	KeyArray.push({Key:"F", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "^{left}", Comment: "快退1m"})
	KeyArray.push({Key:"d", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "^!{right}", Comment: "快进5m"})
	KeyArray.push({Key:"D", Mode: "VIM模式", Group: "播放", Func: "SendKeyInput", Param: "^!{left}", Comment: "快退5m"})
    
	KeyArray.push({Key:"r", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{]}", Comment: "倍速_加0.1"})
	KeyArray.push({Key:"R", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{[}", Comment: "倍速_减0.1"})
	KeyArray.push({Key:"t", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{] 5}", Comment: "倍速_加0.5"})
	KeyArray.push({Key:"T", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{[ 5}", Comment: "倍速_减0.5"})
	KeyArray.push({Key:"E", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{] 10}", Comment: "倍速_加1"})
	KeyArray.push({Key:"e", Mode: "VIM模式", Group: "倍速", Func: "SendKeyInput", Param: "{=}", Comment: "倍速_正常"})
    
	KeyArray.push({Key:"Q", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "!{f4}", Comment: "关闭程序"})
	KeyArray.push({Key:"b", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "f", Comment: "全屏"})
	KeyArray.push({Key:"<esc>", Mode: "VIM模式", Group: "控制", Func: "VLCMediaPlayer_隐藏程序", Param: "", Comment: "隐藏程序"})
	; KeyArray.push({Key:"*SS", Mode: "VIM模式", Group: "控制", Func: "VLCMediaPlayer_显示程序", Param: "", Comment: "显示程序"})
	KeyArray.push({Key:"q", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "!k", Comment: "旋转"})
    KeyArray.push({Key:"l", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "^l", Comment: "打开关闭列表"})
    KeyArray.push({Key:"y", Mode: "VIM模式", Group: "控制", Func: "VLCMediaPlayer_视图_总在最前", Param: "", Comment: "视图_总在最前"})
    KeyArray.push({Key:"1", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "!2", Comment: "缩放50%"})
    KeyArray.push({Key:"2", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "!3", Comment: "缩放100%"})
    KeyArray.push({Key:"3", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "!4", Comment: "缩放200%"})
    KeyArray.push({Key:"4", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "!1", Comment: "缩放25%"})
	
    vim.SetWin("VLCMediaPlayer", "", "vlc.exe")
    vim.SetTimeOut(500, "VLCMediaPlayer")
	for k, v in KeyArray{
        if (v.Key!="")
            vim.map(v.Key, "VLCMediaPlayer", v.Mode, v.Func, v.Param, v.Group, v.Comment)
	}
}

VLCMediaPlayer_隐藏程序(){
    WinMinimize "ahk_class Qt5QWindowIcon"
    sleep 50
    WinHide "ahk_class Qt5QWindowIcon"
}

VLCMediaPlayer_显示程序(){
    DetectHiddenWindows  "On"
    WinShow "ahk_class Qt5QWindowIcon"
}

VLCMediaPlayer_视图_总在最前(){
    SendInput "{Alt down}"
    sleep 200
    SendInput "i"
    sleep 200
    SendInput "t"
    sleep 200
    SendInput "{Alt up}"
}
