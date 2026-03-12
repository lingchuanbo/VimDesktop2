------------------------------------------------------------------
--  SiNi Software Example Show Multi-Sub Material Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DisplayMultiSub_Dlg)catch()

rollout _DisplayMultiSub_Dlg "Show Multi-Sub Material" width:150 height:40(
	button Select_Bt "Show Multi-Sub Material" pos:[5,10] width:140 height:23
	
	on _DisplayMultiSub_Dlg close do(
		Si_Mesh.RestoreWirecolour()
	)
	
	on Select_Bt pressed do(
		Objs = selection as array
		Si_Mesh.DisplayMultiSub Objs
	)
)

CreateDialog _DisplayMultiSub_Dlg