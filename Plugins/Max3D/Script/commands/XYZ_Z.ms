selectedObjects = getCurrentSelection()
if selectedObjects.count > 0 then for obj in selectedObjects do 
	(
        for obj in selection do
        (
        CenterPivot obj  --���Ĺ�����
        -- obj.pivot.z = obj.min.z  --物体z

        obj.pivot.z = 0
        obj.pivot.x = 0
        obj.pivot.y = 0
        -- 改为世界中心点
        )
    )else (
        
	Messagebox "No object selected" title: "Unity Tool"
)

