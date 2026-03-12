actionMan.executeAction 0 "40021"  -- Selection: Select Al

selectedObjects = getCurrentSelection()
--´ò×é
group selectedObjects

actionMan.executeAction 0 "40021"  -- Selection: Select Al

for obj in selection do (
	
	-- Center Geometry ----------------------------------------------------------------------------------------------------
	if superClassOf obj == geometryClass then (
		local Volume = 0.0
		local Center = [0.0, 0.0, 0.0]
		local theMesh = snapshotasmesh obj
		local numFaces = theMesh.numfaces
		local Borders = (meshop.getOpenEdges theMesh)
		local EXArea = 0.0
		local EYArea = 0.0
		local TotArea = 0.0
		
		--print ("Face count: " + numFaces as string)
		--print ("Closed mesh: " + Borders.isEmpty as string)
		
		if Borders.isEmpty == true do (  -- se la geometria ¨¨ chiusa, calcola metodo complesso per vertici
			
			for i = 1 to numFaces do (
				local Face= getFace theMesh i
				local vert1 = getVert theMesh Face.x
				local vert2 = getVert theMesh Face.y
				local vert3 = getVert theMesh Face.z
				local dV = Dot (Cross (vert2 - vert1) (vert3 - vert1)) vert1
				Volume+= dV
				Center+= (vert1 + vert2 + vert3) * dV
			)
			
			delete theMesh
			Volume /= 6
			Center /= 24
			Center /= Volume
			
			obj.pivot = [Center.x , Center.y , obj.min.z]
			
			--print "Caso 1"
			
		) 
		
		if Borders.isEmpty == false and numFaces < 45000 do (  -- se la geometria ¨¨ aperta e leggera, calcola metodo per singola faccia
			
			for i = 1 to numFaces do (
				local FaceArea = meshop.getFaceArea theMesh i
				local FacePos = meshop.getFaceCenter theMesh i
				EXArea += (FaceArea * FacePos.x)
				EYArea += (FaceArea * FacePos.y)
				TotArea += FaceArea
			)
			
			delete theMesh
			obj.pivot = [EXArea/TotArea , EYArea/TotArea , obj.min.z]
			
			--print "Caso 2"
			
		)
		
		if Borders.isEmpty == false and numFaces > 45000 do (  -- se la geometria ¨¨ aperta ma troppo pesante, non calcolare baricentro  
			
			obj.pivot = [obj.center.x , obj.center.y , obj.min.z]
			
			--print "Caso 3"
			
		)
		
	)
	
	-- Center Splines ------------------------------------------------------------------------------------------------------
	else if superClassOf obj == shape then (
		local Center = [0.0, 0.0, 0.0]
		local numSpline = numSplines obj
		local totVert = numKnots obj
		
		for s = 1 to numSpline do (
			local numVert = numKnots obj s
			
			for v = 1 to numVert do (
				Center += (getKnotPoint obj s v)				
			)
		)
		
		local VertX = Center.x / totVert
		local VertY = Center.y / totVert
		
		obj.pivot = [VertX , VertY , obj.min.z]
	)
	
	-- Center Helpers / Groups ------------------------------------------------------------------------------------------
	else if superclassOf obj == helper then (
		
		obj.pivot = [obj.center.x, obj.center.y, obj.min.z]
		
	)
	
	-- Center Other ------------------------------------------------------------------------------------------------------
	else ( obj.pivot = [obj.center.x , obj.center.y , obj.min.z] )

)
toolMode.pivotCenter()