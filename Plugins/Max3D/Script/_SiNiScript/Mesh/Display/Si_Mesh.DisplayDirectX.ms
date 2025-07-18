------------------------------------------------------------------
--  SiNi Software Example Show DirectX Material Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DisplayDirectX_Dlg)catch()

rollout _DisplayDirectX_Dlg "Show DirectX Material" width:150 height:40(
	button Select_Bt "Show DirectX Material" pos:[5,10] width:140 height:23
	
	on _DisplayDirectX_Dlg close do(
		Si_Mesh.DisplayDirectX NULL
	)
	
	on Select_Bt pressed do(
		Objs = selection as array
		Si_Mesh.DisplayDirectX Objs
	)
)

CreateDialog _DisplayDirectX_Dlg