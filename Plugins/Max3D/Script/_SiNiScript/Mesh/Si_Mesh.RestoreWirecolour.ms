------------------------------------------------------------------
--  SiNi Software Example Restore Wirecolour Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _RestoreWirecolour_Dlg)catch()

rollout _RestoreWirecolour_Dlg "Restore Wirecolour" width:150 height:40(
	button Wirecolour_Bt "Restore Wirecolour Scene" pos:[5,10] width:140 height:23
	
	on Wirecolour_Bt pressed do(
		Si_Mesh.RestoreWirecolour()
	)
)

CreateDialog _RestoreWirecolour_Dlg