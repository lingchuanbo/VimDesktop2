------------------------------------------------------------------
--  SiNi Software Example Select diagnostics yellow green Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _SelectSplineGreen_Dlg)catch()

rollout _SelectSplineGreen_Dlg "Select diagnostics green" width:150 height:40(
	button Selectdiagnostics_Bt "Select diagnostics green" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt pressed do(
		local BadSpl = Si_Spl.SelectSplineGreen()
		print ("Total of " + (BadSpl.count as string) + " good green splines selected")
	)
)

CreateDialog _SelectSplineGreen_Dlg 