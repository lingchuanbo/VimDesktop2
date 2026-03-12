------------------------------------------------------------------
--  SiNi Software Example Display object Mapping Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DisplayMapping_Dlg)catch()

rollout _DisplayMapping_Dlg "Display Object Mapping" width:150 height:40(
	button Select_Bt "Display Object Mapping" pos:[5,10] width:140 height:23
	
	on _DisplayMapping_Dlg close do(
		Si_Mesh.DisplayOpen NULL
	)
	
	on Select_Bt pressed do(
		Objs = selection as array
		Si_Mesh.DisplayMapping Objs
	)
)

CreateDialog _DisplayMapping_Dlg