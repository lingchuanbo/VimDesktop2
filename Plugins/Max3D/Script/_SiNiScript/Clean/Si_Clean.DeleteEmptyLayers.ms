------------------------------------------------------------------
--  SiNi Software Example Delete Empty Layers Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Open_DeleteEmptyLayers_Dlg)catch()

rollout _Open_DeleteEmptyLayers_Dlg "Delete Empty Layers" width:150 height:70(
	button Open_Bt "Delete Empty Layers" pos:[5,10] width:140 height:23
	label _mesage_chk "" pos:[10,40] width:140 height:23
	
	on Open_Bt pressed do(
		local RemoveAmount = Si_Clean.DeleteEmptyLayers()
		_mesage_chk.text = ("Delete " + (RemoveAmount as string) + " Empty Layers")
	)
)

CreateDialog _Open_DeleteEmptyLayers_Dlg