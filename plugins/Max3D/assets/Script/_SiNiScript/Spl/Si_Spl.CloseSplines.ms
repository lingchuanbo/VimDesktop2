------------------------------------------------------------------
--  SiNi Software Example Diagnostics Fix open splines Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _CloseSplines_Dlg)catch()

rollout _CloseSplines_Dlg "Fix open Splines" width:150 height:40(
	button Selectdiagnostics_Bt "Fix open Splines" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt pressed do(
		local Spl = selection as array
		local SplineCount = Spl.count
		local RepairCount = Si_Spl.CloseSplines Spl
		print ("Repaired " + (RepairCount as string) + " open shapes from " + (SplineCount as string) + " splines")
	)
)

CreateDialog _CloseSplines_Dlg