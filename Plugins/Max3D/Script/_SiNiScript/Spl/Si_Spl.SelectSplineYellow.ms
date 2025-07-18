------------------------------------------------------------------
--  SiNi Software Example Select diagnostics yellow Wirecolour Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _SelectSplineYellow_Dlg)catch()

rollout _SelectSplineYellow_Dlg "Select diagnostics yellow" width:150 height:40(
	button Selectdiagnostics_Bt "Select diagnostics yellow" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt pressed do(
		local BadSpl = Si_Spl.SelectSplineYellow()
		print ("Total of " + (BadSpl.count as string) + " yellow splines selected")
	)
)

CreateDialog _SelectSplineYellow_Dlg 