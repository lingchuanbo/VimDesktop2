------------------------------------------------------------------
--  SiNi Software Example weld Spline Knots Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _WeldKnots_Dlg)catch()

rollout _WeldKnots_Dlg "Weld Spline Knots" width:150 height:60(
	spinner _Weld_Spn "Weld Threshold: " pos:[10,10] type:#float fieldwidth:38 range:[0.001,100,0.001]
	button WeldKnots_Bt "Weld Spline Knots" pos:[5,30] width:140 height:23
	
	on WeldKnots_Bt pressed do(
		local Spl = selection as array
		local KnotsRemoved = Si_Spl.WeldKnots Spl _Weld_Spn.value
		print ("Removed " + (KnotsRemoved as string) + " knots")
	)
)

CreateDialog _WeldKnots_Dlg