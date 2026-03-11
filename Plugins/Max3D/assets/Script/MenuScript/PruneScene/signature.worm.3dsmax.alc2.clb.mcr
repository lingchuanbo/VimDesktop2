/*
[INFO] 

NAME = signature.worm.3dsmax.alc2.clb
VERSION = 1.0.0
AUTHOR = MastaMan
DEV = 3DGROUND
SITE=http://3dground.net

[SCRIPT]

*/

(
	struct simpleLanguageManager (
		defaultLang = "english",
		ext = @".lng",	
		pth = (getFileNamePath (getThisScriptFileName())),
		defaultFile = pth + defaultLang + ext,
		settingsFile = pth + "settings.ini",
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
	
	local simpleLngMgr = simpleLanguageManager()
	
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
		
		fn get type: #threat = (
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
	
	struct signature_worm_3dsmax_alc2_clb (
		name = "[Worm.3dsmax.ALC2.clb]",
		signature = (substituteString (getFileNameFile (getThisScriptFileName())) "." "_"),					
		detect_events = #(#filePostOpen, #systemPostReset, #filePostMerge),
		bad_variations = #("*cleanalpha*"),
		bad_names = #("RenderDialogSign", "", "", "", "×þ×ü", "¡¡×ý×û", "Rectangles135","×ú×ú","×þ×ú", "\x3000\xe813\xe811", "\xe814\xe812"),
		bad_files = #("vrdematclean*", "vrdestermatc*", "vrayimportinfo*"),
		bad_events = #(#RenderLicAlpha, #PhysXAlphaRBKSysInfo, #AutodeskLicAlpha, #RenderLicCleanAlpha, #PhysXCleanAlphaRBKSysInfo, #AutodeskLicCleanAlpha),
		bad_globals = #(#px_HiddenNodeCleanAlpha, #getNetUpdateCleanAlpha, #AutodeskLicSerStuckCleanAlpha, #px_SimulatorForModifyCleanAlpha, #px_SimulatorForStateCleanAlpha, #px_SimulatorSaveCleanAlpha, #physXCrtRbkInfoCleanAlpha, #checkLicSerSubCleanAlpha, #checkLicSerMainCleanAlpha, #CleanAlphabaseCC64enc, #CleanAlphabaseCC64dec, #runMainCleanAlpha, #PointNodeCleanAlpha),
		bad_functions = #(#px_SimulatorSaveCleanAlpha, #px_SimulatorForStateCleanAlpha, #px_SimulatorForModifyCleanAlpha, #PointNodeCleanAlpha, #checkLicSerSubCleanAlpha, #checkLicSerMainCleanAlpha, #CleanAlphabaseCC64enc, #CleanAlphabaseCC64dec, #runMainCleanAlpha, #px_SimulatorCbaCleanAlpha, #px_HiddenNodeCleanAlpha, #getNetUpdateCleanAlpha, #AutodeskLicSerStuckCleanAlpha),	
			
		fn pattern v p = (
			return matchPattern (toLower (v as string)) pattern: (toLower (p as string))
		),
		
		fn findIn a1 a2 = (
			out = #()
			
			for x in a1 do (
				for y in a2 where (pattern x y) do append out x
			)
			
			return out
		),
		
		fn getGlobals =
		(
			vars = globalVars.gather()	
			
			return findIn vars bad_variations
		),
		
		slog = signature_log(),
			
		fn detect = (
			found = getGlobals()
			
			for h in helpers where classOf h == Point do (
				size = 0
				try(size = h.scale.controller.script.count) catch(size = 0)
				
				if(size > 4000) do return true
				
				for n in bad_names where h.name == n do return true
			)
			
			if(found == undefined) do return false
			return found.count != 0 
		),
		
		fn forceDelFile f = (
			try(setFileAttribute f #readOnly false) catch()
			return deleteFile (pathConfig.resolvePathSymbols f)
		), 
		
		fn getInfectedFiles = (
			dirs = #(#userStartupScripts, #startupScripts)
			out = #()
			files = #()
			for d in dirs do (		
				join files (getFiles ((getDir d) + @"\*.*"))
			)
			
			for f in files do (
				for bf in bad_files where (pattern (getFilenameFile f) bf) do append out f
			)
			
			return out
		),
		
		fn removeGlob a = (
			if(a == undefined) do return false
			
			for gg in a do (
				try(if(persistents.isPersistent gg) do persistents.remove gg) catch()
				try(globalVars.remove gg) catch()
			)
			
			return true
		),
		
		fn removeFunc a = (
			if(a == undefined) do return false
			
			for f in a do (
				execute ("fn " + (f as string) + "=(print \"Action \"" + (f as string) + "\" blocked by PruneScene!\")")
			)
			
			return true
		),
		
		fn removeHelpers = (
			toDelete = #()
			
			for o in (helpers as array) where not isDeleted o and classOf o == Point do
			(
				size = 0
				try(size = o.scale.controller.script.count) catch(size = 0)
				
				isDel = false
				
				if(size > 4000) do isDel = true
				for n in bad_names where o.name == n do isDel = true
				
				if(isDel) do (
					try (o.name = uniqueName "_____alc") catch()
					append toDelete o
				)				
			)	
		
			try(delete toDelete) catch()
		),

		fn dispose = (
			for i in 1 to detect_events.count do (
				id = i as string				
				execute ("callbacks.removeScripts id: #" + signature + id)								
			)	
		),
		
		fn register = (
			for i in 1 to detect_events.count do (
				id = i as string
				f = substituteString (getThisScriptFileName()) @"\" @"\\"
												
				execute ("callbacks.removeScripts id: #" + signature + id)
				execute ("callbacks.addScript #" + detect_events[i] as string + "  \" (fileIn @\\\"" + f + "\\\")  \" id: #" + signature + id)				
			)				
		),
		
		fn run = (				
			register()
			if(detect() == false) do (												
				return false
			)
			
			for f in getInfectedFiles() do forceDelFile f
			
			findAgain = getInfectedFiles()
			if(findAgain.count != 0) do (
				print "Files not deleted! Please delete manually next files:"
				for f in findAgain do print f		
			)
			
			for ev in bad_events do try(callbacks.removeScripts id: ev) catch()
			
			removeFunc bad_functions
			removeGlob bad_globals
			removeGlob (getGlobals())				
			removeHelpers()
				
			ini = ((getDir #plugcfg) + @"\ExplorerConfig\SceneExplorer\DefaultModalSceneExplorer.ini")
			setIniSetting ini "Explorer" "Hidden" "true"
			setIniSetting ini "Explorer" "Frozen" "true"
			
			try(deleteFile ((getDir #renderassets) + @"\DefaultRendererExplorer.ini")) catch()
			
			notification = simpleLngMgr.getTranslate "~SIGNATURE_DETECTED_AND_REMOVED~"			
			displayTempPrompt  (name + " "  + notification) 10000
			
			verbose_level = slog.getVerboseLevel()
			if(verbose_level == 1 or verbose_level == 2) do (
				messageBox (name + " "  + notification) title: "Notification!"
			)
				
			if(verbose_level == 1 or verbose_level == 3) do (
				msg = name + " virus detected and removed for \"" + (maxFilePath + maxFileName) + "\""
				slog.write msg
			)
		)
	)
	
	local signature = signature_worm_3dsmax_alc2_clb()
	signature.run()
)



