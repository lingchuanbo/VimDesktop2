class MainRuntimeConfig {
    static ApplyMainConfigChanges(changedSections, sectionKeyDiffs, removedSections := "") {
        try {
            if (!IsObject(changedSections) || changedSections.Length = 0) {
                this.ApplyMainConfigCore()
                return
            }

            if (HasValue(changedSections, "config"))
                this.ApplyMainConfigCore()

            if (HasValue(changedSections, "global"))
                this.RefreshGlobalMappings()

            if (HasValue(changedSections, "exclude"))
                this.RefreshExcludeWindows()

            if (HasValue(changedSections, "plugins") || HasValue(changedSections, "plugins_DefaultMode"))
                this.ApplyPluginStatusChanges(sectionKeyDiffs)

            if (HasValue(changedSections, "extensions"))
                VimDesktop_RefreshExtensions()

            for _, secName in changedSections {
                if (this.IsPluginSectionName(secName)) {
                    try {
                        this.RefreshPluginFromMainConfig(secName)
                    } catch Error as e {
                        VimD_Log("WARN", "MAIN_PLUGIN_REFRESH_FAIL", "Failed to hot-refresh plugin config: " secName, e)
                    }
                }
            }

            if (IsObject(removedSections)) {
                for _, secName in removedSections {
                    if (this.IsPluginSectionName(secName)) {
                        try {
                            this.ResetPluginMappings(secName, true)
                        } catch Error as e {
                            VimD_Log("WARN", "MAIN_PLUGIN_RESET_FAIL", "Failed to handle removed plugin config: " secName, e)
                        }
                    }
                }
            }
        } catch Error as e {
            VimD_Log("WARN", "MAIN_CONFIG_APPLY", "Failed to apply main config changes", e)
        }
    }

    static ApplyMainConfigCore() {
        global VimDesktop_Global
        global vim
        configCache := _LoadMainConfig()
        VimDesktop_Global.default_enable_show_info := configCache["default_enable_show_info"]
        VimDesktop_Global.Editor := configCache["editor"]
        _ApplyThemeSettings(configCache["theme_mode"])
        _ApplyLogSetting(configCache["enable_log"])
        try vim.Debug(configCache["enable_debug"] == 1)
    }

    static ApplyPluginIniChanges(pluginNames) {
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

    static RefreshGlobalMappings() {
        this.ResetPluginMappings("global")
        _ProcessGlobalHotKeys()
    }

    static RefreshExcludeWindows() {
        global vim
        if (IsObject(vim))
            vim.ExcludeWinList := Map()
        _ProcessExcludeWindows()
    }

    static ApplyPluginStatusChanges(sectionKeyDiffs) {
        global vim
        global INIObject
        if (!IsObject(sectionKeyDiffs))
            return

        pluginNames := []
        if (sectionKeyDiffs.Has("plugins")) {
            diff := sectionKeyDiffs["plugins"]
            this.PushUniqueList(pluginNames, diff["added"])
            this.PushUniqueList(pluginNames, diff["removed"])
            this.PushUniqueList(pluginNames, diff["changed"])
        }
        if (sectionKeyDiffs.Has("plugins_DefaultMode")) {
            diff := sectionKeyDiffs["plugins_DefaultMode"]
            this.PushUniqueList(pluginNames, diff["added"])
            this.PushUniqueList(pluginNames, diff["removed"])
            this.PushUniqueList(pluginNames, diff["changed"])
        }

        for _, pluginName in pluginNames {
            if (pluginName = "")
                continue

            enabled := _GetEffectivePluginEnabled(pluginName, 0)

            defaultMode := ""
            if (INIObject.HasOwnProp("plugins_DefaultMode") && INIObject.plugins_DefaultMode.HasOwnProp(pluginName))
                defaultMode := INIObject.plugins_DefaultMode.%pluginName%

            if (enabled && !IsObject(vim.GetWin(pluginName))) {
                pluginFile := PluginCatalog.GetPluginMainFile(pluginName)
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

    static RefreshPluginFromMainConfig(pluginName) {
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
                pluginFile := PluginCatalog.GetPluginMainFile(pluginName)
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

        this.ResetPluginMappings(pluginName)
        this.ClearWinMappings(pluginName)

        if (!IsObject(vim.GetWin(pluginName)) && config["enabled"]) {
            pluginFile := PluginCatalog.GetPluginMainFile(pluginName)
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

    static ResetPluginMappings(pluginName, disable := false) {
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

    static ClearWinMappings(pluginName, winObj := "") {
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

    static IsPluginSectionName(sectionName) {
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

    static PushUniqueList(target, items) {
        if (!IsObject(target) || !IsObject(items))
            return
        for _, value in items {
            if (!HasValue(target, value))
                target.Push(value)
        }
    }
}
