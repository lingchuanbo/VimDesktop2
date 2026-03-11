------------------------------------------------------------------
--  SiNi Software Example Diagnostics Find Reversed Splines Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _FindReversed_Dlg)catch()

rollout _FindReversed_Dlg "Find Reversed Splines" width:150 height:40(
	button Selectdiagnostics_Bt "Find Reversed Splines" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt pressed do(
		local Spl = selection as array
		local BadSpl = Si_Spl.FindReversed Spl
		print ("Total of " + (BadSpl.count as string) + " reversed splines found")
	)
)

CreateDialog _FindReversed_Dlg