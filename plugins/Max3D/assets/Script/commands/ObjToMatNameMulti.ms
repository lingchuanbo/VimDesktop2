selectedObjects = getCurrentSelection()
if selectedObjects.count > 0 then for obj in selectedObjects do 
	(
		--获取名字并新建材质球
		-- for i in geometry do i.material = StandardMaterial name:(i.name)
		--添加给多维材质
		if selection.count >= 1 then
		(
			local selectedGeom = selection as array
			local newMat = multisubmaterial()
			newMat.name = obj.name
			newMat.count = selectedGeom.count
			--meditMaterials[1] = newMat
			--for i in 1 to selectedGeom.count do
			--(
			--	addModifier selectedGeom[i] (Materialmodifier ())
			--	selectedGeom[i].modifiers[#Material].materialID = i
			--	newMat.material[i] = selectedGeom[i].material
			--	selectedGeom[i].material = newMat
			--)
		)
	)else
(
	Messagebox "No object selected" title: "Unity Tool"
)
