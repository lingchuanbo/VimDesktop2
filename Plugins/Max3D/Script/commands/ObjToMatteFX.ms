
selectedObjects = getCurrentSelection()

for i in selectedObjects do
(
	-- 组

	tmpArr = for i in selection where isGroupHead i collect i
	if tmpArr.count > 0 then
		(
			FOR obj in selection where isGroupHead obj DO
			(
				local newMat = matteShadow()
				newMat.receiveshadows = off
				newMat.applyAtmosphere = on
				newMat.atmosphereDepth = 1
				obj.children.material = newMat
				)
			
			)
	-- obj
	if selectedObjects.count > 0 then for i in selectedObjects do
	(
			local newMat = matteShadow()
			newMat.applyAtmosphere = on
			newMat.atmosphereDepth = 1
			newMat.receiveshadows = off
			i.material = newMat
		)
		
)
