------------------------------------------------------------------
--  SiNi Software Example Diagnostics Fix Reversed splines Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _RedrawReversed_Dlg)catch()

rollout _RedrawReversed_Dlg "Fix Reversed Splines" width:150 height:40(
	button Selectdiagnostics_Bt "Fix Reversed Splines" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt pressed do(
		local Spl = selection as array
		local SplineCount = Spl.count
		local RepairCount = Si_Spl.RedrawReversed Spl
		print ("Repaired " + (RepairCount as string) + " reversed shapes in " + (SplineCount as string) + " splines")
	)
)

CreateDialog _RedrawReversed_Dlg