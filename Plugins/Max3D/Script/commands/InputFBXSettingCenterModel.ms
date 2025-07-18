
--actionMan.executeAction 0 "40021"  -- Selection: Select Al
--sel = getCurrentSelection()
--group sel
actionMan.executeAction 0 "40021"  -- Selection: Select Al
selectedObjects = getCurrentSelection()


global rot = eulerToQuat(eulerAngles 90 0 -180)
function Y_UP obj =
(
   Select obj
   ResetXForm obj
   modPanel.addModToSelection (XForm ()) ui:on

   obj.modifiers[#XForm].gizmo.rotation += rot as quat



   rotate obj (inverse rot as quat)

   for obj in (selection as array) do ( convertToPoly obj)  
)
-- --打组
--group selectedObjects
--clearSelection()
--actionMan.executeAction 0 "40021"  -- Selection: Select Al
for obj in selectedObjects do (
	--print obj
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
		
		if Borders.isEmpty == true do (  -- se la geometria è chiusa, calcola metodo complesso per vertici
			
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
		
		if Borders.isEmpty == false and numFaces < 45000 do (  -- se la geometria è aperta e leggera, calcola metodo per singola faccia
			
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
		
		if Borders.isEmpty == false and numFaces > 45000 do (  -- se la geometria è aperta ma troppo pesante, non calcolare baricentro  
			
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
print "中心点移到所有模型底下中心--------完成"
--actionMan.executeAction 0 "40021"  -- Selection: Select Al
--selectedObjects = getCurrentSelection()

-- for obj in isGroupHead  do
-- (
-- 	--移动到原点位置
-- 	obj.pos=[0,0,0]
--     -- 改为世界中心点
-- )
for x in selectedObjects where (isgrouphead x) do
(
	x.pos=[0,0,0]
)
print "所有模型移到场景中心--------完成"

-- --------------- close Groups -----
					
sel = getcurrentselection() 


for i = 1 to sel.count do (
	
	
	dada = classof sel[i]
	bo = sel[i].baseObject

	
		if dada == Dummy then (

		
			if isGroupHead sel[i] then (
				setGroupOpen sel[i] false
			)					
		)		
	) 
	
--------------------------------

try (

sel = getcurrentselection() 


for i = 1 to sel.count do (
	
	
	dada = classof sel[i]
	bo = sel[i].baseObject
	
		if dada == Dummy then (

		
			if isGroupHead sel[i] then (
				
				--actionMan.executeAction 0 "40141"  -- Groups: Ungroup

					
				unGroup sel[i]
				
			)					
		)		
	) 

	) catch()


print "组解散--------完成"
actionMan.executeAction 0 "40021"  -- Selection: Select Al
selectedObjects=getcurrentselection() 
if selectedObjects.count > 0 then for obj in selectedObjects do 
	(

		--sel = getcurrentselection() 

		--中心点底部中心

		--轴心处理 0 0 0
        for obj in selection do
        (
        CenterPivot obj
        obj.pivot.z = 0
        obj.pivot.x = 0
        obj.pivot.y = 0
        --位置处理 0 0 0
        --obj.pos=[0,0,0]
        -- 改为世界中心点
		print "轴心处理-------完成"
        )
        --旋转处理
        Y_UP obj
		print "Y轴心处理-------完成"

        --旋转初始化
        euRotate=eulerAngles -90 0 0 

        obj.rotation = euRotate

		print "旋转初始化-------完成"
		
		if maxFileName !="" then
		(
			global temp_name= maxFileName
			global numberofMax = findString temp_name ".max"
		if numberofMax !=undefined then
		(
			global nameOfFile=replace temp_name numberofMax 4 ""
		)
		)else(
			global nameOfFile = ""
		)
		--获取名字并新建材质球
		-- for i in geometry do i.material = StandardMaterial name:(i.name)
		--添加给多维材质
		local poGetFaceMatID = polyop.getFaceMatID
		local curO = undefined
		local existingMatIds = #()
		local spinnersArr = #()

		if selection.count >= 1 then
		(
			curO = selection[1]
				if classof curO == Editable_Poly do
				(
					for c in spinnersArr do c.enabled = false
					facesCnt = polyop.getNumFaces curO
					
					existingMatIds = #()
					for f = 1 to facesCnt do
						(
							appendIfUnique existingMatIds (poGetFaceMatID curO f)
							
						)
					print existingMatIds.count
					if existingMatIds.count >= 1 do
						(
							--如果一个ID默认同名材质
							for i in geometry do (
								i.material = StandardMaterial name:(i.name)
								i.material.ambient = color 255 255 255
								i.material.Diffuse = color 255 255 255
							)
						)
					--if existingMatIds.count >= 2 do
						--(
							--如果多个材质设置为多维材质
						--	mat = multimaterial()
						--	mat.count = existingMatIds.count
						--	mat.name = nameOfFile
						--	selectedObjects.material=mat

						--	for i=1 to mat.count do
						--	mat[i] = standardmaterial name:(nameOfFile +"-0"+ i as String) diffusecolor:(random black white)
				
						--	meditmaterials[activeMeditSlot] = mat


						--)
				)
		)
		print "材质初始化-------完成"
		actionMan.executeAction 0 "40021"  -- Selection: Select Al
    )else (
        
	Messagebox "No object selected" title: "Unity Tool"
)
