------------------------------------------------------------------
--  SiNi Software Example Objects Find Double Faces Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DisplayDblFaces_Dlg)catch()

rollout _DisplayDblFaces_Dlg "Find Double Faces" width:150 height:40(
	button Select_Bt "Find Double Faces" pos:[5,10] width:140 height:23
	
	on _DisplayDblFaces_Dlg close do(
		Si_Mesh.RestoreWirecolour()
	)
	
	on Select_Bt pressed do(
		Objs = selection as array
		Si_Mesh.DisplayDblFaces Objs
	)
)

CreateDialog _DisplayDblFaces_Dlg