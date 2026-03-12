------------------------------------------------------------------
--  SiNi Software Example Random Select Objects by percentage Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Open_RandSelection_Dlg)catch()
Global Objs #()

rollout _Open_RandSelection_Dlg "Random Select Objects by percentage" width:150 height:160(
	label Message_Lb "<Select Objects First>" pos:[15,10] width:190 height:15 
	button Select_Bt "Use Selected Objs." pos:[5,30] width:140 height:23 enabled:true
	spinner RandPercent_Spn "Random Percent: " pos:[10,60] type:#integer fieldwidth:30 range:[0,100,50] enabled:false
	label HowTo_Lb "First select objects and press USE SELETED OBJS button.  Use spinner to change percent amount" pos:[3,90] width:145 height:55 
	
	on Select_Bt pressed do(
		Objs = selection as array
		if Objs.count > 0 then(
			RandPercent_Spn.enabled = true
			Message_Lb.text = ((Objs.count as string) + " Total Objects")
			RandPercent_Spn.value = 50
			Si_Trans.RandSelectObj Objs 50
		)
		else(
			RandPercent_Spn.enabled = false
			Message_Lb.text = "<Select Objects First>"
		)
	)
	
	on RandPercent_Spn changed val do (
		if Objs.count > 0 do
			Si_Trans.RandSelectObj Objs val
	)
)

CreateDialog _Open_RandSelection_Dlg