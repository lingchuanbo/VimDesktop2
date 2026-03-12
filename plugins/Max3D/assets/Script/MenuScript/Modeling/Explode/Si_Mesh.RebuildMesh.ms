------------------------------------------------------------------
--  SiNi Software Example Rebuild Mesh Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _RebuildMesh_Dlg)catch()

rollout _RebuildMesh_Dlg "Rebuild New Mesh" width:150 height:40(
	button Select_Bt "Rebuild New Mesh" pos:[5,10] width:140 height:23
	
	on Select_Bt pressed do(
		Objs = selection as array
		Si_Mesh.RebuildMesh Objs
	)
)

CreateDialog _RebuildMesh_Dlg