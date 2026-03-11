------------------------------------------------------------------
--  SiNi Software Example weld Objects Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Weld_Dlg)catch()

rollout _Weld_Dlg "Weld Objects" width:150 height:60(
	spinner _Weld_Spn "Weld Threshold: " pos:[10,10] type:#float fieldwidth:38 range:[0,100,0.001]
	button Weld_Bt "Weld Geometry" pos:[5,30] width:140 height:23
	
	on Weld_Bt pressed do(
		Objs = selection as array
		Si_Mesh.Weld Objs _Weld_Spn.value
	)
)

CreateDialog _Weld_Dlg