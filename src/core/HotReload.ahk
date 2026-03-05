#y:: Reload()

VimDesktop_StartConfigHotReload(intervalMs := "") {
    global VimDesktop_ConfigHotReloadIntervalMs
    if (intervalMs = "")
        intervalMs := VimDesktop_ConfigHotReloadIntervalMs
    if (intervalMs <= 0)
        return
    SetTimer(VimDesktop_ConfigHotReloadTick, intervalMs)
}

VimDesktop_ConfigHotReloadTick() {
    global INIObject
    static isRunning := false
    if (isRunning)
        return
    isRunning := true

    try {
        enableDebug := false
        try enableDebug := (INIObject.config.enable_debug = 1)
        reportPath := PathResolver.ConfigPath("config_validation.log")

        result := ConfigService.RefreshIfChanged(true, enableDebug, reportPath)
        if (IsObject(result) && result.Has("changed") && result["changed"])
            VimDesktop_ApplyRuntimeConfig(result)
    } catch Error as e {
        VimD_Log("WARN", "CONFIG_HOT_RELOAD_TICK", "配置热重载异常", e)
    } finally {
        isRunning := false
    }
}

VimDesktop_ApplyRuntimeConfig(result := "") {
    global VimDesktop_Global
    global vim
    try {
        if (IsObject(result)) {
            if (result.Has("main") && result["main"]) {
                sections := result.Has("main_sections") ? result["main_sections"] : []
                sectionKeyDiffs := result.Has("main_section_keys") ? result["main_section_keys"] : Map()
                removedSections := result.Has("main_sections_removed") ? result["main_sections_removed"] : []
                VimDesktop_ApplyMainConfigChanges(sections, sectionKeyDiffs, removedSections)
            }
            if (result.Has("plugins") && IsObject(result["plugins"]) && result["plugins"].Length > 0) {
                VimDesktop_ApplyPluginIniChanges(result["plugins"])
            }
            return
        }

        VimDesktop_ApplyMainConfigCore()
    } catch Error as e {
        VimD_Log("WARN", "CONFIG_HOT_RELOAD_APPLY", "应用热加载配置失败", e)
    }
}
