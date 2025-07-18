------------------------------------------------------------------
--  SiNi Software Clean Files Maxscript Sample Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _CleanFiles_Dlg)catch()
Global MaxFileDir = undefined

rollout _CleanFiles_Dlg "Relink Files External Max File Maxscript Sample" width:500 height:45(
	label _MaxFile_lb "Select Max File" pos:[10,10] width:390 height:23 style_sunkenedge:true
	button btn_browseMaxFile "..." pos:[410,10] width:40 height:23
	button btn_Relink "Clean" pos:[455,10] width:40 height:23 enabled:false
	
	on btn_browseMaxFile pressed do (
		MaxFileDir = getOpenFileName caption:"Select Max file..." types:"Max file(*.max)|*.max|All|*.*|"
		if MaxFileDir != undefined do ( 
			_MaxFile_lb.text = MaxFileDir 
			btn_Relink.enabled = true
		)
	)
	
	on btn_Relink pressed do (
		Si_Relink.CleanMaxFile MaxFileDir #()
	)
)

CreateDialog _CleanFiles_Dlg 