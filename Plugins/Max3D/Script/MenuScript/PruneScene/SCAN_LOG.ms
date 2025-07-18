/*
[INFO] 

NAME = Scan Log
VERSION = 1.1.0
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

try(destroyDialog _rScanLog) catch()
rollout _rScanLog "Virus Scan Log" (
	dotNetControl lbxLog "system.windows.forms.listView" height: 400 width: 850 offset: [-13, -5]
	
	button btnClearAllLog "~MODALS_CLEAR_ALL_LOG~" align: #left height: 25 width: 100 pos: [10, -50]
	
		
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
		
		fn getTranslatedLogType type = (
			return case type of (
				#threat: simpleLngMgr.getTranslate "~MODALS_THREAT~"
				#warn:  simpleLngMgr.getTranslate "~MODALS_WARNING~"
				default:  simpleLngMgr.getTranslate "~MODALS_DEFAULT~"
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
		
		fn get type: #threat = (
			ini = getLogFile()
			s = getLogType type
			s = getTranslatedLogType type
			
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
	
	fn setBottomBarVertPos = (
		v = 36
		size = GetDialogSize _rScanLog
		btnClearAllLog.pos.y = size.y - v
	)
	
	fn getDotNetColor r g b = (DotNetClass "System.Drawing.Color").fromargb r g b 
	
	fn initDotNet =
	(	
		setBottomBarVertPos()
		
		align = dotNetClass "HorizontalAlignment"
		
		lbxLog.Clear()
		lbxLog.View = (dotNetClass "System.Windows.Forms.View").Details	
		lbxLog.FullRowSelect = true
		lbxLog.GridLines = true		
		lbxLog.ShowItemToolTips = true
		lbxLog.MultiSelect = false
		lbxLog.CheckBoxes = false
		lbxLog.HideSelection = false
		lbxLog.Columns.Add "#" 35
		lbxLog.Columns.Add (simpleLngMgr.getTranslate "~MODALS_DATE~") 130
		lbxLog.Columns.Add (simpleLngMgr.getTranslate "~MODALS_TYPE~") 70 align.center
		lbxLog.Columns.Add (simpleLngMgr.getTranslate "~MODALS_MESSAGE~") (850 - 35 - 130 - 70 - 5) 
					
		lbxLog.Update()
		lbxLog.Refresh()
	)
		
	fn getSelectedId =
	(
		c = lbxLog.SelectedItems.Count - 1		
		id = 0		
		for i = 0 to c do id = lbxLog.SelectedItems.Item[i].Index + 1
		return id
	)
	
	fn getSelectedItem =
	(
		item = undefined
		c = lbxLog.SelectedItems.Count - 1					
		for i = 0 to c do item = lbxLog.SelectedItems.Item[i]
		return item
	)
	
	fn setDotnetBoldFont = (
		bold = (dotnetclass "System.Drawing.FontStyle").Bold
		return dotnetobject "System.Drawing.Font" "Arial" 8 bold
	)
	
	fn addToLbxList r =
	(				
		lbxLog.Items.Clear()
		rows = #()	
		i = 1
		for x in r do	
		(
			li = dotNetObject "System.Windows.Forms.ListViewItem" ""
			li.useItemStyleForSubItems = false
			bold = (dotnetclass "System.Drawing.FontStyle").Bold
						
			li.text = (i as string) + "."
			li.subitems.add x[1]	
			
			type = case x[2] of (
				"Threat": simpleLngMgr.getTranslate "~MODALS_THREAT~"
				"Warning":  simpleLngMgr.getTranslate "~MODALS_WARNING~"
				default:  simpleLngMgr.getTranslate "~MODALS_DEFAULT~"
			)
			
			li.subitems.add type
					
			msg = substituteString x[3] "virus detected and removed for" (simpleLngMgr.getTranslate "~MODALS_VIRUS_REMOVED_FOR~")
			msg = substituteString msg "virus detected but not removed from startup folder!" (simpleLngMgr.getTranslate "~MODALS_DETECTED_BUT_NOT_REMOVED~")
			
			li.subitems.add msg
			li.tag = x[3]		
			
			bg = getDotNetColor 183 183 183; fg = getDotNetColor 67 67 67
			
			case x[2] of (
				"Threat": (
					bg = getDotNetColor 147 196 125
					fg = getDotNetColor 56 118 79
				)
				"Warning": (
					bg = getDotNetColor 255 229 153
					fg = getDotNetColor 215 144 0
				)
			)
			
			li.subItems.Item[2].backColor = bg
			li.subItems.Item[2].foreColor = fg
			li.subItems.Item[2].Font = setDotnetBoldFont()
						
			append rows li		
			i += 1
		)
		
		lbxLog.Items.addRange rows
	)	
	
	fn buildThreatList = (
		
		slog = signature_log()
		r = slog.getAll()
				
		addToLbxList r
	)
		
	fn clearAllLog = (
		slog = signature_log()
		slog.clearAll()
		
		buildThreatList()
	)
	
	fn getOnlineHelp = (
		shellLaunch "http://3dground.net/manual/prune-scene#virus-active-protecton" ""
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
			
		if(id != 0) do (		
			lngOnlineHelp = simpleLngMgr.getTranslate "~ONLINE_HELP~"
			dotNet.addEventHandler (contextMenu.Items.Add(lngOnlineHelp)) "Click" getOnlineHelp				
		)
					
		lbxLog.ContextMenuStrip = contextMenu
	)
	
	on lbxLog MouseUp do
	(		
		bindContextMenu()
	)
			
	on _rScanLog open do (
		initDotNet()		
		buildThreatList()
		
		simpleLngMgr.translateUi _rScanLog
	)
	
	on _rScanLog resized size do (
		lbxLog.width = size.x
		lbxLog.height = size.y - 50
		
		setBottomBarVertPos()
	)
	
	on btnClearAllLog pressed do clearAllLog()
)

createDialog _rScanLog 850 450 style: #(#style_toolwindow, #style_resizing, #style_sysmenu, #style_toolwindow)