------------------------------------------------------------------
--  SiNi Software Example Subdivide Splines Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _SubdivideSplines_Dlg)catch()

rollout _SubdivideSplines_Dlg "Subdivide Splines" width:150 height:60(
	spinner _Distance_Spn "Knot Distance: " pos:[10,10] type:#float fieldwidth:38 range:[0,100,0.5]
	button AddKnots_Bt "Subdivide Splines" pos:[5,30] width:140 height:23
	
	on AddKnots_Bt pressed do(
		local Spl = selection as array
		Spl = Si_Spl.SubdivideSplines Spl _Distance_Spn.value
	)
)

CreateDialog _SubdivideSplines_Dlg