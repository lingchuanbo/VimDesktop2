------------------------------------------------------------------
--  SiNi Software Example Optimise Splines Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _OptimiseSplines_Dlg)catch()

rollout _OptimiseSplines_Dlg "Optimise Splines" width:150 height:60(
	spinner _Angle_Spn "Angle Threshold: " pos:[10,10] type:#float fieldwidth:38 range:[0,100,0.5]
	button AddKnots_Bt "Optimise Splines" pos:[5,30] width:140 height:23
	
	on AddKnots_Bt pressed do(
		local Spl = selection as array
		local KnotsRemoved = Si_Spl.OptimiseSplines Spl _Angle_Spn.value
		print ("Removed " + (KnotsRemoved as string) + " knots")
	)
)

CreateDialog _OptimiseSplines_Dlg