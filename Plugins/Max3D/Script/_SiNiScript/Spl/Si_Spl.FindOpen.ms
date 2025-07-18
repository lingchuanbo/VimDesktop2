------------------------------------------------------------------
--  SiNi Software Example Diagnostics Find Open Splines Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _FindOpen_Dlg)catch()

rollout _FindOpen_Dlg "Find Open Splines" width:150 height:40(
	button Selectdiagnostics_Bt "Find Open Splines" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt pressed do(
		local Spl = selection as array
		local BadSpl = Si_Spl.FindOpen Spl
		print ("Total of " + (BadSpl.count as string) + " open splines found")
	)
)

CreateDialog _FindOpen_Dlg