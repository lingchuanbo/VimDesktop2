------------------------------------------------------------------
--  SiNi Software Example Open Forensic Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Copy_Obj_Dlg)catch()

rollout _Copy_Obj_Dlg "Copy Objects" width:150 height:40(
	button Open_Bt "Copy Selected Objects" pos:[5,10] width:140 height:23
	
	on Open_Bt pressed do(
		SiNi_IgNite.CopyObj()
	)
)

CreateDialog _Copy_Obj_Dlg 