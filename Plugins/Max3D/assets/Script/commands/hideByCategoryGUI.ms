(	
	/**
	    * @file hideByCategoryGUI.ms
	    * @description 3ds Max 类别隐藏/显示统一控制面板
	    * @version 1.0
	    * @author BoBO
	    */
	try
	(		
		-- 销毁已存在的窗口
		if( hideByCategoryDialog != undefined ) then
		(			
			try( destroyDialog hideByCategoryDialog ) catch()
		)
		-- 创建主对话框
		rollout hideByCategoryDialog "类别显示控制 v1.0" width: 300 height: 400
		
		(			
			group "类别控制"
			
			(				
				checkbox chkGeometry "几何体" align: #left offset:[0, 5]
				checkbox chkShapes "图形&编辑样条线" align: #left offset:[0, 5]
				checkbox chkLights "灯光" align: #left offset:[0, 5]
				checkbox chkCameras "摄像机" align: #left offset:[0, 5]
				checkbox chkHelpers "辅助对象" align: #left offset:[0, 5]
				checkbox chkSpacewarps "空间扭曲" align: #left offset:[0, 5]
				checkbox chkParticles "粒子系统" align: #left offset:[0, 5]
				checkbox chkBones "骨骼" align: #left offset:[0, 5]
				checkbox chkModelPrefix "model_开头模型" align: #left offset:[0, 5]
				checkbox chkVFXPrefix "vfx_开头特效" align: #left offset:[0, 5]
			)
			group "预设配置"
			
			(				
				button btnDefault "默认设置" width: 60 height: 25 across: 3
				button btnShowAll "显示全部" width: 60 height: 25
				button btnHideAll "隐藏全部" width: 60 height: 25
			)
			button btnClose "关闭" width: 120 height: 30 align: #center offset:[0, 10]
			-- 初始化函数
			on hideByCategoryDialog open do
			(				
				-- 设置初始状态
				chkGeometry.checked = not hideByCategory.geometry
				chkShapes.checked = not hideByCategory.shapes -- 修正拼写错误
				chkLights.checked = not hideByCategory.lights
				chkCameras.checked = not hideByCategory.cameras
				chkHelpers.checked = not hideByCategory.helpers
				chkSpacewarps.checked = not hideByCategory.spacewarps
				chkParticles.checked = not hideByCategory.particles
				chkBones.checked = not hideByCategory.bones
				chkModelPrefix.checked = true -- 默认显示model_开头的对象
				chkVFXPrefix.checked = true -- 默认显示vfx_开头的对象
				-- 立即执行对应的隐藏/显示功能
				hideByCategory.geometry = not chkGeometry.checked
				hideByCategory.shapes = not chkShapes.checked
				hideByCategory.lights = not chkLights.checked
				hideByCategory.cameras = not chkCameras.checked
				hideByCategory.helpers = not chkHelpers.checked
				hideByCategory.spacewarps = not chkSpacewarps.checked
				hideByCategory.particles = not chkParticles.checked
				hideByCategory.bones = not chkBones.checked
				hideByModelPrefix chkModelPrefix.checked
				hideByVFXPrefix chkVFXPrefix.checked
			)
			-- 实时响应事件
			on chkGeometry changed state do( hideByCategory.geometry = not state )
			on chkShapes changed state do( hideByCategory.shapes = not state )
			on chkLights changed state do( hideByCategory.lights = not state )
			on chkCameras changed state do( hideByCategory.cameras = not state )
			on chkHelpers changed state do( hideByCategory.helpers = not state )
			on chkSpacewarps changed state do( hideByCategory.spacewarps = not state )
			on chkParticles changed state do( hideByCategory.particles = not state )
			on chkBones changed state do( hideByCategory.bones = not state )
			on chkModelPrefix changed state do( hideByModelPrefix state )
			on chkVFXPrefix changed state do( hideByVFXPrefix state )
			-- 默认设置按钮事件
			on btnDefault pressed do
			(				
				chkShapes.checked = false
				chkLights.checked = false
				chkSpacewarps.checked = true
				chkParticles.checked = true
				chkGeometry.checked = true
				chkCameras.checked = false
				chkHelpers.checked = true
				chkBones.checked = false
				chkModelPrefix.checked = true
				chkVFXPrefix.checked = true
				-- 立即执行对应的隐藏/显示功能
				hideByCategory.geometry = not chkGeometry.checked
				hideByCategory.shapes = not chkShapes.checked
				hideByCategory.lights = not chkLights.checked
				hideByCategory.cameras = not chkCameras.checked
				hideByCategory.helpers = not chkHelpers.checked
				hideByCategory.spacewarps = not chkSpacewarps.checked
				hideByCategory.particles = not chkParticles.checked
				hideByCategory.bones = not chkBones.checked
				hideByModelPrefix chkModelPrefix.checked
				hideByVFXPrefix chkVFXPrefix.checked
			)
			-- -- 显示全部按钮事件
			on btnShowAll pressed do
			(				
				chkGeometry.checked = true
				chkShapes.checked = true
				chkLights.checked = true
				chkCameras.checked = true
				chkHelpers.checked = true
				chkSpacewarps.checked = true
				chkParticles.checked = true
				chkBones.checked = true
				chkModelPrefix.checked = true
				chkVFXPrefix.checked = true
				-- 立即执行对应的隐藏/显示功能
				hideByCategory.geometry = not chkGeometry.checked
				hideByCategory.shapes = not chkShapes.checked
				hideByCategory.lights = not chkLights.checked
				hideByCategory.cameras = not chkCameras.checked
				hideByCategory.helpers = not chkHelpers.checked
				hideByCategory.spacewarps = not chkSpacewarps.checked
				hideByCategory.particles = not chkParticles.checked
				hideByCategory.bones = not chkBones.checked
				hideByModelPrefix chkModelPrefix.checked
				hideByVFXPrefix chkVFXPrefix.checked
			)
			-- -- 隐藏全部按钮事件
			on btnHideAll pressed do
			(				
				chkGeometry.checked = false
				chkShapes.checked = false
				chkLights.checked = false
				chkCameras.checked = false
				chkHelpers.checked = false
				chkSpacewarps.checked = false
				chkParticles.checked = false
				chkBones.checked = false
				chkModelPrefix.checked = false
				chkVFXPrefix.checked = false
				-- 立即执行对应的隐藏/显示功能
				hideByCategory.geometry = not chkGeometry.checked
				hideByCategory.shapes = not chkShapes.checked
				hideByCategory.lights = not chkLights.checked
				hideByCategory.cameras = not chkCameras.checked
				hideByCategory.helpers = not chkHelpers.checked
				hideByCategory.spacewarps = not chkSpacewarps.checked
				hideByCategory.particles = not chkParticles.checked
				hideByCategory.bones = not chkBones.checked
				hideByModelPrefix chkModelPrefix.checked
				hideByVFXPrefix chkVFXPrefix.checked
			)
			-- -- -- 关闭按钮事件
			on btnClose pressed do
			(				
				destroyDialog hideByCategoryDialog
			)
		)
		-- 创建并显示对话框
		createDialog hideByCategoryDialog
	)
	catch
	(		
		format "错误: %"( getCurrentException() )
	)
)
-- 添加在文件末尾的函数定义
fn hideByModelPrefix state = 
(	
	-- 获取所有以"model_"开头的对象
	local modelObjects = for obj in objects
	where
		matchPattern obj.name pattern: "model_*" collect
		obj
	if state then
	(		
		-- 显示所有以"model_"开头的对象
		unhide modelObjects
	)
	else
	(		
		-- 隐藏所有以"model_"开头的对象
		hide modelObjects
	)
)
fn hideByVFXPrefix state = 
(	
	-- 获取所有以"vfx_"开头的对象
	local vfxObjects = for obj in objects
	where
		matchPattern obj.name pattern: "vfx_*" collect
		obj
	if state then
	(		
		-- 显示所有以"vfx_"开头的对象
		unhide vfxObjects
	)
	else
	(		
		-- 隐藏所有以"vfx_"开头的对象
		hide vfxObjects
	)
)