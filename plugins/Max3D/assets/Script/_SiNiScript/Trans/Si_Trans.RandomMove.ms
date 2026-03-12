------------------------------------------------------------------
--  SiNi Software Example Random Move Objects Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Open_RandomMove_Dlg)catch()
Global Objs #() 

rollout _Open_RandomMove_Dlg "Random Move Objects" width:150 height:285(
	label Message_Lb "<Select Objects First>" pos:[15,10] width:190 height:15 
	button Select_Bt "Use Selected Objects" pos:[5,30] width:140 height:23 enabled:true
	spinner Min_X_Spn "Move Min X: " pos:[8,60] type:#float fieldwidth:60 range:[-10000,10000,0] enabled:false
	spinner Max_X_Spn "Move Max X: " pos:[4,80] type:#float fieldwidth:60 range:[-10000,10000,0] enabled:false
	spinner Min_Y_Spn "Move Min Y: " pos:[9,100] type:#float fieldwidth:60 range:[-10000,10000,0] enabled:false
	spinner Max_Y_Spn "Move Max Y: " pos:[5,120] type:#float fieldwidth:60 range:[-10000,10000,0] enabled:false
	spinner Min_Z_Spn "Move Min Z: " pos:[8,140] type:#float fieldwidth:60 range:[-10000,10000,0] enabled:false
	spinner Max_Z_Spn "Move Max Z: " pos:[3,160] type:#float fieldwidth:60 range:[-10000,10000,0] enabled:false
	button Move_Bt "Move Objects" pos:[5,180] width:140 height:23  enabled:false
	label HowTo_Lb "First select objects and press USE SELETED OBJS button.  Use spinners to randomly transform objects and Press MOVE OBJECTS button" pos:[3,210] width:145 height:70 
	
	on Select_Bt pressed do(
		Objs = selection as array
		if Objs.count > 0 then(
			Min_X_Spn.enabled = true
			Max_X_Spn.enabled = true
			Min_Y_Spn.enabled = true
			Max_Y_Spn.enabled = true
			Min_Z_Spn.enabled = true
			Max_Z_Spn.enabled = true
			Message_Lb.text = ((Objs.count as string) + " Total Objects")
			clearSelection()
		)
		else(
			Min_X_Spn.enabled = false
			Max_X_Spn.enabled = false
			Min_Y_Spn.enabled = false
			Max_Y_Spn.enabled = false
			Min_Z_Spn.enabled = false
			Max_Z_Spn.enabled = false
			Move_Bt.enabled = false
			Message_Lb.text = "<Select Objects First>"
			clearSelection()
		)
	)
	
	on Move_Bt pressed do(
		Si_Trans.RandomMove Objs Min_X_Spn.value Max_X_Spn.value Min_Y_Spn.value Max_Y_Spn.value Min_Z_Spn.value Max_Z_Spn.value
	)
	on Min_X_Spn changed val do Move_Bt.enabled = true
	on Max_X_Spn changed val do  Move_Bt.enabled = true
	on Min_Y_Spn changed val do  Move_Bt.enabled = true
	on Max_Y_Spn changed val do  Move_Bt.enabled = true
	on Min_Z_Spn changed val do Move_Bt.enabled = true
	on Max_Z_Spn changed val do  Move_Bt.enabled = true
)

CreateDialog _Open_RandomMove_Dlg