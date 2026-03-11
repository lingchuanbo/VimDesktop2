------------------------------------------------------------------
--  SiNi Software Example Delete ISO Verts Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DeleteIsoVerts_Dlg)catch()

rollout _DeleteIsoVerts_Dlg "Delete ISO Verts" width:150 height:40(
	button Select_Bt "Delete ISO Verts" pos:[5,10] width:140 height:23
	
	on Select_Bt pressed do(
		Objs = selection as array
		
		Message = Si_Mesh.DeleteIsoVerts Objs
		if Message == false then
			Print "No ISO Verts found"
		else
			Print "Removed ISO Verts"
	)
)

CreateDialog _DeleteIsoVerts_Dlg