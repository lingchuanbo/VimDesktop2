------------------------------------------------------------------
--  SiNi Software Example Attach Splines Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _AttachSplines_Dlg)catch()

rollout _AttachSplines_Dlg "Attach Splines" width:150 height:130(
	checkbox _Weld_chk "Weld Attached" pos:[10,10] width:110 height:18 checked:true
	spinner _Weld_Spn "Weld Threshold: " pos:[10,30] type:#float fieldwidth:38 range:[-100,100,0.001]
	checkbox _NewName_chk "Change Name" pos:[10,50] width:110 height:18
	editText _New_Name "" pos:[5,70] width:140 height:18 enabled:false
	button AttachSplines_Bt "Attach Selected Splines" pos:[5,95] width:140 height:23
	
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
	
	on AttachSplines_Bt pressed do(
		local Spl = selection as array
		local OriginalSplineCount = Spl.Count
		Si_Spl.AttachSplines Spl _Weld_chk.state _Weld_Spn.value _NewName_chk.state _New_Name.text
		print ("Attached " + (OriginalSplineCount as string) + " splines into 1 spline")
	)
)

CreateDialog _AttachSplines_Dlg