#Requires AutoHotkey v2.0

class ConfigServiceSchemaRegistry {
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
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "set_time_out", "type", "int", "min", 50,
            "max", 5000))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_enabled", "type", "bool"))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_enable_debug", "type", "bool"))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_check_interval", "type", "int", "min", 50,
            "max", 3000))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_enable_mouse_click", "type", "bool"))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_max_retries", "type", "int", "min", 1,
            "max", 10))
        afterEffectsRules.Push(Map("section", "AfterEffects", "key", "ime_auto_switch_timeout", "type", "int",
            "min", 500, "max", 30000))
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

        return schemas
    }
}
