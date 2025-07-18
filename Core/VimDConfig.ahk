VimDConfig_KeyMapEdit(){
    ;生成窗体
	global VimDConfig_Manager := Gui()
	try
		VimDConfig_Manager.Destroy()
	global VimDConfig_Manager := Gui("", Lang["Manager"]["Gui"]["Title"]) ;+Resize +MaximizeBox -Caption +E0x00000080 不显示任务栏
	VimDConfig_Manager.SetFont("s10 ", "Microsoft YaHei")
	; VimDConfig_Manager.BackColor := 0x80FFFF
	VimDConfig_Manager.OnEvent("Escape", (*) => Reload())
	VimDConfig_Manager.OnEvent("Close", (*) => Reload())
	VimDConfig_Manager.Add("GroupBox", "x10 y10 w200 h435", Lang["Manager"]["Gui"]["GroupBox1"])
    LV1:= VimDConfig_Manager.Add("ListView", "xp+10 yp+25 w180 r16 grid AltSubmit vLV1", Lang["Manager"]["Gui"]["ListView1Columns"]) ; 数组数据
    LV1.OnEvent("Click", LV1_Click)
    LV1.OnEvent("ContextMenu", LV1_ContextMenu)
    VimDConfig_Manager.Add("GroupBox", "section x10 y+20 w200 h155", Lang["Manager"]["Gui"]["GroupBox2"])
    LV2:= VimDConfig_Manager.Add("ListView", "xp+10 yp+25 w180 R4 grid AltSubmit vLV2", Lang["Manager"]["Gui"]["ListView2Columns"]) ; 数组数据
    LV2.OnEvent("Click", LV2_Click)
    LV2.OnEvent("ContextMenu", LV2_ContextMenu)

    VimDConfig_Manager.Add("GroupBox", "section x215 y10 w1045 h105", Lang["Manager"]["Gui"]["GroupBox3"])
    VimDConfig_Manager.Add("Text", "section xp+10 yp+25 w40 h21", Lang["Manager"]["Gui"]["PluginName"])
    VimDConfig_Manager.Add("Edit", "x+5 ys-3 w250 h21 vPluginName ReadOnly", "")
    VimDConfig_Manager.Add("Text", "ys w40 h21", Lang["Manager"]["Gui"]["Author"])
    VimDConfig_Manager.Add("Edit", "x+5 ys-3 w185 h21 vAuthor ReadOnly", "")
    VimDConfig_Manager.Add("Text", "ys w40 h21", Lang["Manager"]["Gui"]["Version"])
    VimDConfig_Manager.Add("Edit", "x+5 ys-3 w185 h21 vVersion ReadOnly", "")
    VimDConfig_Manager.Add("Text", "ys w40 h21", Lang["Manager"]["Gui"]["PluginType"])
    VimDConfig_Manager.Add("Edit", "x+5 ys-3 w185 h21 vPluginType ReadOnly", "")
    VimDConfig_Manager.Add("Text", "section xs w40 h21", Lang["Manager"]["Gui"]["Comment"])
    VimDConfig_Manager.Add("Edit", "x+5 ys-3 w980 h43 vComment ReadOnly", "")
    
    
    VimDConfig_Manager.Add("GroupBox", "Section x215 y+20 w1045 h483", Lang["Manager"]["Gui"]["GroupBox4"])
    VimDConfig_Manager.Add("Text", "Section xp+10 yp+25 w40 h21", Lang["Manager"]["Gui"]["Group"])
    VimDConfig_Manager.Add("DropDownList", "x+5 ys-3 w80 vGroup choose2", Lang["Manager"]["Gui"]["GroupList"])
    VimDConfig_Manager.Add("Text", "x+30 ys w40 h21", Lang["Manager"]["Gui"]["Search"])
    VimDConfig_Manager.Add("Edit", "x+5 ys-3 w250 h25 vSearch").OnEvent("Change", Edit_Search_Change)

    LV3:= VimDConfig_Manager.Add("ListView", "xs w1025 r17 Sort grid vLV3", Lang["Manager"]["Gui"]["ListView3Columns"]) ; 数组数据
    LV3.OnEvent("DoubleClick", LV3_DoubleClick)
    LV3.OnEvent("ContextMenu", LV3_ContextMenu)
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

	VimDConfig_Manager.Show()
    VimDConfig_Manager_LoadWinList()
    LV1.Modify(1, "Select")
    LV2.Modify(1, "Select")
    VimDConfig_Manager["Search"].Focus
}

VimDConfig_EditConfig(){
    Run A_ScriptDir "\vimd.ini"
}

VimDConfig_EditCustom(){
    try 
    {
        If (fileExist(VimDesktop_Global.Editor))
            Run VimDesktop_Global.Editor " " A_ScriptDir "\custom.ahk"
        else
            Run "notepad.exe"  " " A_ScriptDir "\custom.ahk"
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
            
        ; 直接从INI文件读取状态，而不是依赖vim对象的缓存状态
        isEnabled := false
        if (k="global") {
            try {
                isEnabled := INIObject.global.enabled = 1
            } catch {
                isEnabled := false
            }
            LV1.Add("", isEnabled ? Lang["General"]["Enable"] : Lang["General"]["Disable"], Lang["General"]["Global"])
        } else {
            ; 检查是否是内部插件
            if (v.Inside) {
                try {
                    isEnabled := INIObject.%k%.enabled = 1
                } catch {
                    isEnabled := false
                }
            } else {
                try {
                    isEnabled := INIObject.plugins.%k% = 1
                } catch {
                    isEnabled := false
                }
            }
            LV1.Add("", isEnabled ? Lang["General"]["Enable"] : Lang["General"]["Disable"], k)
        }
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

    VimDConfig_Manager["PluginName"].Text:=plugin
    VimDConfig_Manager["PluginType"].Text:=winObj.inside ? Lang["General"]["Inside"] : Lang["General"]["Outside"]

    pluginFile:=A_ScriptDir "\plugins\" plugin "\" plugin ".ahk"
    if (FileExist(pluginFile)){ ;文件必须存在，跳过内置插件
        ; AHK V2以UTF-8编码，iniRead仅支持ANSI或UTF-16，所以使用整文读取及正则匹配。
        pluginTxt:=FileRead(pluginFile, "UTF-8")
        ; Version:=IniRead(pluginFile, "PluginInfo", "Version", "")
        if (RegExMatch(pluginTxt,"i)Version\s*=(.*)", &m))
            VimDConfig_Manager["Version"].Text:=Trim(m[1])
        else
            VimDConfig_Manager["Version"].Text:=""

        ; Author:=IniRead(pluginFile, "PluginInfo", "Author", "")
        if (RegExMatch(pluginTxt,"i)Author\s*=(.*)", &m))
            VimDConfig_Manager["Author"].Text:=Trim(m[1])
        else
            VimDConfig_Manager["Author"].Text:=""

        ; Comment:=IniRead(pluginFile, "PluginInfo", "Comment", "")
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
    LV2:=VimDConfig_Manager["LV2"]
    LV2.delete()
    If (plugin = Lang["General"]["Global"]){
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
        if plugin=Lang["General"]["Global"]
            plugin:="global"
        if(Item=Lang["General"]["Disable"]){
            LV1.Modify(LV1_SelectedItem,"Col1", Lang["General"]["Disable"])
            if (vim.GetWin(plugin="global"?"":plugin).Inside){
                Rst:=INIObject.AddKey(plugin,"enabled",0)
                if !Rst
                    INIObject.%plugin%.enabled:=0
            } else {
                Rst:=INIObject.AddKey("plugins",plugin,0)
                if !Rst
                    INIObject.plugins.%plugin%:=0
            }
        }else{
            LV1.Modify(LV1_SelectedItem,"Col1", Lang["General"]["Enable"])
            if (vim.GetWin(plugin="global"?"":plugin).Inside){
                Rst:=INIObject.AddKey(plugin,"enabled",1)
                if !Rst
                    INIObject.%plugin%.enabled:=1
            } else {
                Rst:=INIObject.AddKey("plugins",plugin,1)
                if !Rst
                    INIObject.plugins.%plugin%:=1
            }
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
        if plugin=Lang["General"]["Global"]
            plugin:="global"
        mode:=LV2.GetText(LV2_SelectedItem, 2) 
        Loop LV2.GetCount()
        {
            if(A_index!=LV2_SelectedItem){
                LV2.Modify(A_index,"Col1","")
            }else{
                LV2.Modify(A_index,"Col1",Lang["General"]["Default"])
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
        }
        INIObject.save()
    }
}

VimDConfig_LoadHotkey(win, mode := "", FilterGroup:="", FilterStr:=""){
    VimDesktop_Global.Current_KeyMap := ""
    If strlen(mode){
        winObj  := vim.GetWin(win)
        ModeObj := winObj.modeList[mode]
    } Else
        ModeObj := vim.GetMode(win)

    LV3:=VimDConfig_Manager["LV3"]
    LV3.delete()
    LV3.Opt("-Redraw") ; 重新启用重绘 (上面把它禁用了)
    N:=0
    for key, i in ModeObj.KeyMapList
    {
        _keyStr:=vim.Convert2MapKey(key)
        tAction:=vim.GetAction(win, mode, _keyStr)
        _group:=tAction.Group
        _Key:=tAction.OriKey
        _Action:=tAction.Function
        _Param:=KyFunc_StringParam(tAction.Param, ', ', '"')
        ; _Param:="[ " KyFunc_ArrayJoin(tAction.Param, ', ', '"') " ]"
        _Comment:=tAction.Comment
        if (tAction.Type = 1)
        {

        } else {
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
            _Key:=OutK
        }
        if (FilterGroup!="" && FilterStr!="") {
            Switch FilterGroup{
                case Lang["Manager"]["Gui"]["GroupList"][1]:
                    if !InStr(_group, FilterStr)
                        continue
                case Lang["Manager"]["Gui"]["GroupList"][2]:
                    if !InStr(_Key, FilterStr)
                        continue
                case Lang["Manager"]["Gui"]["GroupList"][3]:
                    if !InStr(_Action, FilterStr)
                        continue
                case Lang["Manager"]["Gui"]["GroupList"][4]:
                    if !InStr(_Param, FilterStr)
                        continue
                case Lang["Manager"]["Gui"]["GroupList"][5]:
                    if !InStr(_Comment, FilterStr)
                        continue
            }
            LV3.Add("",_group, _Key, _Action, _Param, _Comment)
            VimDesktop_Global.Current_KeyMap .= Key "`t" _Comment "`t" _Action "`n"
        } else {
            LV3.Add("",_group, _Key, _Action, _Param, _Comment)
            VimDesktop_Global.Current_KeyMap .= Key "`t" _Comment "`t" _Action "`n"
        }
    }
    LV3.Opt("+Redraw")
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
    LV1:=VimDConfig_Manager["LV1"]
    FocusedRowNumber := LV1.GetNext(0, "F")  ; 查找焦点行.
    if !FocusedRowNumber  ; 没有焦点行.
        return
    plugin:=LV1.GetText(FocusedRowNumber, 2) 

    if plugin=Lang["General"]["Global"]
        plugin:="global"

    LV2:=VimDConfig_Manager["LV2"]
    FocusedRowNumber := LV2.GetNext(0, "F")  ; 查找焦点行.
    if !FocusedRowNumber  ; 没有焦点行.
        return
    mode:=LV2.GetText(FocusedRowNumber, 2) 
    
    if (vim.GetWin(plugin="global" ? "global" : plugin).Inside){
        label_key := Format('{1}\s*\=', EscapeRegex(Keys))
        label_mode := Format('\[\={1}\]', EscapeRegex(mode))
        if (Action="VIMD_CMD")
            label_Action := Format('{1}', EscapeRegex(Param))
        else
            label_Action := Format('{1}', EscapeRegex(Action))
        ;查找插件热键映射
        Loop Read VimDesktop_Global.ConfigPath
        {
            if (RegExMatch(A_LoopReadLine, label_key) &&  RegExMatch(A_LoopReadLine, label_mode) && RegExMatch(A_LoopReadLine, label_Action)) {
                EditFile(VimDesktop_Global.ConfigPath, A_Index)
                return
            }
        }
    } else {
        label_key := Format('Key:\s*"{1}"', Keys)
        label_mode := Format('Mode:\s*"{1}"', mode)

        ;查找插件热键映射
        pluginFile:=A_ScriptDir "\plugins\" plugin "\" plugin ".ahk"
        Loop Read pluginFile
        {
            if (RegExMatch(A_LoopReadLine, label_key) &&  RegExMatch(A_LoopReadLine, label_mode)) {
                EditFile(pluginFile, A_Index)
                return
            }
        }
    }
}

SearchFileForEdit(Action, Param, Desc, EditKeyMapping){

    label_Action := Format('m)^\s*{1}\s*\(.*\)[\s\n\r]*\{', EscapeRegex(Action))

    if (Action="VIMD_CMD"){
        Loop Read VimDesktop_Global.ConfigPath
        {
            if (RegExMatch(A_LoopReadLine, label_Action)) {
                EditFile(VimDesktop_Global.ConfigPath, A_Index)
                return
            }
        }
    }

    Loop Files A_ScriptDir "\plugins\*.ahk", "RF"
    {
        Loop Read A_LoopFileFullPath
        {
            
            if (RegExMatch(A_LoopReadLine, label_Action))
            {
                EditFile(A_LoopFileFullPath, A_Index)
                return
            }
        }
    }

    Loop Files A_ScriptDir "\core\*.ahk", "F"
    {
        Loop Read A_LoopFileFullPath
        {
            if (RegExMatch(A_LoopReadLine, label_Action))
            {
                EditFile(A_LoopFileFullPath, A_Index)
                return
            }
        }
    }

    Loop Files A_ScriptDir "\lib\*.ahk", "F"
    {
        Loop Read A_LoopFileFullPath
        {
            if (RegExMatch(A_LoopReadLine, label_Action))
            {
                EditFile(A_LoopFileFullPath, A_Index)
                return
            }
        }
    }

    Loop Files A_ScriptDir "\custom\*.ahk", "F"
    {
        Loop Read A_LoopFileFullPath
        {
            if (RegExMatch(A_LoopReadLine, label_Action))
            {
                EditFile(A_LoopFileFullPath, A_Index)
                return
            }
        }
    }

}

EditFile(editPath, line := 1){
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
    
    If (not FileExist(VimDesktop_Global.Editor)){
        MsgRst:=MsgBox("未配置【编辑器】路径，是否设置路径？`n--------------------------`n【是】设置路径`n【否】以[记事本]打开`n--------------------------", "询问", "4132")
        if (MsgRst="Yes") {
            SelectedFile := FileSelect(1, A_WorkingDir, "选择编辑器", "程序(*.exe)")
            if A_LastError
                return
            if (SelectedFile ="")
                return
            VimDesktop_Global.Editor:=SelectedFile
            INIObject.config.editor:=SelectedFile
            INIObject.save()
            reload
        }
    }
    if (VimDesktop_Global.Editor="")
        VimDesktop_Global.Editor:="notepad.exe"

    ; 根据编辑器 exe 名称获取打开参数
    SplitPath VimDesktop_Global.Editor, , , &OutExtension, &OutNameNoExt
    args := editorArgs[OutNameNoExt]
    args:=StrReplace(args, "$line", line)
    args:=StrReplace(args, "$file", '"' editPath '"')
    target := VimDesktop_Global.Editor " " args
    run target
}

Edit_Search_Change(*){
    LV1:=VimDConfig_Manager["LV1"]
    FocusedRowNumber := LV1.GetNext(0, "F")  ; 查找焦点行.
    if !FocusedRowNumber  ; 没有焦点行.
        return
    plugin:=LV1.GetText(FocusedRowNumber, 2) 
    win := RegExMatch(plugin, Format("^{1}$", Lang["General"]["Global"])) ? "" : plugin
    ; Convert plugin name TotalCommander to class name TTOTAL_CMD

    LV2:=VimDConfig_Manager["LV2"]
    FocusedRowNumber := LV2.GetNext(0, "F")  ; 查找焦点行.
    if !FocusedRowNumber  ; 没有焦点行.
        return
    mode:=LV2.GetText(FocusedRowNumber, 2) 
    VimDConfig_LoadHotkey(win, mode, VimDConfig_Manager["Group"].Text, VimDConfig_Manager["Search"].Text)
    ; search_to_display(VimDesktop_Global.Current_KeyMap)
}

search_to_display(lines){
    OutputVar:=VimDConfig_Manager["Search"].Text
    LV3:=VimDConfig_Manager["LV3"]
    text := StrSplit(lines, "`n")
    LV3.Delete() ; 清理不掉，第二次加载后，都成了重复的了，不知道怎么处理
    LV3.Opt("-Redraw") ; 重新启用重绘 (上面把它禁用了)
    N:=0
    for k, v in text
    {
        if (v ="")
            continue
        N+=1
        if Instr(v, OutputVar)
        {
            list := StrSplit(v, "`t")
            LV3.Add("", N,list[1], list[2], list[3])
        }
    }
    LV3.Opt("+Redraw")
}
