------------------------------------------------------------------
--  SiNi Software Example AutoSmooth Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _AutoSmooth_Dlg)catch()

rollout _AutoSmooth_Dlg "AutoSmooth Object" width:150 height:40(
	button Smooth_Bt "AutoSmooth Object" pos:[5,10] width:140 height:23
	
	on Smooth_Bt pressed do(
		Objs = selection as array
		Si_Mesh.AutoSmooth Objs
	)
)

CreateDialog _AutoSmooth_Dlg