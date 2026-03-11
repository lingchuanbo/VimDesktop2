------------------------------------------------------------------
--  SiNi Software Example Explode Elements Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _ExplodeElement_Dlg)catch()

rollout _ExplodeElement_Dlg "Explode Elements" width:150 height:125(
	checkbox _Pivot_chk "Centre Pivot" pos:[10,10] width:110 height:18 checked:true
	checkbox _WireColour_chk "Keep Wirecolour" pos:[10,30] width:110 height:18
	checkbox _NewName_chk "Change Name" pos:[10,50] width:110 height:18
	editText _New_Name "" pos:[5,70] width:140 height:18 enabled:false
	button ExplodeElement_Bt "Explode Selected To Element" pos:[5,95] width:140 height:23
	
	on _NewName_chk changed state do (
		if state == true then(
			_New_Name.enabled = true	
		)
		else(
			_New_Name.text = ""
			_New_Name.enabled = false
		)
	)
	
	on ExplodeElement_Bt pressed do(
		Objs = selection as array
		Si_Mesh.ExplodeElement Objs _Pivot_chk.state _WireColour_chk.state _New_Name.text
	)
)

CreateDialog _ExplodeElement_Dlg
