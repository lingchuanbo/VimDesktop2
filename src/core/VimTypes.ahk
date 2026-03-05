
/* __win【win对象】
    类名: __win
    作用: win对象
    参数: class：class
            filepath：进程名
            title：标题
    返回:  win对象
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
class __win {
    /* __win【win对象】
        类名: __win
        作用: win对象
        参数: class：class
                filepath：进程名
                title：标题
        返回:  win对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    __new(class := "", filepath := "", title := "") {
        this.class := class
        this.filepath := filepath
        this.title := title
        this.KeyList := Map()
        this.SuperKeyList := Map()
        this.modeList := Map()
        this.Status := 1      ;是否启用
        this.defaultMode := ""   ;默认模式
        this.mode := ""    ;当前模式
        this.Inside := 0     ;是否为Vimd.ini内置插件
        this.LastKey := ""
        this.KeyTemp := ""
        this.MaxCount := 99
        this.Count := 0
        this.TimeOut := 0
        this.Info := VimDesktop_Global.default_enable_show_info
        this.BeforeActionDoFunc := ""
        this.AfterActionDoFunc := ""
        this.ShowInfoFunc := "ShowInfo"
        this.HideInfoFunc := "HideInfo"
    }

    /* ChangeMode【检查模式是否存在】
        函数: ChangeMode
        作用: 检查模式是否存在，如存在则返回模式对象，如果不存在则新建并返回模式对象
        参数: modeName：模式名称
        返回: mode对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    ChangeMode(modeName) {
        this.mode := modeName
        this.KeyTemp := ""
        this.Count := 0
        if not this.modeList.Has(modeName)
            this.modeList[modeName] := __Mode(modeName)

        modeObj := this.modeList[modeName]
        if (modeObj.modeFunction != "") {
            func := modeObj.modeFunction
            if Type(%func%) = "Func"
                %func%()
        }
        return modeObj
    }

    /* ExistMode【返回mode名称】
        函数: ExistMode
        作用: 返回mode名称
        参数:
        返回: mode名称
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    ExistMode() {
        return this.mode
    }

    /* SetInfo【设置信息】
        函数: SetInfo
        作用: 设置信息
        参数: bold
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetInfo(bold) {
        this.info := bold
    }

    /* SetShowInfo【设置显示信息】
        函数: SetShowInfo
        作用: 设置显示信息
        参数: func
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetShowInfo(func) {
        this.ShowInfoFunc := func
    }

    /* SetHideInfo【设置隐藏信息 】
        函数: SetHideInfo
        作用: 设置隐藏信息
        参数: func
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetHideInfo(func) {
        this.HideInfoFunc := func
    }

    /* ShowMore【显示更多】
        函数: ShowMore
        作用: 显示更多
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    ShowMore() {
        f := this.ShowInfoFunc
        if Type(%f%) = "Func" And this.Info
            %f%()
    }

    /* HideMore【隐藏更多】
        函数: HideMore
        作用: 隐藏更多
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    HideMore() {
        f := this.HideInfoFunc
        if Type(%f%) = "Func" And this.Info
            %f%()
    }
}

/* __Mode【mode对象】
    类名: __Mode
    作用: mode对象
    参数: mode对象
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
class __Mode {
    /* __Mode【mode对象】
        类名: __Mode
        作用: mode对象
        参数: mode对象
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    __new(modeName) {
        this.name := modeName
        this.keyMapList := Map()
        this.keyMoreList := Map()
        this.noWaitList := Map()
        this.modeFunction := ""
    }

    /* SetKeyMap【设置热键映射】
        函数: SetKeyMap
        作用: 设置热键映射
        参数: key：热键
                action：动作
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetKeyMap(key, action) {
        this.keyMapList[key] := action
    }

    /* GetKeyMap【获取热键映射】
        函数: GetKeyMap
        作用: 获取热键映射
        参数: key：热键
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetKeyMap(key) {
        if this.keyMapList.Has(key)
            return this.keyMapList[key]
        else
            return ""
    }

    /* DelKeyMap【删除热键映射】
        函数: DelKeyMap
        作用: 删除热键映射
        参数: key：热键
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    DelKeyMap(key) {
        this.keyMapList[key] := ""
    }

    /* SetNoWait【设置无等待】
        函数: SetNoWait
        作用: 设置无等待
        参数: key：热键
                bold
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetNoWait(key, bold) {
        this.noWaitList[key] := bold
    }

    /* GetNoWait【获取无等待】
        函数: GetNoWait
        作用: 获取无等待
        参数: key：热键
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetNoWait(key) {
        if this.noWaitList.Has(key)
            return this.noWaitList[key]
        else
            return false
    }

    /* SetMoreKey【设置更多热键缓存】
        函数: SetMoreKey
        作用: 设置更多热键缓存
        参数: key：热键
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetMoreKey(key) {
        this.keyMoreList[key] := true
    }

    /* GetMoreKey【获取更多热键缓存】
        函数: GetMoreKey
        作用: 获取更多热键缓存
        参数: key：热键
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    GetMoreKey(key) {
        if this.keyMoreList.Has(key)
            return this.keyMoreList[key]
        else
            return false
    }
}

/* __Action【创建__Action对象】
    类名: __Action
    作用: 创建__Action对象
    参数: KeyName：热键
            Action：动作
            Param：参数
            Group：分组
            Comment：备注
    返回: __Action对象
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
class __Action {
    ; Action 有几种类型
    ; 1 代表执行Function的值对应的函数 (默认)
    ; 2 代表运行CmdLine对应的值
    ; 3 代表发送HotString对应的文本

    /* __Action【创建__Action对象】
        类名: __Action
        作用: 创建__Action对象
        参数: KeyName：热键
                Action：动作
                Param：参数
                Group：分组
                Comment：备注
        返回: __Action对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    __new(KeyName, Action, Param, Group, Comment, OriKey) {
        this.Name := KeyName
        this.Comment := Comment
        this.MaxTimes := 0
        this.Type := 1
        this.Function := Action
        this.CmdLine := ""
        this.HotString := ""
        this.Param := Param
        this.Group := Group
        this.OriKey := OriKey
    }

    /* SetFunction【设置函数】
        函数: SetFunction
        作用: 设置函数
        参数: Function
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetFunction(Function) {
        this.Function := Function
        this.Type := 1
    }

    /* SetCmdLine【设置CmdLine】
        函数: SetCmdLine
        作用: 设置CmdLine
        参数: CmdLine
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetCmdLine(CmdLine) {
        this.CmdLine := CmdLine
        this.Type := 2
    }

    /* SetHotString【设置HotString】
        函数: SetHotString
        作用: 设置HotString
        参数: HotString
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetHotString(HotString) {
        this.HotString := HotString
        this.Type := 3
    }

    /* SetMaxTimes【设置最大次数】
        函数: SetMaxTimes
        作用: 设置最大次数
        参数: Times
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    SetMaxTimes(Times) {
        this.MaxTimes := Times
    }

    /* Do【执行Action】
        函数: Do
        作用: 执行Action
        参数: Times：执行次数
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Do(Times := 0) {
        Times := !Times ? 1 : Times
        if this.MaxTimes And (Times > this.MaxTimes)
            Times := this.MaxTimes
        ; if INIObject.config.enable_debug
        ;     vim._Debug.add(Format("Name:{1}`nAction:{2}`n----------------------",this.name, this.Function))
        loop Times {
            switch this.Type {
                case 1:
                    f := this.Function
                    f := RegExReplace(f, "<\d>$", "")

                    ; 特殊处理 SingleDoubleFullHandlers 函数
                    if (f = "SingleDoubleFullHandlers") {
                        ; 调用存储的处理函数
                        global singleDoubleHandlers
                        if (IsSet(singleDoubleHandlers) && singleDoubleHandlers.Has(this.Name)) {
                            handler := singleDoubleHandlers[this.Name]
                            ; 使用按键名称而不是A_ThisHotkey，因为在vim系统中A_ThisHotkey可能不正确
                            handler(this.OriKey ? this.OriKey : this.Name)
                        }
                    } else if (Type(%f%) = "Func") {
                        if (this.Param = "") {
                            %f%()
                        } else {
                            %f%(this.Param)
                        }
                    }
                case 2:
                    Run(cmd := this.CmdLine)
                case 3:
                    Send(str := this.HotString)
            }
        }
    }
}

/* __Plugin【创建__Plugin对象】
    类名: __Plugin
    作用: 创建__Plugin对象
    参数: PluginName：插件名称
    返回: __Plugin对象
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
class __Plugin {
    /* __Plugin【创建__Plugin对象】
        类名: __Plugin
        作用: 创建__Plugin对象
        参数: PluginName：插件名称
        返回: __Plugin对象
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    __new(PluginName) {
        this.PluginName := PluginName
        this.Author := ""
        this.Ver := ""
        this.Comment := ""
        this.Name := ""
        this.Entry := ""
        this._LoadMeta()
    }

    _LoadMeta() {
        metaPath := PathResolver.PluginPath(this.PluginName, "plugin.meta.ini")
        if (!FileExist(metaPath))
            return
        try {
            name := IniRead(metaPath, "plugin", "name", this.PluginName)
            author := IniRead(metaPath, "plugin", "author", "")
            ver := IniRead(metaPath, "plugin", "version", "")
            comment := IniRead(metaPath, "plugin", "comment", "")
            entry := IniRead(metaPath, "plugin", "entry", "")
            if (entry = "")
                entry := IniRead(metaPath, "plugin", "main", "")
            entry := Trim(entry, " `t")
            if (SubStr(entry, 1, 1) = "\" || SubStr(entry, 1, 1) = "/")
                entry := SubStr(entry, 2)

            this.Name := name
            if (author != "")
                this.Author := author
            if (ver != "")
                this.Ver := ver
            if (comment != "")
                this.Comment := comment
            if (entry != "")
                this.Entry := entry
        } catch {
            ; 忽略元信息读取失败
        }
    }

    /* CheckFunc【检查函数并执行】
        函数: CheckFunc
        作用: 检查函数并执行
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    CheckFunc() {
        p := this.PluginName
        if (Type(%p%) = "Func") {
            %p%()
            this.Error := false
        } else
            this.Error := true
    }
}

/* __vimDebug【vimDebug】
    类名: __vimDebug
    作用: vimDebug
    参数:
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
class __vimDebug {
    /* __vimDebug【vimDebug】
        类名: __vimDebug
        作用: vimDebug
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    __new(key) {
        this.mode := key
        if key {
            try {
                if (IsObject(vimDebug) && vimDebug.Hwnd)
                    vimDebug.Destroy()
            } catch {
                ; 忽略销毁错误
            }

            global vimDebug := Gui("+AlwaysOnTop", "_vimDebug")
            vimDebug.SetFont("c000000 s10", "Verdana")
            vimDebug.OnEvent("Escape", (*) => vimDebug.Destroy())
            vimDebug.OnEvent("Close", (*) => vimDebug.Destroy())
            vimDebug.Add("Edit", "x-2 y-2 w400 h60 readonly vEdit1")
            vimDebug.Show("w378 h56 y600")
        }
        else {
            try {
                if (IsObject(vimDebug) && vimDebug.Hwnd)
                    vimDebug.Destroy()
            } catch {
                ; 忽略销毁错误
            }

            global vimDebug := Gui("+AlwaysOnTop", "_vimDebug")
            vimDebug.SetFont("c000000 s10", "Verdana")
            vimDebug.OnEvent("Escape", (*) => vimDebug.Destroy())
            vimDebug.OnEvent("Close", (*) => vimDebug.Destroy())
            vimDebug.Add("Edit", "x10 y10 w400 h300 readonly vEdit1")
            vimDebug.Add("Edit", "x10 y320 w400 h26 readonly vEdit2")
            vimDebug.Show("w420 h356")
        }
    }

    /* var【设置值】
        函数: var
        作用: 设置值
        参数: obj
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    var(obj) {
        this.vim := obj
    }

    /* Set【设置值】
        函数: Set
        作用: 设置值
        参数: v
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Set(v) {
        try {
            winName := this.vim.CheckWin()
            winObj := this.vim.GetWin(winName)
            if winObj.Count
                k := " 热键缓存:" winObj.Count winObj.KeyTemp
            else
                k := " 热键缓存:" winObj.KeyTemp

            ; 检查 GUI 是否存在且有效
            if (IsObject(vimDebug) && vimDebug.Hwnd) {
                vimDebug["Edit1"].Value := v
                vimDebug["Edit2"].Value := k
            }
        } catch {
            ; 如果出现错误，忽略（调试窗口可能已关闭）
        }
    }

    /* Get【获取值】
        函数: Get
        作用: 获取值
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Get() {
        try {
            ; 检查 GUI 是否存在且有效
            if (IsObject(vimDebug) && vimDebug.Hwnd) {
                return vimDebug["Edit1"].Value
            }
        } catch {
            ; 如果出现错误，返回空字符串
        }
        return ""
    }

    /* Add【添加值】
        函数: Add
        作用: 添加值
        参数: v
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Add(v) {
        b := this.Get()
        if this.mode
            this.Set(b)
        else
            this.Set(v "`n" b)
    }

    /* Clear【清除值】
        函数: Clear
        作用: 清除值
        参数:
        返回:
        作者:  Kawvin
        版本:  1.0
        AHK版本: 2.0.18
    */
    Clear() {
        this.Set("")
    }
}
/*
    函数: HasValue
    作用: 检查数组中是否包含指定值
    参数:
        - haystack: 要搜索的数组
        - needle: 要查找的值
    返回: 如果找到则返回true，否则返回false
    作者: BoBO
    版本: 1.0
    AHK版本: 2.0
*/
HasValue(haystack, needle) {
    if !IsObject(haystack)
        return false

    for index, value in haystack {
        if (value = needle)
            return true
    }
    return false
}
