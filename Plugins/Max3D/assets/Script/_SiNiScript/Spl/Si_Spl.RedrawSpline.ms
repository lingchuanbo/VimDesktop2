------------------------------------------------------------------
--  SiNi Software Example Redraw selected splines Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _RedrawSpline_Dlg)catch()

rollout _RedrawSpline_Dlg "Redraw selected splines" width:150 height:40(
	button Selectdiagnostics_Bt "Redraw selected splines" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt pressed do(
		local Spl = selection as array
		Si_Spl.RedrawSpline Spl
	)
)

CreateDialog _RedrawSpline_Dlg