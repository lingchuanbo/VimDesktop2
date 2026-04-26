#Requires AutoHotkey v2.0

class PluginCatalog {
    static _PluginNamesCache := []
    static _PluginNamesCacheTick := 0
    static _PluginNamesCacheTtl := 30000

    static ListPluginNames() {
        tick := A_TickCount
        if (this._PluginNamesCache.Length > 0
            && tick - this._PluginNamesCacheTick < this._PluginNamesCacheTtl)
            return this._PluginNamesCache

        pluginNames := []
        pluginsDir := PathResolver.PluginsDir()
        if !DirExist(pluginsDir) {
            this._PluginNamesCache := pluginNames
            this._PluginNamesCacheTick := tick
            return pluginNames
        }

        loop files, pluginsDir "\*", "D" {
            pluginNames.Push(A_LoopFileName)
        }
        this._PluginNamesCache := pluginNames
        this._PluginNamesCacheTick := tick
        return pluginNames
    }

    static GetMetaPath(pluginName) {
        return PathResolver.PluginPath(pluginName, "plugin.meta.ini")
    }

    static GetRuntimeDir(pluginName) {
        return PathResolver.PluginPath(pluginName, "runtime")
    }

    static GetAssetsDir(pluginName) {
        return PathResolver.PluginPath(pluginName, "assets")
    }

    static GetLegacyResourcePath(pluginName, relativePath := "") {
        baseDir := PathResolver.PluginPath(pluginName)
        if (relativePath = "")
            return baseDir
        relativePath := StrReplace(relativePath, "/", "\")
        return baseDir "\" relativePath
    }

    static GetResourcePath(pluginName, relativePath := "") {
        relativePath := StrReplace(relativePath, "/", "\")
        assetsPath := this.GetAssetsDir(pluginName)
        if (relativePath != "") {
            assetFile := assetsPath "\" relativePath
            if (FileExist(assetFile) || DirExist(assetFile))
                return assetFile
        } else if DirExist(assetsPath) {
            return assetsPath
        }

        return this.GetLegacyResourcePath(pluginName, relativePath)
    }

    static _MetaCache := Map()

    static ReadMeta(pluginName) {
        if this._MetaCache.Has(pluginName)
            return this._MetaCache[pluginName]

        meta := Map(
            "name", pluginName,
            "author", "",
            "version", "",
            "comment", "",
            "entry", ""
        )

        metaPath := this.GetMetaPath(pluginName)
        if !FileExist(metaPath) {
            this._MetaCache[pluginName] := meta
            return meta
        }

        try {
            content := FileRead(metaPath, "UTF-8")
            this._TryReadMetaKey(content, "name", meta)
            this._TryReadMetaKey(content, "author", meta)
            this._TryReadMetaKey(content, "version", meta)
            this._TryReadMetaKey(content, "comment", meta)
            this._TryReadMetaKey(content, "entry", meta)
            if (meta["entry"] = "")
                this._TryReadMetaKey(content, "main", meta, "entry")
            if (meta["entry"] != "" && (SubStr(meta["entry"], 1, 1) = "\" || SubStr(meta["entry"], 1, 1) = "/"))
                meta["entry"] := SubStr(meta["entry"], 2)
        } catch Error as e {
            VimD_Log("WARN", "PLUGIN_READ_META", "Failed to read plugin meta: " pluginName, e)
        }

        this._MetaCache[pluginName] := meta
        return meta
    }

    static GetPluginEntry(pluginName) {
        meta := this.ReadMeta(pluginName)
        return meta["entry"]
    }

    static GetPluginMainFile(pluginName) {
        entry := this.GetPluginEntry(pluginName)
        if (entry = "")
            entry := pluginName ".ahk"
        return PathResolver.PluginPath(pluginName, entry)
    }

    static GetPluginConfigCandidates(pluginName) {
        pluginDir := PathResolver.PluginPath(pluginName)
        runtimeDir := this.GetRuntimeDir(pluginName)
        return [
            runtimeDir "\config.ini",
            runtimeDir "\" pluginName ".ini",
            pluginDir "\" pluginName ".ini",
            pluginDir "\" StrLower(pluginName) ".ini",
            pluginDir "\config.ini",
            pluginDir "\plugin.ini"
        ]
    }

    static _TryReadMetaKey(content, keyName, meta, targetKey := "") {
        if (targetKey = "")
            targetKey := keyName
        if (RegExMatch(content, "im)^\s*" keyName "\s*=\s*(.*)$", &m))
            meta[targetKey] := Trim(m[1], " `t`r`n")
    }
}
