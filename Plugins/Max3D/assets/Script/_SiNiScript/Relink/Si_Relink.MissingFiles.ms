------------------------------------------------------------------
--  SiNi Software Relink Files Maxscript Archive Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _MissingFiles_Dlg)catch()
Global MissingFiles = #("No Missing Files")

rollout _MissingFiles_Dlg "Find Missing Files Maxscript Sample" width:500 height:440(
	listbox MissingList "Missing Files" items:MissingFiles selection:0 height:30 readOnly:true
	
	on _MissingFiles_Dlg open do (
		print "Looking for miising files"
		--MissingFiles = Si_Relink.MissingFiles() 
	)
)

CreateDialog _MissingFiles_Dlg ---Si_Relink.MissingFiles