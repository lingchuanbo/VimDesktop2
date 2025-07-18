------------------------------------------------------------------
--  SiNi Software Example Open Forensic Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Paste_Mtl_Dlg)catch()

rollout _Paste_Mtl_Dlg "Paste Materials" width:150 height:40(
	button Open_Bt "Paste Materials" pos:[5,10] width:140 height:23
	
	on Open_Bt pressed do(
		SiNi_IgNite.PasteMtl()
	)
)

CreateDialog _Paste_Mtl_Dlg 