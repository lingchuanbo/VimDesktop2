-- Align Pivot for 3ds Max
-- Description in author's store at artstation.com/basachi
-- v2.1 26.01.2022
-- macroscript AlignPivotBasachi
-- category:"Basachi"
-- tooltip:"Align Pivot Basachi"
-- buttonText:"APB"
-- (	
	global prevSnapIsEdge
	global fixPivotPosition
	
	fn ResetPivotToWorld = 
	(
		userTool = toolmode.commandMode
		
		toolmode.commandMode = #move
		toolMode.coordsys #world
		setCoordCenter #Selection
		
		toolmode.commandMode = #uscale
		toolMode.coordsys #world
		setCoordCenter #Selection
		
		toolmode.commandMode = #rotate
		toolMode.coordsys #world
		setCoordCenter #Selection
		
		toolmode.commandMode = userTool
		prevSnapIsEdge = false
	)	
	fn PivotToggle =
	(
		userTool = toolmode.commandMode
		
		if getRefCoordSys() != #working_pivot then
		(
			toolmode.commandMode = #move
			toolMode.coordsys #working_pivot
			if fixPivotPosition == true then setCoordCenter #system
			else setCoordCenter #Selection
			
			toolmode.commandMode = #uscale
			toolMode.coordsys #working_pivot
			if fixPivotPosition == true then setCoordCenter #system
			else setCoordCenter #Selection
			
			toolmode.commandMode = #rotate
			toolMode.coordsys #working_pivot
			if fixPivotPosition == true then setCoordCenter #system
			else setCoordCenter #Selection
		)
		else
		(
			toolmode.commandMode = #move
			toolMode.coordsys #world
			setCoordCenter #Selection
			
			toolmode.commandMode = #uscale
			toolMode.coordsys #world
			setCoordCenter #Selection
			
			toolmode.commandMode = #rotate
			toolMode.coordsys #world
			setCoordCenter #Selection
		)
		toolmode.commandMode = userTool
	)
	fn SetWorkingPivot TM = 
	(
		userTool = toolmode.commandMode
		
		toolmode.commandMode = #move
		toolMode.coordsys #working_pivot
		if fixPivotPosition == true then setCoordCenter #system
		else setCoordCenter #Selection
		WorkingPivot.setTM TM
		
		toolmode.commandMode = #uscale
		toolMode.coordsys #working_pivot
		if fixPivotPosition == true then setCoordCenter #system
		else setCoordCenter #Selection
		WorkingPivot.setTM TM
		
		toolmode.commandMode = #rotate
		toolMode.coordsys #working_pivot
		if fixPivotPosition == true then setCoordCenter #system
		else setCoordCenter #Selection
		WorkingPivot.setTM TM
		
		toolmode.commandMode = userTool
	)
	fn VertSnap vert =
	(
		fixPivotPosition = false
		faces = (polyop.getFacesUsingVert $ vert as array)
		faceNormal = [0,0,0] 
		for f in faces do
			faceNormal += polyop.getFaceNormal $ f
		p = Point()
		p.pos =  polyOp.getVert $ vert
		p.dir = faceNormal
		SetWorkingPivot (p.transform)
		delete p
		prevSnapIsEdge = false
	)
	fn TwoVertsSnap verts =
	(
		fixPivotPosition = false
		vPos1 =  polyOp.getVert $ verts[1]
		vPos2 =  polyOp.getVert $ verts[2]
		p = Point()
		p.dir = vPos1 - vPos2
		p.pos = (vPos1 + vPos2)/2.0
		userTool = toolmode.commandMode
		SetWorkingPivot (p.transform)
		delete p
		prevSnapIsEdge = false
	)
	fn TwoVertsSnapSpline vPos1 vPos2 =
	(
		fixPivotPosition = false
		p = Point()
		p.dir = vPos1 - vPos2
		p.pos = (vPos1 + vPos2)/2.0
		userTool = toolmode.commandMode
		SetWorkingPivot (p.transform)
		delete p
		prevSnapIsEdge = false
	)
	fn EdgeSnap edg  =
	(
		fixPivotPosition = false
		global prevEdge
		global prevObj
		global change
		
		connectedFaces = polyop.getFacesUsingEdge $ edg as array
		faceMiddle_Z = [0,0,0]
		for f in connectedFaces do faceMiddle_Z += polyop.getFaceNormal $ f
		
		containedVerts = polyop.getVertsUsingEdge $ edg as array
		vPos1 =  polyOp.getVert $ containedVerts[1]
		vPos2 =  polyOp.getVert $ containedVerts[2]
		
		TMpos = (vPos1 + vPos2)/2.0
		edgVec_X = normalize(vPos1 - vPos2)
		vec_Y = normalize(cross edgVec_X faceMiddle_Z)
		faceMiddle_Z = normalize(cross vec_Y edgVec_X)
		
		if prevEdge == edg and prevObj == $ and prevSnapIsEdge == true and connectedFaces.count == 2 then
		(
			if change == 0 then
			(				
				change = 1
				face1_Z = polyop.getFaceNormal $ connectedFaces[1]
				vec1_Y = normalize(cross edgVec_X face1_Z)
				SetWorkingPivot (matrix3 edgVec_X vec1_Y face1_Z TMpos)
			)
			else if change == 1 then
			(
				change = 2
				face2_Z = polyop.getFaceNormal $ connectedFaces[2]
				vec2_Y = normalize(cross edgVec_X face2_Z)
				SetWorkingPivot (matrix3 edgVec_X vec2_Y face2_Z TMpos)
			)
			else if change == 2 then
			(
				change = 0
				SetWorkingPivot (matrix3 edgVec_X vec_Y faceMiddle_Z TMpos)
			)			
		)
		else
		(
			SetWorkingPivot (matrix3 edgVec_X vec_Y faceMiddle_Z TMpos)
			prevEdge = edg
			prevObj = $
			prevSnapIsEdge = true
			change = 0
		)
 	)
	fn FaceSnap face = 
	(
		fixPivotPosition = false
		TMpos = polyop.getFaceCenter $ face
		faceEdges = polyop.getEdgesUsingFace $ face as array
		edgeVerts = polyop.getVertsUsingEdge $ faceEdges[1] as array
		vPos1 = polyOp.getVert $ edgeVerts[1]
		vPos2 = polyOp.getVert $ edgeVerts[2]
		edgVec_X = normalize(vPos1 - vPos2)
		faceNormal_Z = polyop.getFaceNormal $ face
		vec_Y = normalize(cross edgVec_X faceNormal_Z)
		SetWorkingPivot (matrix3 edgVec_X vec_Y faceNormal_Z TMpos)
		prevSnapIsEdge = false
	)
	fn ManyFacesSnap faces =
	(
		fixPivotPosition = false
		faceNormal_Z = [0,0,0] 
		TMpos = [0,0,0]
		for f in faces do
		(
			faceNormal_Z += polyop.getFaceNormal $ f
			TMpos += polyop.getFaceCenter $ f
		)
		TMpos /= faces.count
		p = Point()
		p.dir = faceNormal_Z
		SetWorkingPivot (matrix3 p.transform[1] p.transform[2] p.transform[3] TMpos)
		delete p
		prevSnapIsEdge = false
	)
	if (mouse.pos)[1] < 0 or (mouse.pos)[2] < 0 or(mouse.pos)[1] > gw.getWinSizeX() or	(mouse.pos)[2] > gw.getWinSizeY() then
	(
		fixPivotPosition = false
		ResetPivotToWorld()
	)
	else if mouse.buttonStates[1] then
	(
		try  -- protects against errors if user press and hold LMB + hotkey
		(
			m = (matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0])
			userTool2 = toolmode.commandMode -- protects against errors if the gizmo was grabbed in time the script was running
			toolmode.commandMode = #select -- protects against errors if the gizmo was grabbed in time the script was running
			oldSnapMode = snapMode.active
			snapMode.active = true
			
			if getRefCoordSys() == #working_pivot then m = WorkingPivot.getTM()
			tool mouseCtrl
			(
				on freeMove do
				(
					m.pos = worldPoint
					if lButton != true do #stop
				)
			) 
			starttool mouseCtrl
			fixPivotPosition = true
			SetWorkingPivot m
			
			snapMode.active = oldSnapMode
			toolmode.commandMode = userTool2 -- protects against errors if the gizmo was grabbed in time the script was running
			prevSnapIsEdge = false
		)
		catch
		(
			return 0
		)
	)
	else
	(
		-----------------------------------------------------------------------------------
		--------------------------------- Editable_Poly -----------------------------------
		-----------------------------------------------------------------------------------
		if classof (modPanel.getCurrentObject()) == Editable_Poly then
		(
			case subobjectLevel of
			(
				1:
				(
					sel = polyop.getVertSelection $ as array
					if sel.count == 0 then PivotToggle()
					else if sel.count == 1 then VertSnap sel[1]
					else if sel.count == 2 then TwoVertsSnap sel
				)
				2:
				(
					sel = polyop.getEdgeSelection $ as array
					if sel.count == 0 then PivotToggle()
					else if sel.count == 1 then EdgeSnap sel[1]
				)
				3:
				(
					sel = polyop.getEdgeSelection $ as array
					if sel.count == 0 then PivotToggle()
					else if sel.count == 1 then EdgeSnap sel[1]
				)
				4:
				(
					sel = polyop.getFaceSelection $ as array
					if sel.count == 0 then PivotToggle()
					else if sel.count == 1 then FaceSnap sel[1]
					else ManyFacesSnap sel
				)
				5:
				(
					sel = polyop.getFaceSelection $ as array
					if sel.count == 0 then PivotToggle()
					else if sel.count == 1 then FaceSnap sel[1]
					else ManyFacesSnap sel
				)
				default: PivotToggle()
			)
		)
		-----------------------------------------------------------------------------------
		----------------------------------- Edit_Poly -------------------------------------
		-----------------------------------------------------------------------------------
		else if classof (modPanel.getCurrentObject()) == Edit_Poly then
		(
			if ($ as string) != "$selection" do
			(
				case subobjectLevel of
				(
					1:
					(
						sel = $.modifiers[#Edit_Poly].GetSelection #Vertex as array
						if sel.count == 0 then PivotToggle()
						else if sel.count == 1 then VertSnap sel[1]
						else if sel.count == 2 then TwoVertsSnap sel
					)
					2:
					(
						sel = $.modifiers[#Edit_Poly].GetSelection #Edge as array
						if sel.count == 0 then PivotToggle()
						else if sel.count == 1 then EdgeSnap sel[1]
					)
					3:
					(
						sel = $.modifiers[#Edit_Poly].GetSelection #Edge as array
						if sel.count == 0 then PivotToggle()
						else if sel.count == 1 then EdgeSnap sel[1]
					)
					4:
					(
						sel = $.modifiers[#Edit_Poly].GetSelection #Face as array
						if sel.count == 0 then PivotToggle()
						else if sel.count == 1 then FaceSnap sel[1]
						else ManyFacesSnap sel
					)
					5:
					(
						sel = $.modifiers[#Edit_Poly].GetSelection #Face as array
						if sel.count == 0 then PivotToggle()
						else if sel.count == 1 then FaceSnap sel[1]
						else ManyFacesSnap sel
					)
					default: PivotToggle()
				)
			)
		)
		-----------------------------------------------------------------------------------
		--------------------------- Editable Spline and Line ------------------------------
		-----------------------------------------------------------------------------------
		else if classof(modPanel.getCurrentObject()) == SplineShape or classof(modPanel.getCurrentObject()) == line then
		(
			selectedArr = #()
			if subObjectLevel == 1 then
			(
				for splineNum in 1 to numSplines $ do
				(
					selected = getKnotSelection $ splineNum
					if selected.count > 2 then exit
					if selected.count != 0 then for sel in selected do append selectedArr #(sel, splineNum)
					else if selectedArr.count > 2 then exit
				)
				if selectedArr.count == 2 then
				(
					vPos1 = getKnotPoint $ selectedArr[1][2] selectedArr[1][1]
					vPos2 = getKnotPoint $ selectedArr[2][2] selectedArr[2][1]
					TwoVertsSnapSpline vPos1 vPos2
				)
			)
			else if subObjectLevel == 2 then
			(
				for splineNum in 1 to numSplines $ do
				(
					selected = getSegSelection $ splineNum
					if selected.count > 1 then exit
					else if selected.count != 0 then for sel in selected do append selectedArr #(sel, splineNum)
					if selectedArr.count > 1 then exit
				)
				if selectedArr.count == 1 then
				(
					vPos1 = getKnotPoint $ selectedArr[1][2] selectedArr[1][1]
					if numKnots $ selectedArr[1][2] == numSegments $ selectedArr[1][2] then vPos2 = getKnotPoint $ selectedArr[1][2] 1 -- closed splie
					else vPos2 = getKnotPoint $ selectedArr[1][2] (selectedArr[1][1] + 1) -- open spline
					TwoVertsSnapSpline vPos1 vPos2
				)
			)
			else if subObjectLevel > 2 then return 0
			else PivotToggle()
		)
		-----------------------------------------------------------------------------------
		----------------------------------- Default ---------------------------------------
		-----------------------------------------------------------------------------------
		else PivotToggle()
-- 	)
-- )