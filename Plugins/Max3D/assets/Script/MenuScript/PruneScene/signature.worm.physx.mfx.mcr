/*
[INFO] 

NAME = signature.worm.physx.mfx
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
	
	struct signature_worm_3dsmax_physx_mfx (
		name = "[Worm.3dsmax.PhysX.mfx]",
		signature = (substituteString (getFileNameFile (getThisScriptFileName())) "." "_"),				
		detect_events = #(#filePostOpen, #systemPostReset, #filePostMerge),
		remove_events = #(#PhysXPluginMfx),
		remove_globals = #(#PhysXPluginMfx, #PhysXPluginGup),
		remove_files = #("PhysXPluginStl.ms", "PhysXPluginStl.mse"),
		
		slog = signature_log(),		
		
		fn pattern v p = (
			return matchPattern (toLower (v as string)) pattern: (toLower (p as string))
		),			
			
		fn detect = (
			return try(globalVars.isGlobal #PhysXPluginMfx) catch(false)
		),
		
		fn forceDelFile f = (
			try(setFileAttribute f #readOnly false) catch()
			return deleteFile (pathConfig.resolvePathSymbols f)
		), 
		
		fn getInfectedFiles = (
			dirs = #(#userStartupScripts, #startupScripts)
			out = #()
			for d in dirs do 
			(		
				files = getFiles ((getDir d) + @"\*.*")
				for find in remove_files do (
					for f in files where (findString (toLower f) (toLower find) != undefined) do append out f
				)
			)
			
			return out
		),
		
		fn removeGlobal g = (
			try(if(persistents.isPersistent g) do persistents.remove g) catch()
			try(globalVars.remove g) catch()
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
			for ev in remove_events do try(callbacks.removeScripts id: ev) catch()
			for g in remove_globals do removeGlobal g
			
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
	
	local signature = signature_worm_3dsmax_physx_mfx()
	signature.run()
)



