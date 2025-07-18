selectedObjects = getCurrentSelection()

if selectedObjects.count > 0 then for obj in selectedObjects do 
	(

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
					if existingMatIds.count == 1 do
						(
							--如果一个ID默认同名材质
							for i in geometry do i.material = StandardMaterial name:(i.name)
						)
					if existingMatIds.count >= 2 do
						(
							--如果多个材质设置为多维材质
							mat = multimaterial()
							mat.count = existingMatIds.count
							mat.name = nameOfFile
							selectedObjects.material=mat

							for i=1 to mat.count do
							mat[i] = standardmaterial name:(nameOfFile +"-0"+ i as String) diffusecolor:(random black white)
				
							meditmaterials[activeMeditSlot] = mat


						)
				)
		)
	)else(
		Messagebox "No object selected" title: "BoBO"
)
