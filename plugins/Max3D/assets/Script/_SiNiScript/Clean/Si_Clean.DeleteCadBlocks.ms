------------------------------------------------------------------
--  SiNi Software Example Delete Cad Blocks Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Open_DeleteCadBlocks_Dlg)catch()

rollout _Open_DeleteCadBlocks_Dlg "Delete Cad Blocks" width:150 height:70(
	button Open_Bt "Delete Cad Blocks" pos:[5,10] width:140 height:23
	label _mesage_chk "" pos:[10,40] width:140 height:23
	
	on Open_Bt pressed do(
		local RemoveAmount = Si_Clean.DeleteCadBlocks()
		_mesage_chk.text = ("Removed " + (RemoveAmount as string) + " blocks")
	)
)

CreateDialog _Open_DeleteCadBlocks_Dlg