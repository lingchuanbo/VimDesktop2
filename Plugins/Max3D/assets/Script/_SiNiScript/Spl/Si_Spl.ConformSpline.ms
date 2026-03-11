------------------------------------------------------------------
--  SiNi Software Example Conform selected splines Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _ConformSpline_Dlg)catch()

rollout _ConformSpline_Dlg "Conform selected splines" width:150 height:40(
	button Selectdiagnostics_Bt "Conform selected splines" pos:[5,10] width:140 height:23
	
	on Selectdiagnostics_Bt pressed do(
		local Spl = selection as array
		Si_Spl.ConformSpline Spl
	)
)

CreateDialog _ConformSpline_Dlg