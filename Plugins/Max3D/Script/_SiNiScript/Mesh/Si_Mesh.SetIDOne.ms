------------------------------------------------------------------
--  SiNi Software Example All Mat IDs To 1 Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _SetIDOne_Dlg)catch()

rollout _SetIDOne_Dlg "All Mat IDs To 1" width:150 height:40(
	button ToOne_Bt "All Mat IDs To 1" pos:[5,10] width:140 height:23
	
	on ToOne_Bt pressed do(
		Objs = selection as array
		Si_Mesh.SetIDOne Objs
	)
)

CreateDialog _SetIDOne_Dlg