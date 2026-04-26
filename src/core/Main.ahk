; Main.ahk - 内存优化版本
; 优化策略：
; 1. 延迟初始化 - 只在需要时创建对象
; 2. 缓存优化 - 避免重复的文件读取和正则匹配
; 3. 批量处理 - 减少循环开销
; 4. 内存清理 - 及时释放不需要的资源

VimDesktop_Run() {
    global vim := class_vim()

    configCache := _LoadMainConfig()

    VimDesktop_Global.default_enable_show_info := configCache["default_enable_show_info"]
    VimDesktop_Global.Editor := configCache["editor"]

    _InitMemoryOptimizer()

    ; 给 check.ahk 使用
    IniWrite A_ScriptHwnd, A_Temp "\vimd_auto.ini", "auto", "hwnd"

    _EnsureConfigFile()

    _InitLogAndDebug(configCache)

    ; 应用保存的主题设置
    _ApplyThemeSettings(configCache["theme_mode"])

    CheckPlugin()
    CheckHotKey()

    _StartGlobalWindowMonitor()

    ; 用于接收来自 check.ahk 的信息
    OnMessage 0x4a, ReceiveWMCopyData
}

_LoadMainConfig() {
    ; 缓存配置访问，避免重复读取
    static configCache := Map()

    ; 批量读取配置，减少 INIObject 访问次数
    try {
        configCache["default_enable_show_info"] := INIObject.config.default_enable_show_info
        configCache["editor"] := INIObject.config.editor
        configCache["enable_log"] := INIObject.config.enable_log
        configCache["enable_debug"] := INIObject.config.enable_debug
        configCache["theme_mode"] := INIObject.config.theme_mode
    } catch Error as e {
        VimD_Log("WARN", "MAIN_CONFIG_CACHE_READ", "读取全局配置失败，回退默认值", e)
        ; 使用默认值
        configCache["default_enable_show_info"] := 0
        configCache["editor"] := "notepad.exe"
        configCache["enable_log"] := 0
        configCache["enable_debug"] := 0
        configCache["theme_mode"] := "system"
    }

    return configCache
}

_InitMemoryOptimizer() {
    global MAIN_MEMORY_OPT_INTERVAL_MS
    ; 启用内存优化器 - 每 5 分钟清理一次内存
    try {
        MemoryOptimizer.Enable(MAIN_MEMORY_OPT_INTERVAL_MS)
    } catch Error as e {
        VimD_Log("WARN", "MAIN_MEMORY_OPT_INIT", "内存优化器初始化失败", e)
        ; 忽略内存优化器初始化错误
    }
}

_EnsureConfigFile() {
    if (!FileExist(VimDesktop_Global.ConfigPath)) {
        FileCopy PathResolver.ConfigPath("vimd.ini.help.txt"), VimDesktop_Global.ConfigPath
    }
}

_InitLogAndDebug(configCache) {
    global vim
    ; 延迟初始化日志和调试
    if (configCache["enable_log"] == 1) {
        global logObject := Logger(PathResolver.RootPath("debug.log"))
    }

    if (configCache["enable_debug"] == 1) {
        vim.Debug(true)
    }
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
    } catch Error as e {
        VimD_Log("WARN", "MAIN_THEME_APPLY", "应用主题失败，回退系统默认", e)
        WindowsTheme.SetAppMode("Default")
    }
}

_StartGlobalWindowMonitor() {
    ; 启动全局窗口监控（用于清除按键缓存）
    try {
        ToolTipInfoManager.StartGlobalWindowMonitor()
    } catch Error as e {
        VimD_Log("WARN", "MAIN_WINDOW_MONITOR_START", "全局窗口监控启动失败", e)
        ; 忽略全局窗口监控启动错误
    }
}

CheckPlugin(LoadAll := 0) {
    return MainPluginBootstrap.CheckPlugin(LoadAll)
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
    globalConfig := _ReadGlobalConfig()
    _enabled := globalConfig.Has("enabled") ? globalConfig["enabled"] : 0
    _default_Mode := globalConfig.Has("default_Mode") ? globalConfig["default_Mode"] : "normal"

    _ProcessGlobalMappings(globalConfig, _enabled)
    _SetGlobalWindowState(_enabled, _default_Mode)
}

_ReadGlobalConfig() {
    ; 批量读取全局配置
    globalConfig := Map()
    for key, value in INIObject.global.OwnProps() {
        if (!_IsEasyIniReserved(key))
            globalConfig[key] := value
    }
    return globalConfig
}

_ProcessGlobalMappings(globalConfig, enabled) {
    for key, action in globalConfig {
        if (key == "enabled" || key == "default_Mode")
            continue

        _ProcessHotKeyMapping(key, action, "global", enabled)
    }
}

_SetGlobalWindowState(enabled, defaultMode) {
    ; 设置全局窗体状态
    globalWin := vim.GetWin("global")
    globalWin.status := enabled
    globalWin.defaultMode := defaultMode
    globalWin.Inside := 1

    try {
        vim.mode(defaultMode, "global")
    } catch Error as e {
        VimD_Log("WARN", "MAIN_GLOBAL_MODE_SET", "设置全局默认模式失败", e)
    }
}

; 处理排除窗体
_ProcessExcludeWindows() {
    for win, flag in INIObject.exclude.OwnProps() {
        if (!_IsEasyIniReserved(win)) {
            vim.SetWin(win, win)
            vim.ExcludeWin(win, true)
        }
    }
}

; 处理插件热键
_ProcessPluginHotKeys(LoadAll) {
    global MAIN_PLUGIN_SKIP_REGEX, MAIN_PLUGIN_SETTING_REGEX
    skipRegex := MAIN_PLUGIN_SKIP_REGEX
    settingRegex := MAIN_PLUGIN_SETTING_REGEX

    for PluginName, Key in INIObject.OwnProps() {
        if (RegExMatch(PluginName, skipRegex))
            continue
        if (!IsObject(Key)) {
            _Main_LogInvalidPluginConfig(PluginName, Key, "config_not_object")
            continue
        }

        ; Skip explicitly disabled plugins early to avoid the expensive
        ; _MergePluginIniConfig (7x INI reads). When enabled=0 is in main
        ; config, plugin INI cannot override it.
        if (!LoadAll && Key.HasOwnProp("enabled") && !_ParseBoolValue(Key.enabled, 0))
            continue

        ; 批量读取插件配置
        pluginConfig := _ReadPluginConfig(Key, PluginName)
        hasMappings := _HasPluginMappings(Key, settingRegex)

        ; 仅配置覆盖（无热键映射），不走内置插件逻辑
        if (!hasMappings) {
            _ApplyPluginConfigOverrides(PluginName, pluginConfig)
            continue
        }

        ; 检查是否启用（二次确认，处理 plugin INI 覆盖的情况）
        if (!LoadAll && !pluginConfig["enabled"])
            continue

        ; 设置窗体
        winObj := _SetupPluginWindow(PluginName, pluginConfig)

        ; 处理热键映射
        _ProcessPluginMappings(PluginName, Key, pluginConfig, settingRegex)

        ; 设置插件状态
        _SetPluginStatus(PluginName, pluginConfig, winObj)
    }
}

_HasPluginMappings(Key, settingRegex) {
    for keyName, action in Key.OwnProps() {
        if (RegExMatch(keyName, settingRegex)
        || keyName == "default_Mode"
        || keyName == "EasyIni_SectionComment")
            continue
        return true
    }
    return false
}

; 读取插件配置
_ReadPluginConfig(Key, pluginName := "") {
    config := Map()
    config["enabled"] := 0
    config["set_class"] := ""
    config["set_file"] := ""
    config["set_time_out"] := 800
    config["set_max_count"] := 100
    config["enable_show_info"] := 0
    config["default_Mode"] := "normal"
    present := Map()

    if (!IsObject(Key)) {
        if (pluginName != "")
            _Main_LogInvalidPluginConfig(pluginName, Key, "config_not_object")
        return config
    }
    for prop, value in Key.OwnProps() {
        if (config.Has(prop))
            config[prop] := value
        present[prop] := true
    }

    if (pluginName != "") {
        _MergePluginIniConfig(config, present, pluginName)
        if (!present.Has("enabled"))
            config["enabled"] := _GetEffectivePluginEnabled(pluginName, config["enabled"])
    }
    config["_present"] := present
    return config
}

_MergePluginIniConfig(config, present, pluginName) {
    try {
        sectionName := pluginName

        if (!present.Has("set_class")) {
            raw := ConfigService.GetPluginValue(pluginName, "set_class", "", sectionName, false)
            if (raw != "") {
                config["set_class"] := raw
                present["set_class"] := true
            }
        }
        if (!present.Has("set_file")) {
            raw := ConfigService.GetPluginValue(pluginName, "set_file", "", sectionName, false)
            if (raw != "") {
                config["set_file"] := raw
                present["set_file"] := true
            }
        }
        if (!present.Has("set_time_out")) {
            raw := ConfigService.GetPluginValue(pluginName, "set_time_out", "", sectionName, false)
            if (raw != "" && RegExMatch(raw, "^-?\d+$")) {
                config["set_time_out"] := Integer(raw)
                present["set_time_out"] := true
            }
        }
        if (!present.Has("set_max_count")) {
            raw := ConfigService.GetPluginValue(pluginName, "set_max_count", "", sectionName, false)
            if (raw != "" && RegExMatch(raw, "^-?\d+$")) {
                config["set_max_count"] := Integer(raw)
                present["set_max_count"] := true
            }
        }
        if (!present.Has("enable_show_info")) {
            raw := ConfigService.GetPluginValue(pluginName, "enable_show_info", "", sectionName, false)
            if (raw != "") {
                config["enable_show_info"] := _ParseBoolValue(raw, config["enable_show_info"])
                present["enable_show_info"] := true
            }
        }
        if (!present.Has("enabled")) {
            raw := ConfigService.GetPluginValue(pluginName, "enabled", "", sectionName, false)
            if (raw != "") {
                config["enabled"] := _ParseBoolValue(raw, config["enabled"])
                present["enabled"] := true
            }
        }
        if (!present.Has("default_Mode")) {
            raw := ConfigService.GetPluginValue(pluginName, "default_Mode", "", sectionName, false)
            if (raw != "") {
                config["default_Mode"] := raw
                present["default_Mode"] := true
            }
        }
    } catch Error as e {
        VimD_Log("WARN", "MAIN_MERGE_INI", "读取插件 INI 失败: " pluginName, e)
    }
}

; 设置插件窗体
_SetupPluginWindow(PluginName, config) {
    win := vim.SetWin(PluginName, config["set_class"], config["set_file"])
    vim.SetTimeOut(config["set_time_out"], PluginName)
    vim.SetMaxCount(config["set_max_count"], PluginName)

    if (config["enable_show_info"] == 1) {
        win.SetInfo(true)
    }
    return win
}

_ApplyPluginConfigOverrides(PluginName, config) {
    if !IsObject(vim)
        return
    winObj := vim.GetWin(PluginName)
    if !IsObject(winObj)
        return

    present := config.Has("_present") ? config["_present"] : Map()

    hasClassOverride := present.Has("set_class") && config["set_class"] != ""
    hasFileOverride := present.Has("set_file") && config["set_file"] != ""

    if (hasClassOverride || hasFileOverride) {
        classVal := hasClassOverride ? config["set_class"] : winObj.class
        fileVal := hasFileOverride ? config["set_file"] : winObj.filepath
        if (classVal != "" || fileVal != "")
            vim.SetWin(PluginName, classVal, fileVal)
    }

    if (present.Has("set_time_out"))
        vim.SetTimeOut(config["set_time_out"], PluginName)
    if (present.Has("set_max_count"))
        vim.SetMaxCount(config["set_max_count"], PluginName)
    if (present.Has("enable_show_info"))
        winObj.SetInfo(_ParseBoolValue(config["enable_show_info"], winObj.Info ? 1 : 0))
}

_ApplyExternalPluginOverrides(pluginName) {
    if (INIObject.HasOwnProp(pluginName))
        return
    config := _ReadPluginConfig({}, pluginName)
    _ApplyPluginConfigOverrides(pluginName, config)
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
_SetPluginStatus(PluginName, config, winObj := "") {
    if (!IsObject(winObj))
        winObj := vim.GetWin(PluginName)
    winObj.status := config["enabled"]
    winObj.defaultMode := config["default_Mode"]
    winObj.Inside := 1

    try {
        vim.mode(config["default_Mode"], PluginName)
    } catch Error as e {
        VimD_Log("WARN", "MAIN_PLUGIN_MODE_SET", "设置插件模式失败: " PluginName, e)
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
    global MAIN_CMD_CACHE_MAX
    ; 缓存正则表达式匹配结果
    static cmdCache := Map()

    if (cmdCache.Has(Param)) {
        cmdType := cmdCache[Param]
    } else {
        cmdType := _VIMD_GetCmdType(Param)

        ; 缓存结果，但限制缓存大小
        if (cmdCache.Count < MAIN_CMD_CACHE_MAX) {
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

_VIMD_GetCmdType(param) {
    if (RegExMatch(param, "i)^(run)\|"))
        return "run"
    if (RegExMatch(param, "i)^(key)\|"))
        return "key"
    if (RegExMatch(param, "i)^(dir)\|"))
        return "dir"
    if (RegExMatch(param, "i)^(tccmd)\|"))
        return "tccmd"
    if (RegExMatch(param, "i)^(wshkey)\|"))
        return "wshkey"
    return ""
}

_Main_GetPluginFilePath(pluginName) {
    return PluginCatalog.GetPluginMainFile(pluginName)
}

_EnsureIniSections(sectionNames) {
    _sections := INIObject.GetSections()
    for _, sectionName in sectionNames {
        if (!InStr(_sections, sectionName)) {
            INIObject.AddSection(sectionName)
        }
    }
}

_Main_LogInvalidPluginConfig(pluginName, keyValue, reason := "") {
    typeInfo := ""
    try {
        typeInfo := " type=" Type(keyValue)
    }
    msg := "插件配置无效: " pluginName
    if (reason != "")
        msg .= " (" reason ")"
    if (typeInfo != "")
        msg .= typeInfo
    VimD_Log("WARN", "MAIN_PLUGIN_CONFIG_INVALID", msg)
}

_ParseBoolValue(value, defaultValue := 0) {
    normalized := StrLower(Trim(value ""))
    if (normalized = "1" || normalized = "true" || normalized = "yes" || normalized = "on")
        return 1
    if (normalized = "0" || normalized = "false" || normalized = "no" || normalized = "off")
        return 0
    return defaultValue
}

_GetEffectivePluginEnabled(pluginName, defaultValue := 0) {
    global INIObject
    enabled := defaultValue
    if (INIObject.HasOwnProp("plugins") && INIObject.plugins.HasOwnProp(pluginName)) {
        enabled := _ParseBoolValue(INIObject.plugins.%pluginName%, enabled)
        if (INIObject.HasOwnProp(pluginName)) {
            keyObj := INIObject.%pluginName%
            if (IsObject(keyObj) && keyObj.HasOwnProp("enabled"))
                enabled := _ParseBoolValue(keyObj.enabled, enabled)
        }
    }
    return enabled
}

VimDesktop_ApplyMainConfigChanges(changedSections, sectionKeyDiffs, removedSections := "") {
    return MainRuntimeConfig.ApplyMainConfigChanges(changedSections, sectionKeyDiffs, removedSections)
}

VimDesktop_ApplyMainConfigCore() {
    return MainRuntimeConfig.ApplyMainConfigCore()
}

_ApplyLogSetting(enableLog) {
    try {
        global logObject
        if (enableLog == 1) {
            if (!IsSet(logObject) || !IsObject(logObject))
                logObject := Logger(PathResolver.RootPath("debug.log"))
        } else {
            if (IsSet(logObject))
                logObject := ""
        }
    } catch Error as e {
        VimD_Log("WARN", "MAIN_LOG_SWITCH", "日志切换失败", e)
    }
}

VimDesktop_ApplyPluginIniChanges(pluginNames) {
    return MainRuntimeConfig.ApplyPluginIniChanges(pluginNames)
}

VimDesktop_RefreshGlobalMappings() {
    return MainRuntimeConfig.RefreshGlobalMappings()
}

VimDesktop_RefreshExcludeWindows() {
    return MainRuntimeConfig.RefreshExcludeWindows()
}

VimDesktop_ApplyPluginStatusChanges(sectionKeyDiffs) {
    return MainRuntimeConfig.ApplyPluginStatusChanges(sectionKeyDiffs)
}

VimDesktop_RefreshPluginFromMainConfig(pluginName) {
    return MainRuntimeConfig.RefreshPluginFromMainConfig(pluginName)
}

VimDesktop_ResetPluginMappings(pluginName, disable := false) {
    return MainRuntimeConfig.ResetPluginMappings(pluginName, disable)
}

VimDesktop_ClearWinMappings(pluginName, winObj := "") {
    return MainRuntimeConfig.ClearWinMappings(pluginName, winObj)
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
