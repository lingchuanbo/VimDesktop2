------------------------------------------------------------------
--  SiNi Software Example Retopo Plane Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _RetopoMassing_Dlg)catch()

rollout _RetopoMassing_Dlg "Retopo Massing" width:150 height:80(
	checkbox _Delete_chk "Delete Original Geo." pos:[10,10] width:110 height:18 checked:true
	spinner _Retopo_Spn "Retopo Dist.: " pos:[10,30] type:#float fieldwidth:38 range:[0,2,1.0]
	button Retopo_Bt "Retopo Massing" pos:[5,50] width:140 height:23
	
	on Retopo_Bt pressed do(
		Objs = selection as array
		Si_Mesh.RetopoMassing Objs _Retopo_Spn.value _Delete_chk.state
	)
)

CreateDialog _RetopoMassing_Dlg