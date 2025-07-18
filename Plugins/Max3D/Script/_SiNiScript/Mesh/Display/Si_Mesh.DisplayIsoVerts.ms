------------------------------------------------------------------
--  SiNi Software Example Objects with ISO Verts Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DisplayIsoVerts_Dlg)catch()

rollout _DisplayIsoVerts_Dlg "Show Objects with ISO Verts" width:150 height:40(
	button Select_Bt "Show Objects with ISO Verts" pos:[5,10] width:140 height:23
	
	on _DisplayIsoVerts_Dlg close do(
		Si_Mesh.DisplayIsoVerts NULL
	)
	
	on Select_Bt pressed do(
		Objs = selection as array
		Si_Mesh.DisplayIsoVerts Objs
	)
)

CreateDialog _DisplayIsoVerts_Dlg