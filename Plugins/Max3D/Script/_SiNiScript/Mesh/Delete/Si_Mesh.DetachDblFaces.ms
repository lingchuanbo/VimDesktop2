------------------------------------------------------------------
--  SiNi Software Example Detach Double Faces Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DetachDblFaces_Dlg)catch()

rollout _DetachDblFaces_Dlg "Detach Double Faces" width:150 height:40(
	button Select_Bt "Detach Double Faces" pos:[5,10] width:140 height:23
	
	on Select_Bt pressed do(
		Objs = selection as array
		Message = Si_Mesh.DetachDblFaces Objs
		if Message == false then
			Print "No Double Faces found"
		else
			Print "Detached Double Faces"
	)
)

CreateDialog _DetachDblFaces_Dlg 