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
)
	
	
rollout roll_MSOP "M_MultiMaterial ByBoBO" width:350 height:496
(	
	group "Create:"

		(
			editText basename "Material Base Name: " width:190 height:16 text:nameOfFile
			
			button btn_MSStandard "Standard Multi/Sub" tooltip:"Create Standard Multi/Sub Material" width:100 height:20 align:#left across:2
			spinner spn_stdnum_mtl "Count:" tooltip:"Number of Multi/Sub Materials" width:50 height:16 range:[2,100,2] type:#integer fieldwidth:35 align:#right
			editText basename2 "设置完在执行FBX导出" align:#center width:110 height:15
		)

		on btn_MSStandard pressed do
			
		(	
			selectedObjects = getCurrentSelection()
			if selectedObjects.count > 0 then for obj in selectedObjects do 
			(
			mat = multimaterial()
			mat.count = spn_stdnum_mtl.value
			mat.name = basename.text as String
			selectedObjects.material=mat

			for i=1 to mat.count do
			mat[i] = standardmaterial name:(basename.text +"-0"+ i as String) diffusecolor:(random black white)

			meditmaterials[activeMeditSlot] = mat
				
			)else(
				
				Messagebox "No object selected" title: "BoBO"
				
			)


		)
)

createDialog roll_MSOP 210 90