------------------------------------------------------------------
--  SiNi Software Example Display Open Objects Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DisplayOpen_Dlg)catch()

rollout _DisplayOpen_Dlg "Display Open Objects" width:150 height:40(
	button Select_Bt "Display Open Objects" pos:[5,10] width:140 height:23
	
	on _DisplayOpen_Dlg close do(
		Si_Mesh.DisplayOpen NULL
	)
	
	on Select_Bt pressed do(
		Objs = selection as array
		Si_Mesh.DisplayOpen Objs
	)
)

CreateDialog _DisplayOpen_Dlg