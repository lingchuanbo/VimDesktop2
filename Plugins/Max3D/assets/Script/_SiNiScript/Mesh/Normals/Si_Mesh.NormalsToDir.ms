------------------------------------------------------------------
--  SiNi Software Example Normals To Pivot Dir Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _NormalsToDir_Dlg)catch()

rollout _NormalsToDir_Dlg "Normals To Pivot Dir" width:150 height:40(
	button Normals_Bt "Normals To Pivot Dir" pos:[5,10] width:140 height:23
	
	on Normals_Bt pressed do(
		Objs = selection as array
		Si_Mesh.NormalsToDir Objs 
	)
)

CreateDialog _NormalsToDir_Dlg