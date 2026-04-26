class MainPluginBootstrap {
    static CheckPlugin(LoadAll := 0) {
        global MAIN_PLUGIN_SCAN_INTERVAL_MS
        static pluginDirs := []
        static lastScanTime := 0
        static metaTimes := Map()
        static fileTimes := Map()   ; 跟踪 .ahk 文件修改时间
        static metaInitialized := false

        currentTime := A_TickCount
        if (currentTime - lastScanTime > MAIN_PLUGIN_SCAN_INTERVAL_MS || pluginDirs.Length == 0) {
            pluginDirs := PluginCatalog.ListPluginNames()
            lastScanTime := currentTime
        }

        hasNewPlugin := false
        anyChange := false
        newPlugins := []

        for _, pluginName in pluginDirs {
            pluginEnabled := INIObject.plugins.HasOwnProp(pluginName) ? INIObject.plugins.%pluginName% : ""

            pluginFile := PluginCatalog.GetPluginMainFile(pluginName)
            if (pluginEnabled == "" && FileExist(pluginFile)) {
                newPlugins.Push(pluginName)
                hasNewPlugin := true
            }

            ; 检测 plugin.meta.ini 修改
            metaPath := PluginCatalog.GetMetaPath(pluginName)
            if (FileExist(metaPath)) {
                try {
                    metaTime := FileGetTime(metaPath, "M")
                    if (!metaInitialized) {
                        metaTimes[pluginName] := metaTime
                    } else if (!metaTimes.Has(pluginName) || metaTimes[pluginName] != metaTime) {
                        metaTimes[pluginName] := metaTime
                        anyChange := true
                    }
                } catch {
                }
            } else if (metaInitialized && metaTimes.Has(pluginName)) {
                metaTimes.Delete(pluginName)
                anyChange := true
            }

            ; 检测 .ahk 文件修改
            if (FileExist(pluginFile)) {
                try {
                    fileTime := FileGetTime(pluginFile, "M")
                    if (!metaInitialized) {
                        fileTimes[pluginName] := fileTime
                    } else if (!fileTimes.Has(pluginName) || fileTimes[pluginName] != fileTime) {
                        fileTimes[pluginName] := fileTime
                        anyChange := true
                    }
                } catch {
                }
            } else if (metaInitialized && fileTimes.Has(pluginName)) {
                fileTimes.Delete(pluginName)
                anyChange := true
            }
        }

        if (!metaInitialized) {
            metaInitialized := true
            anyChange := false
        }

        if (hasNewPlugin) {
            this.ProcessNewPlugins(newPlugins)
            INIObject.save()
            Reload()
            return
        }

        if (anyChange) {
            this.RebuildPluginIncludes()
            Reload()
            return
        }

        this.LoadPlugins(LoadAll)
        this.SetDefaultModes()
    }

    static ProcessNewPlugins(newPlugins) {
        _EnsureIniSections(["plugins", "plugins_DefaultMode"])

        for _, pluginName in newPlugins {
            MsgBox Format(Lang["General"]["Plugin_New"], pluginName), Lang["General"]["Info"], "4160"
            this.RebuildPluginIncludes()

            rst := INIObject.AddKey("plugins", pluginName, 1)
            if (!rst)
                INIObject.plugins.%pluginName% := 1

            pluginFile := PluginCatalog.GetPluginMainFile(pluginName)
            defaultMode := ""
            try {
                fileContent := FileRead(pluginFile, "UTF-8")
                if (RegExMatch(fileContent, 'im)Mode:\s*\"(.*?)\"', &m))
                    defaultMode := m[1]
            } catch Error as e {
                VimD_Log("WARN", "MAIN_PLUGIN_DEFAULTMODE_READ", "Failed to read plugin default mode: " pluginName, e)
            }

            rst := INIObject.AddKey("plugins_DefaultMode", pluginName, defaultMode)
            if (!rst)
                INIObject.plugins_DefaultMode.%pluginName% := defaultMode

            Sleep 1000
        }
    }

    static LoadPlugins(LoadAll) {
        validPlugins := Map()
        invalidPlugins := []

        for plugin, flag in INIObject.plugins.OwnProps() {
            if (_IsEasyIniReserved(plugin))
                continue

            pluginFile := PluginCatalog.GetPluginMainFile(plugin)
            if (FileExist(pluginFile)) {
                validPlugins[plugin] := flag
            } else {
                invalidPlugins.Push(plugin)
            }
        }

        for _, plugin in invalidPlugins {
            try {
                INIObject.DeleteKey("plugins", plugin)
                INIObject.DeleteKey("plugins_DefaultMode", plugin)
            } catch Error as e {
                VimD_Log("WARN", "MAIN_PLUGIN_INVALID_CLEAN", "Failed to clean invalid plugin config: " plugin, e)
            }
        }

        if (invalidPlugins.Length > 0)
            INIObject.save()

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
                    "Plugin load summary: enabled=" loadedCount " total=" totalCount)
            }
        }
    }

    static SetDefaultModes() {
        for plugin, mode in INIObject.plugins_DefaultMode.OwnProps() {
            if (_IsEasyIniReserved(plugin))
                continue

            try {
                winObj := vim.GetWin(plugin)
                winObj.defaultMode := mode
                vim.mode(mode, plugin)
                winObj.Inside := 0
            } catch Error as e {
                VimD_Log("WARN", "MAIN_DEFAULT_MODE_SET", "Failed to set plugin default mode: " plugin, e)
            }
        }
    }

    static RebuildPluginIncludes() {
        if (FileExist(PathResolver.RootPath("vimd.exe"))) {
            Run Format('{1}\vimd.exe {1}\plugins\check.ahk', PathResolver.RootDir())
        } else {
            Run PathResolver.PluginPath("check.ahk")
        }
    }
}
