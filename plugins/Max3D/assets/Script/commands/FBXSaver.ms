

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

	rollout import_fbx "FBX Saver" width:162 height:225
	(
		button 'btn1' "Save" pos:[36,175] width:90 height:32 align:#left
		button 'btn2' "Update" pos:[36,140] width:90 height:32 align:#left
		button 'btn3' "Location" pos:[101,92] width:51 height:20 align:#left

		editText 'edt1' "" text:nameOfFile pos:[10,20] width:140 height:25 align:#left

		label 'lbl1' "FBXName" pos:[67,4] width:64 height:14 align:#left
		label 'lbl2' maxFilePath pos:[15,94] width:83 height:20 align:#left
		label 'lbl3' "Start" pos:[30,52] width:27 height:14 align:#left
		label 'lbl4' "End" pos:[106,52] width:21 height:14 align:#left
		label 'lbl5' "Created by BoBO" pos:[35,210] width:100 height:14 align:#left
		label 'lbl6' "FPS" pos:[130,116] width:21 height:14 align:#left

		spinner 'spn1' "" pos:[19,70] width:54 height:16 range:[-1,1000,AnimationRange.Start] type:#integer scale:1  align:#left
		spinner 'spn2' "" pos:[92,70] width:54 height:16 range:[0,1000,AnimationRange.End] type:#integer scale:1  align:#left
		spinner 'spn3' "" pos:[80,115] width:40 height:16 range:[1,1000,30] type:#integer scale:1  align:#left

		checkbox 'chk1' "Animation" pos:[10,115] width:60 height:16 align:#left

		on btn1 pressed do
		(
			framerate = spn3.value
			AnimationRange = interval spn1.value spn2.value
		f = lbl2.caption + "/" + edt1.text +".fbx"
			/*messagebox f*/
			FBXExporterSetParam "SmoothingGroups" true
			FBXExporterSetParam "SmoothMeshExport" true
			FBXExporterSetParam "GeomAsBone" false
			FBXExporterSetParam "PreserveEdgeOrientation" false
			exportFile f #noPrompt selectedOnly:true using:FBXEXP
		)

		on chk1 changed theState do
		(
			if chk1.checked == true then
			(
				FBXExporterSetParam "Animation" true
				)
				else
				(
					FBXExporterSetParam "Animation" false
					)
		)
		
		on spn3 changed onetrue do
		(
			framerate = spn3.value
		)
		
		on btn2 pressed do
			(
				framerate = spn3.value
			AnimationRange = interval spn1.value spn2.value
			)
		on btn3 pressed do
		(
			temp_path = getSavepath()
			if temp_path !=undefined then
			(
				lbl2.caption = temp_path 
			)
		)
	)
	createDialog import_fbx
)
else 
(
	Messagebox "No object selected" title: "Unity Tool"
)


