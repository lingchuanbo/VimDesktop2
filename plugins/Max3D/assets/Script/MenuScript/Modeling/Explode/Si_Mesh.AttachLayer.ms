------------------------------------------------------------------
--  SiNi Software Example Attach Objects by Layer Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _AttachLayer_Dlg)catch()

rollout _AttachLayer_Dlg "Attach By Layer" width:150 height:125(
	checkbox _Weld_chk "Weld Attached" pos:[10,10] width:110 height:18 checked:true
	spinner _Weld_Spn "Weld Threshold: " pos:[10,30] type:#float fieldwidth:38 range:[-100,100,0.001]
	checkbox _NewName_chk "Change Name" pos:[10,50] width:110 height:18
	editText _New_Name "" pos:[5,70] width:140 height:18 enabled:false
	button AttachLayer_Bt "Attach Selected By Layer" pos:[5,95] width:140 height:23
	
	on _NewName_chk changed state do (
		if state == true then(
			_New_Name.enabled = true	
		)
		else(
			_New_Name.text = ""
			_New_Name.enabled = false
		)
	)
	
	on _Weld_chk changed state do (
		if state == true then _Weld_Spn.enabled = true else _Weld_Spn.enabled = false
	)
	
	on AttachLayer_Bt pressed do(
		Objs = selection as array
		if _Weld_chk.checked == true then
			Si_Mesh.AttachLayer Objs _Weld_chk.state _Weld_Spn.value _New_Name.text
		else
			Si_Mesh.AttachLayer Objs _Weld_chk.state 0.0 _New_Name.text
	)
)

CreateDialog _AttachLayer_Dlg