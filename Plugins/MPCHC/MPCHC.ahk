/*
[PluginInfo]
PluginName=MPCHC
Author=Kawvin
Version=0.1_2025.06.13
Comment=MPC播放器
*/

MPCHC(){
    KeyArray:=Array()
	KeyArray.push({Key:"<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】"})

	KeyArray.push({Key:"<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】"})
	KeyArray.push({Key:"z", Mode: "VIM模式", Group: "音量", Func: "MPCHC_SendPos", Param: 907, Comment: "声音增大"})
	KeyArray.push({Key:"Z", Mode: "VIM模式", Group: "音量", Func: "MPCHC_SendPos", Param: 908, Comment: "声音减小"})
	KeyArray.push({Key:"x", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "{Volume_Up 2}", Comment: "系统声音增大"})
	KeyArray.push({Key:"X", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "{Volume_Down 2}", Comment: "系统声音减小"})
	KeyArray.push({Key:"<capslock>", Mode: "VIM模式", Group: "音量", Func: "SendKeyInput", Param: "{Volume_Mute}", Comment: "系统声音静音"})
    
	KeyArray.push({Key:"g", Mode: "VIM模式", Group: "播放", Func: "MPCHC_SendPos", Param: 889, Comment: "播放_暂停"})
	KeyArray.push({Key:"w", Mode: "VIM模式", Group: "播放", Func: "MPCHC_SendPos", Param: 922, Comment: "播放下一个"})
	KeyArray.push({Key:"W", Mode: "VIM模式", Group: "播放", Func: "MPCHC_SendPos", Param: 921, Comment: "播放上一个"})
	KeyArray.push({Key:"s", Mode: "VIM模式", Group: "播放", Func: "MPCHC_SendPos", Param: 900, Comment: "快进2s"})
	KeyArray.push({Key:"S", Mode: "VIM模式", Group: "播放", Func: "MPCHC_SendPos", Param: 899, Comment: "快退2s"})
	KeyArray.push({Key:"<space>", Mode: "VIM模式", Group: "播放", Func: "MPCHC_SendPos", Param: 902, Comment: "快进15s"})
	KeyArray.push({Key:"v", Mode: "VIM模式", Group: "播放", Func: "MPCHC_SendPos", Param: 901, Comment: "快退15s"})
	KeyArray.push({Key:"f", Mode: "VIM模式", Group: "播放", Func: "MPCHC_SendPos", Param: 904, Comment: "快进1m"})
	KeyArray.push({Key:"F", Mode: "VIM模式", Group: "播放", Func: "MPCHC_SendPos", Param: 903, Comment: "快退1m"})
	KeyArray.push({Key:"d", Mode: "VIM模式", Group: "播放", Func: "MPCHC_SendPos", Param: 898, Comment: "快进5m"})
	KeyArray.push({Key:"D", Mode: "VIM模式", Group: "播放", Func: "MPCHC_SendPos", Param: 897, Comment: "快退5m"})
    
	; KeyArray.push({Key:"r", Mode: "VIM模式", Group: "倍速", Func: "MPCHC_SendPos", Param: "{c}", Comment: "倍速_加0.1"})
	; KeyArray.push({Key:"R", Mode: "VIM模式", Group: "倍速", Func: "MPCHC_SendPos", Param: "{x}", Comment: "倍速_减0.1"})
	KeyArray.push({Key:"t", Mode: "VIM模式", Group: "倍速", Func: "MPCHC_SendPos", Param: 895, Comment: "倍速_乘2(双倍)"})
	KeyArray.push({Key:"T", Mode: "VIM模式", Group: "倍速", Func: "MPCHC_SendPos", Param: 894, Comment: "倍速_除2(50%)"})
	; KeyArray.push({Key:"E", Mode: "VIM模式", Group: "倍速", Func: "MPCHC_SendPos<2>", Param: 895, Comment: "倍速_加1"})
	KeyArray.push({Key:"e", Mode: "VIM模式", Group: "倍速", Func: "MPCHC_SendPos", Param: 896, Comment: "倍速_正常"})
    
	KeyArray.push({Key:"Q", Mode: "VIM模式", Group: "控制", Func: "MPCHC_SendPos", Param: 816, Comment: "关闭程序"})
	KeyArray.push({Key:"b", Mode: "VIM模式", Group: "控制", Func: "MPCHC_SendPos", Param: 830, Comment: "全屏"})
	KeyArray.push({Key:"<esc>", Mode: "VIM模式", Group: "控制", Func: "MPCHC_隐藏程序", Param: "", Comment: "隐藏程序"})
	; KeyArray.push({Key:"*SS", Mode: "VIM模式", Group: "控制", Func: "MPCHC_显示程序", Param: "", Comment: "显示程序"})
	; KeyArray.push({Key:"q", Mode: "VIM模式", Group: "控制", Func: "MPCHC_SendPos", Param: "!k", Comment: "旋转"})
    KeyArray.push({Key:"l", Mode: "VIM模式", Group: "控制", Func: "MPCHC_SendPos", Param: 824, Comment: "打开关闭列表"})

	KeyArray.push({Key:"1", Mode: "VIM模式", Group: "控制", Func: "MPCHC_SendPos", Param: 832, Comment: "缩放50%"})
    KeyArray.push({Key:"2", Mode: "VIM模式", Group: "控制", Func: "MPCHC_SendPos", Param: 833, Comment: "缩放100%"})
    KeyArray.push({Key:"3", Mode: "VIM模式", Group: "控制", Func: "MPCHC_SendPos", Param: 834, Comment: "缩放200%"})
    KeyArray.push({Key:"4", Mode: "VIM模式", Group: "控制", Func: "MPCHC_SendPos", Param: 813, Comment: "缩放25%"})

    vim.SetWin("MPCHC", "MediaPlayerClassicW", "mpc-hc64.exe")
    vim.SetTimeOut(500, "MPCHC")
	for k, v in KeyArray{
        if (v.Key!="")
            vim.map(v.Key, "MPCHC", v.Mode, v.Func, v.Param, v.Group, v.Comment)
	}
}

MPCHC_隐藏程序(){
    WinMinimize "ahk_class MediaPlayerClassicW"
    sleep 50
    WinHide "ahk_class MediaPlayerClassicW"
}

MPCHC_显示程序(){
    DetectHiddenWindows  "On"
    WinShow "ahk_class MediaPlayerClassicW"
}

MPCHC_SendPos(aID){
    ;WM_COMMAND := 0x0111  ; 点击菜单, 点击子窗口按钮.
    SendMessage  0x111, aID, 0, , "ahk_class MediaPlayerClassicW"
}

/*
play;887
pause;888
play/pause;889
stop;890
Frame Forward;891
Frame Backward;892
Increase Rate;895
Decrease rate;894
Audio Delay +10ms;905
Audio Delay -10ms;906
Jump Forward Small;900
Jump Backward Small;899
Jump Forward Medium;902
Jump Backward Medium;901
Jump Forward Large;904
Jump Backward Large;903
Jump Forward Keyframe;898
Jump Backward Keyframe;897
Next;921
Previous;920
Next Playlist Item;919
Previous Playlist Item;918
Toggle Caption & Menu;817
Toggle Seeker;818
Toggle Controls;819
Toggle Information;820
Toggle Statistics;821
Toggle Status;822
Toggle SubResync Bar;823
Toggle Playlist;824
Toggle Capture Bar;825
View Minimal;827
View Compact;828
View Normal;829
Fullscreen;830
Fullscreen (no res change);831
zoom 50%;832
zoom 100%;833
zoom 200%;834
Always on Top;884
Volume Up;907
Volume Down;908
Volume Mute;909
DVD Title Menu;922
DVD Root Menu;923
DVD Menu Activate(Enter);932
DVD Menu Left;928
DVD Menu Right;929
DVD Menu Up;930
DVD Menu Down;931
DVD Menu Back;933
Filters Menu;950
Player Menu (long);949
Player Menu (short);948
Boss Button;943
DVD Menu Leave;934
DVD Chapter Menu;927
DVD Angle Menu;926
DVD Audio Menu;925
Subs On/Off;955
Previous Subtitle;954
Next Subtitle;953
Previous Audio;952
Next Audio;951
Next Subtitle DVD;964
Previous Audio DVD;963
Next Audio DVD;962
Previous Angle DVD;961
Next Angle DVD;960
Previous Subtitle .OGM;959
Next Subtitle .OGM;958
Previous Audio .OGM;957
Next Audio .OGM;956
Reload Subtitles;973
Subtitles On/Off DVD;966
Previous Subtitle DVD;965
DVD Menu Subtitle;924
Options;886
Exit;816 
*/
