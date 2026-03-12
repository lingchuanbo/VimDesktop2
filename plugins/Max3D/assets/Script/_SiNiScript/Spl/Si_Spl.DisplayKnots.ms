------------------------------------------------------------------
--  SiNi Software Example Display all knots Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DisplayKnots_Dlg)catch()

rollout _DisplayKnots_Dlg "Display all knots" width:150 height:40(
	checkbutton Selectdiagnostics_Bt "Display all knots" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt changed state do(
		if state then(
			Si_Spl.DisplayKnots true
		)
		else(
			Si_Spl.DisplayKnots false
		)
	)
)

CreateDialog _DisplayKnots_Dlg