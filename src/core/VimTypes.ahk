; VimTypes.ahk - 核心数据类型定义
; 原作者: Kawvin, 优化: BoBO

; __win - 窗口对象，管理按键列表、模式列表、状态等
class __win {
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

    ; 切换模式，不存在则自动创建
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

    ; 返回当前模式名称
    ExistMode() {
        return this.mode
    }

    ; 设置是否显示提示信息
    SetInfo(bold) {
        this.info := bold
    }

    ; 设置显示信息回调函数
    SetShowInfo(func) {
        this.ShowInfoFunc := func
    }

    ; 设置隐藏信息回调函数
    SetHideInfo(func) {
        this.HideInfoFunc := func
    }

    ; 显示按键提示
    ShowMore() {
        f := this.ShowInfoFunc
        if Type(%f%) = "Func" And this.Info
            %f%()
    }

    ; 隐藏按键提示
    HideMore() {
        f := this.HideInfoFunc
        if Type(%f%) = "Func" And this.Info
            %f%()
    }
}

; __Mode - 模式对象，管理热键映射(keyMapList)、组合键(keyMoreList)、无等待(noWaitList)
class __Mode {
    __new(modeName) {
        this.name := modeName
        this.keyMapList := Map()
        this.keyMoreList := Map()
        this.noWaitList := Map()
        this.modeFunction := ""
    }

    SetKeyMap(key, action) {
        this.keyMapList[key] := action
    }

    GetKeyMap(key) {
        if this.keyMapList.Has(key)
            return this.keyMapList[key]
        else
            return ""
    }

    DelKeyMap(key) {
        this.keyMapList[key] := ""
    }

    SetNoWait(key, bold) {
        this.noWaitList[key] := bold
    }

    GetNoWait(key) {
        if this.noWaitList.Has(key)
            return this.noWaitList[key]
        else
            return false
    }

    SetMoreKey(key) {
        this.keyMoreList[key] := true
    }

    GetMoreKey(key) {
        if this.keyMoreList.Has(key)
            return this.keyMoreList[key]
        else
            return false
    }
}

; __Action - 动作对象
; Type: 1=执行函数(默认), 2=运行命令行, 3=发送文本
class __Action {
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

    SetFunction(Function) {
        this.Function := Function
        this.Type := 1
    }

    SetCmdLine(CmdLine) {
        this.CmdLine := CmdLine
        this.Type := 2
    }

    SetHotString(HotString) {
        this.HotString := HotString
        this.Type := 3
    }

    SetMaxTimes(Times) {
        this.MaxTimes := Times
    }

    ; 执行动作，支持指定次数
    Do(Times := 0) {
        Times := !Times ? 1 : Times
        if this.MaxTimes And (Times > this.MaxTimes)
            Times := this.MaxTimes
        loop Times {
            switch this.Type {
                case 1:
                    f := this.Function
                    f := RegExReplace(f, "<\d>$", "")

                    ; 特殊处理 SingleDoubleFullHandlers 函数
                    if (f = "SingleDoubleFullHandlers") {
                        global singleDoubleHandlers
                        if (IsSet(singleDoubleHandlers) && singleDoubleHandlers.Has(this.Name)) {
                            handler := singleDoubleHandlers[this.Name]
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

; __Plugin - 插件对象，自动从 plugin.meta.ini 加载元信息
class __Plugin {
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

    ; 检查插件入口函数是否存在并执行
    CheckFunc() {
        p := this.PluginName
        if (Type(%p%) = "Func") {
            %p%()
            this.Error := false
        } else
            this.Error := true
    }
}

; __vimDebug - 调试窗口
class __vimDebug {
    __new(key) {
        this.mode := key
        ; 销毁旧窗口
        try {
            if (IsObject(vimDebug) && vimDebug.Hwnd)
                vimDebug.Destroy()
        } catch {
        }

        ; 创建新窗口
        global vimDebug := Gui("+AlwaysOnTop", "_vimDebug")
        vimDebug.SetFont("c000000 s10", "Verdana")
        vimDebug.OnEvent("Escape", (*) => vimDebug.Destroy())
        vimDebug.OnEvent("Close", (*) => vimDebug.Destroy())

        if key {
            ; 紧凑模式：仅显示单行
            vimDebug.Add("Edit", "x-2 y-2 w400 h60 readonly vEdit1")
            vimDebug.Show("w378 h56 y600")
        } else {
            ; 完整模式：显示详细调试信息
            vimDebug.Add("Edit", "x10 y10 w400 h300 readonly vEdit1")
            vimDebug.Add("Edit", "x10 y320 w400 h26 readonly vEdit2")
            vimDebug.Show("w420 h356")
        }
    }

    var(obj) {
        this.vim := obj
    }

    Set(v) {
        try {
            winName := this.vim.CheckWin()
            winObj := this.vim.GetWin(winName)
            if winObj.Count
                k := " 热键缓存:" winObj.Count winObj.KeyTemp
            else
                k := " 热键缓存:" winObj.KeyTemp

            if (IsObject(vimDebug) && vimDebug.Hwnd) {
                vimDebug["Edit1"].Value := v
                vimDebug["Edit2"].Value := k
            }
        } catch {
        }
    }

    Get() {
        try {
            if (IsObject(vimDebug) && vimDebug.Hwnd) {
                return vimDebug["Edit1"].Value
            }
        } catch {
        }
        return ""
    }

    Add(v) {
        b := this.Get()
        if this.mode
            this.Set(b)
        else
            this.Set(v "`n" b)
    }

    Clear() {
        this.Set("")
    }
}

; 检查数组中是否包含指定值
HasValue(haystack, needle) {
    if !IsObject(haystack)
        return false

    for index, value in haystack {
        if (value = needle)
            return true
    }
    return false
}
