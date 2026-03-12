------------------------------------------------------------------
--  SiNi Software Example Select diagnostics red Wirecolour Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _SelectSplineRed_Dlg)catch()

rollout _SelectSplineRed_Dlg "Select diagnostics red" width:150 height:40(
	button Selectdiagnostics_Bt "Select diagnostics red" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt pressed do(
		local BadSpl = Si_Spl.SelectSplineRed()
		print ("Total of " + (BadSpl.count as string) + " bad red splines selected")
	)
)

CreateDialog _SelectSplineRed_Dlg