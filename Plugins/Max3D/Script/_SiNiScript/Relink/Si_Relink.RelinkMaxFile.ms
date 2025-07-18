------------------------------------------------------------------
--  SiNi Software Relink Files Maxscript Sample Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _ExtRelinkFiles_Dlg)catch()
Global MaxFileDir = undefined
Global RelinkDir = undefined

rollout _ExtRelinkFiles_Dlg "Relink Files External Max File Maxscript Sample" width:500 height:70(
	label _MaxFile_lb "Select Max File" pos:[10,10] width:390 height:23 style_sunkenedge:true
	button btn_browseMaxFile "..." pos:[410,10] width:40 height:23
	label _Path_lb "Select search Path" pos:[10,40] width:390 height:23 style_sunkenedge:true
	button btn_browse "..." pos:[410,40] width:40 height:23
	button btn_Relink "Relink" pos:[455,40] width:40 height:23 enabled:false
	
	on btn_browseMaxFile pressed do (
		MaxFileDir = getOpenFileName caption:"Select Max file..." types:"Max file(*.max)|*.max|All|*.*|"
		if MaxFileDir != undefined do ( 
			_MaxFile_lb.text = MaxFileDir 
			if(MaxFileDir != undefined and RelinkDir != undefined) then btn_Relink.enabled = true
		)
	)
	
	on btn_browse pressed do (
		RelinkDir = getSavePath caption:"Select Relink Directory..."
		if RelinkDir != undefined do ( 
			_Path_lb.text = RelinkDir 
			if(MaxFileDir != undefined and RelinkDir != undefined) then btn_Relink.enabled = true
		)
	)
	
	on btn_Relink pressed do (
		Si_Relink.RelinkMaxFile MaxFileDir RelinkDir
	)
)

CreateDialog _ExtRelinkFiles_Dlg 