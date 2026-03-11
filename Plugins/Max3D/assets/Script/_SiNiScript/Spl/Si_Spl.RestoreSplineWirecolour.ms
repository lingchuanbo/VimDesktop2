------------------------------------------------------------------
--  SiNi Software Example Spline Restore Spline Wirecolour Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _RestoreSplineWirecolour_Dlg)catch()

rollout _RestoreSplineWirecolour_Dlg "Restore Spline Wirecolour" width:150 height:40(
	button RestoreSplineWirecolour_Bt "Restore Spline Wirecolour" pos:[5,10] width:140 height:23
	
	on RestoreSplineWirecolour_Bt pressed do(
		Si_Spl.RestoreSplineWirecolour()
	)
)

CreateDialog _RestoreSplineWirecolour_Dlg
