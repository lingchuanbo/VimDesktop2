if (getfiles (symbolicPaths.expandFileName "$maxScripts\\total_commander.ini")).count == 0 then
	(
		setinisetting (symbolicPaths.expandFileName "$maxScripts\\total_commander.ini") "TotalCommander" "1" "empty"
	)

if rendOutputFilename != "" then
	(
		get_open_dir = ("\"" + rendOutputFilename + "\"")
		ShellLaunch getTCExePath ("/O /S /L=" + get_open_dir)
	)
	else
	(
		messagebox "渲染输出目录为空！"
	)