------------------------------------------------------------------
--  SiNi Software Example Diagnostics Detach overlapping splines Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DetachOverlapping_Dlg)catch()

rollout _DetachOverlapping_Dlg "Detach Overlapping Splines" width:150 height:40(
	button Selectdiagnostics_Bt "Detach Overlapping Splines" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt pressed do(
		local Spl = selection as array
		local SplineCount = Spl.count
		local DeleteCount = Si_Spl.DetachOverlapping Spl
		print ("Detached " + (DeleteCount.count as string) + " overlapping segments from " + (SplineCount as string) + " splines")
	)
)

CreateDialog _DetachOverlapping_Dlg 