-- 特效文件命名规范
-- By.BoBO

-- 查找分类代码
-- selectedObjects = selection as array  
  
-- for obj in selectedObjects do  
-- (  
--     className = classof obj  
	
-- 	className2 = superclassof obj
      
--     -- 根据类名判断对象类型  
-- 	print(className)
-- 	print(className2)

-- )
for obj in selection do
(
    -- 模型
    if superclassof obj == GeometryClass then
    (
		-- 粒子
		if classof obj == SuperSpray then
		(
			obj.name = "vfx_pt_" + obj.name
		)
		else if classof obj == PArray then
		(
			obj.name = "vfx_pt_" + obj.name
		)
		else if classof obj == PCloud then
		(
			obj.name = "vfx_pt_" + obj.name
		)
		else if classof obj == Spray then
		(
			obj.name = "vfx_pt_" + obj.name
		)else
		(
			-- 非粒子模型
			obj.name = "vfx_" + obj.name
		)
    )
    -- 辅助
    else if superclassof obj == SpacewarpObject then
    (
        obj.name = "vfx_pt_sw_" + obj.name
    )
	-- 辅助
	else if superclassof obj == shape then
	(
		obj.name = "vfx_shapes_" + obj.name
	)
	-- 灯光
    else if superclassof obj == Light then
    (
        obj.name = "vfx_light_" + obj.name
    )
    -- 摄像机
    else if superclassof obj == Camera then
    (
        obj.name = "vfx_cam_" + obj.name
    )
	-- 帮助
	else if superclassof obj == Helper then
    (
        obj.name = "vfx_help_" + obj.name
    )
	
)
