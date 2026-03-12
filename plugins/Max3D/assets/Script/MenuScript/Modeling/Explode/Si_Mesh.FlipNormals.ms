------------------------------------------------------------------
--  SiNi Software Example Flip Normals Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _FlipNormals_Dlg)catch()

rollout _FlipNormals_Dlg "Flip Normals" width:150 height:40(
	button Normals_Bt "Flip Normals" pos:[5,10] width:140 height:23
	
	on Normals_Bt pressed do(
		Objs = selection as array
		Si_Mesh.FlipNormals Objs 
	)
)

CreateDialog _FlipNormals_Dlg