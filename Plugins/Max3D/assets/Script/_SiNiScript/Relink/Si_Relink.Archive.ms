------------------------------------------------------------------
--  SiNi Software Relink Files Maxscript Archive Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Archive_Dlg)catch()
Global RelinkDir = undefined

rollout _Archive_Dlg "Archive Files Maxscript Sample" width:350 height:95(
	checkbox Tex_Ck "Textures" pos:[30,10] width:110 height:18 checked:true
	checkbox XRef_Ck "XRef Scenes" pos:[180,10] width:110 height:18 checked:true
	checkbox Proxy_Ck "All Proxy Types" pos:[30,30] width:110 height:18 checked:true
	checkbox PRT_Ck "Caches / Simulations" pos:[180,30] width:120 height:18 checked:true
	label _Path_lb "Select Archive Path" pos:[10,60] width:240 height:23 style_sunkenedge:true
	button btn_browse "..." pos:[260,60] width:40 height:23
	button btn_Archive "Archive" pos:[305,60] width:40 height:23 enabled:false
	
	on btn_browse pressed do (
		RelinkDir = getSavePath caption:"Select Archive Directory..."
		if RelinkDir != undefined do ( 
			_Path_lb.text = RelinkDir 
			btn_Relink.enabled = true
		)
	)
	
	on btn_Archive pressed do (
		Si_Relink.Archive RelinkDir Tex_Ck.checked XRef_Ck.checked Proxy_Ck.checked PRT_Ck.checked
	)
)

CreateDialog _Archive_Dlg