if (getfiles (symbolicPaths.expandFileName "$maxScripts\\total_commander.ini")).count == 0 then
	(
		setinisetting (symbolicPaths.expandFileName "$maxScripts\\total_commander.ini") "TotalCommander" "1" "empty"
	)
	
if maxfilepath != "" then
	(
		-- maxfilename
		get_open_dir = ("\"" + maxfilepath )
		ShellLaunch getTCExePath ("/O /S /L=" + get_open_dir)
		Print("TC路径是:"+getTCExePath)
		Print("打开目录为:"+get_open_dir)
	)
	else
	(
		messagebox "请先保存文件！"
	)