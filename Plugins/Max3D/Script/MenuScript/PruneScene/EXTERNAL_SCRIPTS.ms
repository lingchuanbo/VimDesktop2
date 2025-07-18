/*
[INFO] 

NAME = External Scripts
VERSION = 1.0.0
AUTHOR = MastaMan
DEV = 3DGROUND
SITE=http://3dground.net

[SCRIPT]

*/

struct simpleLanguageManager (
	defaultLang = "english",
	ext = @".lng",	
	pth = (getFileNamePath (getThisScriptFileName())),
	defaultFile = pth + defaultLang + ext,
	settingsFile = pth + @"settings.ini",
	fn getLang = (		
		local l = getIniSetting settingsFile "SETTINGS" "LANG"			
		local f = pth + l + ext			
		if(l == "") do return defaultFile
			
		return f
	),
	lang = getLang(),
	fn getTranslate l sec: "UI" = (
		local f = getLang()
		local o = getIniSetting f sec l
		if(o == "") do return l
		
		o = substituteString o " || " "\n\n"
		o = substituteString o " | " "\n"
		return o
	),
	fn translateUi r = (
		for i in 1 to r.controls.count do (
			local c = r.controls[i]
			local isCaptionExist = c.caption[1] == "~"
			local isTextExist = try(c.text[1] == "~") catch(false)
			local isTagExist = try(c.tag[1] == "~") catch(false)
			
			if(isCaptionExist) do (
				c.caption = getTranslate (c.caption)
			)
			if(isTextExist ) do (
				c.text = getTranslate (c.text)
			)
			if(isTagExist) do (
				c.text = getTranslate (c.tag)
			)
		)
	)
)

global simpleLngMgr = simpleLanguageManager()

try(destroyDialog _rExternalScripts) catch()
rollout _rExternalScripts "External Scripts (*.ms)" (
	local globalLinkHrefColor = if((colorMan.getColor #background)[1] < 0.5) then (orange) else (color 161 55 32)
	local infoWidth = 240
	local bottomBarHeight = 50
	local bottomBarButtonOffset = 38
	
	dotNetControl lbxList "system.windows.forms.listView" height: 400 width: 550 offset: [-13, -5]
	dotNetControl edtInfo "System.Windows.Forms.Textbox" width: 300 height: 400 align:#right pos: [600, 0]
	
	button btnAddToList "~MODALS_ADD_TO_LIST~" align: #left height: 25 width: 120 pos: [10, -50]
	button btnRemoveFromList "~MODALS_REMOVE_FROM_LIST~" align: #left height: 25 width: 120 pos: [135, -50]
	HyperLink hplGetExternalScripts "~GET_EXTERNAL_SCRIPTS_FREE~" address: "https://github.com/3DGROUND/Prune-Scene-External-Scripts-Batch-Prune-"  color: globalLinkHrefColor hoverColor: globalLinkHrefColor visitedColor: globalLinkHrefColor pos: [265, -50]
		
	fn getDotnetColor r g b = (dotnetclass "System.Drawing.Color").FromArgb r g b
	
	fn getBgColor = (
		local b = (colorman.getcolor #rollupTitleFace) * 255
		local c = getDotnetColor b[1] b[2] b[3]
		return c
	)

	fn getTextColor = (
		local t = (colorMan.getColor #text) * 255
		local c = getDotnetColor t[1] t[2] t[3]
		return c
	)
	
	fn getSelectedId = (
		local c = lbxList.SelectedItems.Count - 1		
		local id = 0		
		for i in 0 to c do id = lbxList.SelectedItems.Item[i].Index + 1
		return id
	)
	
	fn setSelectedItem id = (
		local item = lbxList.Items.Item[id - 1]
		item.Selected = true
		item.Focused = true
		item.EnsureVisible()
	)
	
	fn getSelectedItem = (
		local item = undefined
		local c = lbxList.SelectedItems.Count - 1					
		for i in 0 to c do item = lbxList.SelectedItems.Item[i]
		return item
	)
	
	fn initTextBox textBox = (
		textBox.Font = dotNetObject "System.Drawing.Font" "MS Sans Serif" 8 ((dotNetClass "System.Drawing.FontStyle").Regular)
		textBox.BorderStyle = (dotNetClass "System.Windows.Forms.BorderStyle").FixedSingle
		textBox.BackColor = getBgColor()
		textBox.ForeColor = getTextColor()
		textBox.MultiLine = true
		textBox.WordWrap = true
		textBox.ScrollBars = (dotNetClass "System.Windows.Forms.ScrollBars").Vertical
		textBox.ReadOnly = true
	)

	fn getOpenFiles filt: "Scripts files (*.ms) | *.ms"  = (
		local f = #()
		
		local d = dotNetObject "System.Windows.Forms.OpenFileDialog" 
		d.title = "Select Files"
		d.Multiselect = true
		d.Filter = filt
		d.FilterIndex = 1
		
		local r = d.showDialog() 
		r.ToString()
		r.Equals r.OK
		r.Equals r.Cancel
		
		local f = d.fileNames 
		
		return f
	)	
	
	fn setBottomBarVertPos = (
		local size = GetDialogSize _rExternalScripts
		btnRemoveFromList.pos.y = size.y - bottomBarButtonOffset
		btnAddToList.pos.y = size.y - bottomBarButtonOffset
		hplGetExternalScripts.pos.y = size.y - bottomBarButtonOffset + 6
	)
	
	fn initDotNet = (	
		setBottomBarVertPos()
		
		align = dotNetClass "HorizontalAlignment"
		
		lbxList.Clear()
		lbxList.View = (dotNetClass "System.Windows.Forms.View").Details	
		lbxList.FullRowSelect = true
		lbxList.GridLines = true		
		lbxList.ShowItemToolTips = true
		lbxList.MultiSelect = false
		lbxList.CheckBoxes = false
		lbxList.HideSelection = false
		lbxList.Columns.Add "#" 35
		lbxList.Columns.Add (simpleLngMgr.getTranslate "~MODALS_NAME~") 200
		lbxList.Columns.Add (simpleLngMgr.getTranslate "~MODALS_TYPE~") 90 align.center
		lbxList.Columns.Add (simpleLngMgr.getTranslate "~MODALS_PATH~") (750 - 150 - 180 - 208) 
		
		lbxList.Update()
		lbxList.Refresh()
		
		initTextBox edtInfo
	)
		
	fn showScriptInfo = (
		local m = ""
		local n = "\r\n"
		
		local id = getSelectedId()
		local li = getSelectedItem()
		
		if(id == 0 or li == undefined) do (
			m = simpleLngMgr.getTranslate "~TOOLTIP_SELECT_FOR_INFO~" sec: "TOOLTIPS"
			edtInfo.text = m
			return false
		)
		
		local file = li.tag
		
		
		local name = getINISetting file "INFO" "NAME"
		local type = getINISetting file "INFO" "TYPE"
		local ver = getINISetting file "INFO" "VERSION"
		local author = getINISetting file "INFO" "AUTHOR"
		local dev = getINISetting file "INFO" "DEV"
		local site = getINISetting file "INFO" "SITE"
		local req = getINISetting file "INFO" "REQ"
		local desc = getINISetting file "INFO" "DESC"
		local date = getINISetting file "INFO" "DATE"
		local tnx = getINISetting file "INFO" "THANKS"
		
		if (type == "") then (
			m += (filenameFromPath file) + n + n			
			m += simpleLngMgr.getTranslate "~TOOLTIP_NO_INFO_ABOUT_SCRIPT~" sec: "TOOLTIPS"			
		) else (
			m += name + " " + ver + n + n
			if (author != "") do m += "Author: " + author 
			if (dev != "") do m += " (" + dev + ")" 
			if (site != "") do m += n + "Site: " + site 
			if (date != "") do m += n + "Updated: " + date
			if (tnx != "") do m += n + "Big Thanks: " + tnx
			
			if (req != "") do (
				m += n + n + "Requirements:" + n
				m += req
			)
			
			if (desc != "") do (
				m += n + n + "Description:" + n
				m += desc
			)
		)
		
		m += n + n + "Location: " + n + file
		
		edtInfo.text = m
	)
		
	fn getIni k = (
		local d = getFilenamePath  (getThisScriptFilename())			
		local ini = d + "external_scripts.ini"
		if(k == "") do return getIniSetting ini "LIST"
		return getIniSetting ini "LIST" k
	)
	
	fn getSortedList = (
		fn compareFN v1 v2 = (
			local a = v1[2] as integer
			local b = v2[2] as integer
			if (a > b) do return 1
			if (a < b) do return -1
			return 0		
		)
		
		local list = #()
		for k in (getIni "") do (
			local id = getIni k
			append list #(k, id)
		)
		
		qsort list compareFN
		
		return for i in list collect i[1]
	)
	
	fn removeIni k = (
		local d = getFilenamePath  (getThisScriptFilename())			
		local ini = d + "external_scripts.ini"
			
		delIniSetting ini "LIST" k
	)
	
	fn setIni k id = (
		local d = getFilenamePath  (getThisScriptFilename())			
		local ini = d + "external_scripts.ini"
		
		setINISetting ini "LIST" k (id as string)
	)
	
	fn removeItemId id = (
		try(lbxList.Items.RemoveAt[id]) catch()
	)
	
	
	fn setDotnetBoldFont = (
		bold = (dotnetclass "System.Drawing.FontStyle").Bold
		return dotnetobject "System.Drawing.Font" "Arial" 8 bold
	)
	
	fn addToLbxList r =	(				
		lbxList.Items.Clear()
		local rows = #()	
		local i = 1
		for x in r do (
			local li = dotNetObject "System.Windows.Forms.ListViewItem" ""
			li.useItemStyleForSubItems = false
			local bold = (dotnetclass "System.Drawing.FontStyle").Bold
			
			li.text = (i as string) + "."
			li.subitems.add x[1]	
			li.subitems.add x[2]	
			
			li.subitems.add x[3]	
			li.tag = x[4]		
			
			local bg = getDotNetColor 147 196 125
			local fg = getDotNetColor 56 118 79

			
			if (not x[5]) do (
				bg = getDotNetColor 224 102 102
				fg = getDotNetColor 153 0 47
			) 
				
			li.subItems.Item[2].backColor = bg
			li.subItems.Item[2].foreColor = fg
			li.subItems.Item[2].Font = setDotnetBoldFont()
			
			
			append rows li		
			i += 1
		)
		
		lbxList.Items.addRange rows
	)	
		
	fn convertFileToUTF8 o n  =	(
		local f = openFile o
		local buffer = #()
		while (not eof f) do (
			szLine = readline f		
			szLine = trimRight (trimLeft szLine)		
			append buffer szLine
		)
		flush f
		close f	
		
		--deleteFile o
		
		local s = dotNetObject "System.IO.StreamWriter" (n) true ((dotNetClass "System.Text.Encoding").GetEncoding("UTF-8"))
		
		for l in buffer where  l.count > 0 do s.WriteLine(dotNetObject "System.String" l)			
		s.Close()		
	)
	
	fn buildList = (	
		local list = getSortedList()
		if(list == undefined) do return false
		
		r = #()

		for f in list do (
			row = #()
			
			local found = simpleLngMgr.getTranslate "~MODALS_FOUND~"
			local not_found = simpleLngMgr.getTranslate "~MODALS_NOTFOUND~"
			local isExist = doesFileExist f 
			
			row[1] = filenameFromPath f
			row[2] = if (isExist) then found else not_found
			row[3] = getFilenamePath  f
			row[4] = f
			row[5] = isExist
			
			append r row
		)
		
		addToLbxList r
	)
	
	fn addToList = (		
		local list = getIni ""
		local cnt = list.count
		
		local ff = getOpenFiles()
		
		for f in ff do (
			setIni f (cnt += 1)
		)
		
		buildList()
		
		showScriptInfo()
	)
	
	fn shiftItem v = (
		local id = getSelectedId()
		local li = getSelectedItem()
		
		if(id == 0 or li == undefined) do return messageBox (simpleLngMgr.getTranslate "~MODALS_SELECT_FILE_FROM_LIST_MSG~") title: "Notify!"
		
		local file = li.tag
		
		local list = getSortedList()
		
		for i in 1 to list.count do setIni list[i] i
		
		local selectId = id
		
		for i in 1 to list.count do (
			if (list[i] == file) then (
				local n = i + v
				
				if (n < 1) do exit
				if (n > list.count) do exit
				
				local o = list[n]
				local c =  list[i]
				
				selectId = n
				setIni c n
				setIni o i
			) 
		)
		
		buildList()
		
		setSelectedItem selectId
		
		showScriptInfo()
	)
	
	fn itemUp = (
		shiftItem -1
	)
	
	fn itemDown = (
		shiftItem 1
	)
	
	fn removeFromList = (
		local id = getSelectedId()
		local li = getSelectedItem()
		
		if(id == 0 or li == undefined) do return messageBox (simpleLngMgr.getTranslate "~MODALS_SELECT_FILE_FROM_LIST_MSG~") title: "Notify!"
		
		local file = li.tag
		
		fileName = filenameFromPath file
		local m = simpleLngMgr.getTranslate "~MODALS_DELETE_FILE_MSG~"
		m += " \"" + fileName + "\" "
		m += simpleLngMgr.getTranslate "~MODALS_DELETE_FILE_MSG2~"
		
		local q = queryBox m title: "Confirm?"
		if(not q) do return false
		
		removeIni file	
		buildList()
		
		showScriptInfo()
	)
	
	fn openLocation = (
		local id = getSelectedId()
		local li = getSelectedItem()
		
		if(id == 0 or li == undefined) do return messageBox (simpleLngMgr.getTranslate "~MODALS_SELECT_FILE_FROM_LIST_MSG~") title: "Notify!"
		
		local file = li.tag
		
		local p = getFilenamePath file
		ShellLaunch p ""
	)
	
	fn getOnlineHelp = (
		shellLaunch "http://3dground.net/manual/prune-scene#batch-prune" ""
	)
	
	fn contextMenuItem m n enabled: true = (
		local item = undefined	
		local c = m.Items.Count - 1
		for i = c to 0 by - 1 where c > 0 do (
			local ii = m.Items.Item[i].Text
			if(ii == n) do (
				item = m.Items.Item[i]
				item.Enabled = enabled
				exit
			)
		)
		
		return item
	)
	
	fn bindContextMenu = (
		local id = getSelectedId()
		
		contextMenu = dotNetObject "System.Windows.Forms.ContextMenuStrip"
		
		lngAdd = simpleLngMgr.getTranslate "~MODALS_ADD_TO_LIST~"
		lngRemove = simpleLngMgr.getTranslate "~MODALS_REMOVE_FROM_LIST~"
		lngUp = simpleLngMgr.getTranslate "~MODALS_UP~"
		lngDown = simpleLngMgr.getTranslate "~MODALS_DOWN~"
		lngOnlineHelp = simpleLngMgr.getTranslate "~ONLINE_HELP~"
		lngLocation = simpleLngMgr.getTranslate "~MODALS_OPEN_SCRIPT_LOCATON~"
			
		if(id != 0) do (
			dotNet.addEventHandler (contextMenu.Items.Add(lngAdd)) "Click" addToList				
			dotNet.addEventHandler (contextMenu.Items.Add(lngRemove)) "Click" removeFromList				
			contextMenu.Items.Add("-")
			dotNet.addEventHandler (contextMenu.Items.Add(lngUp)) "Click" itemUp				
			dotNet.addEventHandler (contextMenu.Items.Add(lngDown)) "Click" itemDown
			contextMenu.Items.Add("-")
			dotNet.addEventHandler (contextMenu.Items.Add(lngLocation)) "Click" openLocation
			contextMenu.Items.Add("-")
			dotNet.addEventHandler (contextMenu.Items.Add(lngOnlineHelp)) "Click" getOnlineHelp				
		)
		
		lbxList.ContextMenuStrip = contextMenu
	)
	
	fn onResize = (
		local size = GetDialogSize _rExternalScripts
		
		lbxList.width = size.x - infoWidth
		lbxList.height = size.y - bottomBarHeight
		
		edtInfo.pos.x = size.x - infoWidth
		edtInfo.width = infoWidth
		edtInfo.height = size.y - bottomBarHeight
		
		setBottomBarVertPos()
	)
	
	on lbxList SelectedIndexChanged a do (
		showScriptInfo()
	)
	
	on lbxList MouseUp do (		
		bindContextMenu()
	)
	
	on _rExternalScripts open do (
		initDotNet()		
		buildList()
		onResize()
		
		showScriptInfo()
		
		simpleLngMgr.translateUi _rExternalScripts
	)
	
	on _rExternalScripts resized size do (
		onResize()
	)
	
	on btnRemoveFromList pressed do removeFromList()
	on btnAddToList pressed do addToList()
)

createDialog _rExternalScripts 800 450 style: #(#style_toolwindow, #style_resizing, #style_sysmenu, #style_toolwindow) modal: true