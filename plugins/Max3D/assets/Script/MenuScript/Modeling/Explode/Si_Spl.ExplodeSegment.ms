------------------------------------------------------------------
--  SiNi Software Example Explode Segment Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _ExplodeSegment_Dlg)catch()

rollout _ExplodeSegment_Dlg "Explode Segment" width:150 height:140(
	checkbox _Pivot_chk "Centre Pivot" pos:[10,10] width:110 height:18 checked:true
	checkbox _WireColour_chk "Keep Wirecolour" pos:[10,30] width:110 height:18
	checkbox _NewName_chk "Change Name" pos:[10,50] width:110 height:18
	editText _New_Name "" pos:[5,70] width:140 height:18 enabled:false
	button ExplodeSegment_Bt "Explode To Segment" pos:[5,95] width:140 height:23
	label Message_Lb "" pos:[15,120] width:190 height:15  
	
	on _NewName_chk changed state do (
		if state == true then(
			_New_Name.enabled = true	
		)
		else(
			_New_Name.text = ""
			_New_Name.enabled = false
		)
	)
	
	on ExplodeSegment_Bt pressed do(
		Message_Lb.text = ""
		local Spl = selection as array
		local SegmentCount = Si_Spl.ExplodeSegment Spl _Pivot_chk.state _WireColour_chk.state _NewName_chk.state _New_Name.text
		Message_Lb.text = ("Exploded " + (SegmentCount as string) + " segments") 
	)
)

CreateDialog _ExplodeSegment_Dlg