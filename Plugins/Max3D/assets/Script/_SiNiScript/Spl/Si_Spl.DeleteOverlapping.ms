------------------------------------------------------------------
--  SiNi Software Example Diagnostics delete overlapping splines Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DeleteOverlapping_Dlg)catch()

rollout _DeleteOverlapping_Dlg "Delete Overlapping Splines" width:150 height:40(
	button Selectdiagnostics_Bt "Delete Overlapping Splines" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt pressed do(
		local Spl = selection as array
		local SplineCount = Spl.count
		local DeleteCount = Si_Spl.DeleteOverlapping Spl
		print ("Deleted " + (DeleteCount as string) + " overlapping segments from " + (SplineCount as string) + " splines")
	)
)

CreateDialog _DeleteOverlapping_Dlg