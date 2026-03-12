------------------------------------------------------------------
--  SiNi Software Example Spline Corners to curves Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _CurveToCorner_Dlg)catch()

rollout _CurveToCorner_Dlg "Spline Corners to curves" width:150 height:60(
	spinner _Distance_Spn "Knot Distance: " pos:[10,10] type:#float fieldwidth:38 range:[0,100,0.5]
	button CurveToCorner_Bt "Make Corner to curve" pos:[5,30] width:140 height:23
	
	on CurveToCorner_Bt pressed do(
		local Spl = selection as array
		local knotsAdded = Si_Spl.CurveToCorner Spl _Distance_Spn.value
		print ("Added " + (knotsAdded as string) + " more corner knots")
	)
)

CreateDialog _CurveToCorner_Dlg