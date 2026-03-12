/*
 * 功能: 基于Render53.ms框架的渲染脚本，合并了Render.ms中的BaseDefOutputDir函数
 * 逻辑: 检测场景中是否有名为"大"的虚拟体，如果没有则执行BaseDefOutputDir函数进行基本渲染
 * 作者: BoBO
 * 日期: 2025-6-8
 */
-- ===================================================================
-- 1. 参数设置
-- ===================================================================
helperName = "大" -- 目标虚拟体的名字
rotationIncrement = -45.0 -- 每次旋转的角度
-- 方向 5 的参数
targetAngle5_Min = -50.0
targetAngle5_Max = -40.0
outputSuffix5 = "5" -- 对应方向 5 的文件夹和命名后缀
-- 方向 3 的参数
targetAngle3_Min = -140.0
targetAngle3_Max = -130.0
outputSuffix3 = "3" -- 对应方向 3 的文件夹和命名后缀
theName = "10000"
Prefix = ".tga"
-- ===================================================================
-- 2. 辅助函数定义
-- ===================================================================
/**
 * 旋转指定物体的Z轴
 * @param {Node} obj - 要旋转的物体
 * @param {Float} angle - 旋转角度
 * @returns {Boolean} 旋转是否成功
 */
fn rotateObjectZ obj angle = 
(	
	if isValidNode obj then
	(		
		rotate obj( angleaxis angle[0, 0, 1] )
		true
	)
	else
	(		
		false
	)
)
/**
 * 执行渲染的函数
 * @param {String} outputFolder - 输出文件夹路径
 * @param {String} fileNamePrefix - 文件名前缀
 */
fn executeRender outputFolder fileNamePrefix = 
(	
	if not( doesFileExist outputFolder ) do( makeDir outputFolder )
	local renderOutputPath = outputFolder + "\\" + theName + Prefix
	local cameraName = "Camera" -- 要使用的摄像机名称
	local targetCamera = getNodeByName cameraName
	try
	(		
		-- 检查摄像机是否存在
		if( getNodeByName "Camera" )!= undefined do
		(			
			-- 设置渲染引擎（默认扫描线）
			renderers.current = Default_Scanline_Renderer()
			-- 设置TGA输出格式
			tgaio.setAlphaSplit false
			tgaio.setPreMultAlpha true
			rendOutputFileName = renderOutputPath
			format "准备渲染, 输出路径: %\n" renderOutputPath
			actionMan.executeAction 0 "50031" -- Render: Render
			format "渲染完成! 文件已保存到: %\n" renderOutputPath
		)
	)
	catch
	(		
		format "--- 渲染失败 ---\n\n"
	)
)
/**
 * 基本默认输出目录函数（来自Render.ms）
 * 当场景中没有虚拟体时执行基本渲染
 */
fn BaseDefOutputDir = 
(	
	theName = "10000"
	Prefix = ".tga"
	str = maxfilename
	strName = replaceSub str ".max" "" + "\\"
	outPutDir = maxfilepath + strName
	-- 创建文件夹
	makeDir outPutDir
	outPutFiledir = outPutDir + theName + Prefix
	rendOutputFileName = outPutFiledir
	actionMan.executeAction 0 "50031" -- Render: Render
)
-- ===================================================================
-- 3. 主逻辑
-- ===================================================================
clearListener()
format "脚本开始执行...\n"
targetNode = getNodeByName helperName
-- 判断是否有虚拟体"大"
if targetNode == undefined then
(	
	format "场景中未找到名为 \"%\" 的虚拟体，执行基本渲染...\n" helperName
	BaseDefOutputDir()
	format "基本渲染完成!\n"
)
else
(	
	-- 有虚拟体，执行多角度渲染流程
	format "成功找到虚拟体: '%'\n" targetNode.name
	select targetNode
	-- 必须先保存MAX文件，才能确定输出路径
	if maxFilePath == "" then
	(		
		messageBox "错误: MAX文件尚未保存，无法确定输出路径。请先保存文件。"
	)
	else
	(		
		local maxFileNameWithoutExt = getFilenameFile maxFileName
		local maxFileDir = getFilenamePath maxFileName
		-- === 第一阶段: 旋转并渲染方向 5 ===
		format "--- 第一阶段: 处理方向 5 ---\n"
		-- 使用负号修正法读取角度
		local currentZ_Rotation = -( ( targetNode.rotation as eulerangles ).z_rotation )
		format "初始Z轴角度 (修正后): %.2f°\n" currentZ_Rotation
		local safetyCounter = 0
		while
			not( currentZ_Rotation >= targetAngle5_Min and currentZ_Rotation <= targetAngle5_Max ) and safetyCounter < 8 do
		(			
			format "当前角度 %.2f° 不在范围 [-50,-40] 内, 正在旋转...\n" currentZ_Rotation
			rotateObjectZ targetNode rotationIncrement
			currentZ_Rotation = -( ( targetNode.rotation as eulerangles ).z_rotation )
			format "旋转后，新角度 (修正后): %.2f°\n" currentZ_Rotation
			safetyCounter += 1
			if safetyCounter >= 8 then
			(				
				messageBox "警告: 旋转超过8次仍未达到方向5，脚本已中止。"
				exit
			)
			sleep 0.1
		)
		format "成功到达方向 5 的范围 (角度: %.2f°)。开始渲染...\n" currentZ_Rotation
		local outputPath5 = maxfilepath + maxFileNameWithoutExt + outputSuffix5 + "\\"
		format "渲染-------路径: %\n" outputPath5
		executeRender outputPath5( maxFileNameWithoutExt + outputSuffix5 )
		-- === 第二阶段: 旋转并渲染方向 3 ===
		format "\n--- 第二阶段: 处理方向 3 ---\n"
		format "从当前位置再旋转 -45°...\n"
		rotateObjectZ targetNode -90.0
		currentZ_Rotation = -( ( targetNode.rotation as eulerangles ).z_rotation )
		format "旋转后，新角度 (修正后): %.2f°\n" currentZ_Rotation
		if not( currentZ_Rotation >= targetAngle3_Min and currentZ_Rotation <= targetAngle3_Max ) and safetyCounter < 2 do
		(			
			format "警告: 当前角度 %.2f° 不在预期的方向 3 范围 [-140°, -130°] 内。\n" currentZ_Rotation
			rotateObjectZ targetNode rotationIncrement
			currentZ_Rotation = -( ( targetNode.rotation as eulerangles ).z_rotation )
			format "旋转后，新角度 (修正后): %.2f°\n" currentZ_Rotation
			safetyCounter += 1
			if safetyCounter >= 2 then
			(				
				messageBox "警告: 旋转超过2次仍未达到方向3，脚本已中止。"
				exit
			)
			sleep 0.1
		)
		format "开始渲染方向 3...\n"
		local outputPath3 = maxfilepath + maxFileNameWithoutExt + outputSuffix3 + "\\"
		executeRender outputPath3( maxFileNameWithoutExt + outputSuffix3 )
		format "所有任务已完成。\n"
	)
)
） 