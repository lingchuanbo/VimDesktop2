VimDesktop_TrayMenuCreate() {
    global VimDesktop_TrayMenu
    VimDesktop_TrayMenu := A_TrayMenu
    VimDesktop_TrayMenu.delete()
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Manager"], VimDesktop_TrayHandler)
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Setting"], VimDesktop_TrayHandler)
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["ConfigReport"], VimDesktop_TrayHandler)
    VimDesktop_TrayMenu.Add()

    extensionsMenu := Menu()
    extensionCount := 0

    try {
        if (INIObject.HasOwnProp("extensions")) {
            for key, value in INIObject.extensions.OwnProps() {
                if (key = "__Class" || key = "EasyIni_KeyComment" || key = "EasyIni_SectionComment")
                    continue

                configParts := StrSplit(value, "|")
                scriptPath := configParts[1]
                autoStart := (configParts.Length > 1) ? configParts[2] : "0"

                menuText := key . (autoStart = "1" ? " *" : "")
                extensionsMenu.Add(menuText, VimDesktop_ExtensionHandler)
                extensionCount++
            }
        }
    } catch Error as e {
        extensionsMenu.Add("配置读取错误", (*) => MsgBox("错误：" e.Message, "配置错误", "OK Icon!"))
    }

    if (extensionCount = 0) {
        extensionsMenu.Add("暂无扩展功能", (*) => MsgBox("请在配置文件的[extensions]节中添加扩展功能", "提示", "OK"))
    }

    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Extensions"], extensionsMenu)
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["EditCustom"], VimDesktop_TrayHandler)
    VimDesktop_TrayMenu.Add()
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Reload"], (*) => Reload())
    VimDesktop_TrayMenu.Add(Lang["TrayMenu"]["Exit"], VimDesktop_ExitHandler)
    VimDesktop_TrayMenu.ClickCount := 2
    VimDesktop_TrayMenu.default := Lang["TrayMenu"]["Default"]
    A_IconTip := "VimDesktopV2_BoBO`n版本:1.1(By_Kawvin Mod_BoBO)"
}

VimDesktop_TrayHandler(Item, *) {
    switch Item {
        case Lang["TrayMenu"]["Manager"]:
            VimDConfig_KeyMapEdit()
        case Lang["TrayMenu"]["Setting"]:
            run VimDesktop_Global.ConfigPath
        case Lang["TrayMenu"]["ConfigReport"]:
            VimDesktop_OpenConfigValidationReport()
        case Lang["TrayMenu"]["EditCustom"]:
            try run Format('"{1}" "{2}"', VimDesktop_Global.Editor, PathResolver.ConfigPath("Custom.ahk"))
    }
}

VimDesktop_OpenConfigValidationReport() {
    reportPath := PathResolver.ConfigPath("config_validation.log")

    ConfigService.RefreshIfChanged(false)
    ConfigService.ValidateAndReport(false, true, reportPath)

    try {
        Run Format('"{1}" "{2}"', VimDesktop_Global.Editor, reportPath)
    } catch {
        try Run reportPath
    }
}

; 退出处理函数 - 关闭所有自动启动的扩展功能
VimDesktop_ExitHandler(*) {
    try {
        ; 关闭所有自动启动的扩展功能进程
        if (IsSet(VimDesktop_ExtensionPIDs)) {
            for extensionName, pid in VimDesktop_ExtensionPIDs {
                try {
                    if (ProcessExist(pid)) {
                        ProcessClose(pid)
                        Sleep(100)
                        if (ProcessExist(pid))
                            Run("taskkill /F /PID " pid, , "Hide")
                    }
                } catch {
                    ; 忽略关闭进程时的错误
                }
            }
        }

        ; 清理临时文件
        try {
            FileDelete(A_Temp "\vimd_auto.ini")
        } catch {
            ; 忽略删除临时文件错误
        }

    } catch Error as e {
        if (INIObject.config.enable_debug)
            MsgBox("清理扩展功能时出错：" e.Message, "调试信息", "OK Icon!")
    }

    ExitApp()
}

VimDesktop_ThemeHandler(ItemName, ItemPos, MyMenu) {
    global VimDesktop_TrayMenu

    ; 取消所有选中状态
    MyMenu.Uncheck("明亮模式 ☼")
    MyMenu.Uncheck("暗黑模式 ☾")
    MyMenu.Uncheck("跟随系统 🖥️")

    ; 选中当前项
    MyMenu.Check(ItemName)

    ; 根据选择设置主题
    switch ItemName {
        case "明亮模式 ☼":
            ; 设置为明亮模式
            WindowsTheme.SetAppMode(false)
            ; 更新配置文件
            INIObject.config.theme_mode := "light"
            INIObject.save()

        case "暗黑模式 ☾":
            ; 设置为暗黑模式
            WindowsTheme.SetAppMode(true)
            ; 更新配置文件
            INIObject.config.theme_mode := "dark"
            INIObject.save()

        case "跟随系统 🖥️":
            ; 设置为跟随系统
            WindowsTheme.SetAppMode("Default")
            ; 更新配置文件
            INIObject.config.theme_mode := "system"
            INIObject.save()
    }
}
