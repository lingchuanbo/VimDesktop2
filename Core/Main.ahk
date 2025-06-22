
VimDesktop_Run(){
    global vim := class_vim()
    VimDesktop_Global.default_enable_show_info := INIObject.config.default_enable_show_info
    VimDesktop_Global.Editor := INIObject.config.editor

    ; 给 check.ahk 使用
    IniWrite A_ScriptHwnd, A_Temp "\vimd_auto.ini", "auto", "hwnd"

    if (!FileExist(VimDesktop_Global.ConfigPath)) {
        FileCopy ".\Custom\vimd.ini.help.txt", VimDesktop_Global.ConfigPath
    }

    if (INIObject.config.enable_log == 1) {
        global logObject := Logger(A_ScriptDir "\debug.log")
    }

    if (INIObject.config.enable_debug == 1) {
        vim.Debug(true)
    }

    CheckPlugin()
    CheckHotKey()


    ; 用于接收来自 check.ahk 的信息
    OnMessage 0x4a, ReceiveWMCopyData
}

CheckPlugin(LoadAll:=0){
    ; 检测是否有新增插件
    HasNewPlugin:=false
    Loop Files, A_ScriptDir "\plugins\*", "D" {
        Plugin:=IniRead(VimDesktop_Global.ConfigPath, "plugins", A_LoopFileName, "")
        PluginFile:=A_ScriptDir "\plugins\" A_LoopFileName "\" A_LoopFileName ".ahk"
        if (Plugin = "ERROR" || Plugin=""){
            MsgBox Format(Lang["General"]["Plugin_New"], A_LoopFileName), Lang["General"]["Info"], "4160"
            if (FileExist(A_ScriptDir "\vimd.exe")){
                Run Format('{1}\vimd.exe {1}\plugins\check.ahk', A_ScriptDir)
            } else {
                Run A_ScriptDir "\plugins\check.ahk"
            }
            HasNewPlugin:=true
            _Sections:=INIObject.GetSections()
            if (!InStr(_Sections, "plugins")) {
                INIObject.AddSection("plugins")
            }
            if (!InStr(_Sections, "plugins_DefaultMode")) {
                INIObject.AddSection("plugins_DefaultMode")
            }
            Rst:=INIObject.AddKey("plugins", A_LoopFileName, 1)
            if !Rst
                INIObject.plugins.%A_LoopFileName%:=1
            _defaultMode:=RegExMatch(FileRead(PluginFile, "UTF-8"), 'im)Mode:\s*\"(.*?)\"', &m) ? m[1] : ""
            INIObject.AddSection("plugins_DefaultMode", A_LoopFileName, _defaultMode)
            Rst:=INIObject.AddKey("plugins_DefaultMode", A_LoopFileName, _defaultMode)
            if !Rst
                INIObject.plugins_DefaultMode.%A_LoopFileName%:=_defaultMode
            Sleep 1000
        }
    }
    if HasNewPlugin{
        INIObject.save()
        Reload()
    }

    ;加载插件
    for plugin, flag in INIObject.plugins.OwnProps() {
        if plugin="EasyIni_KeyComment"
            continue
        If (fileExist(A_ScriptDir "\plugins\" plugin "\" plugin ".ahk")){
            if (LoadAll){
                vim.LoadPlugin(plugin)
                vim.GetWin(plugin).status:=flag
            } else {
                if (flag){
                    vim.LoadPlugin(plugin)
                    vim.GetWin(plugin).status:=flag
                }
            }
            
        } else {
            try
                INIObject.DeleteKey("plugins", plugin)
            try
                INIObject.DeleteKey("plugins_DefaultMode", plugin)
            INIObject.save()
        }
    }
    
    ;切换到默认模式
    for plugin, mode in INIObject.plugins_DefaultMode.OwnProps() {
        if plugin="EasyIni_KeyComment"
            continue
        
        ;设置启动状态及默认模式
        try{
            vim.GetWin(plugin).defaultMode:=mode
            vim.mode(mode, plugin)
            vim.GetWin(plugin).Inside:=0
        }
    }
}

CheckHotKey(LoadAll:=0){
    ;全局热键
    _default_Mode:="normal"
    _enabled:=0
    ;是否启用全局热键
    for this_key, this_action in INIObject.global.OwnProps()
    {
        if (this_key="enabled"){
            _enabled:=this_action
            break
        }
    }

    for this_key, this_action in INIObject.global.OwnProps()
    {
        if this_key="EasyIni_KeyComment"
            continue

        if (this_key="default_Mode"){
            _default_Mode:=this_action
            continue
        }

        if (this_key="enabled"){ 
            continue
        }
        this_mode := "normal"
        if RegExMatch(Trim(this_action), "\[\=(.*?)\]", &mode){
            this_mode := mode[1]
            this_action := RegExReplace(this_action, "\[\=(.*?)\]", "")
        }

        vim.mode(this_mode, "global")
        if RegExMatch(this_action, "i)^(run|key|dir|tccmd|wshkey)\|"){
            if (_enabled)
                vim.map(this_key, "global", this_mode, "VIMD_CMD", Param:=this_action, Group:="", Comment:="")
        } else {
            if (InStr(this_action,"||")){
                tArr:= StrSplit(this_action, "||"," ")
                Switch tArr.Length {
                    case 3:
                        this_action:= tArr[1]
                        this_Param:= tArr[2]
                        this_Comment:= tArr[3]
                    case 2:
                        this_action:= tArr[1]
                        this_Param:= tArr[2]
                        this_Comment:= ""
                }
            } else {
                this_action:= this_action
                this_Param:= ""
                this_Comment:= ""
            }
            if (_enabled)
                vim.map(this_key, "global", this_mode, this_action, this_Param, Group:="", this_Comment)
        }
    }
    ;设置启动状态及默认模式
    vim.GetWin("global").status:=_enabled
    vim.GetWin("global").defaultMode:=_default_Mode
    vim.GetWin("global").Inside:=1
    try 
        vim.mode(_default_Mode, "global")

    ;排除窗体
    for win, flag in INIObject.exclude.OwnProps()
    {
        if win="EasyIni_KeyComment"
            continue
        vim.SetWin(win, win)
        vim.ExcludeWin(win, true)
    }

    ;vimd.ini配置文件内写的插件
    ;class_vim.ahk也可以独立使用，见 example.ahk
    for PluginName, Key in INIObject.OwnProps()
    {
        if RegExMatch(PluginName, "i)(config)|(exclude)|(global)|(plugins)|(EasyIni_KeyComment)|(EasyIni_SectionComment)|(EasyIni_ReservedFor_m_sFile)|(EasyIni_TopComments)|(default_Mode)")
            continue

        ;检查是否启用
        _enabled:=0
        for m, n in Key.OwnProps()
        {
            if RegExMatch(m, "i)(set_class)|(set_file)|(set_time_out)|(set_max_count)|(enable_show_info)|(EasyIni_KeyComment)|(enabled)")
                continue

            if (m="enabled"){
                _enabled:=n
                Break
            }
            
        }

        ;不加载全部 + 不启用则跳过
        if !LoadAll && !_enabled
            continue
        
        ;设置窗体
        win := vim.SetWin(PluginName, Key.set_class, Key.set_file)
        vim.SetTimeOut(Key.set_time_out, PluginName)
        vim.SetMaxCount(Key.set_max_count, PluginName)
        if (Key.enable_show_info = 1){
            win.SetInfo(true)
        }
        _default_Mode:="normal"
        for m, n in Key.OwnProps()
        {
            ;if RegExMatch(m, "i)(set_class)|(set_file)|(set_time_out)|(set_max_count)|(enable_show_info)|(EasyIni_KeyComment)")
            if RegExMatch(m, "i)^(set_class|set_file|set_time_out|set_max_count|enable_show_info|enabled|EasyIni_KeyComment)$")
                continue

            if (m="default_Mode"){
                _default_Mode:=n
                continue
            }

            this_mode := "normal"
            this_action := n

            if RegExMatch(this_action, "\[\=(.*?)\]", &mode){
                this_mode := mode[1]
                this_action := RegExReplace(n, "\[\=(.*?)\]", "")
            }

            vim.mode(this_mode, PluginName)

            if RegExMatch(this_action, "i)^(run|key|dir|tccmd|wshkey)\|"){
                vim.map(m, PluginName, this_mode, "VIMD_CMD", Param:=this_action, Group:="", Comment:="")
            } else {
                if (InStr(this_action,"||")){
                    tArr:= StrSplit(this_action, "||"," ")
                    Switch tArr.Length {
                        case 3:
                            this_action:= tArr[1]
                            this_Param:= tArr[2]
                            this_Comment:= tArr[3]
                        case 2:
                            this_action:= tArr[1]
                            this_Param:= tArr[2]
                            this_Comment:= ""
                    }
                } else {
                    ;this_action:= tArr[1]
                    ;this_action:= this_action  ; 直接使用 this_action 自身
                    this_Param:= ""
                    this_Comment:= ""
                }
                ;MsgBox "正在处理: " PluginName "`n键 (Key): " m "`n值 (Action): " this_action
                vim.map(m, PluginName, this_mode, this_action, this_Param, Group:="", this_Comment)
            }
        }
        ;设置启动状态及默认模式
        vim.GetWin(PluginName).status:=_enabled
        vim.GetWin(PluginName).defaultMode:=_default_Mode
        vim.GetWin(PluginName).Inside:=1
        try 
            vim.mode(_default_Mode, PluginName)
    }
}

VIMD_CMD(Param){
    if RegExMatch(Param, "i)^(run)\|", &m) {
        Run substr(Param, strlen(m[1]) + 2) 
    }else if RegExMatch(Param, "i)^(key)\|", &m) {
        Send substr(Param, strlen(m[1]) + 2)
    } else if RegExMatch(Param, "i)^(dir)\|", &m) {
        ; TC_OpenPath(substr(Param, strlen(m[1]) + 2), false)       ;在TC插件下
        f:="TC_OpenPath"
        if Type(%f%)="Func"
            %f%(substr(Param, strlen(m[1]) + 2), false)       ;在TC插件下
        else
            Run substr(Param, strlen(m[1]) + 2)
    } else if RegExMatch(Param, "i)^(tccmd)\|", &m) {
        ; TC_Run(substr(Param, strlen(m[1]) + 2))       ;在TC插件下
        f:="TC_Run"
        if Type(%f%)="Func"
            %f%(substr(Param, strlen(m[1]) + 2))       ;在TC插件下
    } else if RegExMatch(Param, "i)^(wshkey)\|", &m) {
        if (!WshShell) {
            WshShell := ComObject("WScript.Shell")
        }
        WshShell.SendKeys(substr(Param, strlen(m[1]) + 2))
        ; SendLevel 1
        ; Send substr(Param, strlen(m[1]) + 2)
    } else {
        
    }
}

ReceiveWMCopyData(wParam, lParam, msg, hwnd){
    ; 获取 CopyDataStruct 的 lpData 成员.
    StringAddress := NumGet(lParam + 2 * A_PtrSize, "Int64")
    ; 从结构中复制字符串.
    AHKReturn := StrGet(StringAddress)
    if RegExMatch(AHKReturn, "i)reload")  {
        SetTimer (*)=>Reload(), 500
        return true
    }
}

#Include .\class_vim.ahk
