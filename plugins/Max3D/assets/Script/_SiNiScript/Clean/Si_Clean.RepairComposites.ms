------------------------------------------------------------------
--  SiNi Software Example Repair linked Composites Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Open_RepairComposites_Dlg)catch()

rollout _Open_RepairComposites_Dlg "Repair linked Composites" width:150 height:70(
	button Open_Bt "Repair linked Composites" pos:[5,10] width:140 height:23
	label _mesage_chk "" pos:[10,40] width:140 height:23
	
	on Open_Bt pressed do(
		local RemoveAmount = Si_Clean.RepairComposites()
		_mesage_chk.text = ("Repaired " + (RemoveAmount as string) + " Composites")
	)
)

CreateDialog _Open_RepairComposites_Dlg