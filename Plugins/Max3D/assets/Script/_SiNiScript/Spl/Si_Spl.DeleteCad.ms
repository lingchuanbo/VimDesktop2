------------------------------------------------------------------
--  SiNi Software Example Diagnostics Delete Cad Blocks from selected Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _DeleteCad_Dlg)catch()

rollout _DeleteCad_Dlg "Delete Cad Blocks from selected" width:150 height:40(
	button Selectdiagnostics_Bt "Delete Cad Blocks selected" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt pressed do(
		local Spl = selection as array
		local SplineCount = Spl.count
		local Blockscount = Si_Spl.DeleteCad Spl
		print ("Deleted " + (Blockscount as string) + " cad blocks in " + (SplineCount as string) + " splines")
	)
)

CreateDialog _DeleteCad_Dlg