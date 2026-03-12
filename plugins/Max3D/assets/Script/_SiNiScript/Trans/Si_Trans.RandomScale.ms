------------------------------------------------------------------
--  SiNi Software Example Random Scale Objects Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Open_RandomScale_Dlg)catch()
Global Objs #() 

rollout _Open_RandomScale_Dlg "Random Scale Objects" width:150 height:285(
	label Message_Lb "<Select Objects First>" pos:[15,10] width:190 height:15 
	button Select_Bt "Use Selected Objects" pos:[5,30] width:140 height:23 enabled:true
	spinner Min_X_Spn "Scale Min X: " pos:[18,60] type:#integer  fieldwidth:34 range:[0,100000,100] enabled:false
	spinner Max_X_Spn "Scale Max X: " pos:[14,80] type:#integer  fieldwidth:34 range:[0,100000,100] enabled:false
	spinner Min_Y_Spn "Scale Min Y: " pos:[19,100] type:#integer  fieldwidth:34 range:[0,100000,100] enabled:false
	spinner Max_Y_Spn "Scale Max Y: " pos:[15,120] type:#integer  fieldwidth:34 range:[0,100000,100] enabled:false
	spinner Min_Z_Spn "Scale Min Z: " pos:[18,140] type:#integer  fieldwidth:34 range:[0,100000,100] enabled:false
	spinner Max_Z_Spn "Scale Max Z: " pos:[14,160] type:#integer  fieldwidth:34 range:[0,100000,100] enabled:false
	button Scale_Bt "Scale Objects" pos:[5,180] width:140 height:23  enabled:false
	label HowTo_Lb "First select objects and press USE SELETED OBJS button.  Use spinners to randomly transform objects and Press SCALE OBJECTS button" pos:[3,210] width:145 height:70 
	
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
			Scale_Bt.enabled = false
			Message_Lb.text = "<Select Objects First>"
			clearSelection()
		)
	)
	
	on Scale_Bt pressed do(
		Si_Trans.RandomScale Objs Min_X_Spn.value Max_X_Spn.value Min_Y_Spn.value Max_Y_Spn.value Min_Z_Spn.value Max_Z_Spn.value
	)
	on Min_X_Spn changed val do Scale_Bt.enabled = true
	on Max_X_Spn changed val do  Scale_Bt.enabled = true
	on Min_Y_Spn changed val do  Scale_Bt.enabled = true
	on Max_Y_Spn changed val do  Scale_Bt.enabled = true
	on Min_Z_Spn changed val do Scale_Bt.enabled = true
	on Max_Z_Spn changed val do  Scale_Bt.enabled = true
)

CreateDialog _Open_RandomScale_Dlg