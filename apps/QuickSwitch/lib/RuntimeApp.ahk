class RuntimeApp {
    static Run() {
        InitializeConfig()
        this.RegisterHotkeys()
        this.InitializeTrayIcon()
        InitializeCurrentWindows()
        StartWindowMonitoring()
        this.MainLoop()
    }

    static RegisterHotkeys() {
        try {
            Hotkey(g_Config.MainHotkey, ShowSmartMenu, "On")
            Hotkey(g_Config.QuickSwitchHotkey, QuickSwitchLastTwo, "On")

            if (g_Config.EnableGetWindowsFolderActivePath = "1") {
                Hotkey(g_Config.GetWindowsFolderActivePathKey, GetWindowsFolderActivePath, "On")
            }

            Hotkey("^!w", ObjBindMethod(this, "ActivateWeChatHotkey"), "On")
        } catch as e {
            MsgBox("注册热键失败: " . e.message . "`n使用默认热键 Ctrl+Q 和 Ctrl+Tab", "警告", "T5")
            try {
                Hotkey("^q", ShowSmartMenu, "On")
                Hotkey("^Tab", QuickSwitchLastTwo, "On")
                if (g_Config.EnableGetWindowsFolderActivePath = "1") {
                    Hotkey("!w", GetWindowsFolderActivePath, "On")
                }
                Hotkey("^!w", ObjBindMethod(this, "ActivateWeChatHotkey"), "On")
            }
        }
    }

    static ActivateWeChatHotkey(*) {
        ActivateWeChat("")
    }

    static InitializeTrayIcon() {
        iconPath := A_ScriptDir . "\icon\fast-forward-1.ico"
        if (FileExist(iconPath)) {
            TraySetIcon(iconPath)
        }

        A_IconTip := "QuickSwitch - 快速切换工具"
        this.CreateTrayMenu()
    }

    static CreateTrayMenu() {
        A_TrayMenu.Delete()
        A_TrayMenu.Add("设置", ObjBindMethod(this, "OpenConfigFile"))
        A_TrayMenu.Add()
        A_TrayMenu.Add("输出性能摘要", ObjBindMethod(this, "DumpMenuPerfSummaryFromTray"))
        A_TrayMenu.Add("清空性能统计", ObjBindMethod(this, "ResetMenuPerfStatsFromTray"))
        A_TrayMenu.Add()
        A_TrayMenu.Add("关于", ObjBindMethod(this, "ShowAboutFromTray"))
        A_TrayMenu.Add("重启", ObjBindMethod(this, "RestartApplication"))
        A_TrayMenu.Add("退出", ObjBindMethod(this, "ExitApplication"))
        A_TrayMenu.Default := "设置"
    }

    static UpdateTrayMenuThemeStatus() {
        themeText := g_DarkMode ? "切换主题 (当前: 深色)" : "切换主题 (当前: 浅色)"
        try {
            A_TrayMenu.Rename("切换主题", themeText)
        } catch {
        }
    }

    static UpdateTrayMenuGetWindowsFolderActivePathStatus() {
        functionText := (g_Config.EnableGetWindowsFolderActivePath = "1") ? "GetWindowsFolderActivePath功能 (当前: 开启)" :
            "GetWindowsFolderActivePath功能 (当前: 关闭)"
        try {
            A_TrayMenu.Rename("GetWindowsFolderActivePath功能", functionText)
        } catch {
        }
    }

    static UpdateTrayMenuRunModeStatus() {
        try {
            runModeMenu := A_TrayMenu.Handle("运行模式")
            runModeMenu.Uncheck("全部运行")
            runModeMenu.Uncheck("只运行路径跳转")
            runModeMenu.Uncheck("只运行程序切换")

            switch g_Config.RunMode {
                case 0:
                    runModeMenu.Check("全部运行")
                case 1:
                    runModeMenu.Check("只运行路径跳转")
                case 2:
                    runModeMenu.Check("只运行程序切换")
            }
        } catch {
        }
    }

    static OpenConfigFile(*) {
        EditConfigFile()
    }

    static ToggleThemeFromTray(*) {
        ToggleTheme()
        this.UpdateTrayMenuThemeStatus()
    }

    static ToggleGetWindowsFolderActivePathFromTray(*) {
        ToggleGetWindowsFolderActivePath()
        this.UpdateTrayMenuGetWindowsFolderActivePathStatus()
    }

    static SetRunModeFromTray(mode, *) {
        SetRunMode(mode)
        this.UpdateTrayMenuRunModeStatus()
    }

    static ShowAboutFromTray(*) {
        ShowAbout()
    }

    static RestartApplication(*) {
        result := MsgBox("确定要重启 QuickSwitch 吗？", "重启确认", "YesNo Icon?")
        if (result = "Yes") {
            Reload
        }
    }

    static ExitApplication(*) {
        result := MsgBox("确定要退出 QuickSwitch 吗？", "退出确认", "YesNo Icon?")
        if (result = "Yes") {
            ExitApp
        }
    }

    static DumpMenuPerfSummaryFromTray(*) {
        summary := RuntimeLog.BuildMenuPerfSummaryText(g_MenuPerfMinSamples, g_MenuPerfTopN)
        if (summary = "") {
            MsgBox("暂无性能统计样本。请先触发几次菜单后再查看。", "性能统计", "T3")
            return
        }

        if (g_LogEnabled) {
            RuntimeLog.LogPerfSummary(summary, "INFO")
        }
        MsgBox(summary, "菜单性能摘要", "T8")
    }

    static ResetMenuPerfStatsFromTray(*) {
        RuntimeLog.ResetMenuPerfStats()
        if (g_LogEnabled) {
            RuntimeLog.LogMessage("菜单性能统计已手动清空", "INFO")
        }
        MsgBox("菜单性能统计已清空。", "性能统计", "T2")
    }

    static MainLoop() {
        if !IsOSSupported() {
            MsgBox(A_OSVersion . " is not supported.")
            ExitApp()
        }

        SetTimer(ObjBindMethod(RuntimeFileDialog, "MonitorDialogs"), 200)
        loop {
            Sleep(100)
        }
    }
}
