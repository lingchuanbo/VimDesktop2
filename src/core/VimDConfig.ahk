VimDConfig_KeyMapEdit(){
    ;生成窗体
	_VimDConfig_CreateManagerGui()
	
	_VimDConfig_ApplyTheme(VimDConfig_Manager)
	
	_VimDConfig_WireEvents(VimDConfig_Manager)
	_VimDConfig_BuildLayout(VimDConfig_Manager)
    _VimDConfig_ConfigureColumns()

	VimDConfig_Manager.Show()
    VimDConfig_Manager_LoadWinList()
    _VimDConfig_SelectDefaults()
}

_VimDConfig_CreateManagerGui(){
	global VimDConfig_Manager
	try VimDConfig_Manager.Destroy()
	VimDConfig_Manager := Gui("", Lang["Manager"]["Gui"]["Title"]) ;+Resize +MaximizeBox -Caption +E0x00000080 不显示任务栏
	VimDConfig_Manager.SetFont("s10 ", "Microsoft YaHei")
}

_VimDConfig_BuildLayout(gui){
	gui.Add("GroupBox", "x10 y10 w200 h435", Lang["Manager"]["Gui"]["GroupBox1"])
	LV1:= gui.Add("ListView", "xp+10 yp+25 w180 r16 grid AltSubmit vLV1", Lang["Manager"]["Gui"]["ListView1Columns"]) ; 数组数据
	LV1.OnEvent("Click", LV1_Click)
	LV1.OnEvent("ContextMenu", LV1_ContextMenu)
	gui.Add("GroupBox", "section x10 y+20 w200 h155", Lang["Manager"]["Gui"]["GroupBox2"])
	LV2:= gui.Add("ListView", "xp+10 yp+25 w180 R4 grid AltSubmit vLV2", Lang["Manager"]["Gui"]["ListView2Columns"]) ; 数组数据
	LV2.OnEvent("Click", LV2_Click)
	LV2.OnEvent("ContextMenu", LV2_ContextMenu)

	gui.Add("GroupBox", "section x215 y10 w1045 h105", Lang["Manager"]["Gui"]["GroupBox3"])
	gui.Add("Text", "section xp+10 yp+25 w40 h21", Lang["Manager"]["Gui"]["PluginName"])
	gui.Add("Edit", "x+5 ys-3 w250 h21 vPluginName ReadOnly", "")
	gui.Add("Text", "ys w40 h21", Lang["Manager"]["Gui"]["Author"])
	gui.Add("Edit", "x+5 ys-3 w185 h21 vAuthor ReadOnly", "")
	gui.Add("Text", "ys w40 h21", Lang["Manager"]["Gui"]["Version"])
	gui.Add("Edit", "x+5 ys-3 w185 h21 vVersion ReadOnly", "")
	gui.Add("Text", "ys w40 h21", Lang["Manager"]["Gui"]["PluginType"])
	gui.Add("Edit", "x+5 ys-3 w185 h21 vPluginType ReadOnly", "")
	gui.Add("Text", "section xs w40 h21", Lang["Manager"]["Gui"]["Comment"])
	gui.Add("Edit", "x+5 ys-3 w980 h43 vComment ReadOnly", "")

	gui.Add("GroupBox", "Section x215 y+20 w1045 h483", Lang["Manager"]["Gui"]["GroupBox4"])
	gui.Add("Text", "Section xp+10 yp+25 w40 h21", Lang["Manager"]["Gui"]["Group"])
	gui.Add("DropDownList", "x+5 ys-3 w80 vGroup choose2", Lang["Manager"]["Gui"]["GroupList"])
	gui.Add("Text", "x+30 ys w40 h21", Lang["Manager"]["Gui"]["Search"])
	gui.Add("Edit", "x+5 ys-3 w250 h25 vSearch").OnEvent("Change", Edit_Search_Change)

	LV3:= gui.Add("ListView", "xs w1025 r17 Sort grid vLV3", Lang["Manager"]["Gui"]["ListView3Columns"]) ; 数组数据
	LV3.OnEvent("DoubleClick", LV3_DoubleClick)
	LV3.OnEvent("ContextMenu", LV3_ContextMenu)
}

_VimDConfig_ConfigureColumns(){
    LV1:=VimDConfig_Manager["LV1"]
    LV2:=VimDConfig_Manager["LV2"]
    LV3:=VimDConfig_Manager["LV3"]

    try 
        LV1.ModifyCol(1, Lang["Manager"]["ListView"]["ListView1"]["Col1Width"]!=0 ? Lang["Manager"]["ListView"]["ListView1"]["Col1Width"] : 60)
    catch
        LV1.ModifyCol(1, 60)
    try 
        LV1.ModifyCol(2, Lang["Manager"]["ListView"]["ListView1"]["Col2Width"]!=0 ? Lang["Manager"]["ListView"]["ListView1"]["Col2Width"] : 120)
    catch
        LV1.ModifyCol(1, 120)
    
    try 
        LV2.ModifyCol(1, Lang["Manager"]["ListView"]["ListView2"]["Col1Width"]!=0 ? Lang["Manager"]["ListView"]["ListView2"]["Col1Width"] : 60)
    catch
        LV2.ModifyCol(1, 60)
    
    try 
        LV2.ModifyCol(2, Lang["Manager"]["ListView"]["ListView2"]["Col2Width"]!=0 ? Lang["Manager"]["ListView"]["ListView2"]["Col2Width"] : 120)
    catch
        LV2.ModifyCol(2, 120)
    
    try 
        LV3.ModifyCol(1, Lang["Manager"]["ListView"]["ListView3"]["Col1Width"]!=0 ? Lang["Manager"]["ListView"]["ListView3"]["Col1Width"] : 80)
    catch
        LV3.ModifyCol(1, 80)
    try 
        LV3.ModifyCol(2, Lang["Manager"]["ListView"]["ListView3"]["Col2Width"]!=0 ? Lang["Manager"]["ListView"]["ListView3"]["Col2Width"] : 100)
    catch
        LV3.ModifyCol(2, 100)
    try 
        LV3.ModifyCol(3, Lang["Manager"]["ListView"]["ListView3"]["Col3Width"]!=0 ? Lang["Manager"]["ListView"]["ListView3"]["Col3Width"] : 230)
    catch
        LV3.ModifyCol(3, 230)
    try 
        LV3.ModifyCol(4, Lang["Manager"]["ListView"]["ListView3"]["Col4Width"]!=0 ? Lang["Manager"]["ListView"]["ListView3"]["Col4Width"] : 150)
    catch
        LV3.ModifyCol(4, 150)
    try 
        LV3.ModifyCol(5, Lang["Manager"]["ListView"]["ListView3"]["Col5Width"]!=0 ? Lang["Manager"]["ListView"]["ListView3"]["Col5Width"] : 460)
    catch
        LV3.ModifyCol(5, 460)
}

_VimDConfig_SelectDefaults(){
    LV1:=VimDConfig_Manager["LV1"]
    LV2:=VimDConfig_Manager["LV2"]
    LV1.Modify(1, "Select")
    LV2.Modify(1, "Select")
    VimDConfig_Manager["Search"].Focus
}

_VimDConfig_ApplyTheme(gui) {
	; 应用当前主题设置
	try {
	    currentTheme := INIObject.config.theme_mode
	    if (currentTheme = "light")
	        WindowsTheme.SetWindowAttribute(gui, false)
	    else if (currentTheme = "dark")
	        WindowsTheme.SetWindowAttribute(gui, true)
	    else
	        ; 跟随系统设置
	        WindowsTheme.SetWindowAttribute(gui, "Default")
	} catch {
	    ; 默认跟随系统
	    WindowsTheme.SetWindowAttribute(gui, "Default")
	}
}

_VimDConfig_WireEvents(gui) {
	gui.OnEvent("Escape", (*) => Reload())
	gui.OnEvent("Close", (*) => Reload())
}

_VimDConfig_AddWinRow(LV1, winKey, winObj){
	if (winKey="global") {
		isEnabled := _VimDConfig_ReadGlobalEnabled()
		LV1.Add("", isEnabled ? Lang["General"]["Enable"] : Lang["General"]["Disable"], Lang["General"]["Global"])
		return
	}

	isEnabled := _VimDConfig_ReadPluginEnabled(winKey, winObj)
	LV1.Add("", isEnabled ? Lang["General"]["Enable"] : Lang["General"]["Disable"], winKey)
}

_VimDConfig_ReadGlobalEnabled(){
	try {
		return INIObject.global.enabled = 1
	} catch {
		return false
	}
}

_VimDConfig_ReadPluginEnabled(pluginName, winObj){
	isEnabled := false
	if (winObj.Inside) {
		try {
			isEnabled := INIObject.%pluginName%.enabled = 1
		} catch {
			isEnabled := false
		}
	} else {
		try {
			isEnabled := INIObject.plugins.%pluginName% = 1
		} catch {
			isEnabled := false
		}
	}
	return isEnabled
}

_VimDConfig_UpdatePluginHeader(plugin, winObj){
	VimDConfig_Manager["PluginName"].Text:=plugin
	VimDConfig_Manager["PluginType"].Text:=winObj.inside ? Lang["General"]["Inside"] : Lang["General"]["Outside"]
	_VimDConfig_LoadPluginInfo(plugin)
}

_VimDConfig_LoadPluginInfo(plugin){
	pluginFile:=A_ScriptDir "\..\plugins\" plugin "\" plugin ".ahk"
	if (FileExist(pluginFile)){ ;文件必须存在，跳过内置插件
		; AHK V2以UTF-8编码，iniRead仅支持ANSI或UTF-16，所以使用整文读取及正则匹配。
		pluginTxt:=FileRead(pluginFile, "UTF-8")
		if (RegExMatch(pluginTxt,"i)Version\s*=(.*)", &m))
			VimDConfig_Manager["Version"].Text:=Trim(m[1])
		else
			VimDConfig_Manager["Version"].Text:=""

		if (RegExMatch(pluginTxt,"i)Author\s*=(.*)", &m))
			VimDConfig_Manager["Author"].Text:=Trim(m[1])
		else
			VimDConfig_Manager["Author"].Text:=""

		if (RegExMatch(pluginTxt,"i)Comment\s*=(.*)", &m))
			VimDConfig_Manager["Comment"].Text:=Trim(m[1])
		else
			VimDConfig_Manager["Comment"].Text:=""

		pluginTxt:=""
	} else {
		VimDConfig_Manager["Version"].Text:=""
		VimDConfig_Manager["Author"].Text:=""
		VimDConfig_Manager["Comment"].Text:=""
	}
}

_VimDConfig_PopulateModeList(plugin, winObj){
	LV2:=VimDConfig_Manager["LV2"]
	LV2.delete()
	if (plugin = Lang["General"]["Global"]){
		for mode, obj in winObj.modeList
		{
			if (vim.GetWin("").defaultMode=mode)
				LV2.Add("", Lang["General"]["Default"], mode)
			else
				LV2.Add("","", mode)
		}
	} else {
		for mode, obj in winObj.modeList
		{
			if (vim.GetWin(plugin).defaultMode=mode)
				LV2.Add("", Lang["General"]["Default"], mode)
			else
				LV2.Add("","", mode)
		}
	}
	LV2.Modify(1, "Select")
}

_VimDConfig_SetPluginEnabled(plugin, enabled){
	if (plugin = Lang["General"]["Global"])
		plugin := "global"
	if (vim.GetWin(plugin="global" ? "" : plugin).Inside){
		Rst:=INIObject.AddKey(plugin, "enabled", enabled)
		if !Rst
			INIObject.%plugin%.enabled:=enabled
	} else {
		Rst:=INIObject.AddKey("plugins", plugin, enabled)
		if !Rst
			INIObject.plugins.%plugin%:=enabled
	}
}

_VimDConfig_SetDefaultMode(plugin, mode){
	if (plugin = Lang["General"]["Global"])
		plugin := "global"
	if (vim.GetWin(plugin="global" ? "global" : plugin).Inside){
		Rst:=INIObject.AddKey(plugin, "default_Mode", mode)
		if !Rst
			INIObject.%plugin%.default_Mode:=mode
	} else {
		Rst:=INIObject.AddKey("plugins_DefaultMode", plugin, mode)
		if !Rst
			INIObject.plugins_DefaultMode.%plugin%:=mode
	}
}

_VimDConfig_GetModeObj(win, mode){
	if strlen(mode){
		winObj  := vim.GetWin(win)
		return winObj.modeList[mode]
	}
	return vim.GetMode(win)
}

_VimDConfig_FormatKeyDisplay(key, tAction){
	if (tAction.Type = 1)
		return tAction.OriKey

	OutK:=Key
	MyMatchArray:=MyFun_RegExMatchAll(Key,"(<S-.*?>)")
	Idx:=1
	while (Idx<=MyMatchArray.Length)
	{
		TemK:=StrReplace(MyMatchArray[Idx], "<S-", "")
		TemK:=StrReplace(TemK, ">", "")
		OutK:=StrReplace(OutK, MyMatchArray[Idx], TemK)
		Idx+=1
	}
	return OutK
}

_VimDConfig_PassFilter(FilterGroup, FilterStr, group, key, action, param, comment){
	if (FilterGroup="" || FilterStr="")
		return true
	Switch FilterGroup{
		case Lang["Manager"]["Gui"]["GroupList"][1]:
			return InStr(group, FilterStr)
		case Lang["Manager"]["Gui"]["GroupList"][2]:
			return InStr(key, FilterStr)
		case Lang["Manager"]["Gui"]["GroupList"][3]:
			return InStr(action, FilterStr)
		case Lang["Manager"]["Gui"]["GroupList"][4]:
			return InStr(param, FilterStr)
		case Lang["Manager"]["Gui"]["GroupList"][5]:
			return InStr(comment, FilterStr)
	}
	return true
}

_VimDConfig_AddHotkeyRow(LV3, group, key, action, param, comment, rawKey){
	LV3.Add("",group, key, action, param, comment)
	VimDesktop_Global.Current_KeyMap .= rawKey "`t" comment "`t" action "`n"
}

_VimDConfig_GetFocusedPlugin(){
	LV1:=VimDConfig_Manager["LV1"]
	FocusedRowNumber := LV1.GetNext(0, "F")  ; 查找焦点行.
	if !FocusedRowNumber  ; 没有焦点行.
		return ""
	plugin:=LV1.GetText(FocusedRowNumber, 2)
	if (plugin=Lang["General"]["Global"])
		return "global"
	return plugin
}

_VimDConfig_GetFocusedMode(){
	LV2:=VimDConfig_Manager["LV2"]
	FocusedRowNumber := LV2.GetNext(0, "F")  ; 查找焦点行.
	if !FocusedRowNumber  ; 没有焦点行.
		return ""
	return LV2.GetText(FocusedRowNumber, 2)
}

_VimDConfig_GetFocusedWinForHotkey(){
	plugin := _VimDConfig_GetFocusedPlugin()
	if (plugin = "")
		return ""
	return plugin="global" ? "" : plugin
}

_VimDConfig_FindLineByRegex(filePath, regexList){
	Loop Read filePath
	{
		matchAll := true
		for _, re in regexList {
			if !RegExMatch(A_LoopReadLine, re) {
				matchAll := false
				break
			}
		}
		if (matchAll) {
			EditFile(filePath, A_Index)
			return true
		}
	}
	return false
}

_VimDConfig_FindActionInFileList(filePattern, flags, label_Action){
	Loop Files filePattern, flags
	{
		if (_VimDConfig_FindLineByRegex(A_LoopFileFullPath, [label_Action]))
			return true
	}
	return false
}

_VimDConfig_GetActionSearchTargets(){
	return [
		{ pattern: A_ScriptDir "\..\plugins\*.ahk", flags: "RF" },
		{ pattern: A_ScriptDir "\..\src\core\*.ahk", flags: "F" },
		{ pattern: A_ScriptDir "\..\libs\*.ahk", flags: "F" },
		{ pattern: A_ScriptDir "\..\config\*.ahk", flags: "F" }
	]
}

_VimDConfig_GetEditorArgsMap(){
	editorArgs := Map()
	editorArgs["notepad"] := "/g $line $file"
	editorArgs["notepad2"] := "/g $line $file"
	editorArgs["sublime_text"] := "$file:$line"
	editorArgs["vim"] := "+$line $file"
	editorArgs["gvim"] := "--remote-silent-tab +$line $file"
	editorArgs["everedit"] := "-n$line $file"
	editorArgs["notepad++"] := "-n$line $file"
	editorArgs["EmEditor"] := "-l $line $file"
	editorArgs["uedit32"] := "$file/$line"
	editorArgs["Editplus"] := "$file -cursor $line"
	editorArgs["textpad"] := "$file($line)"
	editorArgs["pspad"] := "$file /$line"
	editorArgs["ConTEXT"] := "$file /g1:$line"
	editorArgs["scite"] := "$file -goto:$line"
	editorArgs["Code"] := "--goto $file:$line"
	return editorArgs
}

_VimDConfig_BuildEditorTarget(editorPath, editPath, line){
	; 根据编辑器 exe 名称获取打开参数
	SplitPath editorPath, , , &OutExtension, &OutNameNoExt
	editorArgs := _VimDConfig_GetEditorArgsMap()
	args := editorArgs.Has(OutNameNoExt) ? editorArgs[OutNameNoExt] : "$file"
	args:=StrReplace(args, "$line", line)
	args:=StrReplace(args, "$file", '"' editPath '"')
	return editorPath " " args
}

_VimDConfig_RenderSearchResults(lines, filterText){
    LV3:=VimDConfig_Manager["LV3"]
    text := StrSplit(lines, "`n")
    _VimDConfig_BeginListUpdate(LV3)
    N:=0
	for k, v in text
	{
		if (v ="")
			continue
		N+=1
		if InStr(v, filterText)
		{
			list := StrSplit(v, "`t")
			LV3.Add("", N, list[1], list[2], list[3])
		}
	}
	_VimDConfig_EndListUpdate(LV3)
}

_VimDConfig_ResolveEditorPath(){
    if (not FileExist(VimDesktop_Global.Editor)){
        MsgRst:=MsgBox("未配置【编辑器】路径，是否设置路径？`n--------------------------`n【是】设置路径`n【否】以[记事本]打开`n--------------------------", "询问", "4132")
        if (MsgRst="Yes") {
            SelectedFile := FileSelect(1, A_WorkingDir, "选择编辑器", "程序(*.exe)")
            if A_LastError
                return ""
            if (SelectedFile ="")
                return ""
            VimDesktop_Global.Editor:=SelectedFile
            INIObject.config.editor:=SelectedFile
            INIObject.save()
            reload
        }
    }
    if (VimDesktop_Global.Editor="")
        VimDesktop_Global.Editor:="notepad.exe"
    return VimDesktop_Global.Editor
}

VimDConfig_EditConfig(){
    Run A_ScriptDir "\..\config\vimd.ini"
}

VimDConfig_EditCustom(){
    try 
    {
        If (fileExist(VimDesktop_Global.Editor))
            Run VimDesktop_Global.Editor " " A_ScriptDir "\..\config\Custom.ahk"
        else
            Run "notepad.exe"  " " A_ScriptDir "\..\config\Custom.ahk"
    }
}

VimDConfig_Manager_LoadWinList(){
    global vim
    vim := class_vim()
    CheckPlugin(loadAll:=1)
    CheckHotKey(loadAll:=1)
    
    LV1:=VimDConfig_Manager["LV1"]
    LV1.Delete()
    for k, v in vim.WinList{
        ; 跳过特殊项
        if (k="vim" || RegExMatch(k, "i)^(EasyIni_)"))
            continue

		_VimDConfig_AddWinRow(LV1, k, v)
    }
}

LV1_Click(GuiCtrlObj, Info){
    if (Info=0)
        return
    LV1:=VimDConfig_Manager["LV1"]
    plugin:=LV1.GetText(Info, 2) 
    MyStatus:=LV1.GetText(Info,1) 
    If (plugin = Lang["General"]["Global"])
        winObj := vim.GetWin()
    Else
        winObj := vim.GetWin(plugin)

	_VimDConfig_UpdatePluginHeader(plugin, winObj)
	_VimDConfig_PopulateModeList(plugin, winObj)

    LV3:=VimDConfig_Manager["LV3"]
    LV3.delete()
}

LV1_ContextMenu(GuiCtrlObj, Item, IsRightClick, X, Y){
    if (Item=0)
        return
    LV1:=VimDConfig_Manager["LV1"]
    Local LV1_SelectedItem:=Item
    plugin:=LV1.GetText(LV1_SelectedItem, 2) 
    MyStatus:=LV1.GetText(LV1_SelectedItem,1) 

    CoordMode "Mouse", "Window"
    MouseGetPos &tTemp_X, &tTemp_Y
    tMyMenu := Menu()
    tMyMenu.Add(MyStatus=Lang["General"]["Disable"] ? Lang["General"]["Enable"] : Lang["General"]["Disable"], KyMenu_temp_Handler)
    tMyMenu.Show(tTemp_X, tTemp_Y)
    CoordMode "Mouse", "Screen"

    KyMenu_temp_Handler(Item,*){
        if(Item=Lang["General"]["Disable"]){
            LV1.Modify(LV1_SelectedItem,"Col1", Lang["General"]["Disable"])
            _VimDConfig_SetPluginEnabled(plugin, 0)
        }else{
            LV1.Modify(LV1_SelectedItem,"Col1", Lang["General"]["Enable"])
            _VimDConfig_SetPluginEnabled(plugin, 1)
        }
        INIObject.save()
    }
}

LV2_Click(GuiCtrlObj, Info){
    if (Info=0)
        return
    LV1:=VimDConfig_Manager["LV1"]
    FocusedRowNumber := LV1.GetNext(0, "F")  ; 查找焦点行.
    if !FocusedRowNumber  ; 没有焦点行.
        return
    plugin:=LV1.GetText(FocusedRowNumber, 2) 
    win := RegExMatch(plugin, Format("^{1}$", Lang["General"]["Global"])) ? "global" : plugin
    ; Convert plugin name TotalCommander to class name TTOTAL_CMD

    LV2:=VimDConfig_Manager["LV2"]
    mode:=LV2.GetText(Info, 2) 
    VimDConfig_LoadHotkey(win, mode)
}

LV2_ContextMenu(GuiCtrlObj, Item, IsRightClick, X, Y){
    if (Item=0)
        return
    LV1:=VimDConfig_Manager["LV1"]
    FocusedRowNumber := LV1.GetNext(0, "F")  ; 查找焦点行.
    if !FocusedRowNumber  ; 没有焦点行.
        return
    plugin:=LV1.GetText(FocusedRowNumber, 2) 
    win := RegExMatch(plugin, Format("^{1}$", Lang["General"]["Global"])) ? "global" : plugin

    LV2:=VimDConfig_Manager["LV2"]
    Local LV2_SelectedItem:=Item

    CoordMode "Mouse", "Window"
    MouseGetPos &tTemp_X, &tTemp_Y
    tMyMenu := Menu()
    tMyMenu.Add(Lang["General"]["SetDefault"], KyMenu_temp_Handler)
    tMyMenu.Show(tTemp_X, tTemp_Y)
    CoordMode "Mouse", "Screen"

    KyMenu_temp_Handler(Item,*){
        mode:=LV2.GetText(LV2_SelectedItem, 2) 
        Loop LV2.GetCount()
        {
            if(A_index!=LV2_SelectedItem){
                LV2.Modify(A_index,"Col1","")
            }else{
                LV2.Modify(A_index,"Col1",Lang["General"]["Default"])
                _VimDConfig_SetDefaultMode(plugin, mode)
            }
        }
        INIObject.save()
    }
}

VimDConfig_LoadHotkey(win, mode := "", FilterGroup:="", FilterStr:=""){
    VimDesktop_Global.Current_KeyMap := ""
	ModeObj := _VimDConfig_GetModeObj(win, mode)

    LV3:=VimDConfig_Manager["LV3"]
    _VimDConfig_BeginListUpdate(LV3)
    N:=0
    for key, i in ModeObj.KeyMapList
    {
        _keyStr:=vim.Convert2MapKey(key)
        tAction:=vim.GetAction(win, mode, _keyStr)
        _group:=tAction.Group
        _Key:=_VimDConfig_FormatKeyDisplay(Key, tAction)
        _Action:=tAction.Function
        _Param:=KyFunc_StringParam(tAction.Param, ', ', '"')
        ; _Param:="[ " KyFunc_ArrayJoin(tAction.Param, ', ', '"') " ]"
        _Comment:=tAction.Comment
        if (!_VimDConfig_PassFilter(FilterGroup, FilterStr, _group, _Key, _Action, _Param, _Comment))
            continue

        _VimDConfig_AddHotkeyRow(LV3, _group, _Key, _Action, _Param, _Comment, Key)
    }
    _VimDConfig_EndListUpdate(LV3)
}

_VimDConfig_BeginListUpdate(LV){
    LV.Opt("-Redraw")
    LV.Delete() ; 清理不掉，第二次加载后，都成了重复的了，不知道怎么处理
}

_VimDConfig_EndListUpdate(LV){
    LV.Opt("+Redraw")
}

LV3_DoubleClick(GuiCtrlObj, Info){
    LV3:=VimDConfig_Manager["LV3"]
    SelectedKeys:=LV3.GetText(Info, 2)
    SelectedAction:=LV3.GetText(Info, 3)
    SelectedParm:=LV3.GetText(Info, 4)
    SelectedDesc:=LV3.GetText(Info, 5)
    SearchFileForKey(SelectedKeys, SelectedAction, SelectedParm, SelectedDesc, true)

}

LV3_ContextMenu(GuiCtrlObj, Item, IsRightClick, X, Y){
    LV1:=VimDConfig_Manager["LV1"]
    FocusedRowNumber := LV1.GetNext(0, "F")  ; 查找焦点行.
    if !FocusedRowNumber  ; 没有焦点行.
        return
    plugin:=LV1.GetText(FocusedRowNumber, 2) 

    LV3:=VimDConfig_Manager["LV3"]
    SelectedAction:=LV3.GetText(Item, 3)
    SelectedParm:=LV3.GetText(Item, 4)
    SelectedDesc:=LV3.GetText(Item, 5)

    CoordMode "Mouse", "Window"
    MouseGetPos &tTemp_X, &tTemp_Y
    tMyMenu := Menu()
    tMyMenu.Add(Lang["General"]["Edit_Function"], KyMenu_temp_Handler)
    tMyMenu.Show(tTemp_X, tTemp_Y)
    CoordMode "Mouse", "Screen"

    KyMenu_temp_Handler(Item,*){

        SearchFileForEdit(SelectedAction, SelectedParm, SelectedDesc, false)
    }
}

SearchFileForKey(Keys, Action, Param, Desc, EditKeyMapping){
    plugin := _VimDConfig_GetFocusedPlugin()
    if (plugin = "")
        return

    mode := _VimDConfig_GetFocusedMode()
    if (mode = "")
        return

    if (vim.GetWin(plugin="global" ? "global" : plugin).Inside){
        label_key := Format('{1}\s*\=', EscapeRegex(Keys))
        label_mode := Format('\[\={1}\]', EscapeRegex(mode))
        if (Action="VIMD_CMD")
            label_Action := Format('{1}', EscapeRegex(Param))
        else
            label_Action := Format('{1}', EscapeRegex(Action))
        ;查找插件热键映射
        _VimDConfig_FindLineByRegex(VimDesktop_Global.ConfigPath, [label_key, label_mode, label_Action])
    } else {
        label_key := Format('Key:\s*"{1}"', Keys)
        label_mode := Format('Mode:\s*"{1}"', mode)

        ;查找插件热键映射
        pluginFile:=A_ScriptDir "\..\plugins\" plugin "\" plugin ".ahk"
        _VimDConfig_FindLineByRegex(pluginFile, [label_key, label_mode])
    }
}

SearchFileForEdit(Action, Param, Desc, EditKeyMapping){

    label_Action := Format('m)^\s*{1}\s*\(.*\)[\s\n\r]*\{', EscapeRegex(Action))

    if (Action="VIMD_CMD"){
        if (_VimDConfig_FindLineByRegex(VimDesktop_Global.ConfigPath, [label_Action]))
            return
    }

	for _, spec in _VimDConfig_GetActionSearchTargets() {
		if (_VimDConfig_FindActionInFileList(spec.pattern, spec.flags, label_Action))
			return
	}

}

EditFile(editPath, line := 1){
	editorPath := _VimDConfig_ResolveEditorPath()
	if (editorPath = "")
		return

    target := _VimDConfig_BuildEditorTarget(editorPath, editPath, line)
    run target
}

Edit_Search_Change(*){
    win := _VimDConfig_GetFocusedWinForHotkey()
    if (win = "" && _VimDConfig_GetFocusedPlugin() != "global")
        return
    mode := _VimDConfig_GetFocusedMode()
    if (mode = "")
        return
	groupCtrl := VimDConfig_Manager["Group"]
	searchCtrl := VimDConfig_Manager["Search"]
    VimDConfig_LoadHotkey(win, mode, groupCtrl.Text, searchCtrl.Text)
    ; search_to_display(VimDesktop_Global.Current_KeyMap)
}

search_to_display(lines){
    OutputVar:=VimDConfig_Manager["Search"].Text
	_VimDConfig_RenderSearchResults(lines, OutputVar)
}
