------------------------------------------------------------------
--  SiNi Software Example Open Sculpt Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Open_Sculpt_Dlg)catch()

rollout _Open_Sculpt_Dlg "Open Sculpt" width:150 height:40(
	button Open_Bt "Open Sculpt" pos:[5,10] width:140 height:23
	
	on Open_Bt pressed do(
		Si_Mesh.OpenDialog()
	)
)

CreateDialog _Open_Sculpt_Dlg