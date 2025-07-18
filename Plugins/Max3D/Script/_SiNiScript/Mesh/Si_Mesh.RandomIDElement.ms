------------------------------------------------------------------
--  SiNi Software Example Random Element IDs Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _RandomIDElement_Dlg)catch()

rollout _RandomIDElement_Dlg "Random Element IDs" width:150 height:60(
	spinner _Random_Spn "Random Count: " pos:[10,10] type:#integer fieldwidth:38 range:[0,100,5]
	button Rand_Bt "Random Element IDs" pos:[5,30] width:140 height:23
	
	on Rand_Bt pressed do(
		Objs = selection as array
		Si_Mesh.RandomIDElement Objs _Random_Spn.value
	)
)

CreateDialog _RandomIDElement_Dlg