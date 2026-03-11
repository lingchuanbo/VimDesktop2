-- by BoBO
-- 删除隐藏模型
(
	undo "Delete Hidden Models (Exclude Helpers, Bones & Biped)" on
	(
		local objectsToDelete = #()
		local deleteCount = 0
		
		-- 直接排除的类名列表
		local excludeClasses = #(
			BoneGeometry,  -- 标准骨骼
			Biped_Object,  -- Biped对象
			Point,         -- 点辅助对象
			Dummy          -- 虚拟对象
		)
		
		for obj in objects do
		(
			local classMatch = false
			local objClass = classof obj
			
			-- 检查对象类是否在排除列表中
			for excludeClass in excludeClasses do
			(
				if classof obj == excludeClass then
				(
					classMatch = true
					exit -- 找到匹配后立即退出
				)
			)
			
			-- 核心条件：
			-- 1. 对象隐藏
			-- 2. 可以转换为可编辑多边形（确保是模型）
			-- 3. 不在排除类列表中
			if obj.isHidden and 
			   (canConvertTo obj Editable_Poly) and 
			   not classMatch then
			(
				append objectsToDelete obj
			)
		)

		if objectsToDelete.count > 0 then
		(
			delete objectsToDelete
			deleteCount = objectsToDelete.count
		)
		
		clearListener()
		format "操作完成: 共删除了 % 个隐藏的模型对象。\n" deleteCount
		print "提示: 所有辅助对象 (如 Bone, Biped, Dummy 等) 和骨骼系统已被安全保留。"
	)
)