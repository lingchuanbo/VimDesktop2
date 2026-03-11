------------------------------------------------------------------
--  SiNi Software Example Select Green Objects Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _SelectGreen_Dlg)catch()

rollout _SelectGreen_Dlg "Select Green Objects" width:150 height:40(
	button Select_Bt "Select Green Objects" pos:[5,10] width:140 height:23
	
	on Select_Bt pressed do(
		Objs = Si_Mesh.SelectGreen()
		Print ("Selected " + (Objs.count as string) + " Objects")
	)
)

CreateDialog _SelectGreen_Dlg