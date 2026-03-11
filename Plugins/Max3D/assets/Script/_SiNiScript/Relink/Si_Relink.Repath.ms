------------------------------------------------------------------
--  SiNi Software Repath Files Maxscript Sample Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _RepathFiles_Dlg)catch()
Global RepathDir = undefined

rollout _RepathFiles_Dlg "Repath Files Maxscript Sample" width:500 height:45(
	label _Path_lb "Select search Path" pos:[10,10] width:390 height:23 style_sunkenedge:true
	button btn_browse "..." pos:[405,10] width:40 height:23
	button btn_Repath "Repath" pos:[450,10] width:45 height:23 enabled:false
	
	on btn_browse pressed do (
		RepathDir = getSavePath caption:"Select Repath Directory..."
		if RepathDir != undefined do ( 
			_Path_lb.text = RepathDir 
			btn_Repath.enabled = true
		)
	)
	
	on btn_Repath pressed do (
		Si_Relink.Repath RepathDir false
	)
)

CreateDialog _RepathFiles_Dlg 