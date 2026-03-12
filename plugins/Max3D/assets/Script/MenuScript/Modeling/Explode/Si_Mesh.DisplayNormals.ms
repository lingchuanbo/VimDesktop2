------------------------------------------------------------------
--  SiNi Software Example Display Normals Material Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DisplayNormals_Dlg)catch()

rollout _DisplayNormals_Dlg "Display Normals Material" width:150 height:40(
	button Select_Bt "Display Normals Material" pos:[5,10] width:140 height:23
	
	on _DisplayNormals_Dlg close do(
		Si_Mesh.DisplayNormals NULL
	)
	
	on Select_Bt pressed do(
		Objs = selection as array
		Si_Mesh.DisplayNormals Objs
	)
)

CreateDialog _DisplayNormals_Dlg