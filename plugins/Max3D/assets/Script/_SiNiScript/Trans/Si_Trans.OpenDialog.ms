------------------------------------------------------------------
--  SiNi Software Example Open Jumble Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Open_Jumble_Dlg)catch()

rollout _Open_Jumble_Dlg "Open Jumble" width:150 height:40(
	button Open_Bt "Open Jumble" pos:[5,10] width:140 height:23
	
	on Open_Bt pressed do(
		Si_Trans.OpenDialog()
	)
)

CreateDialog _Open_Jumble_Dlg