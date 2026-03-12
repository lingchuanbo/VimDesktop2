------------------------------------------------------------------
--  SiNi Software Example MakeOutline Percent Line Spline array Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _MakePercentLine_Dlg)catch()

rollout _MakePercentLine_Dlg "Percent Line Array Splines" width:150 height:160(
	spinner _Pos_XY_Spn "Position XY: " pos:[20,10] type:#float fieldwidth:45 range:[0,100,0]
	spinner _Pos_Z_Spn "Position Z: " pos:[25,30] type:#float fieldwidth:45 range:[0,100,0]
	spinner _Clones_Spn "Clone Count: " pos:[18,50] type:#integer fieldwidth:38 range:[0,50,1]
	checkbox Repair_Ck "Try Repair Intersecting" pos:[17,70] width:110 height:18 checked:true
	spinner _Start_Spn "Start Offset: " pos:[12,90] type:#float fieldwidth:45 range:[0,100,0]
	spinner _End_Spn "End Offset: " pos:[18,110] type:#float fieldwidth:45 range:[0,100,0]
	button MakeOutline_Bt "Make Percent Line Array" pos:[5,130] width:140 height:23
	
	on MakeOutline_Bt pressed do(
		local Spl = selection as array
		Si_Spl.MakePercentLine Spl _Pos_XY_Spn.value _Pos_Z_Spn.value _Clones_Spn.value Repair_Ck.state _Start_Spn.value _End_Spn.value
	)
)

CreateDialog _MakePercentLine_Dlg