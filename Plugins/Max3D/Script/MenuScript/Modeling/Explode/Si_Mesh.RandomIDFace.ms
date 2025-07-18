------------------------------------------------------------------
--  SiNi Software Example weld Objects Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _RandomIDFace_Dlg)catch()

rollout _RandomIDFace_Dlg "Random Face IDs" width:150 height:60(
	spinner _Random_Spn "Random Count: " pos:[10,10] type:#integer fieldwidth:38 range:[0,100,5]
	button Rand_Bt "Random Face IDs" pos:[5,30] width:140 height:23
	
	on Rand_Bt pressed do(
		Objs = selection as array
		Si_Mesh.RandomIDFace Objs _Random_Spn.value
	)
)

CreateDialog _RandomIDFace_Dlg