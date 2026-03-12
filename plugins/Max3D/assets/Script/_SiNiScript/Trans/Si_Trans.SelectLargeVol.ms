------------------------------------------------------------------
--  SiNi Software Example Random Select Objects by Large Size Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Open_SelectLargeVol_Dlg)catch()
Global Objs #()

rollout _Open_SelectLargeVol_Dlg "Select Larger" width:150 height:160(
	label Message_Lb "<Select Objects First>" pos:[15,10] width:190 height:15 
	button Select_Bt "Use Selected Objects" pos:[5,30] width:140 height:23 enabled:true
	spinner RandPercent_Spn "Object Size: " pos:[10,60] type:#float fieldwidth:60 range:[0.001,10000,50.001] enabled:false
	label HowTo_Lb "First select objects and press USE SELETED OBJS button.  Use spinner to change Size amount" pos:[3,90] width:145 height:55 
	
	on Select_Bt pressed do(
		Objs = selection as array
		if Objs.count > 0 then(
			RandPercent_Spn.enabled = true
			Message_Lb.text = ((Objs.count as string) + " Total Objects")
			RandPercent_Spn.value = 50
			Si_Trans.SelectLargeVol Objs 50
		)
		else(
			RandPercent_Spn.enabled = false
			Message_Lb.text = "<Select Objects First>"
		)
	)
	
	on RandPercent_Spn changed val do (
		if Objs.count > 0 do
			Si_Trans.SelectLargeVol Objs val
	)
)

CreateDialog _Open_SelectLargeVol_Dlg