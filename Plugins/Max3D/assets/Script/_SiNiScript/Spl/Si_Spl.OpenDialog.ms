------------------------------------------------------------------
--  SiNi Software Example Open Scribe Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Open_Scribe_Dlg)catch()

rollout _Open_Scribe_Dlg "Open Scribe" width:150 height:40(
	button Open_Bt "Open Scribe" pos:[5,10] width:140 height:23
	
	on Open_Bt pressed do(
		Si_Spl.OpenDialog()
	)
)

CreateDialog _Open_Scribe_Dlg