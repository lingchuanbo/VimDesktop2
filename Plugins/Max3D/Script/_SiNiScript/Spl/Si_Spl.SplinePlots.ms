------------------------------------------------------------------
--  SiNi Software Example weld Spline Knots Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _CadPlots_Dlg)catch()

rollout _CadPlots_Dlg "Weld Spline Knots" width:150 height:100(
	checkbox _ConvertToMesh_chk "Convert To Mesh" pos:[10,5] width:110 height:18
	checkbox _NewName_chk "Change Name" pos:[10,25] width:110 height:18
	editText _New_Name "" pos:[5,45] width:140 height:18 enabled:false
	button CadPlots_Bt "Make Spline Plot" pos:[5,70] width:140 height:23
	
	on _NewName_chk changed state do (
		if state == true then(
			_New_Name.enabled = true	
		)
		else(
			_New_Name.text = ""
			_New_Name.enabled = false
		)
	)
		
	on CadPlots_Bt pressed do(
		local Spl = selection as array
		SplinePlots = Si_Spl.SplinePlots Spl _ConvertToMesh_chk.state _New_Name.text
	)
)

CreateDialog _CadPlots_Dlg