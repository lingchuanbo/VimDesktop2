;===========================================================
; ConfigFunctions.ahk - 所有功能函数
;===========================================================

;===========================================================
; 保存配置
;===========================================================
SaveAllConfig(*) {
    global Data
    UTF8IniWrite(Data["MainHotkeyCtrl"].Value, IniFile, "Settings", "MainHotkey")
    UTF8IniWrite(Data["QuickSwitchHotkeyCtrl"].Value, IniFile, "Settings", "QuickSwitchHotkey")
    UTF8IniWrite(Data["GetPathKeyCtrl"].Value, IniFile, "Settings", "GetWindowsFolderActivePathKey")
    UTF8IniWrite(Data["EnableGetPathCtrl"].Value, IniFile, "Settings", "EnableGetWindowsFolderActivePath")
    UTF8IniWrite(Data["MaxHistoryCountCtrl"].Value, IniFile, "Settings", "MaxHistoryCount")
    UTF8IniWrite(Data["EnableQuickAccessCtrl"].Value, IniFile, "Settings", "EnableQuickAccess")
    UTF8IniWrite(Data["QuickAccessKeysCtrl"].Value, IniFile, "Settings", "QuickAccessKeys")
    UTF8IniWrite(Data["RunModeCtrl"].Value - 1, IniFile, "Settings", "RunMode")
    UTF8IniWrite(Data["MenuColorCtrl"].Value, IniFile, "Display", "MenuColor")
    UTF8IniWrite(Data["IconSizeCtrl"].Value, IniFile, "Display", "IconSize")
    UTF8IniWrite(Data["ShowWindowTitleCtrl"].Value, IniFile, "Display", "ShowWindowTitle")
    UTF8IniWrite(Data["ShowProcessNameCtrl"].Value, IniFile, "Display", "ShowProcessName")
    WinPos := Data["WinPos1Ctrl"].Value ? "mouse" : "fixed"
    UTF8IniWrite(WinPos, IniFile, "WindowSwitchMenu", "Position")
    UTF8IniWrite(Data["WinPosXCtrl"].Value, IniFile, "WindowSwitchMenu", "FixedPosX")
    UTF8IniWrite(Data["WinPosYCtrl"].Value, IniFile, "WindowSwitchMenu", "FixedPosY")
    PathPos := Data["PathPos1Ctrl"].Value ? "mouse" : "fixed"
    UTF8IniWrite(PathPos, IniFile, "PathSwitchMenu", "Position")
    UTF8IniWrite(Data["PathPosXCtrl"].Value, IniFile, "PathSwitchMenu", "FixedPosX")
    UTF8IniWrite(Data["PathPosYCtrl"].Value, IniFile, "PathSwitchMenu", "FixedPosY")
    UTF8IniWrite(Data["TCCtrl"].Value, IniFile, "FileManagers", "TotalCommander")
    UTF8IniWrite(Data["ExplorerCtrl"].Value, IniFile, "FileManagers", "Explorer")
    UTF8IniWrite(Data["XYCtrl"].Value, IniFile, "FileManagers", "XYplorer")
    UTF8IniWrite(Data["DOpusCtrl"].Value, IniFile, "FileManagers", "DirectoryOpus")
    UTF8IniWrite(Data["EnableCustomPathsCtrl"].Value, IniFile, "CustomPaths", "EnableCustomPaths")
    UTF8IniWrite(Data["CustomMenuTitleCtrl"].Value, IniFile, "CustomPaths", "MenuTitle")
    UTF8IniWrite(Data["ShowCustomNameCtrl"].Value, IniFile, "CustomPaths", "ShowCustomName")
    SaveCustomPaths()
    UTF8IniWrite(Data["EnableRecentPathsCtrl"].Value, IniFile, "RecentPaths", "EnableRecentPaths")
    UTF8IniWrite(Data["RecentMenuTitleCtrl"].Value, IniFile, "RecentPaths", "MenuTitle")
    UTF8IniWrite(Data["MaxRecentPathsCtrl"].Value, IniFile, "RecentPaths", "MaxRecentPaths")
    SaveExcludedApps()
    SavePinnedApps()
    UTF8IniWrite(Data["EnableLaunchCtrl"].Value, IniFile, "QuickLaunchApps", "EnableQuickLaunchApps")
    UTF8IniWrite(Data["MaxDisplayCountCtrl"].Value, IniFile, "QuickLaunchApps", "MaxDisplayCount")
    SaveLaunchApps()
    
    ; [Theme]
    UTF8IniWrite(Data["DarkModeCtrl"].Value, IniFile, "Theme", "DarkMode")
    
    MsgBox("配置已保存！`n请重启 QuickSwitch 以应用更改。", "成功", 64)
}

;===========================================================
; 辅助函数
;===========================================================
UpdateWinPosControls() {
    global Data
    enabled := !Data["WinPos1Ctrl"].Value
    Data["WinPosXCtrl"].Enabled := enabled
    Data["WinPosYCtrl"].Enabled := enabled
}

UpdatePathPosControls() {
    global Data
    enabled := !Data["PathPos1Ctrl"].Value
    Data["PathPosXCtrl"].Enabled := enabled
    Data["PathPosYCtrl"].Enabled := enabled
}

PickColor(*) {
    global Data
    result := InputBox("请输入颜色代码 (例如: C0C59C):", "选择颜色", "w300 h120", Data["MenuColorCtrl"].Value)
    if (result.Result = "OK" && result.Value != "")
        Data["MenuColorCtrl"].Value := result.Value
}

ClearRecentPaths(*) {
    result := MsgBox("确定要清除所有最近路径记录吗？", "确认", "YesNo 32")
    if (result = "Yes") {
        Loop 50
            UTF8IniDelete(IniFile, "RecentPaths", "Recent" A_Index)
        MsgBox("最近路径记录已清除！", "成功", 64)
    }
}

;===========================================================
; 自定义路径管理
;===========================================================
LoadCustomPaths() {
    global Data
    LV := Data["PathListCtrl"]
    LV.Delete()
    Loop {
        value := UTF8IniRead(IniFile, "CustomPaths", "Path" A_Index, "")
        if (value = "")
            break
        parts := StrSplit(value, "|")
        name := parts.Has(1) ? parts[1] : ""
        path := parts.Has(2) ? parts[2] : ""
        pinned := (parts.Has(3) && parts[3] = "1") ? "是" : "否"
        LV.Add("", A_Index, name, path, pinned)
    }
}

SaveCustomPaths() {
    global Data
    LV := Data["PathListCtrl"]
    Loop 100
        UTF8IniDelete(IniFile, "CustomPaths", "Path" A_Index)
    Loop LV.GetCount() {
        name := LV.GetText(A_Index, 2)
        path := LV.GetText(A_Index, 3)
        pinned := (LV.GetText(A_Index, 4) = "是") ? "1" : ""
        value := name "|" path "|" pinned
        UTF8IniWrite(value, IniFile, "CustomPaths", "Path" A_Index)
    }
}

AddPath(*) {
    global Data
    r1 := InputBox("请输入显示名称:", "添加路径", "w300 h120")
    if (r1.Result != "OK")
        return
    r2 := InputBox("请输入路径:", "添加路径", "w300 h120")
    if (r2.Result != "OK")
        return
    r3 := MsgBox("是否置顶显示？", "添加路径", "YesNo 32")
    pinned := (r3 = "Yes") ? "是" : "否"
    LV := Data["PathListCtrl"]
    cnt := LV.GetCount()
    LV.Add("", cnt + 1, r1.Value, r2.Value, pinned)
}

EditPath(*) {
    global Data
    LV := Data["PathListCtrl"]
    row := LV.GetNext()
    if (!row) {
        MsgBox("请先选择要编辑的项！", "提示", 48)
        return
    }
    name := LV.GetText(row, 2)
    path := LV.GetText(row, 3)
    pinned := LV.GetText(row, 4)
    r1 := InputBox("请输入显示名称:", "编辑路径", "w300 h120", name)
    if (r1.Result != "OK")
        return
    r2 := InputBox("请输入路径:", "编辑路径", "w300 h120", path)
    if (r2.Result != "OK")
        return
    r3 := MsgBox("是否置顶显示？", "编辑路径", "YesNo 32")
    pinned := (r3 = "Yes") ? "是" : "否"
    LV.Modify(row, "", row, r1.Value, r2.Value, pinned)
}

DeletePath(*) {
    global Data
    LV := Data["PathListCtrl"]
    row := LV.GetNext()
    if (!row) {
        MsgBox("请先选择要删除的项！", "提示", 48)
        return
    }
    result := MsgBox("确定要删除选中的项吗？", "确认", "YesNo 32")
    if (result = "Yes") {
        LV.Delete(row)
        RenumberList(LV)
    }
}

MoveUpPath(*) {
    global Data
    LV := Data["PathListCtrl"]
    row := LV.GetNext()
    if (!row || row = 1)
        return
    name := LV.GetText(row, 2)
    path := LV.GetText(row, 3)
    pinned := LV.GetText(row, 4)
    LV.Delete(row)
    LV.Insert(row - 1, "", row - 1, name, path, pinned)
    RenumberList(LV)
    LV.Modify(row - 1, "Select Focus Vis")
}

MoveDownPath(*) {
    global Data
    LV := Data["PathListCtrl"]
    row := LV.GetNext()
    cnt := LV.GetCount()
    if (!row || row = cnt)
        return
    name := LV.GetText(row, 2)
    path := LV.GetText(row, 3)
    pinned := LV.GetText(row, 4)
    LV.Delete(row)
    LV.Insert(row + 1, "", row + 1, name, path, pinned)
    RenumberList(LV)
    LV.Modify(row + 1, "Select Focus Vis")
}

;===========================================================
; 排除程序管理
;===========================================================
LoadExcludedApps() {
    global Data
    LV := Data["ExcludedListCtrl"]
    LV.Delete()
    Loop {
        value := UTF8IniRead(IniFile, "ExcludedApps", "App" A_Index, "")
        if (value = "")
            break
        LV.Add("", A_Index, value)
    }
}

SaveExcludedApps() {
    global Data
    LV := Data["ExcludedListCtrl"]
    Loop 100
        UTF8IniDelete(IniFile, "ExcludedApps", "App" A_Index)
    Loop LV.GetCount() {
        name := LV.GetText(A_Index, 2)
        UTF8IniWrite(name, IniFile, "ExcludedApps", "App" A_Index)
    }
}

AddExcluded(*) {
    global Data
    result := InputBox("请输入程序名称 (例如: notepad.exe):", "添加排除程序", "w300 h120")
    if (result.Result = "OK" && result.Value != "") {
        LV := Data["ExcludedListCtrl"]
        cnt := LV.GetCount()
        LV.Add("", cnt + 1, result.Value)
    }
}

DeleteExcluded(*) {
    global Data
    LV := Data["ExcludedListCtrl"]
    row := LV.GetNext()
    if (!row) {
        MsgBox("请先选择要删除的项！", "提示", 48)
        return
    }
    result := MsgBox("确定要删除选中的项吗？", "确认", "YesNo 32")
    if (result = "Yes") {
        LV.Delete(row)
        RenumberList(LV)
    }
}

;===========================================================
; 置顶程序管理
;===========================================================
LoadPinnedApps() {
    global Data
    LV := Data["PinnedListCtrl"]
    LV.Delete()
    Loop {
        value := UTF8IniRead(IniFile, "PinnedApps", "App" A_Index, "")
        if (value = "")
            break
        LV.Add("", A_Index, value)
    }
}

SavePinnedApps() {
    global Data
    LV := Data["PinnedListCtrl"]
    Loop 100
        UTF8IniDelete(IniFile, "PinnedApps", "App" A_Index)
    Loop LV.GetCount() {
        name := LV.GetText(A_Index, 2)
        UTF8IniWrite(name, IniFile, "PinnedApps", "App" A_Index)
    }
}

AddPinned(*) {
    global Data
    result := InputBox("请输入程序名称 (例如: chrome.exe):", "添加置顶程序", "w300 h120")
    if (result.Result = "OK" && result.Value != "") {
        LV := Data["PinnedListCtrl"]
        cnt := LV.GetCount()
        LV.Add("", cnt + 1, result.Value)
    }
}

DeletePinned(*) {
    global Data
    LV := Data["PinnedListCtrl"]
    row := LV.GetNext()
    if (!row) {
        MsgBox("请先选择要删除的项！", "提示", 48)
        return
    }
    result := MsgBox("确定要删除选中的项吗？", "确认", "YesNo 32")
    if (result = "Yes") {
        LV.Delete(row)
        RenumberList(LV)
    }
}

MoveUpPinned(*) {
    global Data
    LV := Data["PinnedListCtrl"]
    row := LV.GetNext()
    if (!row || row = 1)
        return
    name := LV.GetText(row, 2)
    LV.Delete(row)
    LV.Insert(row - 1, "", row - 1, name)
    RenumberList(LV)
    LV.Modify(row - 1, "Select Focus Vis")
}

MoveDownPinned(*) {
    global Data
    LV := Data["PinnedListCtrl"]
    row := LV.GetNext()
    cnt := LV.GetCount()
    if (!row || row = cnt)
        return
    name := LV.GetText(row, 2)
    LV.Delete(row)
    LV.Insert(row + 1, "", row + 1, name)
    RenumberList(LV)
    LV.Modify(row + 1, "Select Focus Vis")
}

;===========================================================
; 快速启动管理
;===========================================================
LoadLaunchApps() {
    global Data
    LV := Data["LaunchListCtrl"]
    LV.Delete()
    Loop {
        value := UTF8IniRead(IniFile, "QuickLaunchApps", "App" A_Index, "")
        if (value = "")
            break
        parts := StrSplit(value, "|")
        name := parts.Has(1) ? parts[1] : ""
        process := parts.Has(2) ? parts[2] : ""
        path := parts.Has(3) ? parts[3] : ""
        hotkey := parts.Has(4) ? parts[4] : ""
        LV.Add("", A_Index, name, process, path, hotkey)
    }
}

SaveLaunchApps() {
    global Data
    LV := Data["LaunchListCtrl"]
    Loop 100
        UTF8IniDelete(IniFile, "QuickLaunchApps", "App" A_Index)
    Loop LV.GetCount() {
        name := LV.GetText(A_Index, 2)
        process := LV.GetText(A_Index, 3)
        path := LV.GetText(A_Index, 4)
        hotkey := LV.GetText(A_Index, 5)
        value := name "|" process "|" path "|" hotkey
        UTF8IniWrite(value, IniFile, "QuickLaunchApps", "App" A_Index)
    }
}

AddLaunch(*) {
    global Data
    r1 := InputBox("请输入显示名称:", "添加快速启动", "w300 h120")
    if (r1.Result != "OK")
        return
    r2 := InputBox("请输入进程名 (例如: notepad.exe):", "添加快速启动", "w300 h120")
    if (r2.Result != "OK")
        return
    r3 := InputBox("请输入可执行文件路径 (可选，留空自动查找):", "添加快速启动", "w300 h120")
    if (r3.Result != "OK")
        return
    r4 := InputBox("请输入快捷键 (可选):", "添加快速启动", "w300 h120")
    if (r4.Result != "OK")
        return
    LV := Data["LaunchListCtrl"]
    cnt := LV.GetCount()
    LV.Add("", cnt + 1, r1.Value, r2.Value, r3.Value, r4.Value)
}

EditLaunch(*) {
    global Data
    LV := Data["LaunchListCtrl"]
    row := LV.GetNext()
    if (!row) {
        MsgBox("请先选择要编辑的项！", "提示", 48)
        return
    }
    name := LV.GetText(row, 2)
    process := LV.GetText(row, 3)
    path := LV.GetText(row, 4)
    hotkey := LV.GetText(row, 5)
    r1 := InputBox("请输入显示名称:", "编辑快速启动", "w300 h120", name)
    if (r1.Result != "OK")
        return
    r2 := InputBox("请输入进程名:", "编辑快速启动", "w300 h120", process)
    if (r2.Result != "OK")
        return
    r3 := InputBox("请输入可执行文件路径 (可选):", "编辑快速启动", "w300 h120", path)
    if (r3.Result != "OK")
        return
    r4 := InputBox("请输入快捷键 (可选):", "编辑快速启动", "w300 h120", hotkey)
    if (r4.Result != "OK")
        return
    LV.Modify(row, "", row, r1.Value, r2.Value, r3.Value, r4.Value)
}

DeleteLaunch(*) {
    global Data
    LV := Data["LaunchListCtrl"]
    row := LV.GetNext()
    if (!row) {
        MsgBox("请先选择要删除的项！", "提示", 48)
        return
    }
    result := MsgBox("确定要删除选中的项吗？", "确认", "YesNo 32")
    if (result = "Yes") {
        LV.Delete(row)
        RenumberList(LV)
    }
}

MoveUpLaunch(*) {
    global Data
    LV := Data["LaunchListCtrl"]
    row := LV.GetNext()
    if (!row || row = 1)
        return
    name := LV.GetText(row, 2)
    process := LV.GetText(row, 3)
    path := LV.GetText(row, 4)
    hotkey := LV.GetText(row, 5)
    LV.Delete(row)
    LV.Insert(row - 1, "", row - 1, name, process, path, hotkey)
    RenumberList(LV)
    LV.Modify(row - 1, "Select Focus Vis")
}

MoveDownLaunch(*) {
    global Data
    LV := Data["LaunchListCtrl"]
    row := LV.GetNext()
    cnt := LV.GetCount()
    if (!row || row = cnt)
        return
    name := LV.GetText(row, 2)
    process := LV.GetText(row, 3)
    path := LV.GetText(row, 4)
    hotkey := LV.GetText(row, 5)
    LV.Delete(row)
    LV.Insert(row + 1, "", row + 1, name, process, path, hotkey)
    RenumberList(LV)
    LV.Modify(row + 1, "Select Focus Vis")
}

;===========================================================
; 通用函数
;===========================================================
RenumberList(LV) {
    cnt := LV.GetCount()
    Loop cnt
        LV.Modify(A_Index, "", A_Index)
}
