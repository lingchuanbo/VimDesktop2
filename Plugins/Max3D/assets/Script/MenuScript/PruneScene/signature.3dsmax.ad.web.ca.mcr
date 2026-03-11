/*
[INFO] 

NAME = signature.3dsmax.ad.web.ca
VERSION = 1.1.0
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
    
    struct signature_3dsmax_ad_web_ca (
        name = "[AD.3dsmax.Web.CA]",
        signature = (substituteString (getFileNameFile (getThisScriptFileName())) "." "_"),
        detect_events = #(#filePostOpen, #systemPostReset, #filePostMerge),
        find_ca_name = #(#example, #example1),
        bad_text = #("3dsmj.com", "3d.znzmo.com"),
        
        slog = signature_log(),

        fn pattern v p = (
            return matchPattern (toLower (v as string)) pattern: (toLower (p as string))
        ),
            
        fn detect = (
            w = #(rootScene, rootNode)
            cc = 0
            for i in w do cc += custAttributes.count i
            if(cc == 0) do return false
            
            for f in w do (
                c = custAttributes.count f
                for i in 1 to c do (
                    local ca = custAttributes.getDef f 1
                    if(findItem find_ca_name ca.name != 0) do (
                        return true
                    )
                )
            )
            
            return false
        ),
        
        fn forceDelFile f = (
            try(setFileAttribute f #readOnly false
            deleteFile f) catch()
        ), 
            
        fn dispose = (
            for i in 1 to detect_events.count do (
                id = i as string
                execute ("callbacks.removeScripts id: #" + signature + id)
            )
        ),
        
        fn removeCA names = (
            for nn in names do (
                for i in custattributes.getSceneDefs() where pattern i.name nn do (
                    for ii in custAttributes.getDefInstances i do ( 
                        for o in refs.dependents ii do (
                            custAttributes.delete o (custAttributes.getDef o 1)
                        )
                        try(custAttributes.deleteDef ii) catch()
                    )
                    try(custAttributes.deleteDef i) catch()
                )
            )
        ),
        
        fn removeText txt = (
            toDelete = #()
            for i in objects where classOf i == Text and not isDeleted i and isValidNode i do (
                for t in txt where (findString i.text t) != undefined do append toDelete i
            )
            
            try(delete toDelete) catch()
        ),
        
        fn run = (
			displayTempPrompt  (simpleLngMgr.getTranslate "~SIGNATURE_SUCCESS_NO_VIRUS~") 10000
			
            for i in 1 to detect_events.count do (
                id = i as string
                f = substituteString (getThisScriptFileName()) @"\" @"\\"
                                                
                execute ("callbacks.removeScripts id: #" + signature + id)
                execute ("callbacks.addScript #" + detect_events[i] as string + "  \" (fileIn @\\\"" + f + "\\\")  \" id: #" + signature + id)
            )
            
            if(detect() == false) do (
                return false
            )
            
            removeCA find_ca_name
            removeText bad_text
        
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
    
    local signature = signature_3dsmax_ad_web_ca()
    signature.run()
)



