Class_vim() {
    global __v
    vim_Init()
    __v := v := __vim()
    return v
}

/* __vim【__vim数据结构】
    类名: __vim
    作用: __vim数据结构
    参数:
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
class __vim {
    /* __new【新建类】
        函数: __new
        作用: 新建类
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    __new() {
        this.PluginList := Map()               ;插件列表
        this.WinList := Map()               ;窗体列表
        this.WinList["global"] := __win()      ;全局窗体
        ;this.winGlobal  := __win()          ;全局窗体
        this.WinInfo := Map()               ;窗体信息
        this.ActionList := Map()               ;动作列表
        this.ActionFromPlugin := Map()         ;动作来源插件
        this.ExcludeWinList := Map()           ;排除窗体列表
        this.ErrorCode := 0                ;错误代码
        this.ActionFromPluginName := ""     ;动作来源插件名称
        this.LastFoundWin := ""             ;最后发现窗体
        this.HotKeyStr := ""                  ;用于记录全部的热键字符串
        this.HelpStr := ""                    ;用于记录热键功能说明
        this.LastHotKey := ""                 ;记录最后一次的命令
        this._Debug := ""
    }

    /* LoadPlugin【加载插件】
        函数: LoadPlugin
        作用: 加载插件
        参数: PluginName：类名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    LoadPlugin(PluginName) {
        if this.PluginList.Has(PluginName)
            return this.PluginList[PluginName]
        p := __Plugin(PluginName)
        this.PluginList[PluginName] := p
        back := this.ActionFromPluginName
        this.ActionFromPluginName := PluginName
        p.CheckFunc()
        if (p.Error) {
            VimD_Error("VIM_PLUGIN_LOAD", Format(Lang["General"]["Plugin_Load"], PluginName), "", true)
            this.ActionFromPluginName := back
        }
    }

    /* SetPlugin【设置Plugin信息】
        函数: SetPlugin
        作用: 设置Plugin信息
        参数: PluginName：类名称
                Author：作者
                Ver:版本
                Comment:备注
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetPlugin(PluginName, Author := "", Ver := "", Comment := "") {
        p := this.PluginList[PluginName]
        p.Author := Author
        p.Ver := Ver
        p.Comment := Comment
    }

    /* GetPlugin【Plugin对象】
        函数: GetPlugin
        作用: Plugin对象
        参数: PluginName：插件名称
        返回: Plugin对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetPlugin(PluginName) {
        return this.PluginList[PluginName]
    }

    /* SetAction【设置Action(动作)信息 】
        函数: SetAction
        作用: 设置Action(动作)信息
        参数:  KeyName：按键名称
                winName：程序名称
                Mode：模式
                Action：动作，函数名称，VIMD_CMD
                Param：参数，数组
                Group：分组
                Comment：备注
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetAction(KeyName, winName, Mode, Action, Param := "", Group := "", Comment := "", OriKey := "") {
        if (!this.ActionList.Has(winName))
            this.ActionList[winName] := Map()
        if (!this.ActionList[winName].Has(Mode))
            this.ActionList[winName][Mode] := Map()
        if this.ActionList[winName][Mode].Has(KeyName)
            ra := this.ActionList[winName][Mode][KeyName]
        else
            ra := this.ActionList[winName][Mode][KeyName] := __Action(KeyName, Action, Param, Group, Comment, OriKey)
        this.ActionFromPlugin[KeyName] := this.ActionFromPluginName
        return ra
    }

    /* GetAction【获取Action对象】
        函数: GetAction
        作用: 获取Action对象
        参数:  winName：程序名称
                Mode：模式
                KeyName：按键名称
        返回: Action对象 或 false
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetAction(winName, Mode, KeyName) {
        if (!this.ActionList.Has(winName))
            return false
        if (!this.ActionList[winName].Has(Mode))
            return false
        if (this.ActionList[winName][Mode].has(KeyName))
            return this.ActionList[winName][Mode][KeyName]
        else
            return false
    }

    /* SetWin【设置win对象信息 】
        函数: SetWin
        作用: 设置win对象信息
        参数: winName：窗体名称
                class：窗体class（支持用|分隔多个class）
                filepath：窗体进程名
                title：窗体标题
        返回: win对象信息
        作者: Kawvin
        版本: 1.0
        AHK版本: 2.0.18
    */
    SetWin(winName, class, filepath := "", title := "") {
        if this.WinList.Has(winName)
            rw := this.WinList[winName]
        else
            rw := this.WinList[winName] := __win(class, filepath, title)

        if (class != "")
            rw.class := class
        if (filepath != "")
            rw.filepath := filepath
        if (title != "")
            rw.title := title

        ; 从配置文件读取窗口特定的设置
        try {
            if (INIObject.HasSection(winName)) {
                ; 读取 enable_show_info 设置
                if (INIObject.HasKey(winName, "enable_show_info")) {
                    rw.Info := INIObject[winName].enable_show_info
                }
                ; 读取其他窗口特定设置...
            }
        } catch {
            ; 如果读取配置失败，使用默认值
        }

        ; 支持多个class，用|分隔
        if (class != "") {
            if (InStr(class, "|")) {
                classes := StrSplit(class, "|")
                for _, singleClass in classes {
                    singleClass := Trim(singleClass)
                    if (singleClass != "")
                        this.WinInfo["class`t" singleClass] := winName
                }
            } else {
                this.WinInfo["class`t" class] := winName
            }
        }

        if (filepath != "")
            this.WinInfo["filepath`t" filepath] := winName
        if (title != "")
            this.WinInfo["title`t" title] := winName
        return rw
    }

    /* GetWin【返回Win对象 】
        函数: GetWin
        作用: 返回Win对象
        参数: winName：窗体名称
        返回: 返回Win对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetWin(winName := "") {
        if strlen(winName) {
            if (this.WinList.Has(winName)) {
                return this.WinList[winName]
            } else {
                ; 如果窗口不存在，返回null而不是抛出错误
                return ""
            }
        } else {
            return this.WinList["global"]
        }
    }

    /* SetWinGroup【设置窗口组】
        函数: SetWinGroup
        作用: 为一个插件设置多个窗口类，支持不同版本的同一软件
        参数: winName：窗体名称
                classArray：窗体class数组
                filepath：窗体进程名
                title：窗体标题
        返回: win对象信息
        作者: Kiro
        版本: 1.0
        AHK版本: 2.0.18
        示例: vim.SetWinGroup("AfterEffects", ["AE_CApplication_24.6", "AE_CApplication_24.7", "AE_CApplication_24.8"], "AfterFX.exe")
    */
    SetWinGroup(winName, classArray, filepath := "", title := "") {
        if this.WinList.Has(winName)
            rw := this.WinList[winName]
        else
            rw := this.WinList[winName] := __win("", filepath, title)

        ; 为每个class创建映射
        for _, singleClass in classArray {
            singleClass := Trim(singleClass)
            if (singleClass != "")
                this.WinInfo["class`t" singleClass] := winName
        }

        this.WinInfo["filepath`t" filepath] := winName
        this.WinInfo["title`t" title] := winName
        return rw
    }

    /* CheckWin【检查并返回当前窗体名称】
        函数: CheckWin
        作用: 检查并返回当前窗体名称
        参数:
        返回: 窗体名称
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    CheckWin() {
        f := WinGetProcessName("A")
        if (this.WinInfo.Has("filepath`t" f))
            return winName := this.WinInfo["filepath`t" f]
        c := WinGetClass("A")
        if (this.WinInfo.Has("class`t" c))
            return winName := this.WinInfo["class`t" c]
        return "global"
        ; if Strlen(winName := this.WinInfo["filepath`t" f])
        ;     return winName
        ; c:=WinGetClass("A")
        ; if Strlen(winName := this.WinInfo["class`t" c])
        ;     return winName
    }

    /* mode【设置窗体模式，设置模式时，使用此函数】
        函数: mode
        作用: 设置窗体模式，设置模式时，使用此函数
        参数: mode：模式
                win：窗体，为空则为不当前窗体
        返回:  mode对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    mode(mode, win := "") {
        if not IsObject(this.GetWin(win))
            this.SetWin(win, win)
        return this.SetMode(mode, win)
    }

    /* SetMode【设置窗体模式】
        函数: SetMode
        作用: 设置窗体模式
        参数: modeName：模式
                winName：窗体，为空则为不当前窗体
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetMode(modeName, winName := "") {
        winObj := this.GetWin(winName)
        return winObj.ChangeMode(modeName)
    }

    /* SetModeFunction【设置模式的函数】
        函数: SetModeFunction
        作用: 设置模式的函数
        参数: func：函数名称
                modeName：模式名称
                winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetModeFunction(func, modeName, winName := "") {
        winObj := this.GetWin(winName)
        modeObj := winObj.modeList[modeName]
        modeObj.modeFunction := func
    }

    /* getMode【获取mode对象】
        函数: getMode
        作用: 获取mode对象
        参数: winName：窗体名称
        返回: mode对象
        作者: Kawvin
        版本: 1.0
        AHK版本: 2.0.18
    */
    getMode(winName := "") {
        winObj := this.GetWin(winName)
        return winObj.modeList[winObj.ExistMode()]
    }

    /* GetCurMode【获取当前mode名称】
        函数: GetCurMode
        作用: 获取当前mode名称
        参数: winName：窗体名称
        返回: 当前mode名称
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetCurMode(winName := "") {
        winObj := this.GetWin(winName)
        return winObj.ExistMode()
    }

    /* GetInputState【获取输入状态】
        函数: GetInputState
        作用: 获取输入状态
        参数: winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetInputState(WinTitle := "A") {
        hwnd := ControlGetHwnd(WinTitle)
        if (A_Cursor = "IBeam")
            return 1
        if (WinActive(WinTitle)) {
            ptrSize := !A_PtrSize ? 4 : A_PtrSize
            stGTI := Buffer(cbSize := 4 + 4 + (PtrSize * 6) + 16, 0)
            NumPut(cbSize, stGTI, 0, "UInt")   ;   DWORD   cbSize;
            hwnd := DllCall("GetGUIThreadInfo", "Uint", 0, "Uint", &stGTI) ? NumGet(stGTI, 8 + PtrSize, "UInt") : hwnd
        }
        return DllCall("SendMessage"
            , "UInt", DllCall("imm32\ImmGetDefaultIMEWnd", "Uint", hwnd)
            , "UInt", 0x0283  ;Message : WM_IME_CONTROL
            , "Int", 0x0005  ;wParam  : IMC_GETOPENSTATUS
            , "Int", 0)      ;lParam  : 0
    }

    /* BeforeActionDo【设置Action执行前运行的函数】
        函数: BeforeActionDo
        作用: 设置Action执行前运行的函数
        参数: Function：函数名称
                winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    BeforeActionDo(Function, winName := "") {
        winObj := this.GetWin(winName)
        winObj.BeforeActionDoFunc := Function
    }

    /* AfterActionDo【设置Action执行后运行的函数】
        函数:  AfterActionDo
        作用: 设置Action执行后运行的函数
        参数: Function：函数名称
                winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    AfterActionDo(Function, winName := "") {
        winObj := this.GetWin(winName)
        winObj.AfterActionDoFunc := Function
    }

    /* SetMaxCount【设置最大执行数量】
        函数: SetMaxCount
        作用: 设置最大执行数量
        参数: Int：数量
                winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetMaxCount(Int, winName := "") {
        winObj := this.GetWin(winName)
        winObj.MaxCount := int
    }

    /* GetMaxCount【获取最大执行数量】
        函数:  GetMaxCount
        作用: 获取最大执行数量
        参数: winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetMaxCount(winName := "") {
        winObj := this.GetWin(winName)
        return winObj.MaxCount
    }

    /* SetCount【设置执行次数】
        函数: SetCount
        作用: 设置执行次数
        参数: Int：数量
                winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetCount(int, winName := "") {
        winObj := this.GetWin(winName)
        winObj.Count := int
    }

    /* GetCount【获取执行次数】
        函数: GetCount
        作用: 获取执行次数
        参数: winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetCount(winName := "") {
        winObj := this.GetWin(winName)
        return winObj.Count
    }

    /* SetTimeOut【设置超时时间】
        函数: SetTimeOut
        作用: 设置超时时间
        参数: Int：超时时间，单位ms
                winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetTimeOut(Int, winName := "") {
        winObj := this.GetWin(winName)
        winObj.TimeOut := int
    }

    /* GetTimeOut【获取超时时间】
        函数: GetTimeOut
        作用: 获取超时时间
        参数: winName：窗体名称
        返回: 超时时间，单位ms
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetTimeOut(winName := "") {
        winObj := this.GetWin(winName)
        return winObj.TimeOut
    }

    /* Map【热键映射到动作（Action）对象 】
        函数: Map
        作用: 热键映射到动作（Action）对象
        参数: keyName：VIMD按键
                winName：窗体名称
                Mode：模式
                Action：运行名称
                Param：参数
                Group：分组
                Comment：备注
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Map(keyName, winName, Mode, Action, Param := "", Group := "", Comment := "") {
        this.mode(Mode, winName)
        if ( not this.GetAction(winName, Mode, keyName)) {
            _tAction := RegExReplace(Action, "<\d>$", "") ;MPCHC_SendPos 或 带次数的 MPCHC_SendPos<2>
            ; 安全检查函数是否存在（仅在调试模式下报告不存在的函数）
            functionExists := true
            try {
                _funcRef := %_tAction%
                if !(Type(_funcRef) = "Func" || Type(_funcRef) = "Closure")
                    functionExists := false
            } catch {
                functionExists := false
            }

            ; 函数不存在时仅记录警告，不阻止映射注册
            ; （函数可能在运行时动态定义，或由其他模块延迟加载）
            if (!functionExists && INIObject.config.enable_debug)
                this._Debug.Add("警告: 函数 " _tAction " 未找到，按键 " keyName " 仍注册")

            OriKey := keyName
            keyName := this.Convert2VIM_Title(keyName)
            this.SetAction(keyName, winName, Mode, Action, Param, Group, Comment, OriKey)
        }

        winObj := this.GetWin(winName)
        modeObj := this.getMode(winName)
        Class := winObj.class
        filepath := winObj.filepath
        if (winName != "global") {
            if strlen(filepath)
                HotIfWinActive "ahk_exe " filepath
            else
                HotIfWinActive "ahk_class " class
        } else
            HotIfWinActive
        keyName := RegExReplace(keyName, "i)<noWait>", "", &bnoWait)
        keyName := RegExReplace(keyName, "i)<super>", "", &bSuper)
        newKeyName := keyName
        thisKey := ""
        loop {
            if ( not strlen(newKeyName)) {
                break
            } else {
                saveMoreKey .= thisKey
                modeObj.SetMoreKey(saveMoreKey)
            }
            ;获取<insert>及单字母键，如a, B
            if RegExMatch(newKeyName, "^(<.+?>)", &m) {
                thisKey := SubStr(newKeyName, 1, StrLen(m[1]))
                newKeyName := SubStr(newKeyName, StrLen(m[1]) + 1)
            } else {
                thisKey := SubStr(newKeyName, 1, 1)
                newKeyName := SubStr(newKeyName, 2)
            }

            ;将大字字母转换为类<S-*>格式，如 B --> <S-B>
            if RegExMatch(thisKey, "^([A-Z])$", &m)
                thisKey := "<S-" m[1] ">"

            SaveKeyName .= thisKey

            key := this.Convert2AHK(thisKey)
            normalizedKey := this.NormalizeHotkeyName(key)

            ; if INIObject.config.enable_debug{
            ;     if INIObject.config.enable_debug
            ;         this._Debug.Add("Map: " thisKey " to: " Action)
            ; }

            if (SubStr(keyName, 1, 1) = "*") {      ;本行的作用是以*开头的快捷键，不启用
                ;Hotkey Key, "Off"
                continue
            } else {
                A_LastError := 0
                try {
                    Hotkey Key, vim_Key, "On"
                } catch as e {
                    ; 如果热键注册失败，记录错误但不中断程序
                    if (INIObject.config.enable_debug)
                        this._Debug.Add("Error registering hotkey: " Key " - " e.Message)
                    continue
                }
            }

            if A_LastError {
                VimD_Error("VIM_KEY_MAP", Format(Lang["General"]["Key_MapError2"], KeyName, key), "", true)
                this.ErrorCode := "MAP_KEY_ERROR"
                return
            } else {
                winObj.SuperKeyList[normalizedKey] := bSuper
                winObj.KeyList[normalizedKey] := true
            }

        }

        ; 键冲突检测：同一模式内重复绑定
        existingAction := modeObj.GetKeyMap(SaveKeyName)
        if (existingAction && existingAction != Action) {
            VimD_Log("WARN", "VIM_KEY_CONFLICT",
                "键冲突: [" winName "][" Mode "] " SaveKeyName
                . " 从 " existingAction " 覆盖为 " Action)
        }

        modeObj.SetKeyMap(SaveKeyName, Action)
        modeObj.SetNoWait(SaveKeyName, bnoWait)
        return false
    }

    /* ExcludeWin【排除窗体】
        函数: ExcludeWin
        作用: 排除窗体
        参数: winName：窗体名称
                Bold：标记，默认=true
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    ExcludeWin(winName := "", Bold := true) {
        this.ExcludeWinList[winName] := Bold
    }

    /* Toggle【窗体对象状态反值】
        函数: Toggle
        作用: 窗体对象状态反值
        参数: winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Toggle(winName) {
        winObj := this.GetWin(winName)
        winObj.Status := !winObj.Status
        this.Control(winObj.Status, winName)
        return winObj.Status
    }

    /* Control【将当前窗体的所有热键设置为指定状态 】
        函数: Control
        作用: 将当前窗体的所有热键设置为指定状态
        参数:  bold：是否启用热键
                winName：窗体名称，默认当前窗体
                all：是否全部热键，默认false
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Control(bold, winName := "", all := false) {
        local class

        winObj := this.GetWin(winName)
        class := winObj.Class
        filepath := winObj.filepath
        if Strlen(filepath)
            HotIfWinActive "ahk_exe " filepath
        else if Strlen(class)
            HotIfWinActive "ahk_class " class
        else
            HotIfWinActive
        if INIObject.config.enable_debug
            this._Debug.Add("===== Control End  =====")
        for i, k in winObj.KeyList {
            if winObj.SuperKeyList[i] And ( not all)
                continue
            if INIObject.config.enable_debug
                this._Debug.Add("class: " class "`tKey: " i "`tControl: " bold)
            if bold
                Hotkey i, vim_Key, "On"
            else
                Hotkey i, vim_Key, "off"
            winObj.KeyList[i] := bold
        }
        if INIObject.config.enable_debug
            this._Debug.Add("===== Control Start =====")
    }

    /* Copy【复制win对象】
        函数: Copy
        作用: 复制win对象
        参数: winName1, winName2, class, filepath := "", title := ""
        返回: win对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Copy(winName1, winName2, class, filepath := "", title := "") {
        ; if INIObject.config.enable_debug
        ;     this._Debug.Add("Copy>> " winName1 "`t"  winName2 "`t" class)
        win1 := this.GetWin(winName1)
        win2 := this.SetWin(winName2, class, filepath, title)
        win2.class := class
        win2.filepath := filepath
        win2.title := title
        win2.KeyList := win1.KeyList.Clone()
        win2.SuperKeyList := win1.SuperKeyList.Clone()
        win2.modeList := win1.modeList.Clone()
        win2.mode := win1.mode
        win2.LastKey := win1.LastKey
        win2.KeyTemp := win1.KeyTemp
        win2.MaxCount := win1.MaxCount
        win2.Count := win1.Count
        win2.TimeOut := win1.TimeOut
        win2.Info := win1.Info
        win2.BeforeActionDoFunc := win1.BeforeActionDoFunc
        win2.AfterActionDoFunc := win1.AfterActionDoFunc
        win2.ShowInfoFunc := win1.ShowInfoFunc
        win2.HideInfoFunc := win1.HideInfoFunc
        this.Control(Bold := true, winName2, all := true)
        return win2
    }

    /* CopyMode【复制Mode对象】
        函数: CopyMode
        作用: 复制Mode对象
        参数: winName, fromMode, toMode
        返回: Mode对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    CopyMode(winName, fromMode, toMode) {
        winObj := this.GetWin(winName)
        winObj.mode := this.GetCurMode(winName)
        winObj.KeyTemp := ""
        winObj.Count := 0
        from := winObj.modeList[fromMode]
        ; Create a new mode object instead of aliasing the source
        to := __Mode(toMode)
        to.keyMapList := from.keyMapList.Clone()
        to.keyMoreList := from.keyMoreList.Clone()
        to.noWaitList := from.noWaitList.Clone()
        to.modeFunction := from.modeFunction
        winObj.modeList[toMode] := to
        return to
    }

    /* Delete【删除win对象】
        函数: Delete
        作用: 删除win对象
        参数: winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Delete(winName := "") {
        this.Control(false, winName, all := true)
        this.WinList[winName] := ""
    }

    /* GetMore【获取有相同键值的动作】
        函数: GetMore
        作用: 获取有相同键值的动作
        参数:
        返回: Array或字符串
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetMore(obj := false) {
        rt_obj := []
        winObj := this.GetWin(this.LastFoundWin)
        modeObj := this.getMode(this.LastFoundWin)
        if Strlen(winObj.KeyTemp) {
            r := winObj.KeyTemp "`n"
            rt_obj.Push(Map("key", winObj.KeyTemp, "Action", modeObj.GetKeyMap(winObj.KeyTemp)))
            m := "i)^" this.ToMatch(winObj.KeyTemp) ".+"
            for i, k in modeObj.keyMapList {
                if RegExMatch(i, m) {
                    r .= i "`t" modeObj.GetKeyMap(i) "`n"
                    rt_obj.Push(Map("key", i, "Action", modeObj.GetKeyMap(i)))
                }
            }

            if obj
                return rt_obj
            else
                return r
        }
        else
            if winObj.count
                return winObj.count
    }

    /* Clear【清空win对象的按键记录】
        函数: Clear
        作用: 清空win对象的按键记录
        参数: winName：窗体名称
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Clear(winName := "") {
        winObj := this.GetWin(winName)
        winObj.KeyTemp := ""
        winObj.Count := 0
    }

    /* Key【热键执行】
        函数: Key
        作用: 热键执行
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Key() {
        ; 获取winName
        winName := this.CheckWin()
        ; 获取当前的热键
        ahkHotkey := this.NormalizeHotkeyName(A_ThisHotkey)
        k := this.CheckCapsLock(this.Convert2VIM(ahkHotkey))
        this.HotKeyStr .= k
        this.HotKeyStr := this.ShiftUpper(this.HotKeyStr)

        ; 如果winName在排除窗口中，直接发送热键
        if this.ExcludeWinList.Has(winName) {
            Send this.Convert2AHK(k, ToSend := true)
            this.HotKeyStr := ""
            this.LastHotKey := ""
            return
        }

        winObj := this.GetWin(winName)
        ;对于内置热键，因为是始终加载的，此处检查status是否启用
        if (!winObj.status) {
            ; 不启用，按普通键输出
            Send this.Convert2AHK(k, ToSend := true)
            this.HotKeyStr := ""
            this.LastHotKey := ""
            return
        }

        ; 如果当前热键在当前winName无效，判断全局热键中是否有效？
        if Not winObj.KeyList.has(ahkHotkey) {
            winObj := this.GetWin("global")
            if Not winObj.KeyList.has(ahkHotkey) || (!winObj.status) {   ;如果没有当前热键，或全局status=0不启用时，按普通键输出
                ; 无效热键，按普通键输出
                Send this.Convert2AHK(k, ToSend := true)
                this.HotKeyStr := ""
                this.LastHotKey := ""
                return
            } else
                winName := "global"
        }

        this.LastFoundWin := winName
        ; 执行在判断热键前的函数, 如果函数返回true，按普通键输出
        ; if (Type(f := winObj.BeforeActionDoFunc)="Func"){
        ; 修改为无须绑定，直接为默认项【plugin_Before】，2025.06.16
        f := winName "_Before"
        try
            _Rst_Before := %f%()
        catch
            _Rst_Before := 0
        if _Rst_Before {
            Send this.Convert2AHK(k, ToSend := true)
            this.HotKeyStr := ""
            this.LastHotKey := ""
            return
        }

        ; 获取当前模式对应的对象
        modeObj := this.getMode(winName)
        modeName := this.GetCurMode(winName)
        ; 如果模式为空，未设定默认械，则发送原键。
        if (modeName = "") {
            Send this.Convert2AHK(k, ToSend := true)
            return
        }

        ; 把当前热键添加到热键缓存中, 并设置最后热键为k
        winObj.KeyTemp .= winObj.LastKey := k

        if INIObject.config.enable_debug
            this._Debug.Add("----win: " winName "`tHotkey: " k)
        /*
            if winObj.Count
                this._Debug.Add(" [" winName "`t热键:" winObj.Count winObj.KeyTemp)
            else
                this._Debug.Add(" [" winName "]`t热键:" winObj.KeyTemp)
        */

        ; 热键缓存是否有对应的Action?
        ; 判断是否有更多热键, 如果当前具有<noWait>设置，则无视更多热键
        if modeObj.GetMoreKey(winObj.KeyTemp) And ( Not modeObj.GetNoWait(winObj.KeyTemp)) {
            ; 启用TimeOut
            if strlen(modeObj.GetKeyMap(winObj.KeyTemp))
                if tick := winObj.TimeOut
                    SetTimer Vim_TimeOut, tick

            winObj.ShowMore()
            ; 执行在判断热键后的函数, 如果函数返回true，按普通键输出
            ; if (Type(f := winObj.AfterActionDoFunc)="Func") {
            ; 修改为无须绑定，直接为默认项【plugin_After】，2025.06.16
            f := winName "_After"
            try
                _Rst_After := %f%()
            catch
                _Rst_After := 0
            if _Rst_After {
                Send this.Convert2AHK(k, ToSend := true)
            }
            return
        }

        ; 如果没有更多，热键缓存是否有对应的Action?
        if strlen(actionName := modeObj.GetKeyMap(winObj.KeyTemp)) {
            actObj := this.GetAction(winName, modeName, this.Convert2MapKey(winObj.KeyTemp))
            ; if INIObject.config.enable_debug
            ;     this._Debug.Add("热键: " actObj.name "`n动作:" actObj.Function "`n参数:" KyFunc_StringParam(actObj.Param, ",") "`n----------------")
            if actObj {
                if (actObj.Type = 1) And RegExMatch(actObj.Function, "<(\d)>$", &m) { ;整<3>类型的为多次运行的函数
                    ; 数字则进行累加
                    winObj.Count := winObj.Count * 1 + m[1]
                    if winObj.MaxCount And winObj.Count > winObj.MaxCount
                        winObj.Count := winObj.MaxCount
                }
                ; if INIObject.config.enable_debug
                ;this._Debug.Add("act: " actionName "`tLK: " winObj.KeyTemp)
                SetTimer Vim_TimeOut, 0
                actObj.Do(winObj.Count)
                this.HotKeyStr := ""
                winObj.Count := 0
            }
        } else {
            SetTimer Vim_TimeOut, 0
            ; 如果没有，按普通键输出
            if strlen(actionName := modeObj.GetKeyMap(winObj.LastKey)) {
                actObj := this.GetAction(winName, modeName, this.Convert2MapKey(winObj.KeyTemp))
                if (!actObj)
                    Send this.Convert2AHK(k, ToSend := true)
                else
                    actObj.Do(winObj.Count)
                this.HotKeyStr := ""
                winObj.Count := 0
            } else {
                Send this.Convert2AHK(k, ToSend := true)
                winObj.Count := 0
                this.HotKeyStr := ""
            }
        }

        winObj.KeyTemp := ""
        winObj.HideMore()

        ; 执行在判断热键后的函数, 如果函数返回true，按普通键输出
        ; if (Type(f := winObj.AfterActionDoFunc)="Func"){
        ; 修改为无须绑定，直接为默认项【plugin_After】，2025.06.16
        f := winName "_After"
        try
            _Rst_After := %f%()
        catch
            _Rst_After := 0
        if _Rst_After
            Send this.Convert2AHK(k, ToSend := true)
        this.HotKeyStr := ""
    }

    ; IsTimeOut() {{{2
    IsTimeOut() {
        winName := this.LastFoundWin
        winObj := this.GetWin(this.LastFoundWin)
        modeObj := this.getMode(this.LastFoundWin)
        modeName := this.GetCurMode(this.LastFoundWin)
        act := this.GetAction(this.LastFoundWin, modeName, this.Convert2MapKey(winObj.KeyTemp))
        if act {
            winObj.HideMore()
            act.Do(winObj.Count)
            winObj.Count := 0
            winObj.KeyTemp := ""
            ; 执行在判断热键后的函数, 如果函数返回true，按普通键输出
            ; if Type(f := winObj.AfterActionDoFunc)="Func"
            ; 修改为无须绑定，直接为默认项【plugin_After】，2025.06.16
            f := winName "_After"
            try
                _Rst_After := %f%()
            catch
                _Rst_After := 0
            if _Rst_After
                Send this.Convert2AHK(act.name, ToSend := true)
            SetTimer Vim_TimeOut, 0
        }
    }

    /* ShiftUpper【把<s-v>这种形式的热键，转换为V（字母大写）】
        函数: ShiftUpper
        作用: 把<s-v>这种形式的热键，转换为V（字母大写）
        参数: aString :字符呼呼大睡
        返回: 大写字母
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    ShiftUpper(aString) {
        return RegExReplace(aString, "im)<s\-([a-zA-Z])>", "$U1")
    }

    /* Debug【调试 】
        函数: Debug
        作用: 调试
        参数: Bold：1=启用，0=不启用
                history：输出内容
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Debug(Bold, history := false) {
        if Bold {
            this._Debug := __vimDebug(history)
            this._Debug.var(this)
        } else {
            vimDebug.Destroy()
            this._Debug := ""
        }
    }

    ; ============================================================
    ; Key-name database — lazy-initialized, shared by all conversion functions.
    ; Replaces ~200 lines of duplicated RegExMatch chains with a single data source.
    ; ============================================================
    _EnsureKeyDB() {
        if this.HasOwnProp("_KeyDB")
            return

        ; Category 1: Simple special keys — canonical name → true
        ; These wrap in <> for VIM format and {} for Send format.
        simple := "F1,F2,F3,F4,F5,F6,F7,F8,F9,F10,F11,F12"
            . ",LButton,RButton,MButton,XButton1,XButton2"
            . ",WheelDown,WheelUp,WheelLeft,WheelRight"
            . ",CapsLock,Space,Tab,Enter"
            . ",ScrollLock,Home,End,Up,Down,Left,Right,PgUp,PgDn"
            . ",AppsKey,NumpadEnter"
            . ",Numpad0,Numpad1,Numpad2,Numpad3,Numpad4,Numpad5,Numpad6,Numpad7,Numpad8,Numpad9"
            . ",NumpadAdd,NumpadSub,NumpadMult,NumpadDiv,NumpadDot"
            . ",BS,Esc,Insert,Delete,PrtSc,controlBreak"
        this._SimpleKeys := Map()
        this._SimpleKeysLower := Map()
        for k in StrSplit(simple, ",") {
            this._SimpleKeys[k] := true
            this._SimpleKeysLower[StrLower(k)] := k
        }

        ; Category 2: Aliases — lowercase alias → canonical name
        this._KeyAliases := Map()
        this._KeyAliases["backspace"] := "BS"
        this._KeyAliases["escape"] := "Esc"
        this._KeyAliases["ins"] := "Insert"
        this._KeyAliases["del"] := "Delete"
        this._KeyAliases["printscreen"] := "PrtSc"

        ; Category 3: AHK modifier pattern → VIM prefix (Convert2VIM)
        this._ModToVim := [
            ["i)^shift\s&\s(.*)", "<S-"],
            ["^\+(.*)", "<S-"],
            ["i)^lshift\s&\s(.*)", "<LS-"],
            ["^<\+(.*)", "<LS-"],
            ["i)^rshift\s&\s(.*)", "<RS-"],
            ["^>\+(.*)", "<RS-"],
            ["i)^Ctrl\s&\s(.*)", "<C-"],
            ["^\^(.*)", "<C-"],
            ["i)^lctrl\s&\s(.*)", "<LC-"],
            ["^<\^(.*)", "<LC-"],
            ["i)^rctrl\s&\s(.*)", "<RC-"],
            ["^>\^(.*)", "<RC-"],
            ["i)^alt\s&\s(.*)", "<A-"],
            ["^\!(.*)", "<A-"],
            ["i)^lalt\s&\s(.*)", "<LA-"],
            ["^<\!(.*)", "<LA-"],
            ["i)^ralt\s&\s(.*)", "<RA-"],
            ["^>\!(.*)", "<RA-"],
            ["i)^lwin\s&\s(.*)", "<W-"],
            ["^#(.*)", "<W-"],
            ["i)^space\s&\s(.*)", "<SP-"],
            ["i)^~?LButton\s&\s(.*)", "<LB-"],
            ["i)^~?MButton\s&\s(.*)", "<MB-"],
            ["i)^~?RButton\s&\s(.*)", "<RB-"],
            ["i)^~?XButton1\s&\s(.*)", "<XB1-"],
            ["i)^~?XButton2\s&\s(.*)", "<XB2-"],
            ["i)^CapsLock\s&\s(.*)", "<Caps-"],
            ["i)^~?Tab\s&\s(.*)", "<Tab-"],
        ]

        ; Category 4: VIM modifier prefix → [toSendPrefix, rawPrefix] (Convert2AHK)
        this._ModFromVim := [
            ["S-",  "+", "+"],
            ["LS-", "<+", "<+"],
            ["RS-", ">+", ">+"],
            ["C-",  "^", "^"],
            ["LC-", "<^", "<^"],
            ["RC-", ">^", ">^"],
            ["A-",  "!", "!"],
            ["LA-", "<!", "<!"],
            ["RA-", ">!", ">!"],
            ["W-",  "#", "#"],
            ["SP-", "{space}", "space & "],
            ["LB-", "{~LButton}", "~LButton & "],
            ["MB-", "{~MButton}", "~MButton & "],
            ["RB-", "{~RButton}", "~RButton & "],
            ["XB1-", "{~XButton1}", "~XButton1 & "],
            ["XB2-", "{~XButton2}", "~XButton2 & "],
            ["Caps-", "{Caps}", "CapsLock & "],
            ["Tab-", "{~Tab}", "~Tab & "],
        ]

        ; Category 5: Standalone modifier → send format
        this._ModSend := Map()
        this._ModSend["alt"] := "{!}"
        this._ModSend["ctrl"] := "{^}"
        this._ModSend["shift"] := "{+}"
        this._ModSend["win"] := "{#}"

        this._KeyDB := true
    }

    ; Resolve a key name to its canonical form. Returns [canonicalName, isSimple].
    _CanonicalKey(key) {
        lower := StrLower(key)
        if this._KeyAliases.Has(lower)
            return [this._KeyAliases[lower], true]
        if this._SimpleKeysLower.Has(lower)
            return [this._SimpleKeysLower[lower], true]
        return ["", false]
    }

    /* Convert2VIM【将AHK热键名转换为类VIM的热键名 】
        函数: Convert2VIM
        作用: 将AHK热键名转换为类VIM的热键名
        参数: key： AHK热键名
        返回: 类VIM的热键名
        作者:  Kawvin
        修改:  BoBO
        版本:  1.0
        AHK版本: 2.0.18
        例 Convert2VIM("f1")
    */
    Convert2VIM(key) {
        this._EnsureKeyDB()

        ; Uppercase single letter → <S-X>
        if RegExMatch(key, "^[A-Z]$")
            return "<S-" StrUpper(key) ">"

        ; Modifier + key combinations
        for entry in this._ModToVim {
            if RegExMatch(key, entry[1], &m)
                return entry[2] StrUpper(m[1]) ">"
        }

        ; Standalone modifier keys
        lower := StrLower(key)
        if lower = "alt"
            return "<Alt>"
        if lower = "ctrl"
            return "<Ctrl>"
        if lower = "shift"
            return "<Shift>"
        if lower = "lwin"
            return "<Win>"

        ; LT/RT
        if lower = "lt"
            return "<LT>"
        if lower = "rt"
            return "<RT>"

        ; Simple special keys
        resolved := this._CanonicalKey(key)
        if resolved[2]
            return "<" resolved[1] ">"

        return key
    }

    /* Convert2VIM_Title【把ahk热键名转换为vimd热键定义，为保持大小写一致使用，在热键调用时匹配VIM化的热键】
        函数: Convert2VIM_Title
        作用: 把ahk热键名转换为vimd热键定义，为保持大小写一致使用，在热键调用时匹配VIM化的热键
        参数: key： AHK热键名
        返回: 类VIM的热键名
        作者:  Kawvin
        修改:  BoBO
        版本:  1.0
        AHK版本: 2.0.18
        例 Convert2VIM_Title("f1")
    */
    Convert2VIM_Title(key) {
        this._EnsureKeyDB()

        arr := MyFun_RegExMatchAll(key, "<(.*)>")
        if (arr.length) {
            for k, v in arr {
                ; Resolve aliases (BackSpace→BS, Escape→Esc, etc.)
                resolved := this._CanonicalKey(v)
                if resolved[2] && resolved[1] != v
                    key := RegExReplace(key, v, resolved[1])
                ; Uppercase modifier+key combinations (<s-a> → <S-A>)
                else if RegExMatch(v, "\-")
                    key := RegExReplace(key, v, StrUpper(v))
            }
        }
        return key
    }

    /* Convert2AHK【将类VIM的热键名转换为AHK热键名】
        函数: Convert2AHK
        作用: 将类VIM的热键名转换为AHK热键名
        参数: key：类VIM的热键名
                ToSend：是否发送，0：enter , 1：{enter}
        返回:
        作者:  Kawvin
        修改:  BoBO
        版本:  1.0
        AHK版本: 2.0.18
        例 Convert2AHK("<F1>")
    */
    Convert2AHK(key, ToSend := false) {
        this._EnsureKeyDB()

        if !RegExMatch(key, "^<.*>$")
            return key

        inner := SubStr(key, 2, StrLen(key) - 2)
        lower := StrLower(inner)

        ; Modifier combinations
        for entry in this._ModFromVim {
            if RegExMatch(inner, "i)^" entry[1] "(.*)", &m)
                return ToSend ? entry[2] this.CheckToSend(m[1]) : entry[3] m[1]
        }

        ; Standalone modifier keys
        if this._ModSend.Has(lower)
            return ToSend ? this._ModSend[lower] : (lower = "win" ? "lwin" : lower)

        ; LT/RT
        if lower = "lt"
            return ToSend ? "{<}" : "<"
        if lower = "rt"
            return ToSend ? "{>}" : ">"

        ; Simple special keys
        resolved := this._CanonicalKey(inner)
        if resolved[2]
            return ToSend ? "{" resolved[1] "}" : resolved[1]

        return inner
    }

    /* Convert2MapKey【将类VIM的热键名转换为Map热键名】
        函数: Convert2MapKey
        作用: 将类VIM的热键名转换为Map热键名
        参数: key：类VIM的热键名
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
        例 Convert2AHK("<F1>")
    */
    Convert2MapKey(key) {
        return this.ShiftUpper(this.CheckCapsLock(this.Convert2VIM(key)))
    }

    NormalizeHotkeyName(key) {
        if RegExMatch(key, "i)^~?(LButton|MButton|RButton|XButton1|XButton2|Tab)\s&\s(.*)$", &m)
            return "~" m[1] " & " m[2]
        return key
    }

    /* CheckToSend【转换发送键 】
        函数: CheckToSend
        作用: 转换发送键
        参数: key
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    CheckToSend(key) {
        this._EnsureKeyDB()
        lower := StrLower(key)

        ; Standalone modifier keys
        if this._ModSend.Has(lower)
            return this._ModSend[lower]

        ; Simple special keys
        resolved := this._CanonicalKey(key)
        if resolved[2]
            return "{" resolved[1] "}"

        ; LT/RT
        if lower = "lt"
            return "<LT>"
        if lower = "rt"
            return "{>}"

        return StrLower(key)
    }

    /* CheckCapsLock【检测CapsLock是否按下，返回对应的值】
        函数: CheckCapsLock
        作用: 检测CapsLock是否按下，返回对应的值 ，key 的值为类VIM键，如 CheckCapsLock("<S-A>")
        参数: key
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    CheckCapsLock(key) {
        if GetKeyState("CapsLock", "T") {
            if RegExMatch(key, "^[a-z]$")
                return "<S-" key ">"
            if RegExMatch(key, "i)^<S\-([a-zA-Z])>", &m) {
                return StrLower(m[1])
            }
        }
        return key
    }

    /* ToMatch【替换特殊字符】
        函数: ToMatch
        作用: 替换特殊字符
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    ToMatch(v) {
        v := RegExReplace(v, "\+|\?|\.|\*|\{|\}|\(|\)|\||\^|\$|\[|\]|\\", "\$0")
        return RegExReplace(v, "\s", "\s")
    }
}
