------------------------------------------------------------------
--  SiNi Software Example Display Smoothing Material Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DisplaySmoothing_Dlg)catch()

rollout _DisplaySmoothing_Dlg "Display Smoothing Material" width:150 height:40(
	button Select_Bt "Display Smoothing Material" pos:[5,10] width:140 height:23
	
	on _DisplaySmoothing_Dlg close do(
		Si_Mesh.DisplaySmoothing NULL
	)
	
	on Select_Bt pressed do(
		Objs = selection as array
		Si_Mesh.DisplaySmoothing Objs
	)
)

CreateDialog _DisplaySmoothing_Dlg 