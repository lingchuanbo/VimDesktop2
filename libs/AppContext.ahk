#Requires AutoHotkey v2.0

class AppContext {
    static Create() {
        context := {
            Runtime: Object(),
            Vim: Object(),
            INIObject: Object(),
            PluginConfigs: Object(),
            Lang: Object(),
            ExtensionPIDs: Map(),
            ExtensionAutoStartPaths: Map(),
            ConfigHotReloadIntervalMs: 5000
        }

        context.Runtime.ConfigPath := PathResolver.ConfigPath("vimd.ini")
        context.Runtime.Editor := "NotePad.exe"
        context.Runtime.AhkPath := PathResolver.AppsPath("AutoHotkey.exe")
        context.Runtime.default_enable_show_info := ""
        context.Runtime.WshShell := ""
        context.Runtime.__vimLastAction := ""
        context.Runtime.showToolTipStatus := 0
        context.Runtime.Current_KeyMap := ""

        return context
    }
}
