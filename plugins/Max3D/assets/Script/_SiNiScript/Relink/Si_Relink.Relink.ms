------------------------------------------------------------------
--  SiNi Software Relink Files Maxscript Sample Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _RelinkFiles_Dlg)catch()
Global RelinkDir = undefined

rollout _RelinkFiles_Dlg "Relink Files Maxscript Sample" width:500 height:45(
	label _Path_lb "Select search Path" pos:[10,10] width:390 height:23 style_sunkenedge:true
	button btn_browse "..." pos:[410,10] width:40 height:23
	button btn_Relink "Relink" pos:[455,10] width:40 height:23 enabled:false
	
	on btn_browse pressed do (
		RelinkDir = getSavePath caption:"Select Relink Directory..."
		if RelinkDir != undefined do ( 
			_Path_lb.text = RelinkDir 
			btn_Relink.enabled = true
		)
	)
	
	on btn_Relink pressed do (
		Si_Relink.Relink RelinkDir false
	)
)

CreateDialog _RelinkFiles_Dlg 