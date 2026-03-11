#Requires AutoHotkey v2.0

class ConfigServiceChangeTracker {
    static BuildPluginConfigPathIndex(owner) {
        pluginConfigPaths := Map()

        for _, pluginName in PluginCatalog.ListPluginNames() {
            for configPath in PluginCatalog.GetPluginConfigCandidates(pluginName) {
                if FileExist(configPath) {
                    pluginConfigPaths[pluginName] := configPath
                    break
                }
            }
        }

        owner.PluginConfigPaths := pluginConfigPaths
    }

    static LoadPluginConfigs(owner) {
        if !IsObject(owner.PluginConfigs)
            owner.PluginConfigs := {}

        this.BuildPluginConfigPathIndex(owner)

        for pluginName, configPath in owner.PluginConfigPaths {
            if (configPath = "")
                continue
            if (owner.PluginConfigs.HasOwnProp(pluginName))
                continue
            try {
                owner.PluginConfigs.%pluginName% := EasyIni(configPath)
            } catch Error as e {
                VimD_Log("WARN", "CONFIG_PLUGIN_LOAD_FAIL", "Failed to load plugin config: " pluginName " -> " configPath, e)
            }
        }
    }

    static InitFileMtimes(owner) {
        owner.FileMtimes := Map()

        mainPath := owner._GetMainConfigPath()
        if (mainPath != "")
            owner.FileMtimes["main"] := owner._GetFileMtime(mainPath)

        if IsObject(owner.PluginConfigPaths) {
            for pluginName, configPath in owner.PluginConfigPaths {
                if (configPath = "")
                    continue
                owner.FileMtimes["plugin:" pluginName] := owner._GetFileMtime(configPath)
            }
        }
    }

    static InitMainSectionSnapshots(owner) {
        owner.MainSectionSnapshots := this.BuildMainSectionSnapshots(owner)
    }

    static BuildMainSectionSnapshots(owner) {
        snapshots := Map()
        if !IsObject(owner.MainConfig)
            return snapshots

        for secName, secObj in owner.MainConfig.OwnProps() {
            if owner._IsReservedConfigProperty(secName)
                continue
            if !IsObject(secObj)
                continue
            snapshots[secName] := this.SnapshotSection(owner, secObj)
        }
        return snapshots
    }

    static SnapshotSection(owner, sectionObj) {
        snapshot := Map()
        if !IsObject(sectionObj)
            return snapshot
        for key, value in sectionObj.OwnProps() {
            if this.IsReservedSectionKey(key)
                continue
            snapshot[key] := value
        }
        return snapshot
    }

    static IsReservedSectionKey(name) {
        return (name = "EasyIni_KeyComment"
            || name = "EasyIni_SectionComment"
            || name = "__Class")
    }

    static DiffMainSections(owner) {
        oldSnapshots := IsObject(owner.MainSectionSnapshots) ? owner.MainSectionSnapshots : Map()
        newSnapshots := this.BuildMainSectionSnapshots(owner)

        changedSections := []
        addedSections := []
        removedSections := []
        sectionKeyDiffs := Map()

        for secName, newSnap in newSnapshots {
            if !oldSnapshots.Has(secName) {
                addedSections.Push(secName)
                this.PushUnique(changedSections, secName)
                continue
            }

            diff := this.DiffSectionSnapshot(oldSnapshots[secName], newSnap)
            if (diff["added"].Length > 0 || diff["removed"].Length > 0 || diff["changed"].Length > 0) {
                this.PushUnique(changedSections, secName)
                sectionKeyDiffs[secName] := diff
            }
        }

        for secName, oldSnap in oldSnapshots {
            if !newSnapshots.Has(secName) {
                removedSections.Push(secName)
                this.PushUnique(changedSections, secName)
            }
        }

        owner.MainSectionSnapshots := newSnapshots
        return Map(
            "changed_sections", changedSections,
            "added_sections", addedSections,
            "removed_sections", removedSections,
            "section_key_diffs", sectionKeyDiffs
        )
    }

    static DiffSectionSnapshot(oldSnap, newSnap) {
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

    static PushUnique(arr, value) {
        if !IsObject(arr)
            return
        for _, item in arr {
            if (item = value)
                return
        }
        arr.Push(value)
    }

    static GetFileMtime(filePath) {
        if (filePath = "")
            return ""
        try {
            return FileGetTime(filePath, "M")
        } catch {
            return ""
        }
    }

    static HasFileChanged(owner, key, filePath) {
        newTime := this.GetFileMtime(filePath)
        oldTime := owner.FileMtimes.Has(key) ? owner.FileMtimes[key] : ""
        if (newTime = "" && oldTime = "")
            return false
        if (newTime != oldTime) {
            owner.FileMtimes[key] := newTime
            return true
        }
        return false
    }

    static MaybeRefreshPluginConfigPathIndex(owner) {
        nowTick := A_TickCount
        if (owner._LastPluginPathScanTick != 0
            && (nowTick - owner._LastPluginPathScanTick) < owner.PluginPathScanIntervalMs) {
            return
        }

        owner._LastPluginPathScanTick := nowTick
        this.BuildPluginConfigPathIndex(owner)
    }

    static RefreshIfChanged(owner, enableValidation := true, enableDebug := false, logPath := "") {
        result := Map("changed", false, "main", false, "plugins", [])

        if !IsObject(owner.MainConfig)
            return result

        if !IsObject(owner.FileMtimes)
            owner.FileMtimes := Map()

        this.MaybeRefreshPluginConfigPathIndex(owner)

        mainChanged := this.ReloadMainConfigIfChanged(owner)
        changedPlugins := this.ReloadPluginConfigsIfChanged(owner)

        if (mainChanged || changedPlugins.Length > 0) {
            result["changed"] := true
            result["main"] := mainChanged
            result["plugins"] := changedPlugins
            if (mainChanged) {
                mainDiff := this.DiffMainSections(owner)
                result["main_sections"] := mainDiff["changed_sections"]
                result["main_sections_added"] := mainDiff["added_sections"]
                result["main_sections_removed"] := mainDiff["removed_sections"]
                result["main_section_keys"] := mainDiff["section_key_diffs"]
            }

            if (enableValidation)
                owner.ValidateAndReport(enableDebug, true, logPath)

            VimD_Log("INFO", "CONFIG_HOT_RELOAD", "Config refreshed: main=" (mainChanged ? 1 : 0)
                " plugins=" changedPlugins.Length)
        }

        return result
    }

    static ReloadMainConfigIfChanged(owner) {
        mainPath := owner._GetMainConfigPath()
        if (mainPath = "")
            return false

        if !this.HasFileChanged(owner, "main", mainPath)
            return false

        if !FileExist(mainPath) {
            VimD_LogOnce("WARN", "CONFIG_MAIN_MISSING", "Main config file missing: " mainPath)
            return false
        }

        try {
            owner.MainConfig.Reload()
            return true
        } catch Error as e {
            VimD_Log("WARN", "CONFIG_MAIN_RELOAD_FAIL", "Failed to reload main config", e)
            return false
        }
    }

    static ReloadPluginConfigsIfChanged(owner) {
        changedPlugins := []

        if !IsObject(owner.PluginConfigs)
            return changedPlugins

        for pluginName, pluginIni in owner.PluginConfigs.OwnProps() {
            if !IsObject(pluginIni)
                continue

            configPath := ""
            if (owner.PluginConfigPaths.Has(pluginName))
                configPath := owner.PluginConfigPaths[pluginName]
            else if (pluginIni.HasOwnProp("EasyIni_ReservedFor_m_sFile"))
                configPath := pluginIni.EasyIni_ReservedFor_m_sFile

            if (configPath = "")
                continue

            key := "plugin:" pluginName
            if !this.HasFileChanged(owner, key, configPath)
                continue

            if !FileExist(configPath) {
                VimD_LogOnce("WARN", "CONFIG_PLUGIN_MISSING", "Plugin config file missing: " pluginName " -> " configPath)
                continue
            }

            try {
                pluginIni.Reload()
                changedPlugins.Push(pluginName)
            } catch Error as e {
                VimD_Log("WARN", "CONFIG_PLUGIN_RELOAD_FAIL", "Failed to reload plugin config: " pluginName, e)
            }
        }

        for pluginName, configPath in owner.PluginConfigPaths {
            if (owner.PluginConfigs.HasOwnProp(pluginName))
                continue
            if (configPath = "")
                continue

            key := "plugin:" pluginName
            if !this.HasFileChanged(owner, key, configPath)
                continue

            if !FileExist(configPath) {
                VimD_LogOnce("WARN", "CONFIG_PLUGIN_MISSING", "Plugin config file missing: " pluginName " -> " configPath)
                continue
            }

            try {
                owner.PluginConfigs.%pluginName% := EasyIni(configPath)
                changedPlugins.Push(pluginName)
            } catch Error as e {
                VimD_Log("WARN", "CONFIG_PLUGIN_LOAD_FAIL", "Failed to load plugin config: " pluginName " -> " configPath, e)
            }
        }

        return changedPlugins
    }
}
