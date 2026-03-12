------------------------------------------------------------------
--  SiNi Software Example Open Forensic Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Paste_Obj_Dlg)catch()

rollout _Paste_Obj_Dlg "Paste Objects" width:150 height:40(
	button Open_Bt "Paste Objects" pos:[5,10] width:140 height:23
	
	on Open_Bt pressed do(
		SiNi_IgNite.PasteObj()
	)
)

CreateDialog _Paste_Obj_Dlg 