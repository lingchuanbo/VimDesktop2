; 自动启动扩展功能
VimDesktop_AutoStartExtensions() {
    global VimDesktop_ExtensionPIDs
    global VimDesktop_ExtensionAutoStartPaths
    try {
        configMap := VimDesktop_GetExtensionsConfig()
        autoStartCount := 0

        for key, info in configMap {
            if (info["autoStart"] != "1")
                continue
            if !FileExist(info["fullPath"])
                continue

            pid := VimDesktop_StartExtension(key, info)
            if (pid) {
                VimDesktop_ExtensionPIDs[key] := pid
                VimDesktop_ExtensionAutoStartPaths[key] := info["fullPath"]
                autoStartCount++
            }
        }

        if (autoStartCount > 0 && VimDesktop_Global.default_enable_show_info) {
            SetTimer(VimDesktop_ShowAutoStartInfo.Bind(autoStartCount), -1000)
        }

        if (autoStartCount > 0) {
            try {
                if (INIObject.config.enable_log == 1)
                    VimD_Log("INFO", "EXT_AUTOSTART", "自动启动扩展数量: " autoStartCount)
            } catch {
            }
        }
    } catch Error as e {
        if (INIObject.config.enable_debug)
            MsgBox("自动启动扩展功能时出错：" e.Message, "调试信息", "OK Icon!")
    }
}

; 刷新扩展功能（热重载）
VimDesktop_RefreshExtensions() {
    global VimDesktop_ExtensionPIDs
    global VimDesktop_ExtensionAutoStartPaths
    try {
        configMap := VimDesktop_GetExtensionsConfig()
        stopped := []
        started := []

        namesToDelete := []
        for name, pid in VimDesktop_ExtensionPIDs {
            keep := configMap.Has(name) && configMap[name]["autoStart"] = "1"
            if (keep && VimDesktop_ExtensionAutoStartPaths.Has(name)) {
                if (VimDesktop_ExtensionAutoStartPaths[name] != configMap[name]["fullPath"])
                    keep := false
            }

            if (!keep) {
                expectedPath := VimDesktop_ExtensionAutoStartPaths.Has(name) ? VimDesktop_ExtensionAutoStartPaths[name] : ""
                if (VimDesktop_StopExtensionProcess(pid, expectedPath))
                    stopped.Push(name)
                namesToDelete.Push(name)
            }
        }

        for _, name in namesToDelete {
            if (VimDesktop_ExtensionPIDs.Has(name))
                VimDesktop_ExtensionPIDs.Delete(name)
            if (VimDesktop_ExtensionAutoStartPaths.Has(name))
                VimDesktop_ExtensionAutoStartPaths.Delete(name)
        }

        for name, info in configMap {
            if (info["autoStart"] != "1")
                continue
            if (VimDesktop_ExtensionPIDs.Has(name) && ProcessExist(VimDesktop_ExtensionPIDs[name])) {
                VimDesktop_ExtensionAutoStartPaths[name] := info["fullPath"]
                continue
            }
            if !FileExist(info["fullPath"])
                continue

            pid := VimDesktop_StartExtension(name, info)
            if (pid) {
                VimDesktop_ExtensionPIDs[name] := pid
                VimDesktop_ExtensionAutoStartPaths[name] := info["fullPath"]
                started.Push(name)
            }
        }

        VimDesktop_TrayMenuCreate()
        try {
            if (INIObject.config.enable_log == 1) {
                if (started.Length > 0)
                    VimD_Log("INFO", "EXT_REFRESH_START", "扩展启动: " started.Length " -> " VimDesktop_JoinNames(started))
                if (stopped.Length > 0)
                    VimD_Log("INFO", "EXT_REFRESH_STOP", "扩展停止: " stopped.Length " -> " VimDesktop_JoinNames(stopped))
            }
        } catch {
        }
    } catch Error as e {
        if (INIObject.config.enable_debug)
            MsgBox("刷新扩展功能时出错：" e.Message, "调试信息", "OK Icon!")
    }
}

VimDesktop_GetExtensionsConfig() {
    configMap := Map()
    if (!INIObject.HasOwnProp("extensions"))
        return configMap

    for key, value in INIObject.extensions.OwnProps() {
        if (_IsEasyIniReserved(key))
            continue
        if (value = "")
            continue

        parts := StrSplit(value, "|")
        if (parts.Length < 1 || parts[1] = "")
            continue

        scriptPath := parts[1]
        autoStart := (parts.Length > 1) ? parts[2] : "0"
        fullPath := PathResolver.RootPath(scriptPath)
        configMap[key] := Map("scriptPath", scriptPath, "fullPath", fullPath, "autoStart", autoStart)
    }
    return configMap
}

VimDesktop_StartExtension(name, info) {
    scriptPath := info["scriptPath"]
    fullScriptPath := info["fullPath"]
    if !FileExist(fullScriptPath)
        return 0

    try {
        if (InStr(scriptPath, ".exe")) {
            Run(Format('"{1}"', fullScriptPath), , , &processId)
        } else {
            ahkPath := VimDesktop_Global.AhkPath
            Run(Format('"{1}" "{2}"', ahkPath, fullScriptPath), , , &processId)
        }
        return processId
    } catch Error as runError {
        if (INIObject.config.enable_debug)
            MsgBox("启动扩展功能失败：" name " - " runError.Message, "调试信息", "OK Icon!")
    }
    return 0
}

VimDesktop_StopExtensionProcess(pid, expectedPath := "") {
    if (!pid)
        return false
    try {
        if (ProcessExist(pid)) {
            if (expectedPath != "") {
                try {
                    realPath := ProcessGetPath(pid)
                    if (realPath != "" && StrLower(realPath) != StrLower(expectedPath))
                        return false
                } catch {
                }
            }

            ProcessClose(pid)
            Sleep(100)
            if (ProcessExist(pid))
                Run("taskkill /F /PID " pid, , "Hide")
        }
        return true
    } catch {
        return false
    }
}

VimDesktop_JoinNames(items) {
    if (!IsObject(items) || items.Length = 0)
        return ""
    text := ""
    for _, name in items {
        if (text != "")
            text .= ", "
        text .= name
    }
    return text
}

; 显示自动启动信息
VimDesktop_ShowAutoStartInfo(count) {
    try {
        ; 这里可以使用你的提示系统显示信息
        ; MsgBox("已自动启动" count " 个扩展功能", "提示", "OK T2")
    } catch {
        ; 蹇界暐鏄剧ず閿欒
    }
}

; 扩展功能处理函数
VimDesktop_ExtensionHandler(ItemName, *) {
    try {
        ; 移除菜单项中的自动启动标识符
        cleanItemName := StrReplace(ItemName, " *", "")

        ; 从配置中获取对应的脚本路径
        if (INIObject.HasOwnProp("extensions") && INIObject.extensions.HasOwnProp(cleanItemName)) {
            configValue := INIObject.extensions.%cleanItemName%

            ; 解析配置值（脚本路径|自动启动标志）
            configParts := StrSplit(configValue, "|")
            scriptPath := configParts[1]

            ; 构建完整路径
            fullScriptPath := PathResolver.RootPath(scriptPath)

            ; 检查文件是否存在
            if (FileExist(fullScriptPath)) {
                ; 根据文件扩展名选择执行方式
                if (InStr(scriptPath, ".exe")) {
                    ; 直接运行exe文件
                    Run(Format('"{1}"', fullScriptPath))
                } else {
                    ; 使用AutoHotkey运行ahk文件
                    ahkPath := VimDesktop_Global.AhkPath
                    Run(Format('"{1}" "{2}"', ahkPath, fullScriptPath))
                }
            } else {
                MsgBox("文件不存在：" fullScriptPath, "错误", "OK Icon!")
            }
        }
    } catch Error as e {
        MsgBox("执行扩展功能时出错：" e.Message, "错误", "OK Icon!")
    }
}
