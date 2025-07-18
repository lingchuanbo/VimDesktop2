------------------------------------------------------------------
--  SiNi Software Example Retopo Plane Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _RetopoPlane_Dlg)catch()

rollout _RetopoPlane_Dlg "Retopo Plane" width:150 height:60(
	spinner _Retopo_Spn "Retopo Dist.: " pos:[10,10] type:#float fieldwidth:38 range:[0,100,2]
	button Retopo_Bt "Retopo Plane" pos:[5,30] width:140 height:23
	
	on Retopo_Bt pressed do(
		Objs = selection as array
		Si_Mesh.RetopoPlane Objs _Retopo_Spn.value
	)
)

CreateDialog _RetopoPlane_Dlg