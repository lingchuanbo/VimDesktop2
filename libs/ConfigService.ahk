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
        ; LoadPluginConfigs() calls BuildPluginConfigPathIndex internally
        this.LoadPluginConfigs()
        this.GetSchemas()
        this._InitFileMtimes()
        this._InitMainSectionSnapshots()
    }

    static LoadPluginConfigs() {
        return ConfigServiceChangeTracker.LoadPluginConfigs(this)
    }

    static _InitFileMtimes() {
        return ConfigServiceChangeTracker.InitFileMtimes(this)
    }

    static _InitMainSectionSnapshots() {
        return ConfigServiceChangeTracker.InitMainSectionSnapshots(this)
    }

    static _GetMainConfigPath() {
        if (IsObject(this.MainConfig) && this.MainConfig.HasOwnProp("EasyIni_ReservedFor_m_sFile"))
            return this.MainConfig.EasyIni_ReservedFor_m_sFile
        return PathResolver.ConfigPath("vimd.ini")
    }

    static _GetFileMtime(filePath) {
        return ConfigServiceChangeTracker.GetFileMtime(filePath)
    }

    static RefreshIfChanged(enableValidation := true, enableDebug := false, logPath := "") {
        return ConfigServiceChangeTracker.RefreshIfChanged(this, enableValidation, enableDebug, logPath)
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
            } catch Error as e {
                VimD_Log("WARN", "CONFIG_SET_VALUE", "AddSection failed: " pluginName, e)
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
        } catch Error as e {
            VimD_Log("WARN", "CONFIG_SAVE_PLUGIN", "SavePluginConfig failed: " pluginName, e)
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
        } catch Error as e {
            VimD_Log("WARN", "CONFIG_IME_READ", "GetPluginIMEConfig failed: " pluginName, e)
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
            this._ValidateBoolKey(issues, "config", "tooltip_auto_hide", mainConfigPath)
            this._ValidateBoolKey(issues, "config", "tooltip_hide_on_mouse_leave", mainConfigPath)
            this._ValidateBoolKey(issues, "config", "tooltip_hide_on_click_outside", mainConfigPath)
            this._ValidateBoolKey(issues, "config", "tooltip_hide_on_window_change", mainConfigPath)
            this._ValidateBoolKey(issues, "config", "tooltip_global_window_monitor", mainConfigPath)
            this._ValidateBoolKey(issues, "config", "tooltip_clear_key_cache_on_hide", mainConfigPath)
            this._ValidateEnumKey(issues, "config", "tooltip_library", "ToolTipOptions|BTT", mainConfigPath)
            this._ValidateIntKey(issues, "config", "tooltip_hide_timeout", mainConfigPath, 0, 60000)
            this._ValidateIntKey(issues, "config", "tooltip_font_size", mainConfigPath, 6, 72)
            this._ValidateIntKey(issues, "config", "tooltipswitch_font_size", mainConfigPath, 6, 72)

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
        } catch Error as e {
            VimD_Log("WARN", "CONFIG_WRITE_REPORT", "WriteValidationReport failed", e)
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

    static _ValidateIntKey(issues, sectionName, keyName, filePath := "", minValue := "", maxValue := "") {
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

        if !RegExMatch(rawValue, "^-?\d+$") {
            this._AddIssue(issues, filePath != "" ? filePath : this._GetMainConfigPath(), sectionName, keyName,
                "配置类型错误: 需要int", rawValue)
            return
        }

        intValue := Integer(rawValue)
        if (minValue != "" && intValue < minValue) {
            this._AddIssue(issues, filePath != "" ? filePath : this._GetMainConfigPath(), sectionName, keyName,
                "配置越界: 不能小于 " minValue, intValue)
        } else if (maxValue != "" && intValue > maxValue) {
            this._AddIssue(issues, filePath != "" ? filePath : this._GetMainConfigPath(), sectionName, keyName,
                "配置越界: 不能大于 " maxValue, intValue)
        }
    }

    static _ValidateEnumKey(issues, sectionName, keyName, enumSpec, filePath := "") {
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

        if !this._IsEnumValue(rawValue, enumSpec) {
            this._AddIssue(issues, filePath != "" ? filePath : this._GetMainConfigPath(), sectionName, keyName,
                "配置枚举错误: 非法值", rawValue, "允许: " enumSpec)
        }
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
        } catch Error as e {
            VimD_Log("WARN", "CONFIG_GET_INI", "Failed to create plugin INI: " pluginName, e)
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

        this.Schemas := ConfigServiceSchemaRegistry.Build()
        return this.Schemas
    }
}





