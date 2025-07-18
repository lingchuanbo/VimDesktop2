------------------------------------------------------------------
--  SiNi Software Example Delete Double Faces Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DeleteDblFaces_Dlg)catch()

rollout _DeleteDblFaces_Dlg "Delete Double Faces" width:150 height:40(
	button Select_Bt "Delete Double Faces" pos:[5,10] width:140 height:23
	
	on Select_Bt pressed do(
		Objs = selection as array
		Message = Si_Mesh.DeleteDblFaces Objs
		if Message == false then
			Print "No Double Faces found"
		else
			Print "Removed Double Faces"
	)
)

CreateDialog _DeleteDblFaces_Dlg 