------------------------------------------------------------------
--  SiNi Software Example MakeOutline Dotted Line Spline array Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _MakeDottedLine_Dlg)catch()

rollout _MakeDottedLine_Dlg "Dotted Line Array Splines" width:150 height:180(
	spinner _Pos_XY_Spn "Position XY: " pos:[20,10] type:#float fieldwidth:45 range:[0,100,0]
	spinner _Pos_Z_Spn "Position Z: " pos:[25,30] type:#float fieldwidth:45 range:[0,100,0]
	spinner _Clones_Spn "Clone Count: " pos:[18,50] type:#integer fieldwidth:38 range:[0,50,1]
	checkbox Repair_Ck "Try Repair Intersecting" pos:[17,70] width:110 height:18 checked:true
	spinner _Dot_Spn "Dot Length: " pos:[17,90] type:#float fieldwidth:45 range:[0,100,0]
	spinner _Space_Spn "Space Length: " pos:[5,110] type:#float fieldwidth:45 range:[0,100,0]
	checkbox Delete_Ck "Delete Source Splines" pos:[17,130] width:120 height:18 checked:true
	button MakeOutline_Bt "Make Dotted Line Array" pos:[5,150] width:140 height:23
	
	on MakeOutline_Bt pressed do(
		local Spl = selection as array
		Si_Spl.MakeDottedLine Spl _Pos_XY_Spn.value _Pos_Z_Spn.value _Clones_Spn.value Repair_Ck.state _Dot_Spn.value _Space_Spn.value
		if Delete_Ck.state == true do(
			delete Spl
		)
	)
)

CreateDialog _MakeDottedLine_Dlg