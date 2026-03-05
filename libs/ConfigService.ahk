#Requires AutoHotkey v2.0

/*
    ConfigService
    作用:
    1) 统一读取主配置与插件独立配置
    2) 提供插件配置读取的兜底策略
    3) 启动阶段执行最小配置校验并报告问题
*/
class ConfigService {
    static MainConfig := ""
    static PluginConfigs := {}
    static PluginConfigPaths := Map()
    static Schemas := ""
    static FileMtimes := Map()
    static MainSectionSnapshots := Map()
    static PluginPathScanIntervalMs := 30000
    static _LastPluginPathScanTick := 0

    static Init(mainConfig, pluginConfigs) {
        this.MainConfig := mainConfig
        this.PluginConfigs := pluginConfigs
        this.PluginConfigPaths := Map()
        this._BuildPluginConfigPathIndex()
        this.LoadPluginConfigs()
        this.GetSchemas()
        this._InitFileMtimes()
        this._InitMainSectionSnapshots()
    }

    static _BuildPluginConfigPathIndex() {
        pluginsDir := PathResolver.PluginsDir()
        if !DirExist(pluginsDir)
            return

        loop files, pluginsDir "\*", "D" {
            pluginName := A_LoopFileName
            pluginDir := A_LoopFileFullPath
            possibleConfigFiles := [
                pluginDir "\" pluginName ".ini",
                pluginDir "\" StrLower(pluginName) ".ini",
                pluginDir "\config.ini",
                pluginDir "\plugin.ini"
            ]

            for configPath in possibleConfigFiles {
                if FileExist(configPath) {
                    this.PluginConfigPaths[pluginName] := configPath
                    break
                }
            }
        }
    }

    static LoadPluginConfigs() {
        if !IsObject(this.PluginConfigs)
            this.PluginConfigs := {}

        this._BuildPluginConfigPathIndex()

        for pluginName, configPath in this.PluginConfigPaths {
            if (configPath = "")
                continue
            if (this.PluginConfigs.HasOwnProp(pluginName))
                continue
            try {
                this.PluginConfigs.%pluginName% := EasyIni(configPath)
            } catch Error as e {
                VimD_Log("WARN", "CONFIG_PLUGIN_LOAD_FAIL", "插件配置加载失败: " pluginName " -> " configPath, e)
            }
        }
    }

    static _InitFileMtimes() {
        this.FileMtimes := Map()

        mainPath := this._GetMainConfigPath()
        if (mainPath != "")
            this.FileMtimes["main"] := this._GetFileMtime(mainPath)

        if IsObject(this.PluginConfigPaths) {
            for pluginName, configPath in this.PluginConfigPaths {
                if (configPath = "")
                    continue
                this.FileMtimes["plugin:" pluginName] := this._GetFileMtime(configPath)
            }
        }
    }

    static _InitMainSectionSnapshots() {
        this.MainSectionSnapshots := this._BuildMainSectionSnapshots()
    }

    static _BuildMainSectionSnapshots() {
        snapshots := Map()
        if !IsObject(this.MainConfig)
            return snapshots

        for secName, secObj in this.MainConfig.OwnProps() {
            if this._IsReservedConfigProperty(secName)
                continue
            if !IsObject(secObj)
                continue
            snapshots[secName] := this._SnapshotSection(secObj)
        }
        return snapshots
    }

    static _SnapshotSection(sectionObj) {
        snapshot := Map()
        if !IsObject(sectionObj)
            return snapshot
        for key, value in sectionObj.OwnProps() {
            if this._IsReservedSectionKey(key)
                continue
            snapshot[key] := value
        }
        return snapshot
    }

    static _IsReservedSectionKey(name) {
        return (name = "EasyIni_KeyComment"
            || name = "EasyIni_SectionComment"
            || name = "__Class")
    }

    static _DiffMainSections() {
        oldSnapshots := IsObject(this.MainSectionSnapshots) ? this.MainSectionSnapshots : Map()
        newSnapshots := this._BuildMainSectionSnapshots()

        changedSections := []
        addedSections := []
        removedSections := []
        sectionKeyDiffs := Map()

        for secName, newSnap in newSnapshots {
            if !oldSnapshots.Has(secName) {
                addedSections.Push(secName)
                this._PushUnique(changedSections, secName)
                continue
            }

            diff := this._DiffSectionSnapshot(oldSnapshots[secName], newSnap)
            if (diff["added"].Length > 0 || diff["removed"].Length > 0 || diff["changed"].Length > 0) {
                this._PushUnique(changedSections, secName)
                sectionKeyDiffs[secName] := diff
            }
        }

        for secName, oldSnap in oldSnapshots {
            if !newSnapshots.Has(secName) {
                removedSections.Push(secName)
                this._PushUnique(changedSections, secName)
            }
        }

        this.MainSectionSnapshots := newSnapshots
        return Map(
            "changed_sections", changedSections,
            "added_sections", addedSections,
            "removed_sections", removedSections,
            "section_key_diffs", sectionKeyDiffs
        )
    }

    static _DiffSectionSnapshot(oldSnap, newSnap) {
        added := []
        removed := []
        changed := []

        if !IsObject(oldSnap)
            oldSnap := Map()
        if !IsObject(newSnap)
            newSnap := Map()

        for key, value in newSnap {
            if !oldSnap.Has(key) {
                added.Push(key)
            } else if (oldSnap[key] != value) {
                changed.Push(key)
            }
        }

        for key, value in oldSnap {
            if !newSnap.Has(key)
                removed.Push(key)
        }

        return Map("added", added, "removed", removed, "changed", changed)
    }

    static _PushUnique(arr, value) {
        if !IsObject(arr)
            return
        for _, item in arr {
            if (item = value)
                return
        }
        arr.Push(value)
    }

    static _GetMainConfigPath() {
        if (IsObject(this.MainConfig) && this.MainConfig.HasOwnProp("EasyIni_ReservedFor_m_sFile"))
            return this.MainConfig.EasyIni_ReservedFor_m_sFile
        return PathResolver.ConfigPath("vimd.ini")
    }

    static _GetFileMtime(filePath) {
        if (filePath = "")
            return ""
        try {
            return FileGetTime(filePath, "M")
        } catch {
            return ""
        }
    }

    static _HasFileChanged(key, filePath) {
        newTime := this._GetFileMtime(filePath)
        oldTime := this.FileMtimes.Has(key) ? this.FileMtimes[key] : ""
        if (newTime = "" && oldTime = "")
            return false
        if (newTime != oldTime) {
            this.FileMtimes[key] := newTime
            return true
        }
        return false
    }

    static _MaybeRefreshPluginConfigPathIndex() {
        nowTick := A_TickCount
        if (this._LastPluginPathScanTick != 0
            && (nowTick - this._LastPluginPathScanTick) < this.PluginPathScanIntervalMs) {
            return
        }

        this._LastPluginPathScanTick := nowTick
        this._BuildPluginConfigPathIndex()
    }

    static RefreshIfChanged(enableValidation := true, enableDebug := false, logPath := "") {
        result := Map("changed", false, "main", false, "plugins", [])

        if !IsObject(this.MainConfig)
            return result

        if !IsObject(this.FileMtimes)
            this.FileMtimes := Map()

        this._MaybeRefreshPluginConfigPathIndex()

        mainChanged := this._ReloadMainConfigIfChanged()
        changedPlugins := this._ReloadPluginConfigsIfChanged()

        if (mainChanged || changedPlugins.Length > 0) {
            result["changed"] := true
            result["main"] := mainChanged
            result["plugins"] := changedPlugins
            if (mainChanged) {
                mainDiff := this._DiffMainSections()
                result["main_sections"] := mainDiff["changed_sections"]
                result["main_sections_added"] := mainDiff["added_sections"]
                result["main_sections_removed"] := mainDiff["removed_sections"]
                result["main_section_keys"] := mainDiff["section_key_diffs"]
            }

            if (enableValidation)
                this.ValidateAndReport(enableDebug, true, logPath)

            VimD_Log("INFO", "CONFIG_HOT_RELOAD", "配置已刷新: main=" (mainChanged ? 1 : 0)
            " plugins=" changedPlugins.Length)
        }

        return result
    }

    static _ReloadMainConfigIfChanged() {
        mainPath := this._GetMainConfigPath()
        if (mainPath = "")
            return false

        if !this._HasFileChanged("main", mainPath)
            return false

        if !FileExist(mainPath) {
            VimD_LogOnce("WARN", "CONFIG_MAIN_MISSING", "主配置文件不存在: " mainPath)
            return false
        }

        try {
            this.MainConfig.Reload()
            return true
        } catch Error as e {
            VimD_Log("WARN", "CONFIG_MAIN_RELOAD_FAIL", "主配置重载失败", e)
            return false
        }
    }

    static _ReloadPluginConfigsIfChanged() {
        changedPlugins := []

        if !IsObject(this.PluginConfigs)
            return changedPlugins

        for pluginName, pluginIni in this.PluginConfigs.OwnProps() {
            if !IsObject(pluginIni)
                continue

            configPath := ""
            if (this.PluginConfigPaths.Has(pluginName))
                configPath := this.PluginConfigPaths[pluginName]
            else if (pluginIni.HasOwnProp("EasyIni_ReservedFor_m_sFile"))
                configPath := pluginIni.EasyIni_ReservedFor_m_sFile

            if (configPath = "")
                continue

            key := "plugin:" pluginName
            if !this._HasFileChanged(key, configPath)
                continue

            if !FileExist(configPath) {
                VimD_LogOnce("WARN", "CONFIG_PLUGIN_MISSING", "插件配置文件不存在: " pluginName " -> " configPath)
                continue
            }

            try {
                pluginIni.Reload()
                changedPlugins.Push(pluginName)
            } catch Error as e {
                VimD_Log("WARN", "CONFIG_PLUGIN_RELOAD_FAIL", "插件配置重载失败: " pluginName, e)
            }
        }

        for pluginName, configPath in this.PluginConfigPaths {
            if (this.PluginConfigs.HasOwnProp(pluginName))
                continue
            if (configPath = "")
                continue

            key := "plugin:" pluginName
            if !this._HasFileChanged(key, configPath)
                continue

            if !FileExist(configPath) {
                VimD_LogOnce("WARN", "CONFIG_PLUGIN_MISSING", "插件配置文件不存在: " pluginName " -> " configPath)
                continue
            }

            try {
                this.PluginConfigs.%pluginName% := EasyIni(configPath)
                changedPlugins.Push(pluginName)
            } catch Error as e {
                VimD_Log("WARN", "CONFIG_PLUGIN_LOAD_FAIL", "插件配置加载失败: " pluginName " -> " configPath, e)
            }
        }

        return changedPlugins
    }

    static GetPluginConfigPath(pluginName) {
        return this.PluginConfigPaths.Has(pluginName) ? this.PluginConfigPaths[pluginName] : ""
    }

    static GetPluginSection(pluginName, sectionName := "", fallbackToMain := true) {
        targetSection := (sectionName != "") ? sectionName : pluginName

        if (IsObject(this.PluginConfigs) && this.PluginConfigs.HasOwnProp(pluginName)) {
            pluginIni := this.PluginConfigs.%pluginName%
            sectionObj := this._FindSection(pluginIni, targetSection)
            if IsObject(sectionObj)
                return sectionObj
        }

        if (fallbackToMain && IsObject(this.MainConfig)) {
            sectionObj := this._FindSection(this.MainConfig, targetSection)
            if IsObject(sectionObj)
                return sectionObj

            if (targetSection != pluginName) {
                sectionObj := this._FindSection(this.MainConfig, pluginName)
                if IsObject(sectionObj)
                    return sectionObj
            }
        }

        return {}
    }

    static GetPluginValue(pluginName, keyName, defaultValue := "", sectionName := "", fallbackToMain := true) {
        sectionObj := this.GetPluginSection(pluginName, sectionName, fallbackToMain)
        if (IsObject(sectionObj) && sectionObj.HasOwnProp(keyName)) {
            value := sectionObj.%keyName%
            if (value != "")
                return value
        }
        return defaultValue
    }

    static SetPluginValue(pluginName, keyName, value, sectionName := "") {
        targetSection := (sectionName != "") ? sectionName : pluginName
        pluginIni := this._GetOrCreatePluginIni(pluginName)
        if !IsObject(pluginIni)
            return false

        if !pluginIni.HasOwnProp(targetSection) {
            try {
                pluginIni.AddSection(targetSection)
            } catch {
                return false
            }
        }

        pluginIni.%targetSection%.%keyName% := value
        return true
    }

    static SavePluginConfig(pluginName, savePath := "") {
        pluginIni := this._GetOrCreatePluginIni(pluginName)
        if !IsObject(pluginIni)
            return false

        targetPath := savePath
        if (targetPath = "")
            targetPath := this.GetPluginConfigPath(pluginName)
        if (targetPath = "")
            targetPath := PathResolver.PluginPath(pluginName, pluginName ".ini")

        try {
            this._EnsureParentDir(targetPath)
            pluginIni.Save(targetPath)
            this.PluginConfigPaths[pluginName] := targetPath
            return true
        } catch {
            return false
        }
    }

    static GetPluginBoolValue(pluginName, keyName, defaultValue := false, sectionName := "", fallbackToMain := true
    ) {
        rawValue := this.GetPluginValue(pluginName, keyName, "", sectionName, fallbackToMain)
        if (rawValue = "")
            return defaultValue
        return this._ParseBool(rawValue, defaultValue)
    }

    static GetPluginIntValue(pluginName, keyName, defaultValue := 0, sectionName := "", minValue := "", maxValue :=
        "",
        fallbackToMain := true) {
        rawValue := Trim(this.GetPluginValue(pluginName, keyName, "", sectionName, fallbackToMain) "")
        if (rawValue = "")
            return defaultValue
        if !RegExMatch(rawValue, "^-?\d+$")
            return defaultValue

        value := Integer(rawValue)
        if (minValue != "" && value < minValue)
            value := minValue
        if (maxValue != "" && value > maxValue)
            value := maxValue
        return value
    }

    static GetPluginTimeout(pluginName, defaultValue := 300, sectionName := "", minValue := 50, maxValue := 5000) {
        targetSection := (sectionName != "") ? sectionName : pluginName
        try {
            return this.GetPluginIntValue(pluginName, "set_time_out", defaultValue, targetSection, minValue,
                maxValue)
        } catch {
            return defaultValue
        }
    }

    static GetPluginIMEConfig(pluginName, defaults := "", sectionName := "") {
        targetSection := (sectionName != "") ? sectionName : pluginName

        cfg := IsObject(defaults) ? defaults.Clone() : {
            enabled: true,
            enableDebug: false,
            checkInterval: 200,
            enableMouseClick: true,
            maxRetries: 3,
            autoSwitchTimeout: 5000,
            specialHandling: ""
        }

        try {
            cfg.enabled := this.GetPluginBoolValue(pluginName, "ime_enabled", cfg.enabled, targetSection)
            cfg.enableDebug := this.GetPluginBoolValue(pluginName, "ime_enable_debug", cfg.enableDebug,
                targetSection)
            cfg.checkInterval := this.GetPluginIntValue(pluginName, "ime_check_interval", cfg.checkInterval,
                targetSection,
                50, 3000)
            cfg.enableMouseClick := this.GetPluginBoolValue(pluginName, "ime_enable_mouse_click", cfg.enableMouseClick,
                targetSection)
            cfg.maxRetries := this.GetPluginIntValue(pluginName, "ime_max_retries", cfg.maxRetries, targetSection,
                1, 10)
            cfg.autoSwitchTimeout := this.GetPluginIntValue(pluginName, "ime_auto_switch_timeout", cfg.autoSwitchTimeout,
                targetSection, 500, 30000)
            cfg.specialHandling := this.GetPluginValue(pluginName, "ime_special_handling", cfg.specialHandling,
                targetSection)
        } catch {
        }

        return cfg
    }

    static Validate() {
        issues := []
        if !IsObject(this.MainConfig)
            return issues

        mainConfigPath := this._GetMainConfigPath()

        requiredSections := ["config", "global", "plugins", "plugins_DefaultMode"]
        for sectionName in requiredSections {
            if !this.MainConfig.HasOwnProp(sectionName)
                this._AddIssue(issues, mainConfigPath, sectionName, "", "缺少主配置节")
        }

        if this.MainConfig.HasOwnProp("config") {
            themeMode := ""
            try themeMode := this.MainConfig.config.theme_mode
            if (themeMode != "" && !RegExMatch(themeMode, "i)^(light|dark|system)$"))
                this._AddIssue(issues, mainConfigPath, "config", "theme_mode", "theme_mode 无效", themeMode)

            this._ValidateBoolKey(issues, "config", "enable_log", mainConfigPath)
            this._ValidateBoolKey(issues, "config", "enable_debug", mainConfigPath)
            this._ValidateBoolKey(issues, "config", "default_enable_show_info", mainConfigPath)

            langValue := ""
            try langValue := Trim(this.MainConfig.config.lang "")
            if (langValue != "") {
                langPath := PathResolver.LangPath(langValue ".json")
                if !FileExist(langPath)
                    this._AddIssue(issues, mainConfigPath, "config", "lang", "语言文件不存在", langPath)
            }
        }

        if this.MainConfig.HasOwnProp("extensions") {
            for name, value in this.MainConfig.extensions.OwnProps() {
                if (name = "EasyIni_KeyComment" || name = "EasyIni_SectionComment")
                    continue
                if (value = "")
                    continue

                parts := StrSplit(value, "|")
                if (parts.Length < 1 || parts[1] = "") {
                    this._AddIssue(issues, mainConfigPath, "extensions", name, "扩展配置格式异常", value)
                    continue
                }

                fullPath := this._ResolvePath(parts[1])
                if !FileExist(fullPath)
                    this._AddIssue(issues, mainConfigPath, "extensions", name, "扩展文件不存在", fullPath)
            }
        }

        schemas := this.GetSchemas()
        for pluginName, rules in schemas {
            for _, rule in rules {
                sectionName := rule["section"]
                keyName := rule["key"]
                valueType := rule["type"]

                rawValue := Trim(this.GetPluginValue(pluginName, keyName, "", sectionName, true) "")
                if (rawValue = "")
                    continue

                issue := this._ValidateTypedValue(pluginName, sectionName, keyName, rawValue, valueType, rule)
                if (IsObject(issue))
                    issues.Push(issue)
            }
        }

        return issues
    }

    static ValidateAndReport(enableDebug := false, writeToFile := true, logPath := "") {
        issues := this.Validate()
        if (writeToFile)
            this.WriteValidationReport(issues, logPath)

        if (enableDebug && issues.Length > 0) {
            msg := "配置校验发现 " issues.Length " 个问题`n`n"
            for idx, issue in issues {
                msg .= idx ". " this._FormatIssue(issue) "`n"
                if (idx >= 15) {
                    msg .= "...`n"
                    break
                }
            }
            MsgBox(msg, "配置校验", "Icon!")
        }
        return issues
    }

    static WriteValidationReport(issues, logPath := "") {
        targetPath := (logPath != "") ? logPath : PathResolver.ConfigPath("config_validation.log")

        try {
            this._EnsureParentDir(targetPath)

            mainConfigPath := PathResolver.ConfigPath("vimd.ini")
            if (IsObject(this.MainConfig) && this.MainConfig.HasOwnProp("EasyIni_ReservedFor_m_sFile"))
                mainConfigPath := this.MainConfig.EasyIni_ReservedFor_m_sFile

            content := "VimDesktop 配置校验报告`r`n"
            content .= "时间: " FormatTime(, "yyyy-MM-dd HH:mm:ss") "`r`n"
            content .= "主配置: " mainConfigPath "`r`n"
            content .= "插件配置文件数: " this.PluginConfigPaths.Count "`r`n"
            content .= "问题数: " issues.Length "`r`n"
            content .= "----------------------------------------`r`n"

            if (issues.Length = 0) {
                content .= "未发现配置问题。`r`n"
            } else {
                for idx, issue in issues
                    content .= idx ". " this._FormatIssue(issue) "`r`n"
            }

            if FileExist(targetPath)
                FileDelete(targetPath)
            FileAppend(content, targetPath, "UTF-8")
            return true
        } catch {
            return false
        }
    }

    static _FindSection(configObj, sectionName := "") {
        if !IsObject(configObj)
            return ""

        if (sectionName != "" && configObj.HasOwnProp(sectionName))
            return configObj.%sectionName%

        ; 大小写不敏感匹配
        if (sectionName != "") {
            targetName := StrLower(sectionName)
            for secName, secObj in configObj.OwnProps() {
                if this._IsReservedConfigProperty(secName)
                    continue
                if (StrLower(secName) = targetName)
                    return secObj
            }
        }

        return ""
    }

    static _IsReservedConfigProperty(name) {
        return (name = "EasyIni_TopComments"
            || name = "EasyIni_ReservedFor_m_sFile")
    }

    static _ResolvePath(pathValue) {
        pathValue := Trim(pathValue "")
        if (pathValue = "")
            return ""

        if RegExMatch(pathValue, "^[A-Za-z]:\\")
            return pathValue
        if (SubStr(pathValue, 1, 2) = "\\\\")
            return pathValue
        if (SubStr(pathValue, 1, 1) = "\")
            return PathResolver.RootPath(pathValue)

        return PathResolver.RootPath(pathValue)
    }

    static _EnsureParentDir(filePath) {
        SplitPath(filePath, , &dirPath)
        if (dirPath != "" && !DirExist(dirPath))
            DirCreate(dirPath)
    }

    static _MakeIssue(filePath, sectionName, keyName, message, value := "", hint := "") {
        issue := Map("file", filePath, "section", sectionName, "key", keyName, "message", message)
        if (value != "")
            issue["value"] := value
        if (hint != "")
            issue["hint"] := hint
        return issue
    }

    static _AddIssue(issues, filePath, sectionName, keyName, message, value := "", hint := "") {
        if !IsObject(issues)
            return
        issues.Push(this._MakeIssue(filePath, sectionName, keyName, message, value, hint))
    }

    static _FormatIssue(issue) {
        if !IsObject(issue)
            return issue
        filePath := issue.Has("file") ? issue["file"] : ""
        sectionName := issue.Has("section") ? issue["section"] : ""
        keyName := issue.Has("key") ? issue["key"] : ""
        message := issue.Has("message") ? issue["message"] : ""
        value := issue.Has("value") ? issue["value"] : ""
        hint := issue.Has("hint") ? issue["hint"] : ""

        text := ""
        if (filePath != "")
            text .= filePath
        if (sectionName != "" || keyName != "") {
            if (text != "")
                text .= " | "
            if (sectionName != "")
                text .= "[" sectionName "]"
            if (keyName != "")
                text .= (sectionName != "" ? "." : "") keyName
        }
        if (message != "")
            text .= (text != "" ? " - " : "") message
        if (value != "")
            text .= " (value: " value ")"
        if (hint != "")
            text .= " (hint: " hint ")"
        return text
    }

    static _ResolvePluginValueSource(pluginName, sectionName, keyName) {
        mainPath := this._GetMainConfigPath()

        pluginIni := ""
        if (IsObject(this.PluginConfigs) && this.PluginConfigs.HasOwnProp(pluginName))
            pluginIni := this.PluginConfigs.%pluginName%

        if IsObject(pluginIni) {
            sec := this._FindSection(pluginIni, sectionName)
            if (IsObject(sec) && sec.HasOwnProp(keyName) && sec.%keyName% != "") {
                filePath := pluginIni.HasOwnProp("EasyIni_ReservedFor_m_sFile") ? pluginIni.EasyIni_ReservedFor_m_sFile
                    : this.GetPluginConfigPath(pluginName)
                return Map("file", filePath, "section", sectionName, "key", keyName)
            }
        }

        if IsObject(this.MainConfig) {
            secMain := this._FindSection(this.MainConfig, sectionName)
            if (IsObject(secMain) && secMain.HasOwnProp(keyName) && secMain.%keyName% != "")
                return Map("file", mainPath, "section", sectionName, "key", keyName)

            if (sectionName != pluginName) {
                secMain2 := this._FindSection(this.MainConfig, pluginName)
                if (IsObject(secMain2) && secMain2.HasOwnProp(keyName) && secMain2.%keyName% != "")
                    return Map("file", mainPath, "section", pluginName, "key", keyName)
            }
        }

        return Map("file", mainPath, "section", sectionName, "key", keyName)
    }

    static _ValidateBoolKey(issues, sectionName, keyName, filePath := "") {
        if !IsObject(this.MainConfig)
            return
        if !this.MainConfig.HasOwnProp(sectionName)
            return

        sec := this.MainConfig.%sectionName%
        if (!IsObject(sec) || !sec.HasOwnProp(keyName))
            return

        rawValue := Trim(sec.%keyName% "")
        if (rawValue = "")
            return

        if !this._IsBoolString(rawValue)
            this._AddIssue(issues, filePath != "" ? filePath : this._GetMainConfigPath(), sectionName, keyName,
            "配置类型错误: 需要 bool", rawValue)
    }

    static _GetOrCreatePluginIni(pluginName) {
        if !IsObject(this.PluginConfigs)
            this.PluginConfigs := {}

        if (this.PluginConfigs.HasOwnProp(pluginName))
            return this.PluginConfigs.%pluginName%

        configPath := this.GetPluginConfigPath(pluginName)
        if (configPath = "")
            configPath := PathResolver.PluginPath(pluginName, pluginName ".ini")

        try {
            if FileExist(configPath) {
                iniObj := EasyIni(configPath)
            } else {
                iniObj := EasyIni()
                iniObj.EasyIni_ReservedFor_m_sFile := configPath
            }

            this.PluginConfigs.%pluginName% := iniObj
            this.PluginConfigPaths[pluginName] := configPath
            return iniObj
        } catch {
            return ""
        }
    }

    static _ValidateTypedValue(pluginName, sectionName, keyName, rawValue, valueType, rule) {
        location := this._ResolvePluginValueSource(pluginName, sectionName, keyName)
        filePath := location["file"]
        secName := location["section"]
        key := location["key"]

        switch valueType {
            case "bool":
                if !this._IsBoolString(rawValue)
                    return this._MakeIssue(filePath, secName, key, "配置类型错误: 需要 bool", rawValue)

            case "int":
                if !RegExMatch(rawValue, "^-?\d+$")
                    return this._MakeIssue(filePath, secName, key, "配置类型错误: 需要 int", rawValue)

                intValue := Integer(rawValue)
                if (rule.Has("min") && intValue < rule["min"])
                    return this._MakeIssue(filePath, secName, key, "配置越界: 不能小于 " rule["min"], intValue)
                if (rule.Has("max") && intValue > rule["max"])
                    return this._MakeIssue(filePath, secName, key, "配置越界: 不能大于 " rule["max"], intValue)

            case "enum":
                enumValues := rule.Has("enum") ? rule["enum"] : ""
                if !this._IsEnumValue(rawValue, enumValues)
                    return this._MakeIssue(filePath, secName, key, "配置枚举错误: 非法值", rawValue,
                        "允许: " enumValues)

            case "path_exists":
                if !FileExist(rawValue)
                    return this._MakeIssue(filePath, secName, key, "路径不存在", rawValue)

            case "dir_exists":
                if !DirExist(rawValue)
                    return this._MakeIssue(filePath, secName, key, "目录不存在", rawValue)
        }

        return ""
    }

    static _IsBoolString(value) {
        normalized := StrLower(Trim(value ""))
        return (normalized = "1" || normalized = "true" || normalized = "yes" || normalized = "on"
            || normalized = "0" || normalized = "false" || normalized = "no" || normalized = "off")
    }

    static _IsEnumValue(value, enumSpec) {
        target := StrLower(Trim(value ""))
        for _, enumValue in StrSplit(enumSpec, "|") {
            if (target = StrLower(Trim(enumValue)))
                return true
        }
        return false
    }

    static _ParseBool(value, defaultValue := false) {
        normalized := StrLower(Trim(value ""))
        if (normalized = "1" || normalized = "true" || normalized = "yes" || normalized = "on")
            return true
        if (normalized = "0" || normalized = "false" || normalized = "no" || normalized = "off")
            return false
        return defaultValue
    }

    static GetSchemas() {
        if IsObject(this.Schemas)
            return this.Schemas

        schemas := Map()

        everythingRules := []
        everythingRules.Push(Map("section", "Everything", "key", "everything_path", "type", "path_exists"))
        everythingRules.Push(Map("section", "Everything", "key", "enable_double_click", "type", "bool"))
        everythingRules.Push(Map("section", "Everything", "key", "show_debug_info", "type", "bool"))
        schemas["Everything"] := everythingRules

        tcRules := []
        tcRules.Push(Map("section", "TTOTAL_CMD", "key", "tc_path", "type", "path_exists"))
        tcRules.Push(Map("section", "TTOTAL_CMD", "key", "tc_ini_path", "type", "path_exists"))
        tcRules.Push(Map("section", "TTOTAL_CMD", "key", "tc_dir_path", "type", "dir_exists"))
        schemas["TTOTAL_CMD"] := tcRules

        afterEffectsRules := []
        afterEffectsRules.Push(Map("section", "Config", "key", "EnableLogging", "type", "bool"))
        afterEffectsRules.Push(Map("section", "Config", "key", "LogLevel", "type", "enum", "enum",
            "DEBUG|INFO|WARN|ERROR"))
        afterEffectsRules.Push(Map("section", "Config", "key", "LogFileSize", "type", "int", "min", 1, "max", 200))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "set_time_out", "type", "int", "min", 50,
            "max", 5000))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_enabled", "type", "bool"))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_enable_debug", "type", "bool"))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_check_interval", "type", "int", "min", 50,
            "max",
            3000))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_enable_mouse_click", "type", "bool"))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_max_retries", "type", "int", "min", 1,
            "max", 10))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_auto_switch_timeout", "type", "int",
            "min", 500,
            "max", 30000))
        schemas["AfterEffects"] := afterEffectsRules

        blenderRules := []
        blenderRules.Push(Map("section", "Blender", "key", "python_path", "type", "path_exists"))
        blenderRules.Push(Map("section", "Blender", "key", "set_time_out", "type", "int", "min", 50, "max", 5000))
        schemas["Blender"] := blenderRules

        max3DRules := []
        max3DRules.Push(Map("section", "Max3D", "key", "set_time_out", "type", "int", "min", 50, "max", 5000))
        max3DRules.Push(Map("section", "Max3D", "key", "ime_enabled", "type", "bool"))
        max3DRules.Push(Map("section", "Max3D", "key", "ime_enable_debug", "type", "bool"))
        max3DRules.Push(Map("section", "Max3D", "key", "ime_check_interval", "type", "int", "min", 50, "max", 3000))
        max3DRules.Push(Map("section", "Max3D", "key", "ime_enable_mouse_click", "type", "bool"))
        max3DRules.Push(Map("section", "Max3D", "key", "ime_max_retries", "type", "int", "min", 1, "max", 10))
        max3DRules.Push(Map("section", "Max3D", "key", "ime_auto_switch_timeout", "type", "int", "min", 500, "max",
            30000))
        schemas["Max3D"] := max3DRules

        this.Schemas := schemas
        return this.Schemas
    }
}
