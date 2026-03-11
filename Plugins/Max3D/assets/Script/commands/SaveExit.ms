if maxfilepath != "" then
	(
		maxfilepaths =maxfilepath + maxfilename 
        saveMaxFile(maxfilepaths)
        quitMax()
	)
	else
	(
		messagebox "请先保存文件！"
	)