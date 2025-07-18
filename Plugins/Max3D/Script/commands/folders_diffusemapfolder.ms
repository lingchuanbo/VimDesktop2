
if selection.count==1 do 
	(
		try 
			(
				if selection[1].material!=undefined and selection[1].material.diffusemap!=undefined and selection[1].material.diffusemap.bitmap!=undefined then
					(
						arr_path=filterstring (selection[1].material.diffusemap.bitmap as string) ":"
						d_path=arr_path[2]+":"+arr_path[3]
						d_path= getFileNamePath d_path
						print d_path
						ShellLaunch "explorer.exe" d_path
						) else 
						(
							messagebox "Selected object don't have diffuse map"
							)
				) catch 
				(
					messagebox "something wrong =)"
					) 
		)
