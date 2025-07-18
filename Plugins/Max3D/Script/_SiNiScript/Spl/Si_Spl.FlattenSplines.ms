------------------------------------------------------------------
--  SiNi Software Example Diagnostics flatten splines Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _FlattenSplines_Dlg)catch()

rollout _FlattenSplines_Dlg "Flatten splines" width:150 height:40(
	button Selectdiagnostics_Bt "Flatten splines" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt pressed do(
		local Spl = selection as array
		local SplineCount = Spl.count
		local KnotsMoved = Si_Spl.FlattenSplines Spl
		print ("Moved " + (KnotsMoved as string) + " knots in " + (SplineCount as string) + " splines")
	)
)

CreateDialog _FlattenSplines_Dlg