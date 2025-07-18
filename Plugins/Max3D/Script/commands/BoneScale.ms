/*
此脚本用于整体缩放带骨骼的角色场景，主要使用max自带的Rescale World Unites功能
但对于 MAX 普通 bone 的缩放不正常现象进行了修正

*/


linkColor = (color 0 250 200)
try(DestroyDialog Rollout_StdToolsForBoneAndCS) catch()
Rollout Rollout_StdToolsForBoneAndCS "骨骼缩放" width:175
(

	spinner spnScaleValue "设置缩放值" range:[0.002,10000,1.0] align:#Left
	button Resize_btn "执行" width:100 align:#Center


	Fn rescaleScene scaleFactor = (
		undo "Create End" on (
			newEndBoneLst = #()
			boneChildren = #()
			boneObjs = #()

			bipParent = undefined


			-- 为所有常规骨骼创建末端骨骼，以确保它们可以正确缩放 
			boneObjs = for obj in objects where ((ClassOf obj) as string) == "BoneGeometry" collect obj
			if boneObjs.count > 0 then ( -- 选择所有骨骼对象
				for obj in boneObjs do (
					boneChildren = for child in obj.children where ((ClassOf child) as string) == "BoneGeometry" collect child
					if boneChildren.count == 0 then ( -- do with none bone-child bone
						with Animate Off (  --with Animate Off bracket open
							local parentBone  = obj
							local parentTrans = parentBone.transform
							local parentPos   = parentTrans.translation
							local newbone


							newBone=BoneSys.createBone parentPos (parentPos+6) parentBone.dir
							newBone.transform = parentTrans
							in coordSys Local move newBone [parentBone.length,0,0]

							newBone.parent	= parentBone
							append newEndBoneLst newBone

							newBone.width	 = parentBone.width
							newBone.height	= parentBone.height
							newBone.taper	 = 90
							newBone.length	= (parentBone.width+parentBone.height)/2
							newBone.wirecolor = parentBone.wirecolor
						) -- with Animate Off bracket close
					)
				)
			)

			-- do scale
			rescaleWorldUnits scaleFactor

			-- 重新拉伸常规骨骼以解决皮肤问题
			for obj in objects where ((ClassOf obj) as string) == "BoneGeometry" do (
				obj.resetBoneStretch()
			)
			delete newEndBoneLst

			-- 移动 CS bip01 水平位置以匹配比例
			-- 检查是否有cs骨骼，并记录cs控制器
			bipedBone = for obj in objects where classOf obj == Biped_Object collect obj
			biped_ctrl = undefined
			if bipedBone.count > 0 then (
			    for obj in bipedBone do (
			        try  
			        if (obj.transform.controller) as string == "Controller:Body" then (
			            -- 获取用于操作的 Biped 控制器
			            biped_ctrl = obj.transform.controller
			            -- 获取bip01节点
						biped_ctrl.moveAllMode = true
						bipNode = biped.getNode biped_ctrl #horizontal 
						-- 如果 bip01 的父级无法使用 moveAllMode 移动
						bipParent = bipNode.parent
						if bipParent != undefined then (
							bipNode.parent = undefined
						)
						-- 获取原始 位置
						oriPos = biped.getTransform bipNode #pos
						-- newScaleFactor = 0.5 + 0.5*scaleFactor 
						newPos = [oriPos[1]*scaleFactor,oriPos[2]*scaleFactor,oriPos[3]]

						-- 移动
						biped.setTransform bipNode #pos newPos false
						biped_ctrl.moveAllMode = false
						-- 恢复父级
						if bipParent != undefined then (
							bipNode.parent = bipParent
						)
			        )
			        catch()
			    )
			)
			clearSelection()
			redrawViews()

		)
	)
	on Resize_btn pressed do (
		currentSelection = #()
		for obj in selection do ( append currentSelection obj )
		rescaleScene spnScaleValue.value
		select currentSelection
	)
)


createDialog Rollout_StdToolsForBoneAndCS

linkObjs = for i in $Objects where classOf i.controller == Link_Constraint collect i

for obj in linkObjs do(
	if iskindof obj BoneGeometry then(
		obj.boneEnable = false
	)
	linkNode = ( obj.controller.getNode 1 )
	obj.Transform.controller = prs()
	obj.parent = linkNode
)