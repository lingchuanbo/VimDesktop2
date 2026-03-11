------------------------------------------------------------------
--  SiNi Software Example Diagnostics Find Splines with Cad blocks Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _FindCad_Dlg)catch()

rollout _FindCad_Dlg "Find Splines with Cad blocks" width:150 height:40(
	button Selectdiagnostics_Bt "Splines with Cad blocks" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt pressed do(
		local Spl = selection as array
		local BadSpl = Si_Spl.FindCad Spl
		print ("Total of " + (BadSpl.count as string) + " splines found with cad blocks")
	)
)

CreateDialog _FindCad_Dlg