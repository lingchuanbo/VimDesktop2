------------------------------------------------------------------
--  SiNi Software Repath Files Maxscript Sample Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _ExtRepathFiles_Dlg)catch()
Global MaxFileDir = undefined
Global RepathDir = undefined

rollout _ExtRepathFiles_Dlg "Repath Files External Max Maxscript Sample" width:500 height:70(
	label _MaxFile_lb "Select Max File" pos:[10,10] width:390 height:23 style_sunkenedge:true
	button btn_browseMaxFile "..." pos:[405,10] width:40 height:23
	label _Path_lb "Select search Path" pos:[10,40] width:390 height:23 style_sunkenedge:true
	button btn_browse "..." pos:[405,40] width:40 height:23
	button btn_Repath "Repath" pos:[450,40] width:45 height:23 enabled:false
	
	on btn_browseMaxFile pressed do (
		MaxFileDir = getOpenFileName caption:"Select Max file..." types:"Max file(*.max)|*.max|All|*.*|"
		if MaxFileDir != undefined do ( 
			_MaxFile_lb.text = MaxFileDir 
			if(MaxFileDir != undefined and RepathDir != undefined) then btn_Repath.enabled = true
		)
	)
	
	on btn_browse pressed do (
		RepathDir = getSavePath caption:"Select Repath Directory..."
		if RepathDir != undefined do ( 
			_Path_lb.text = RepathDir 
			if(MaxFileDir != undefined and RepathDir != undefined) then btn_Repath.enabled = true
		)
	)
	
	on btn_Repath pressed do (
		Si_Relink.RepathMaxFile MaxFileDir RepathDir
	)
)

CreateDialog _ExtRepathFiles_Dlg 