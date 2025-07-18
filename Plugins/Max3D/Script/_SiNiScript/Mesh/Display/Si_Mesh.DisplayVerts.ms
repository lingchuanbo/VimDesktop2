------------------------------------------------------------------
--  SiNi Software Example Show/Hide verts Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DisplayVerts_Dlg)catch()

rollout _DisplayVerts_Dlg "Show/Hide verts " width:150 height:40(
	button Select_Bt "Show/Hide Verts " pos:[5,10] width:140 height:23
	
	on _DisplayVerts_Dlg close do(
		Si_Mesh.DisplayVerts NULL
	)
	
	on Select_Bt pressed do(
		Objs = selection as array
		Si_Mesh.DisplayVerts Objs
	)
)

CreateDialog _DisplayVerts_Dlg