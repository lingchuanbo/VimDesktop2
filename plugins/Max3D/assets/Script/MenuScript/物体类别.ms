-- 确保有物体被选中
if selection.count == 1 then
(
	local obj = selection[1] -- 获取选中的第一个物体
	
	-- 格式化输出信息
	messagebox (
		"物体名称: " + obj.name + "\n" +
		"超类 (SuperClass): " + (superClassOf obj as string) + "\n" +
		"具体类 (Class): " + (classOf obj as string)
	) title:"物体类别信息"
)
else if selection.count > 1 then
(
	messagebox "请只选择一个物体。"
)
else
(
	messagebox "请先选择一个物体。"
)