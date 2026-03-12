------------------------------------------------------------------
--  SiNi Software Example Open Forensic Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _Select_Cam_Dlg)catch()

rollout _Select_Cam_Dlg "Select Active Camera" width:150 height:40(
	button Open_Bt "Select Active Camera" pos:[5,10] width:140 height:23
	
	on Open_Bt pressed do(
		SiNi_IgNite.SelectCamera()
	)
)

CreateDialog _Select_Cam_Dlg 