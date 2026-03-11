------------------------------------------------------------------
--  SiNi Software Example Delete Groups Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Open_DeleteGroups_Dlg)catch()

rollout _Open_DeleteGroups_Dlg "Delete Groups" width:150 height:70(
	button Open_Bt "Delete Groups" pos:[5,10] width:140 height:23
	label _mesage_chk "" pos:[10,40] width:140 height:23
	
	on Open_Bt pressed do(
		local RemoveAmount = Si_Clean.DeleteGroups()
		_mesage_chk.text = ("Delete " + (RemoveAmount as string) + " Groups")
	)
)

CreateDialog _Open_DeleteGroups_Dlg