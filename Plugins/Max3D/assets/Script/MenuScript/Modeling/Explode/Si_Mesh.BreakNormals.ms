------------------------------------------------------------------
--  SiNi Software Example Break Normals Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _BreakNormals_Dlg)catch()

rollout _BreakNormals_Dlg "Break Normals" width:150 height:40(
	button Normals_Bt "Break Normals" pos:[5,10] width:140 height:23
	
	on Normals_Bt pressed do(
		Objs = selection as array
		Si_Mesh.BreakNormals Objs 
	)
)

CreateDialog _BreakNormals_Dlg