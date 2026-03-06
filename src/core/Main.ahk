; Main.ahk - 内存优化版本
; 优化策略：
; 1. 延迟初始化 - 只在需要时创建对象
; 2. 缓存优化 - 避免重复的文件读取和正则匹配
; 3. 批量处理 - 减少循环开销
; 4. 内存清理 - 及时释放不需要的资源

; 主配置常量（运行时通过 _InitMainConstants 保底赋值）
MAIN_PLUGIN_SCAN_INTERVAL_MS := 30000
MAIN_MEMORY_OPT_INTERVAL_MS := 300000
MAIN_CMD_CACHE_MAX := 100
MAIN_PLUGIN_SKIP_REGEX :=
    "i)^(config|exclude|global|plugins|EasyIni_KeyComment|EasyIni_SectionComment|EasyIni_ReservedFor_m_sFile|EasyIni_TopComments|default_Mode)$"
MAIN_PLUGIN_SETTING_REGEX :=
    "i)^(set_class|set_file|set_time_out|set_max_count|enable_show_info|enabled|EasyIni_KeyComment)$"

VimDesktop_Run() {
    _InitMainConstants()
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
    _InitMainConstants()
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
    _InitMainConstants()
    global MAIN_PLUGIN_SCAN_INTERVAL_MS
    ; 缓存插件目录扫描结果
    static pluginDirs := []
    static lastScanTime := 0
    static metaTimes := Map()
    static metaInitialized := false

    ; 只在必要时重新扫描插件目录（每 30 秒最多一次）
    currentTime := A_TickCount
    if (currentTime - lastScanTime > MAIN_PLUGIN_SCAN_INTERVAL_MS || pluginDirs.Length == 0) {
        pluginDirs := []
        loop files, PathResolver.PluginsDir() "\*", "D" {
            pluginDirs.Push(A_LoopFileName)
        }
        lastScanTime := currentTime
    }

    ; 检测是否有新增插件
    HasNewPlugin := false
    metaChanged := false
    newPlugins := []

    for _, pluginName in pluginDirs {
        Plugin := INIObject.plugins.HasOwnProp(pluginName) ? INIObject.plugins.%pluginName% : ""

        PluginFile := _Main_GetPluginFilePath(pluginName)
        if (Plugin == "" && FileExist(PluginFile)) {
            newPlugins.Push(pluginName)
            HasNewPlugin := true
        }

        ; 检测插件入口元信息变更
        metaPath := PathResolver.PluginPath(pluginName, "plugin.meta.ini")
        if (FileExist(metaPath)) {
            try {
                metaTime := FileGetTime(metaPath, "M")
                if (!metaInitialized) {
                    metaTimes[pluginName] := metaTime
                } else if (!metaTimes.Has(pluginName) || metaTimes[pluginName] != metaTime) {
                    metaTimes[pluginName] := metaTime
                    metaChanged := true
                }
            } catch {
                ; 忽略元信息时间读取错误
            }
        } else if (metaInitialized && metaTimes.Has(pluginName)) {
            metaTimes.Delete(pluginName)
            metaChanged := true
        }
    }

    if (!metaInitialized) {
        metaInitialized := true
        metaChanged := false
    }

    ; 批量处理新插件
    if (HasNewPlugin) {
        _ProcessNewPlugins(newPlugins)
        INIObject.save()
        Reload()
        return
    }

    if (metaChanged) {
        if (FileExist(PathResolver.RootPath("vimd.exe"))) {
            Run Format('{1}\vimd.exe {1}\plugins\check.ahk', PathResolver.RootDir())
        } else {
            Run PathResolver.PluginPath("check.ahk")
        }
        Reload()
        return
    }

    ; 优化的插件加载
    _LoadPlugins(LoadAll)
    _SetDefaultModes()
}

; 批量处理新插件
_ProcessNewPlugins(newPlugins) {
    ; 确保 sections 存在
    _EnsureIniSections(["plugins", "plugins_DefaultMode"])

    for _, pluginName in newPlugins {
        MsgBox Format(Lang["General"]["Plugin_New"], pluginName), Lang["General"]["Info"], "4160"

        if (FileExist(PathResolver.RootPath("vimd.exe"))) {
            Run Format('{1}\vimd.exe {1}\plugins\check.ahk', PathResolver.RootDir())
        } else {
            Run PathResolver.PluginPath("check.ahk")
        }

        ; 添加插件配置
        Rst := INIObject.AddKey("plugins", pluginName, 1)
        if (!Rst)
            INIObject.plugins.%pluginName% := 1

        ; 读取默认模式
        PluginFile := _Main_GetPluginFilePath(pluginName)
        _defaultMode := ""
        try {
            fileContent := FileRead(PluginFile, "UTF-8")
            if (RegExMatch(fileContent, 'im)Mode:\s*\"(.*?)\"', &m))
                _defaultMode := m[1]
        } catch Error as e {
            VimD_Log("WARN", "MAIN_PLUGIN_DEFAULTMODE_READ", "读取插件默认模式失败: " pluginName, e)
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
        if (_IsEasyIniReserved(plugin))
            continue

        pluginFile := _Main_GetPluginFilePath(plugin)
        if (FileExist(pluginFile)) {
            validPlugins[plugin] := flag
        } else {
            invalidPlugins.Push(plugin)
        }
    }

    ; 鎵归噺鍒犻櫎鏃犳晥鎻掍欢
    for _, plugin in invalidPlugins {
        try {
            INIObject.DeleteKey("plugins", plugin)
            INIObject.DeleteKey("plugins_DefaultMode", plugin)
        } catch Error as e {
            VimD_Log("WARN", "MAIN_PLUGIN_INVALID_CLEAN", "清理无效插件配置失败: " plugin, e)
        }
    }

    if (invalidPlugins.Length > 0) {
        INIObject.save()
    }

    ; 加载有效插件
    loadedCount := 0
    totalCount := 0
    for plugin, flag in validPlugins {
        totalCount++
        enabled := _GetEffectivePluginEnabled(plugin, _ParseBoolValue(flag, 0))
        if (LoadAll || enabled) {
            vim.LoadPlugin(plugin)
            winObj := vim.GetWin(plugin)
            winObj.status := enabled
            _ApplyExternalPluginOverrides(plugin)
            loadedCount++
        }
    }

    try {
        if (INIObject.config.enable_log == 1) {
            VimD_Log("INFO", "MAIN_PLUGIN_LOAD_SUMMARY",
                "插件加载完成: enabled=" loadedCount " total=" totalCount)
        }
    }
}

; 设置默认模式
_SetDefaultModes() {
    for plugin, mode in INIObject.plugins_DefaultMode.OwnProps() {
        if (_IsEasyIniReserved(plugin))
            continue

        try {
            winObj := vim.GetWin(plugin)
            winObj.defaultMode := mode
            vim.mode(mode, plugin)
            winObj.Inside := 0
        } catch Error as e {
            VimD_Log("WARN", "MAIN_DEFAULT_MODE_SET", "设置插件默认模式失败: " plugin, e)
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
    _InitMainConstants()
    global MAIN_PLUGIN_SKIP_REGEX, MAIN_PLUGIN_SETTING_REGEX
    ; 预编译正则表达式
    skipRegex := MAIN_PLUGIN_SKIP_REGEX
    settingRegex := MAIN_PLUGIN_SETTING_REGEX

    for PluginName, Key in INIObject.OwnProps() {
        if (RegExMatch(PluginName, skipRegex))
            continue
        if (!IsObject(Key)) {
            _Main_LogInvalidPluginConfig(PluginName, Key, "config_not_object")
            continue
        }

        ; 批量读取插件配置
        pluginConfig := _ReadPluginConfig(Key, PluginName)
        hasMappings := _HasPluginMappings(Key, settingRegex)

        ; 仅配置覆盖（无热键映射），不走内置插件逻辑
        if (!hasMappings) {
            _ApplyPluginConfigOverrides(PluginName, pluginConfig)
            continue
        }

        ; 检查是否启用
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
    } catch {
        ; 读取插件 ini 失败时忽略，保持现有配置
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
    _InitMainConstants()
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
    return PathResolver.PluginPath(pluginName, pluginName ".ahk")
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
    try {
        if (!IsObject(changedSections) || changedSections.Length = 0) {
            VimDesktop_ApplyMainConfigCore()
            return
        }

        if (HasValue(changedSections, "config"))
            VimDesktop_ApplyMainConfigCore()

        if (HasValue(changedSections, "global"))
            VimDesktop_RefreshGlobalMappings()

        if (HasValue(changedSections, "exclude"))
            VimDesktop_RefreshExcludeWindows()

        if (HasValue(changedSections, "plugins") || HasValue(changedSections, "plugins_DefaultMode"))
            VimDesktop_ApplyPluginStatusChanges(sectionKeyDiffs)

        if (HasValue(changedSections, "extensions"))
            VimDesktop_RefreshExtensions()

        for _, secName in changedSections {
            if (VimDesktop_IsPluginSectionName(secName)) {
                try {
                    VimDesktop_RefreshPluginFromMainConfig(secName)
                } catch Error as e {
                    VimD_Log("WARN", "MAIN_PLUGIN_REFRESH_FAIL", "插件配置热刷新失败: " secName, e)
                }
            }
        }

        if (IsObject(removedSections)) {
            for _, secName in removedSections {
                if (VimDesktop_IsPluginSectionName(secName)) {
                    try {
                        VimDesktop_ResetPluginMappings(secName, true)
                    } catch Error as e {
                        VimD_Log("WARN", "MAIN_PLUGIN_RESET_FAIL", "插件配置移除处理失败: " secName, e)
                    }
                }
            }
        }
    } catch Error as e {
        VimD_Log("WARN", "MAIN_CONFIG_APPLY", "应用主配置变更失败", e)
    }
}

VimDesktop_ApplyMainConfigCore() {
    global VimDesktop_Global
    global vim
    configCache := _LoadMainConfig()
    VimDesktop_Global.default_enable_show_info := configCache["default_enable_show_info"]
    VimDesktop_Global.Editor := configCache["editor"]
    _ApplyThemeSettings(configCache["theme_mode"])
    _ApplyLogSetting(configCache["enable_log"])
    try vim.Debug(configCache["enable_debug"] == 1)
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
    } catch {
        ; 忽略日志切换失败
    }
}

VimDesktop_ApplyPluginIniChanges(pluginNames) {
    global vim
    if (!IsObject(pluginNames))
        return

    for _, pluginName in pluginNames {
        if (pluginName = "")
            continue
        winObj := vim.GetWin(pluginName)
        if (!IsObject(winObj))
            continue
        config := _ReadPluginConfig({}, pluginName)
        _ApplyPluginConfigOverrides(pluginName, config)
        _SetPluginStatus(pluginName, config, winObj)
    }
}

VimDesktop_RefreshGlobalMappings() {
    VimDesktop_ResetPluginMappings("global")
    _ProcessGlobalHotKeys()
}

VimDesktop_RefreshExcludeWindows() {
    global vim
    if (IsObject(vim))
        vim.ExcludeWinList := Map()
    _ProcessExcludeWindows()
}

VimDesktop_ApplyPluginStatusChanges(sectionKeyDiffs) {
    global vim
    global INIObject
    if (!IsObject(sectionKeyDiffs))
        return

    pluginNames := []
    if (sectionKeyDiffs.Has("plugins")) {
        diff := sectionKeyDiffs["plugins"]
        VimDesktop_PushUniqueList(pluginNames, diff["added"])
        VimDesktop_PushUniqueList(pluginNames, diff["removed"])
        VimDesktop_PushUniqueList(pluginNames, diff["changed"])
    }
    if (sectionKeyDiffs.Has("plugins_DefaultMode")) {
        diff := sectionKeyDiffs["plugins_DefaultMode"]
        VimDesktop_PushUniqueList(pluginNames, diff["added"])
        VimDesktop_PushUniqueList(pluginNames, diff["removed"])
        VimDesktop_PushUniqueList(pluginNames, diff["changed"])
    }

    for _, pluginName in pluginNames {
        if (pluginName = "")
            continue

        enabled := _GetEffectivePluginEnabled(pluginName, 0)

        defaultMode := ""
        if (INIObject.HasOwnProp("plugins_DefaultMode") && INIObject.plugins_DefaultMode.HasOwnProp(pluginName))
            defaultMode := INIObject.plugins_DefaultMode.%pluginName%

        if (enabled && !IsObject(vim.GetWin(pluginName))) {
            pluginFile := _Main_GetPluginFilePath(pluginName)
            if (FileExist(pluginFile))
                vim.LoadPlugin(pluginName)
        }

        winObj := vim.GetWin(pluginName)
        if (!IsObject(winObj))
            continue

        config := Map("enabled", enabled, "default_Mode", defaultMode)
        if (config["default_Mode"] = "")
            config["default_Mode"] := winObj.defaultMode != "" ? winObj.defaultMode : "normal"
        _SetPluginStatus(pluginName, config, winObj)
    }
}

VimDesktop_RefreshPluginFromMainConfig(pluginName) {
    global INIObject
    global vim
    if (!IsObject(INIObject))
        return
    if (!INIObject.HasOwnProp(pluginName))
        return

    keyObj := INIObject.%pluginName%
    if (!IsObject(keyObj)) {
        _Main_LogInvalidPluginConfig(pluginName, keyObj, "config_not_object")
        return
    }

    _InitMainConstants()
    global MAIN_PLUGIN_SETTING_REGEX

    config := _ReadPluginConfig(keyObj, pluginName)
    hasMappings := _HasPluginMappings(keyObj, MAIN_PLUGIN_SETTING_REGEX)

    if (!hasMappings) {
        if (!IsObject(vim.GetWin(pluginName)) && config["enabled"]) {
            pluginFile := _Main_GetPluginFilePath(pluginName)
            if (FileExist(pluginFile))
                vim.LoadPlugin(pluginName)
        }

        winObj := vim.GetWin(pluginName)
        if (IsObject(winObj)) {
            if (!config["enabled"])
                try vim.Control(false, pluginName, true)
            _ApplyPluginConfigOverrides(pluginName, config)
            _SetPluginStatus(pluginName, config, winObj)
        }
        return
    }

    VimDesktop_ResetPluginMappings(pluginName)
    VimDesktop_ClearWinMappings(pluginName)

    if (!IsObject(vim.GetWin(pluginName)) && config["enabled"]) {
        pluginFile := _Main_GetPluginFilePath(pluginName)
        if (FileExist(pluginFile))
            vim.LoadPlugin(pluginName)
    }

    winObj := vim.GetWin(pluginName)

    if (!config["enabled"]) {
        if (IsObject(winObj))
            _SetPluginStatus(pluginName, config, winObj)
        return
    }

    winObj := _SetupPluginWindow(pluginName, config)
    _ProcessPluginMappings(pluginName, keyObj, config, MAIN_PLUGIN_SETTING_REGEX)
    _SetPluginStatus(pluginName, config, winObj)
}

VimDesktop_ResetPluginMappings(pluginName, disable := false) {
    global vim
    if (!IsObject(vim))
        return

    winObj := vim.GetWin(pluginName)
    if (!IsObject(winObj))
        return

    try vim.Control(false, pluginName, true)

    winObj.KeyList := Map()
    winObj.SuperKeyList := Map()
    winObj.KeyTemp := ""
    winObj.Count := 0

    if (IsObject(winObj.modeList)) {
        for _, modeObj in winObj.modeList {
            if IsObject(modeObj) {
                modeObj.keyMapList := Map()
                modeObj.keyMoreList := Map()
                modeObj.noWaitList := Map()
            }
        }
        winObj.modeList := Map()
    }

    if (vim.ActionList.Has(pluginName))
        vim.ActionList.Delete(pluginName)

    if IsObject(vim.ActionFromPlugin) {
        keysToDelete := []
        for key, value in vim.ActionFromPlugin {
            if (value = pluginName)
                keysToDelete.Push(key)
        }
        for _, key in keysToDelete
            vim.ActionFromPlugin.Delete(key)
    }

    if (disable)
        winObj.status := 0
}

VimDesktop_ClearWinMappings(pluginName, winObj := "") {
    global vim
    if (!IsObject(vim))
        return

    if (!IsObject(winObj))
        winObj := vim.GetWin(pluginName)
    if (!IsObject(winObj))
        return

    classVal := winObj.class
    if (classVal != "") {
        if (InStr(classVal, "|")) {
            classes := StrSplit(classVal, "|")
            for _, singleClass in classes {
                key := "class`t" Trim(singleClass)
                if (vim.WinInfo.Has(key) && vim.WinInfo[key] = pluginName)
                    vim.WinInfo.Delete(key)
            }
        } else {
            key := "class`t" classVal
            if (vim.WinInfo.Has(key) && vim.WinInfo[key] = pluginName)
                vim.WinInfo.Delete(key)
        }
    }

    if (winObj.filepath != "") {
        key := "filepath`t" winObj.filepath
        if (vim.WinInfo.Has(key) && vim.WinInfo[key] = pluginName)
            vim.WinInfo.Delete(key)
    }

    if (winObj.title != "") {
        key := "title`t" winObj.title
        if (vim.WinInfo.Has(key) && vim.WinInfo[key] = pluginName)
            vim.WinInfo.Delete(key)
    }
}

VimDesktop_IsPluginSectionName(sectionName) {
    _InitMainConstants()
    global MAIN_PLUGIN_SKIP_REGEX
    if (sectionName = "")
        return false
    if (sectionName = "plugins_DefaultMode" || sectionName = "extensions")
        return false
    if (RegExMatch(sectionName, MAIN_PLUGIN_SKIP_REGEX))
        return false
    return true
}

VimDesktop_PushUniqueList(target, items) {
    if (!IsObject(target) || !IsObject(items))
        return
    for _, value in items {
        if (!HasValue(target, value))
            target.Push(value)
    }
}

_InitMainConstants() {
    global MAIN_PLUGIN_SCAN_INTERVAL_MS
    global MAIN_MEMORY_OPT_INTERVAL_MS
    global MAIN_CMD_CACHE_MAX
    global MAIN_PLUGIN_SKIP_REGEX
    global MAIN_PLUGIN_SETTING_REGEX

    if (!IsSet(MAIN_PLUGIN_SCAN_INTERVAL_MS) || MAIN_PLUGIN_SCAN_INTERVAL_MS = "")
        MAIN_PLUGIN_SCAN_INTERVAL_MS := 30000
    if (!IsSet(MAIN_MEMORY_OPT_INTERVAL_MS) || MAIN_MEMORY_OPT_INTERVAL_MS = "")
        MAIN_MEMORY_OPT_INTERVAL_MS := 300000
    if (!IsSet(MAIN_CMD_CACHE_MAX) || MAIN_CMD_CACHE_MAX = "")
        MAIN_CMD_CACHE_MAX := 100
    if (!IsSet(MAIN_PLUGIN_SKIP_REGEX) || MAIN_PLUGIN_SKIP_REGEX = "")
        MAIN_PLUGIN_SKIP_REGEX :=
            "i)^(config|exclude|global|plugins|EasyIni_KeyComment|EasyIni_SectionComment|EasyIni_ReservedFor_m_sFile|EasyIni_TopComments|default_Mode)$"
    if (!IsSet(MAIN_PLUGIN_SETTING_REGEX) || MAIN_PLUGIN_SETTING_REGEX = "")
        MAIN_PLUGIN_SETTING_REGEX :=
            "i)^(set_class|set_file|set_time_out|set_max_count|enable_show_info|enabled|EasyIni_KeyComment)$"
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
