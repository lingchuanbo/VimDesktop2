; Main.ahk - 内存优化版本
; 优化策略：
; 1. 延迟初始化 - 只在需要时创建对象
; 2. 缓存优化 - 避免重复的文件读取和正则匹配
; 3. 批量处理 - 减少循环开销
; 4. 内存清理 - 及时释放不需要的资源

VimDesktop_Run() {
    global vim := class_vim()

    ; 缓存配置访问，避免重复读取
    static configCache := Map()

    ; 批量读取配置，减少INIObject访问次数
    try {
        configCache["default_enable_show_info"] := INIObject.config.default_enable_show_info
        configCache["editor"] := INIObject.config.editor
        configCache["enable_log"] := INIObject.config.enable_log
        configCache["enable_debug"] := INIObject.config.enable_debug
        configCache["theme_mode"] := INIObject.config.theme_mode
    } catch {
        ; 使用默认值
        configCache["default_enable_show_info"] := 0
        configCache["editor"] := "notepad.exe"
        configCache["enable_log"] := 0
        configCache["enable_debug"] := 0
        configCache["theme_mode"] := "system"
    }

    VimDesktop_Global.default_enable_show_info := configCache["default_enable_show_info"]
    VimDesktop_Global.Editor := configCache["editor"]

    ; 启用内存优化器 - 每5分钟清理一次内存
    try {
        MemoryOptimizer.Enable(300000)
    } catch {
        ; 忽略内存优化器初始化错误
    }

    ; 给 check.ahk 使用
    IniWrite A_ScriptHwnd, A_Temp "\vimd_auto.ini", "auto", "hwnd"

    if (!FileExist(VimDesktop_Global.ConfigPath)) {
        FileCopy ".\Custom\vimd.ini.help.txt", VimDesktop_Global.ConfigPath
    }

    ; 延迟初始化日志和调试
    if (configCache["enable_log"] == 1) {
        global logObject := Logger(A_ScriptDir "\debug.log")
    }

    if (configCache["enable_debug"] == 1) {
        vim.Debug(true)
    }

    ; 应用保存的主题设置
    _ApplyThemeSettings(configCache["theme_mode"])

    CheckPlugin()
    CheckHotKey()

    ; 用于接收来自 check.ahk 的信息
    OnMessage 0x4a, ReceiveWMCopyData
}

; 优化的主题设置函数
_ApplyThemeSettings(themeMode) {
    try {
        switch themeMode {
            case "light":
                WindowsTheme.SetAppMode(false)
            case "dark":
                WindowsTheme.SetAppMode(true)
            default:
                WindowsTheme.SetAppMode("Default")
        }
    } catch {
        WindowsTheme.SetAppMode("Default")
    }
}

CheckPlugin(LoadAll := 0) {
    ; 缓存插件目录扫描结果
    static pluginDirs := []
    static lastScanTime := 0

    ; 只在必要时重新扫描插件目录（每30秒最多一次）
    currentTime := A_TickCount
    if (currentTime - lastScanTime > 30000 || pluginDirs.Length == 0) {
        pluginDirs := []
        loop files, A_ScriptDir "\plugins\*", "D" {
            pluginDirs.Push(A_LoopFileName)
        }
        lastScanTime := currentTime
    }

    ; 检测是否有新增插件
    HasNewPlugin := false
    newPlugins := []

    for _, pluginName in pluginDirs {
        Plugin := ""
        try {
            Plugin := INIObject.plugins.%pluginName%
        } catch {
            Plugin := ""
        }

        PluginFile := A_ScriptDir "\plugins\" pluginName "\" pluginName ".ahk"
        if (Plugin == "" && FileExist(PluginFile)) {
            newPlugins.Push(pluginName)
            HasNewPlugin := true
        }
    }

    ; 批量处理新插件
    if (HasNewPlugin) {
        _ProcessNewPlugins(newPlugins)
        INIObject.save()
        Reload()
        return
    }

    ; 优化的插件加载
    _LoadPlugins(LoadAll)
    _SetDefaultModes()
}

; 批量处理新插件
_ProcessNewPlugins(newPlugins) {
    ; 确保sections存在
    _sections := INIObject.GetSections()
    if (!InStr(_sections, "plugins")) {
        INIObject.AddSection("plugins")
    }
    if (!InStr(_sections, "plugins_DefaultMode")) {
        INIObject.AddSection("plugins_DefaultMode")
    }

    for _, pluginName in newPlugins {
        MsgBox Format(Lang["General"]["Plugin_New"], pluginName), Lang["General"]["Info"], "4160"

        if (FileExist(A_ScriptDir "\vimd.exe")) {
            Run Format('{1}\vimd.exe {1}\plugins\check.ahk', A_ScriptDir)
        } else {
            Run A_ScriptDir "\plugins\check.ahk"
        }

        ; 添加插件配置
        Rst := INIObject.AddKey("plugins", pluginName, 1)
        if (!Rst)
            INIObject.plugins.%pluginName% := 1

        ; 读取默认模式
        PluginFile := A_ScriptDir "\plugins\" pluginName "\" pluginName ".ahk"
        _defaultMode := ""
        try {
            fileContent := FileRead(PluginFile, "UTF-8")
            if (RegExMatch(fileContent, 'im)Mode:\s*\"(.*?)\"', &m))
                _defaultMode := m[1]
        }

        Rst := INIObject.AddKey("plugins_DefaultMode", pluginName, _defaultMode)
        if (!Rst)
            INIObject.plugins_DefaultMode.%pluginName% := _defaultMode

        Sleep 1000
    }
}

; 优化的插件加载
_LoadPlugins(LoadAll) {
    ; 批量检查插件文件存在性
    validPlugins := Map()
    invalidPlugins := []

    for plugin, flag in INIObject.plugins.OwnProps() {
        if (plugin == "EasyIni_KeyComment")
            continue

        pluginFile := A_ScriptDir "\plugins\" plugin "\" plugin ".ahk"
        if (FileExist(pluginFile)) {
            validPlugins[plugin] := flag
        } else {
            invalidPlugins.Push(plugin)
        }
    }

    ; 批量删除无效插件
    for _, plugin in invalidPlugins {
        try {
            INIObject.DeleteKey("plugins", plugin)
            INIObject.DeleteKey("plugins_DefaultMode", plugin)
        }
    }

    if (invalidPlugins.Length > 0) {
        INIObject.save()
    }

    ; 加载有效插件
    for plugin, flag in validPlugins {
        if (LoadAll || flag) {
            vim.LoadPlugin(plugin)
            vim.GetWin(plugin).status := flag
        }
    }
}

; 设置默认模式
_SetDefaultModes() {
    for plugin, mode in INIObject.plugins_DefaultMode.OwnProps() {
        if (plugin == "EasyIni_KeyComment")
            continue

        try {
            winObj := vim.GetWin(plugin)
            winObj.defaultMode := mode
            vim.mode(mode, plugin)
            winObj.Inside := 0
        }
    }
}

CheckHotKey(LoadAll := 0) {
    ; 处理全局热键
    _ProcessGlobalHotKeys()

    ; 处理排除窗体
    _ProcessExcludeWindows()

    ; 处理插件热键
    _ProcessPluginHotKeys(LoadAll)
}

; 处理全局热键
_ProcessGlobalHotKeys() {
    _default_Mode := "normal"
    _enabled := 0

    ; 批量读取全局配置
    globalConfig := Map()
    for key, value in INIObject.global.OwnProps() {
        if (key != "EasyIni_KeyComment")
            globalConfig[key] := value
    }

    ; 检查是否启用
    if (globalConfig.Has("enabled"))
        _enabled := globalConfig["enabled"]

    ; 获取默认模式
    if (globalConfig.Has("default_Mode"))
        _default_Mode := globalConfig["default_Mode"]

    ; 处理热键映射
    for key, action in globalConfig {
        if (key == "enabled" || key == "default_Mode")
            continue

        _ProcessHotKeyMapping(key, action, "global", _enabled)
    }

    ; 设置全局窗体状态
    globalWin := vim.GetWin("global")
    globalWin.status := _enabled
    globalWin.defaultMode := _default_Mode
    globalWin.Inside := 1

    try {
        vim.mode(_default_Mode, "global")
    }
}

; 处理排除窗体
_ProcessExcludeWindows() {
    for win, flag in INIObject.exclude.OwnProps() {
        if (win != "EasyIni_KeyComment") {
            vim.SetWin(win, win)
            vim.ExcludeWin(win, true)
        }
    }
}

; 处理插件热键
_ProcessPluginHotKeys(LoadAll) {
    ; 预编译正则表达式
    static skipRegex :=
        "i)^(config|exclude|global|plugins|EasyIni_KeyComment|EasyIni_SectionComment|EasyIni_ReservedFor_m_sFile|EasyIni_TopComments|default_Mode)$"
    static settingRegex :=
        "i)^(set_class|set_file|set_time_out|set_max_count|enable_show_info|enabled|EasyIni_KeyComment)$"

    for PluginName, Key in INIObject.OwnProps() {
        if (RegExMatch(PluginName, skipRegex))
            continue

        ; 批量读取插件配置
        pluginConfig := _ReadPluginConfig(Key)

        ; 检查是否启用
        if (!LoadAll && !pluginConfig["enabled"])
            continue

        ; 设置窗体
        _SetupPluginWindow(PluginName, pluginConfig)

        ; 处理热键映射
        _ProcessPluginMappings(PluginName, Key, pluginConfig, settingRegex)

        ; 设置插件状态
        _SetPluginStatus(PluginName, pluginConfig)
    }
}

; 读取插件配置
_ReadPluginConfig(Key) {
    config := Map()
    config["enabled"] := 0
    config["set_class"] := ""
    config["set_file"] := ""
    config["set_time_out"] := 800
    config["set_max_count"] := 100
    config["enable_show_info"] := 0
    config["default_Mode"] := "normal"

    for prop, value in Key.OwnProps() {
        if (config.Has(prop))
            config[prop] := value
    }

    return config
}

; 设置插件窗体
_SetupPluginWindow(PluginName, config) {
    win := vim.SetWin(PluginName, config["set_class"], config["set_file"])
    vim.SetTimeOut(config["set_time_out"], PluginName)
    vim.SetMaxCount(config["set_max_count"], PluginName)

    if (config["enable_show_info"] == 1) {
        win.SetInfo(true)
    }
}

; 处理插件映射
_ProcessPluginMappings(PluginName, Key, config, settingRegex) {
    for keyName, action in Key.OwnProps() {
        if (RegExMatch(keyName, settingRegex) || keyName == "default_Mode")
            continue

        _ProcessHotKeyMapping(keyName, action, PluginName, true)
    }
}

; 设置插件状态
_SetPluginStatus(PluginName, config) {
    winObj := vim.GetWin(PluginName)
    winObj.status := config["enabled"]
    winObj.defaultMode := config["default_Mode"]
    winObj.Inside := 1

    try {
        vim.mode(config["default_Mode"], PluginName)
    }
}

; 统一的热键映射处理
_ProcessHotKeyMapping(key, action, winName, enabled) {
    if (!enabled)
        return

    this_mode := "normal"

    ; 解析模式
    if (RegExMatch(action, "\[\=(.*?)\]", &mode)) {
        this_mode := mode[1]
        action := RegExReplace(action, "\[\=(.*?)\]", "")
    }

    vim.mode(this_mode, winName)

    ; 处理不同类型的动作
    if (RegExMatch(action, "i)^(run|key|dir|tccmd|wshkey)\|")) {
        vim.map(key, winName, this_mode, "VIMD_CMD", action, "", "")
    } else {
        ; 解析参数和注释
        actionParts := _ParseActionString(action)
        vim.map(key, winName, this_mode, actionParts.action, actionParts.param, "", actionParts.comment)
    }
}

; 解析动作字符串
_ParseActionString(actionStr) {
    result := { action: actionStr, param: "", comment: "" }

    if (InStr(actionStr, "||")) {
        parts := StrSplit(actionStr, "||", " ")
        switch parts.Length {
            case 3:
                result.action := parts[1]
                result.param := parts[2]
                result.comment := parts[3]
            case 2:
                result.action := parts[1]
                result.param := parts[2]
        }
    }

    return result
}

VIMD_CMD(Param) {
    ; 缓存正则表达式匹配结果
    static cmdCache := Map()

    if (cmdCache.Has(Param)) {
        cmdType := cmdCache[Param]
    } else {
        cmdType := ""
        if (RegExMatch(Param, "i)^(run)\|", &m)) {
            cmdType := "run"
        } else if (RegExMatch(Param, "i)^(key)\|", &m)) {
            cmdType := "key"
        } else if (RegExMatch(Param, "i)^(dir)\|", &m)) {
            cmdType := "dir"
        } else if (RegExMatch(Param, "i)^(tccmd)\|", &m)) {
            cmdType := "tccmd"
        } else if (RegExMatch(Param, "i)^(wshkey)\|", &m)) {
            cmdType := "wshkey"
        }

        ; 缓存结果，但限制缓存大小
        if (cmdCache.Count < 100) {
            cmdCache[Param] := cmdType
        }
    }

    ; 执行对应命令
    switch cmdType {
        case "run":
            Run SubStr(Param, 5)
        case "key":
            Send SubStr(Param, 5)
        case "dir":
            _HandleDirCommand(SubStr(Param, 5))
        case "tccmd":
            _HandleTCCommand(SubStr(Param, 7))
        case "wshkey":
            _HandleWshKeyCommand(SubStr(Param, 8))
    }
}

; 处理目录命令
_HandleDirCommand(path) {
    f := "TC_OpenPath"
    if (Type(%f%) == "Func") {
        %f%(path, false)
    } else {
        Run path
    }
}

; 处理TC命令
_HandleTCCommand(cmd) {
    f := "TC_Run"
    if (Type(%f%) == "Func") {
        %f%(cmd)
    }
}

; 处理WSH按键命令
_HandleWshKeyCommand(keys) {
    static WshShell := 0
    if (!WshShell) {
        WshShell := ComObject("WScript.Shell")
    }
    WshShell.SendKeys(keys)
}

ReceiveWMCopyData(wParam, lParam, msg, hwnd) {
    ; 获取 CopyDataStruct 的 lpData 成员.
    StringAddress := NumGet(lParam + 2 * A_PtrSize, "Int64")
    ; 从结构中复制字符串.
    AHKReturn := StrGet(StringAddress)
    if (RegExMatch(AHKReturn, "i)reload")) {
        SetTimer(() => Reload(), 500)
        return true
    }
}

#Include .\class_vim.ahk