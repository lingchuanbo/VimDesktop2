------------------------------------------------------------------
--  SiNi Software Example Unify Normals Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _UnifyNormals_Dlg)catch()

-- rollout _UnifyNormals_Dlg "Unify Normals" width:150 height:40(
--	button Normals_Bt "Unify Normals" pos:[5,10] width:140 height:23
	
--	on Normals_Bt pressed do(
		Objs = selection as array
		Si_Mesh.UnifyNormals Objs 
--	)
--)

--CreateDialog _UnifyNormals_Dlg