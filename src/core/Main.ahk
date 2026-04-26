; Main.ahk - 核心引导和全局热键
; 引导顺序：配置 → 内存优化 → 日志/主题 → 插件 → 全局监控

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

    _ApplyThemeSettings(configCache["theme_mode"])

    CheckPlugin()
    CheckHotKey()

    _StartGlobalWindowMonitor()

    ; 用于接收来自 check.ahk 的信息
    OnMessage 0x4a, ReceiveWMCopyData
}

_LoadMainConfig() {
    static configCache := Map()

    try {
        configCache["default_enable_show_info"] := INIObject.config.default_enable_show_info
        configCache["editor"] := INIObject.config.editor
        configCache["enable_log"] := INIObject.config.enable_log
        configCache["enable_debug"] := INIObject.config.enable_debug
        configCache["theme_mode"] := INIObject.config.theme_mode
    } catch Error as e {
        VimD_Log("WARN", "MAIN_CONFIG_CACHE_READ", "读取全局配置失败，回退默认值", e)
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
    try {
        MemoryOptimizer.Enable(MAIN_MEMORY_OPT_INTERVAL_MS)
    } catch Error as e {
        VimD_Log("WARN", "MAIN_MEMORY_OPT_INIT", "内存优化器初始化失败", e)
    }
}

_EnsureConfigFile() {
    if (!FileExist(VimDesktop_Global.ConfigPath)) {
        FileCopy PathResolver.ConfigPath("vimd.ini.help.txt"), VimDesktop_Global.ConfigPath
    }
}

_InitLogAndDebug(configCache) {
    global vim
    if (configCache["enable_log"] == 1) {
        global logObject := Logger(PathResolver.RootPath("debug.log"))
    }

    if (configCache["enable_debug"] == 1) {
        vim.Debug(true)
    }
}

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
    try {
        ToolTipInfoManager.StartGlobalWindowMonitor()
    } catch Error as e {
        VimD_Log("WARN", "MAIN_WINDOW_MONITOR_START", "全局窗口监控启动失败", e)
    }
}

; ===== 插件调度入口 =====

CheckPlugin(LoadAll := 0) {
    return MainPluginBootstrap.CheckPlugin(LoadAll)
}

CheckHotKey(LoadAll := 0) {
    _ProcessGlobalHotKeys()
    _ProcessExcludeWindows()
    _ProcessPluginHotKeys(LoadAll)
}

; ===== 全局热键 =====

_ProcessGlobalHotKeys() {
    globalConfig := _ReadGlobalConfig()
    _enabled := globalConfig.Has("enabled") ? globalConfig["enabled"] : 0
    _default_Mode := globalConfig.Has("default_Mode") ? globalConfig["default_Mode"] : "normal"

    _ProcessGlobalMappings(globalConfig, _enabled)
    _SetGlobalWindowState(_enabled, _default_Mode)
}

_ReadGlobalConfig() {
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

; ===== 排除窗体 =====

_ProcessExcludeWindows() {
    for win, flag in INIObject.exclude.OwnProps() {
        if (!_IsEasyIniReserved(win)) {
            vim.SetWin(win, win)
            vim.ExcludeWin(win, true)
        }
    }
}

; ===== 热键映射（全局和插件共享） =====

_ProcessHotKeyMapping(key, action, winName, enabled) {
    if (!enabled)
        return

    this_mode := "normal"

    if (RegExMatch(action, "\[\=(.*?)\]", &mode)) {
        this_mode := mode[1]
        action := RegExReplace(action, "\[\=(.*?)\]", "")
    }

    vim.mode(this_mode, winName)

    if (RegExMatch(action, "i)^(run|key|dir|tccmd|wshkey)\|")) {
        vim.map(key, winName, this_mode, "VIMD_CMD", action, "", "")
    } else {
        actionParts := _ParseActionString(action)
        vim.map(key, winName, this_mode, actionParts.action, actionParts.param, "", actionParts.comment)
    }
}

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

; ===== 工具函数 =====

_EnsureIniSections(sectionNames) {
    _sections := INIObject.GetSections()
    for _, sectionName in sectionNames {
        if (!InStr(_sections, sectionName)) {
            INIObject.AddSection(sectionName)
        }
    }
}

; ===== RuntimeConfig 委托（保持向后兼容） =====

VimDesktop_ApplyMainConfigChanges(changedSections, sectionKeyDiffs, removedSections := "") {
    return MainRuntimeConfig.ApplyMainConfigChanges(changedSections, sectionKeyDiffs, removedSections)
}

VimDesktop_ApplyMainConfigCore() {
    return MainRuntimeConfig.ApplyMainConfigCore()
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

; ===== IPC 消息处理 =====

ReceiveWMCopyData(wParam, lParam, msg, hwnd) {
    StringAddress := NumGet(lParam + 2 * A_PtrSize, "Int64")
    AHKReturn := StrGet(StringAddress)
    if (RegExMatch(AHKReturn, "i)reload")) {
        SetTimer(() => Reload(), 500)
        return true
    }
}

#Include .\class_vim.ahk
