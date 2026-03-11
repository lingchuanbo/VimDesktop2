------------------------------------------------------------------
--  SiNi Software Example Open Forensic Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Copy_Mtl_Dlg)catch()

rollout _Copy_Mtl_Dlg "Copy Materials" width:150 height:40(
	button Open_Bt "Copy Materials" pos:[5,10] width:140 height:23
	
	on Open_Bt pressed do(
		SiNi_IgNite.CopyMtl()
	)
)

CreateDialog _Copy_Mtl_Dlg 