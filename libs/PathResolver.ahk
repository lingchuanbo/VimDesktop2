#Requires AutoHotkey v2.0

class PathResolver {
    static RootDir() {
        return this._Join(A_ScriptDir, "..")
    }

    static SrcDir() {
        return this._Join(this.RootDir(), "src")
    }

    static LibsDir() {
        return this._Join(this.RootDir(), "libs")
    }

    static PluginsDir() {
        return this._Join(this.RootDir(), "plugins")
    }

    static ConfigDir() {
        return this._Join(this.RootDir(), "config")
    }

    static AppsDir() {
        return this._Join(this.RootDir(), "apps")
    }

    static LangDir() {
        return this._Join(this.RootDir(), "lang")
    }

    static DocsDir() {
        return this._Join(this.RootDir(), "docs")
    }

    static RootPath(pathValue := "") {
        if (pathValue = "")
            return ""
        if (RegExMatch(pathValue, "i)^[a-z]:\\"))
            return pathValue
        if (SubStr(pathValue, 1, 2) = "\\")
            return pathValue
        if (SubStr(pathValue, 1, 1) = "\" || SubStr(pathValue, 1, 1) = "/")
            return this.RootDir() . pathValue
        return this._Join(this.RootDir(), pathValue)
    }

    static ConfigPath(fileName := "") {
        return this._Join(this.ConfigDir(), fileName)
    }

    static PluginPath(pluginName := "", fileName := "") {
        base := this.PluginsDir()
        if (pluginName != "")
            base := this._Join(base, pluginName)
        if (fileName != "")
            base := this._Join(base, fileName)
        return base
    }

    static AppsPath(fileName := "") {
        return this._Join(this.AppsDir(), fileName)
    }

    static LangPath(fileName := "") {
        return this._Join(this.LangDir(), fileName)
    }

    static _Join(base, part) {
        if (part = "")
            return base
        if (SubStr(base, 0) = "\" || SubStr(base, 0) = "/")
            return base . part
        return base "\" part
    }
}
