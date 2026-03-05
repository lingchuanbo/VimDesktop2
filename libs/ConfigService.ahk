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
    static PluginPathScanIntervalMs := 30000
    static _LastPluginPathScanTick := 0

    static Init(mainConfig, pluginConfigs) {
        this.MainConfig := mainConfig
        this.PluginConfigs := pluginConfigs
        this.PluginConfigPaths := Map()
        this._BuildPluginConfigPathIndex()
        this.GetSchemas()
        this._InitFileMtimes()
    }

    static _BuildPluginConfigPathIndex() {
        pluginsDir := A_ScriptDir "\..\plugins"
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

    static _GetMainConfigPath() {
        if (IsObject(this.MainConfig) && this.MainConfig.HasOwnProp("EasyIni_ReservedFor_m_sFile"))
            return this.MainConfig.EasyIni_ReservedFor_m_sFile
        return A_ScriptDir "\..\config\vimd.ini"
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
            targetPath := A_ScriptDir "\..\plugins\" pluginName "\" pluginName ".ini"

        try {
            this._EnsureParentDir(targetPath)
            pluginIni.Save(targetPath)
            this.PluginConfigPaths[pluginName] := targetPath
            return true
        } catch {
            return false
        }
    }

    static GetPluginBoolValue(pluginName, keyName, defaultValue := false, sectionName := "", fallbackToMain := true) {
        rawValue := this.GetPluginValue(pluginName, keyName, "", sectionName, fallbackToMain)
        if (rawValue = "")
            return defaultValue
        return this._ParseBool(rawValue, defaultValue)
    }

    static GetPluginIntValue(pluginName, keyName, defaultValue := 0, sectionName := "", minValue := "", maxValue := "",
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
            return this.GetPluginIntValue(pluginName, "set_time_out", defaultValue, targetSection, minValue, maxValue)
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
            cfg.enableDebug := this.GetPluginBoolValue(pluginName, "ime_enable_debug", cfg.enableDebug, targetSection)
            cfg.checkInterval := this.GetPluginIntValue(pluginName, "ime_check_interval", cfg.checkInterval, targetSection,
                50, 3000)
            cfg.enableMouseClick := this.GetPluginBoolValue(pluginName, "ime_enable_mouse_click", cfg.enableMouseClick,
                targetSection)
            cfg.maxRetries := this.GetPluginIntValue(pluginName, "ime_max_retries", cfg.maxRetries, targetSection, 1, 10)
            cfg.autoSwitchTimeout := this.GetPluginIntValue(pluginName, "ime_auto_switch_timeout", cfg.autoSwitchTimeout,
                targetSection, 500, 30000)
            cfg.specialHandling := this.GetPluginValue(pluginName, "ime_special_handling", cfg.specialHandling, targetSection)
        } catch {
        }

        return cfg
    }

    static Validate() {
        issues := []
        if !IsObject(this.MainConfig)
            return issues

        requiredSections := ["config", "global", "plugins", "plugins_DefaultMode"]
        for sectionName in requiredSections {
            if !this.MainConfig.HasOwnProp(sectionName)
                issues.Push("缺少主配置节 [" sectionName "]")
        }

        if this.MainConfig.HasOwnProp("config") {
            themeMode := ""
            try themeMode := this.MainConfig.config.theme_mode
            if (themeMode != "" && !RegExMatch(themeMode, "i)^(light|dark|system)$"))
                issues.Push("theme_mode 无效: " themeMode)

            this._ValidateBoolKey(issues, "config", "enable_log")
            this._ValidateBoolKey(issues, "config", "enable_debug")
            this._ValidateBoolKey(issues, "config", "default_enable_show_info")

            langValue := ""
            try langValue := Trim(this.MainConfig.config.lang "")
            if (langValue != "") {
                langPath := A_ScriptDir "\..\lang\" langValue ".json"
                if !FileExist(langPath)
                    issues.Push("语言文件不存在: " langPath)
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
                    issues.Push("扩展配置格式异常: " name)
                    continue
                }

                fullPath := this._ResolvePath(parts[1])
                if !FileExist(fullPath)
                    issues.Push("扩展文件不存在: " name " -> " fullPath)
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
                if (issue != "")
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
            msg := "配置校验发现 " issues.Length " 个问题:`n`n"
            for idx, issue in issues {
                msg .= idx ". " issue "`n"
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
        targetPath := (logPath != "") ? logPath : (A_ScriptDir "\..\config\config_validation.log")

        try {
            this._EnsureParentDir(targetPath)

            mainConfigPath := A_ScriptDir "\..\config\vimd.ini"
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
                    content .= idx ". " issue "`r`n"
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

        if (sectionName != "") {
            targetName := StrLower(sectionName)
            for secName, secObj in configObj.OwnProps() {
                if this._IsReservedConfigProperty(secName)
                    continue
                if (StrLower(secName) = targetName)
                    return secObj
            }
        }

        secCount := 0
        singleSection := ""
        for secName, secObj in configObj.OwnProps() {
            if this._IsReservedConfigProperty(secName)
                continue
            secCount += 1
            singleSection := secObj
            if (secCount > 1)
                break
        }
        if (secCount = 1)
            return singleSection

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
            return A_ScriptDir "\.." pathValue

        return A_ScriptDir "\..\" pathValue
    }

    static _EnsureParentDir(filePath) {
        SplitPath(filePath, , &dirPath)
        if (dirPath != "" && !DirExist(dirPath))
            DirCreate(dirPath)
    }

    static _ValidateBoolKey(issues, sectionName, keyName) {
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
            issues.Push("配置类型错误: " sectionName "." keyName " 需要 bool, 当前值: " rawValue)
    }

    static _GetOrCreatePluginIni(pluginName) {
        if !IsObject(this.PluginConfigs)
            this.PluginConfigs := {}

        if (this.PluginConfigs.HasOwnProp(pluginName))
            return this.PluginConfigs.%pluginName%

        configPath := this.GetPluginConfigPath(pluginName)
        if (configPath = "")
            configPath := A_ScriptDir "\..\plugins\" pluginName "\" pluginName ".ini"

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
        ruleRef := pluginName "." sectionName "." keyName

        switch valueType {
            case "bool":
                if !this._IsBoolString(rawValue)
                    return "配置类型错误: " ruleRef " 需要 bool, 当前值: " rawValue

            case "int":
                if !RegExMatch(rawValue, "^-?\d+$")
                    return "配置类型错误: " ruleRef " 需要 int, 当前值: " rawValue

                intValue := Integer(rawValue)
                if (rule.Has("min") && intValue < rule["min"])
                    return "配置越界: " ruleRef " 不能小于 " rule["min"] ", 当前值: " intValue
                if (rule.Has("max") && intValue > rule["max"])
                    return "配置越界: " ruleRef " 不能大于 " rule["max"] ", 当前值: " intValue

            case "enum":
                enumValues := rule.Has("enum") ? rule["enum"] : ""
                if !this._IsEnumValue(rawValue, enumValues)
                    return "配置枚举错误: " ruleRef " 非法值 " rawValue " (允许: " enumValues ")"

            case "path_exists":
                if !FileExist(rawValue)
                    return "路径不存在: " ruleRef " -> " rawValue

            case "dir_exists":
                if !DirExist(rawValue)
                    return "目录不存在: " ruleRef " -> " rawValue
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
        afterEffectsRules.Push(Map("section", "Config", "key", "LogLevel", "type", "enum", "enum", "DEBUG|INFO|WARN|ERROR"))
        afterEffectsRules.Push(Map("section", "Config", "key", "LogFileSize", "type", "int", "min", 1, "max", 200))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "set_time_out", "type", "int", "min", 50, "max", 5000))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_enabled", "type", "bool"))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_enable_debug", "type", "bool"))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_check_interval", "type", "int", "min", 50, "max",
            3000))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_enable_mouse_click", "type", "bool"))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_max_retries", "type", "int", "min", 1, "max", 10))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_auto_switch_timeout", "type", "int", "min", 500,
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
        max3DRules.Push(Map("section", "Max3D", "key", "ime_auto_switch_timeout", "type", "int", "min", 500, "max", 30000))
        schemas["Max3D"] := max3DRules

        this.Schemas := schemas
        return this.Schemas
    }
}
