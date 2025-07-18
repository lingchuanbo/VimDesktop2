
-- polyOp.setFaceMatID $ (polyOp.GetFaceSelection $) 1 快速设置id

global rol_setmatIds 
	try( destroyDialog rol_setmatIds)catch()
	rollout rol_setmatIds "Transfert IDs"
	(	
		local poGetFaceMatID = polyop.getFaceMatID
		local curO = undefined
		local existingMatIds = #()
		local spinnersArr = #()
 
		button btn_getExistingMatIds "Get Existing MatIds" width:100 align:#center
 
		group "MatIds"
		(
			spinner sp01 "01-->" width:90 range:[1,99,1] type:#integer align:#left enabled:false
			spinner sp02 "02-->" width:90 range:[1,99,2] type:#integer align:#left enabled:false
			spinner sp03 "03-->" width:90 range:[1,99,3] type:#integer align:#left enabled:false
			spinner sp04 "04-->" width:90 range:[1,99,4] type:#integer align:#left enabled:false
			spinner sp05 "05-->" width:90 range:[1,99,5] type:#integer align:#left enabled:false
			spinner sp06 "06-->" width:90 range:[1,99,6] type:#integer align:#left enabled:false
			spinner sp07 "07-->" width:90 range:[1,99,7] type:#integer align:#left enabled:false
			spinner sp08 "08-->" width:90 range:[1,99,8] type:#integer align:#left enabled:false
			spinner sp09 "09-->" width:90 range:[1,99,9] type:#integer align:#left enabled:false
			spinner sp10 "10-->" width:90 range:[1,99,10] type:#integer align:#left enabled:false
			spinner sp11 "11-->" width:90 range:[1,99,11] type:#integer align:#left enabled:false
			spinner sp12 "12-->" width:90 range:[1,99,12] type:#integer align:#left enabled:false
			spinner sp13 "13-->" width:90 range:[1,99,13] type:#integer align:#left enabled:false
			spinner sp14 "14-->" width:90 range:[1,99,14] type:#integer align:#left enabled:false
			spinner sp15 "15-->" width:90 range:[1,99,15] type:#integer align:#left enabled:false
			spinner sp16 "16-->" width:90 range:[1,99,16] type:#integer align:#left enabled:false
			spinner sp17 "17-->" width:90 range:[1,99,17] type:#integer align:#left enabled:false
			spinner sp18 "18-->" width:90 range:[1,99,18] type:#integer align:#left enabled:false
			spinner sp19 "19-->" width:90 range:[1,99,19] type:#integer align:#left enabled:false
			spinner sp20 "20-->" width:90 range:[1,99,20] type:#integer align:#left enabled:false
			spinner sp21 "21-->" width:90 range:[1,99,21] type:#integer align:#left enabled:false
			spinner sp22 "22-->" width:90 range:[1,99,22] type:#integer align:#left enabled:false
			spinner sp23 "23-->" width:90 range:[1,99,23] type:#integer align:#left enabled:false
			spinner sp24 "24-->" width:90 range:[1,99,24] type:#integer align:#left enabled:false
		)
 
		button btn_GO "GO" width:100 align:#center
 
		on btn_getExistingMatIds pressed do
		(
			if selection.count == 1 do
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
					if existingMatIds.count != 0 do
					(
						for id in  existingMatIds do 
						(
							spinnersArr[id].enabled = true
						)
					)
				)
			)
		)
 
		on btn_GO pressed do 
		(
			for c = 1 to spinnersArr.count where spinnersArr[c].enabled == true do
			(
				curO.EditablePoly.selectByMaterial c
				curO.EditablePoly.setMaterialIndex spinnersArr[c].value 1
			)
		)
 
		on rol_setmatIds open do
		(
			spinnersArr = for c in rol_setmatIds.controls where classOf c == SpinnerControl collect c
		)
	)	
createDialog rol_setmatIds 110 590