#Requires AutoHotkey v2.0

class ConfigServiceSchemaRegistry {
    static _TimeOutRule(section) {
        return Map("section", section, "key", "set_time_out", "type", "int", "min", 50, "max", 5000)
    }

    static _IMERules(section) {
        rules := []
        rules.Push(Map("section", section, "key", "ime_enabled", "type", "bool"))
        rules.Push(Map("section", section, "key", "ime_enable_debug", "type", "bool"))
        rules.Push(Map("section", section, "key", "ime_check_interval", "type", "int", "min", 50, "max", 3000))
        rules.Push(Map("section", section, "key", "ime_enable_mouse_click", "type", "bool"))
        rules.Push(Map("section", section, "key", "ime_max_retries", "type", "int", "min", 1, "max", 10))
        rules.Push(Map("section", section, "key", "ime_auto_switch_timeout", "type", "int", "min", 500, "max", 30000))
        return rules
    }

    static Build() {
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
        afterEffectsRules.Push(this._TimeOutRule("AfterEffects"))
        for _, rule in this._IMERules("AfterEffects")
            afterEffectsRules.Push(rule)
        schemas["AfterEffects"] := afterEffectsRules

        blenderRules := []
        blenderRules.Push(Map("section", "Blender", "key", "python_path", "type", "path_exists"))
        blenderRules.Push(this._TimeOutRule("Blender"))
        schemas["Blender"] := blenderRules

        max3DRules := []
        max3DRules.Push(this._TimeOutRule("Max3D"))
        for _, rule in this._IMERules("Max3D")
            max3DRules.Push(rule)
        schemas["Max3D"] := max3DRules

        return schemas
    }
}
