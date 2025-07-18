/*
[INFO] 

NAME = Detect Threats
VERSION = 1.0.1
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

struct signature_log (
	fn getLogFile = (
		d = getFilenamePath  (getThisScriptFilename())			
		return (d + "scanlog.ini")
	),
	
	fn getVerboseLevel = (
		ini = getLogFile()
		v = getIniSetting ini "SETTINGS" "VERBOSELEVEL"
		if(v == "") do return 1
		return try(v as integer) catch(1)
	),
	
	fn setVerboseLevel lvl = (
		ini = getLogFile()
		setIniSetting ini "SETTINGS" "VERBOSELEVEL" (lvl as string)
	),
	
	fn getLogType type = (
		return case type of (
			#threat: "Threat"
			#warn: "Warning"
			default: "Default"
		)
	),
	
	fn getTime = (
		t = #()
		for i in getLocalTime() do (
			s = (i as string)
			if(s.count < 2) do s = "0" + s
			append t s
		)
		
		return t[4] + "." + t[2] + "." + t[1] + " " + t[5] + ":" + t[6] + ":" + t[7]
	),
	
	fn write msg type: #threat = (
		ini = getLogFile()
		
		s = getLogType type
		k = getTime()
		
		setIniSetting ini s k msg
	),
	
	fn getLog type: #threat = (
		ini = getLogFile()
		s = getLogType type
		
		out = #()
		
		for i in (getIniSetting ini s) do (
			tmp = #()
			tmp[1] = i
			tmp[2] = s
			tmp[3] = (getIniSetting ini s i)
			append out tmp
		)
		
		return out
	),
	
	fn getAll = (
		out = #()
		ini = getLogFile()
		
		for i in (getIniSetting ini) where i != "SETTINGS" do (
							
			for ii in (getIniSetting ini i) do (
				tmp = #()
				tmp[1] = ii
				tmp[2] = i
				tmp[3] = (getIniSetting ini i ii)

				append out tmp
			)
		)
		
		return out
	),
	
	fn clearAll = (
		out = #()
		ini = getLogFile()
		
		for i in (getIniSetting ini) where i != "SETTINGS" do (
			delIniSetting ini i
		)
	)
)

global simpleLngMgr = simpleLanguageManager()

try(destroyDialog _rDetectedThreats) catch()
rollout _rDetectedThreats "Last Scanned Detected Threats" (
	dotNetControl lbxThreats "system.windows.forms.listView" height: 350 width: 750 offset: [-13, -5]
	
	button btnDisinfect "~MODALS_DISINFECT~" align: #left height: 25 width: 100 pos: [10, -50]
	button btnRemoveFromList "~MODALS_IGNORE~" align: #left height: 25 width: 100 pos: [125, -50]
	button btnBatchDisinfect "~MODALS_BATCH_DISINFECT~" align: #left height: 25 width: 140 pos: [240, -50]
		
	fn setBottomBarVertPos = (
		v = 36
		size = GetDialogSize _rDetectedThreats
		btnDisinfect.pos.y = size.y - v
		btnRemoveFromList.pos.y = size.y - v
		btnBatchDisinfect.pos.y = size.y - v
	)
	
	fn getDotNetColor r g b = (DotNetClass "System.Drawing.Color").fromargb r g b 
	
	fn initDotNet =
	(	
		setBottomBarVertPos()
		
		align = dotNetClass "HorizontalAlignment"
		
		lbxThreats.Clear()
		lbxThreats.View = (dotNetClass "System.Windows.Forms.View").Details	
		lbxThreats.FullRowSelect = true
		lbxThreats.GridLines = true		
		lbxThreats.ShowItemToolTips = true
		lbxThreats.MultiSelect = false
		lbxThreats.CheckBoxes = false
		lbxThreats.HideSelection = false
		lbxThreats.Columns.Add "#" 35
		lbxThreats.Columns.Add (simpleLngMgr.getTranslate "~MODALS_DATE~") 110
		lbxThreats.Columns.Add (simpleLngMgr.getTranslate "~MODALS_TYPE~") 70 align.center
		lbxThreats.Columns.Add (simpleLngMgr.getTranslate "~MODALS_PATH~") (750 - 150 - 70) 
					
		lbxThreats.Update()
		lbxThreats.Refresh()
	)
	
	fn getScanIni s k = (
		d = getFilenamePath  (getThisScriptFilename())			
		ini = d + "scanfiles.ini"
		if(not doesFileExist ini) do return undefined	
		if(k == "") do return getIniSetting ini s
		return getIniSetting ini s k
	)
	
	fn removeScanIni k = (
		d = getFilenamePath  (getThisScriptFilename())			
		ini = d + "scanfiles.ini"
			
		delIniSetting ini "SCAN" k
	)
	
	fn removeItemId id = (
		try(lbxThreats.Items.RemoveAt[id]) catch()
	)
		
	fn getSelectedId =
	(
		c = lbxThreats.SelectedItems.Count - 1		
		id = 0		
		for i = 0 to c do id = lbxThreats.SelectedItems.Item[i].Index + 1
		return id
	)
	
	fn getSelectedItem =
	(
		item = undefined
		c = lbxThreats.SelectedItems.Count - 1					
		for i = 0 to c do item = lbxThreats.SelectedItems.Item[i]
		return item
	)
	
	fn setDotnetBoldFont = (
		bold = (dotnetclass "System.Drawing.FontStyle").Bold
		return dotnetobject "System.Drawing.Font" "Arial" 8 bold
	)
	
	fn addToLbxList r =
	(				
		lbxThreats.Items.Clear()
		rows = #()	
		i = 1
		for x in r do	
		(
			li = dotNetObject "System.Windows.Forms.ListViewItem" ""
			li.useItemStyleForSubItems = false
			bold = (dotnetclass "System.Drawing.FontStyle").Bold
						
			li.text = (i as string) + "."
			li.subitems.add x[1]	
			li.subitems.add x[2]	
					
			li.subitems.add x[3]	
			li.tag = x[3]		
			
			li.subItems.Item[2].backColor = getDotNetColor 224 102 102
			li.subItems.Item[2].foreColor = getDotNetColor 153 0 47
			li.subItems.Item[2].Font = setDotnetBoldFont()
						
			append rows li		
			i += 1
		)
		
		lbxThreats.Items.addRange rows
	)	
		
	fn convertFileToUTF8 o n  =
	(
		f = openFile o
		buffer = #()
		while (not eof f) do
		(
			szLine = readline f		
			szLine = trimRight (trimLeft szLine)		
			append buffer szLine
		)
		flush f
		close f	
		
		--deleteFile o
		
		s = dotNetObject "System.IO.StreamWriter" (n) true ((dotNetClass "System.Text.Encoding").GetEncoding("UTF-8"))
		
		for l in buffer where  l.count > 0 do s.WriteLine(dotNetObject "System.String" l)			
		s.Close()		
	)
	
	fn buildThreatList = (	
		scan = getScanIni "SCAN" ""
		if(scan == undefined) do return false
		
		date = getScanIni "DONE" "lastscan"
		date = trimRight (trimRight date ".0123456789") ":"
		
		r = #()

		for s in scan where (doesFileExist s) == true do (
			row = #()
			row[1] = date
			row[2] = simpleLngMgr.getTranslate "~MODALS_THREAT~"
			row[3] = s
			
			append r row
		)
		
		addToLbxList r
	)
	
	fn getSaveVersion = (
		v = maxVersion()
		v = (v[1] / 1000) - 2
		
		a = 2000 + v
		
		o = case v of 
		(
			11: #(a - 1, a)
			12: #(a - 2, a - 1, a)
			default: #(a - 3, a - 2, a - 1, a)		
		)
		
		return (for i in o collect i as string)
	)
		
	fn batchDisinfect = (
		files = getScanIni "SCAN" ""
		if(files == undefined) do files = #()
		slog = signature_log()
		version = (getSaveVersion())[1] as integer
		
		verbose_level = slog.getVerboseLevel()
		
		if(files.count == 0) do return messageBox (simpleLngMgr.getTranslate "~MODALS_BATCH_NO_FILES_MSG~") title: "Notify!"
		q = queryBox (simpleLngMgr.getTranslate "~MODALS_BATCH_WARN_MSG~") title: "Notify!"
		if(not q) do return false
		
		setSaveRequired true
		checkForSave()
		
		d = getFilenamePath  (getThisScriptFilename())			
		signatures = getFiles (d + "signature*.mcr")
		
		for f in files do (
			print ("Open and disinfect: " + f)
			try(setVRaySilentMode()) catch()
			f = pathConfig.resolvePathSymbols f
			
			if(doesFileExist f) do	try(loadMaxFile f useFileUnits: true quiet: true) catch()
			
			slog.setVerboseLevel 3
			for ss in signatures do try(fileIn ss) catch()
			slog.setVerboseLevel verbose_level
			
			removeScanIni f
			buildThreatList()
				
			saveMaxFile f quiet: true saveAsVersion: version
		)	

		resetMaxFile #noPrompt 	
		
		messageBox (simpleLngMgr.getTranslate "~MODALS_BATCH_DONE_SUCCESS_MSG~") title: "Success!" beep: false
	)
	
	fn openAndDisinfect = (
		id = getSelectedId()
		li = getSelectedItem()
		
		if(id == 0 or li == undefined) do return messageBox (simpleLngMgr.getTranslate "~MODALS_SELECT_FILE_FROM_LIST_MSG~") title: "Notify!"		
		local fullFilePath = li.tag as string
		
		if(fullFilePath == undefined) do return false
		fileName = filenameFromPath fullFilePath
		
		m = (simpleLngMgr.getTranslate "~MODALS_OPEN_AND_PRUNE_VIRUSES_MSG~") + " \"" + fileName + "\" ?"		
		q = queryBox m title: "Confirm?"
		if(not q) do return false
		
		if(not doesFileExist fullFilePath) do return messageBox ("File \"" + fileName + "\" not exist!") title: "Notify!"
		setSaveRequired true
		checkForSave()
		
		objs = getMAXFileObjectNames fullFilePath
			
		loadMaxFile (pathConfig.resolvePathSymbols (fullFilePath as string)) useFileUnits: true quiet: true
		currScene = maxFilepath + maxFileName
		if(fullFilePath != currScene) do (
			notification = simpleLngMgr.getTranslate "~MODALS_ERROR_OPEN_FILE_MSG~"
			notification += " \"" + fileName + "\"!\n"
			notification +=  simpleLngMgr.getTranslate "~MODALS_ERROR_OPEN_FILE_MSG2~"
			return messageBox notification  title: "Error!"
		)
		
		d = getFilenamePath  (getThisScriptFilename())			
		signatures = getFiles (d + "signature*.mcr")
		
		for ss in signatures do try(fileIn ss) catch()
			
		removeScanIni fullFilePath	
		buildThreatList()
		
		notification = simpleLngMgr.getTranslate "~MODALS_VIRUSES_REMOVED_FROM_MSG~"
		notification += " \"" + fileName + "\"\n"
		notification += simpleLngMgr.getTranslate "~MODALS_VIRUSES_REMOVED_FROM_MSG2~"
		messageBox notification title: "Success!" beep: false
		
		newFile = maxFilepath + maxFileName
			
		ff = getMAXSaveFileName filename: newFile
			
		if(ff == undefined) do return false
			
		saveMaxFile ff quiet: true
	)
	
	fn removeFromList = (
		id = getSelectedId()
		li = getSelectedItem()
				
		if(id == 0 or li == undefined) do return messageBox (simpleLngMgr.getTranslate "~MODALS_SELECT_FILE_FROM_LIST_MSG~") title: "Notify!"
		
		file = li.tag
		
		fileName = filenameFromPath file
		m = simpleLngMgr.getTranslate "~MODALS_DELETE_FILE_MSG~"
		m += " \"" + fileName + "\" "
		m += simpleLngMgr.getTranslate "~MODALS_DELETE_FILE_MSG2~"
		
		q = queryBox m title: "Confirm?"
		if(not q) do return false
				
		if(not doesFileExist file) do return false
		
		removeScanIni file	
		buildThreatList()
	)
	
	fn getOnlineHelp = (
		shellLaunch "http://3dground.net/manual/prune-scene#virus-selective-scan" ""
	)
	
	fn contextMenuItem m n enabled: true =
	(
		item = undefined	
		c = m.Items.Count - 1
		for i = c to 0 by - 1 where c > 0 do
		(
			ii = m.Items.Item[i].Text
			if(ii == n) do
			(
				item = m.Items.Item[i]
				item.Enabled = enabled
				exit
			)
		)
		
		return item
	)
	
	fn bindContextMenu =
	(
		id = getSelectedId()
			
		contextMenu = dotNetObject "System.Windows.Forms.ContextMenuStrip"
		
		lngDisinfect = simpleLngMgr.getTranslate "~MODALS_DISINFECT~"
		lngIgnore = simpleLngMgr.getTranslate "~MODALS_IGNORE~"
		lngOnlineHelp = simpleLngMgr.getTranslate "~ONLINE_HELP~"
			
		if(id != 0) do (
			dotNet.addEventHandler (contextMenu.Items.Add(lngDisinfect)) "Click" openAndDisinfect				
			dotNet.addEventHandler (contextMenu.Items.Add(lngIgnore)) "Click" removeFromList				
			contextMenu.Items.Add("-")
			dotNet.addEventHandler (contextMenu.Items.Add(lngOnlineHelp)) "Click" getOnlineHelp				
		)
					
		lbxThreats.ContextMenuStrip = contextMenu
	)
	
	on lbxThreats MouseUp do
	(		
		bindContextMenu()
	)
	
	on lbxThreats DoubleClick do
	(		
		_rDetectedThreats.btnDisinfect.pressed()
	)
	
	
	
	on _rDetectedThreats open do (
		initDotNet()		
		buildThreatList()
		
		simpleLngMgr.translateUi _rDetectedThreats
	)
	
	on _rDetectedThreats resized size do (
		lbxThreats.width = size.x
		lbxThreats.height = size.y - 50
		
		setBottomBarVertPos()
	)
	
	on btnDisinfect pressed do openAndDisinfect()
	on btnRemoveFromList pressed do removeFromList()
	on btnBatchDisinfect pressed do batchDisinfect()
)

createDialog _rDetectedThreats 750 400 style: #(#style_toolwindow, #style_resizing, #style_sysmenu, #style_toolwindow)