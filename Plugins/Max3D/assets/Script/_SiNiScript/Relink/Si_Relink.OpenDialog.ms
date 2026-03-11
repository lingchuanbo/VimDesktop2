------------------------------------------------------------------
--  SiNi Software Example Open Unite Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Open_Unite_Dlg)catch()

rollout _Open_Unite_Dlg "Open Unite" width:150 height:40(
	button Open_Bt "Open Unite" pos:[5,10] width:140 height:23
	
	on Open_Bt pressed do(
		Si_Relink.OpenDialog()
	)
)

CreateDialog _Open_Unite_Dlg