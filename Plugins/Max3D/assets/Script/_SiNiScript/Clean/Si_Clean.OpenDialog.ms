------------------------------------------------------------------
--  SiNi Software Example Open Forensic Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Open_Forensic_Dlg)catch()

rollout _Open_Forensic_Dlg "Open Forensic" width:150 height:40(
	button Open_Bt "Open Forensic" pos:[5,10] width:140 height:23
	
	on Open_Bt pressed do(
		Si_Clean.OpenDialog()
	)
)

CreateDialog _Open_Forensic_Dlg