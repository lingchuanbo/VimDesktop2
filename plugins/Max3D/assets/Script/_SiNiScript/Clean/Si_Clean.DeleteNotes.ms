------------------------------------------------------------------
--  SiNi Software Example Delete Note Tracks Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Open_DeleteNotes_Dlg)catch()

rollout _Open_DeleteNotes_Dlg "Delete Note Tracks" width:150 height:70(
	button Open_Bt "Delete Note Tracks" pos:[5,10] width:140 height:23
	label _mesage_chk "" pos:[10,40] width:140 height:23
	
	on Open_Bt pressed do(
		local RemoveAmount = Si_Clean.DeleteNotes()
		_mesage_chk.text = ("Delete " + (RemoveAmount as string) + " Note Tracks")
	)
)

CreateDialog _Open_DeleteNotes_Dlg