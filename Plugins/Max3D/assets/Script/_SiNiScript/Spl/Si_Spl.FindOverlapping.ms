------------------------------------------------------------------
--  SiNi Software Example Diagnostics Find Overlapping Splines Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _FindOverlapping_Dlg)catch()

rollout _FindOverlapping_Dlg "Find Overlapping Splines" width:150 height:40(
	button Selectdiagnostics_Bt "Find Overlapping Splines" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt pressed do(
		local Spl = selection as array
		local BadSpl = Si_Spl.FindOverlapping Spl
		print ("Total of " + (BadSpl.count as string) + " overlapping splines found")
	)
)

CreateDialog _FindOverlapping_Dlg