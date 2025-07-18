------------------------------------------------------------------
--  SiNi Software Example Open Forensic Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Open_IgNite_Dlg)catch()

rollout _Open_IgNite_Dlg "Open IgNite" width:150 height:40(
	button Open_Bt "Open IgNite" pos:[5,10] width:140 height:23
	
	on Open_Bt pressed do(
		SiNi_IgNite.OpenDialog()
	)
)

CreateDialog _Open_IgNite_Dlg