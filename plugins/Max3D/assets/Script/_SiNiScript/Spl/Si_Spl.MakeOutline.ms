------------------------------------------------------------------
--  SiNi Software Example MakeOutline Spline array Script
--  Press <CTRL E> to run this from Maxscript Editor
------------------------------------------------------------------
clearlistener()
gc()
try(DestroyDialog _MakeOutline_Dlg)catch()

rollout _MakeOutline_Dlg "Outline Array Splines" width:150 height:120(
	spinner _Pos_XY_Spn "Position XY: " pos:[20,10] type:#float fieldwidth:45 range:[0,100,0]
	spinner _Pos_Z_Spn "Position Z: " pos:[25,30] type:#float fieldwidth:45 range:[0,100,0]
	spinner _Clones_Spn "Clone Count: " pos:[18,50] type:#integer fieldwidth:38 range:[1,50,1]
	checkbox Repair_Ck "Try Repair Intersecting" pos:[17,70] width:110 height:18 checked:true
	button MakeOutline_Bt "Make Outline Array" pos:[5,90] width:140 height:23
	
	on MakeOutline_Bt pressed do(
		local Spl = selection as array
		Si_Spl.MakeOutline Spl _Pos_XY_Spn.value _Pos_Z_Spn.value _Clones_Spn.value Repair_Ck.state
	)
)

CreateDialog _MakeOutline_Dlg