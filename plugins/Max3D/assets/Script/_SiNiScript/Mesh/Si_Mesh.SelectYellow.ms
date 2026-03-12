------------------------------------------------------------------
--  SiNi Software Example Select Red Objects Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _SelectYellow_Dlg)catch()

rollout _SelectYellow_Dlg "Select Yellow Objects" width:150 height:40(
	button Select_Bt "Select Yellow Objects" pos:[5,10] width:140 height:23
	
	on Select_Bt pressed do(
		Objs = Si_Mesh.SelectYellow()
		Print ("Selected " + (Objs.count as string) + " Objects")
	)
)

CreateDialog _SelectYellow_Dlg