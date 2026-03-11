------------------------------------------------------------------
--  SiNi Software Example Open Forensic Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Paste_Mod_Dlg)catch()

rollout _Paste_Mod_Dlg "Paste Modifiers" width:150 height:40(
	button Open_Bt "Paste Modifiers" pos:[5,10] width:140 height:23
	
	on Open_Bt pressed do(
		SiNi_IgNite.PasteMod()
	)
)

CreateDialog _Paste_Mod_Dlg 