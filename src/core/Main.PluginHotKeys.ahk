; Main.PluginHotKeys.ahk - 插件热键处理管道
; 负责从 INI 配置读取→合并→窗体设置→模式注册的完整流程

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

        if (!LoadAll && Key.HasOwnProp("enabled") && !_ParseBoolValue(Key.enabled, 0))
            continue

        pluginConfig := _ReadPluginConfig(Key, PluginName)
        hasMappings := _HasPluginMappings(Key, settingRegex)

        if (!hasMappings) {
            _ApplyPluginConfigOverrides(PluginName, pluginConfig)
            continue
        }

        if (!LoadAll && !pluginConfig["enabled"])
            continue

        winObj := _SetupPluginWindow(PluginName, pluginConfig)
        _ProcessPluginMappings(PluginName, Key, pluginConfig, settingRegex)
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

; 工具函数
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

_Main_GetPluginFilePath(pluginName) {
    return PluginCatalog.GetPluginMainFile(pluginName)
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
