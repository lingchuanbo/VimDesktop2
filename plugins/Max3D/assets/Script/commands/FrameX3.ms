-- https://help.autodesk.com/view/3DSMAX/2017/ENU/?guid=__files_GUID_30AF1E53_5A69_402D_84D6_4D6ECCDD6D20_htm
-- 帮助文档
-- 拉长帧率操作
-- 当前帧率为 8 改为帧率 24 并设置 隔 3 渲染
-- By:BoBO



-- 当前帧率为 8 改为帧率 30 并设置 隔 3 渲染
if (frameRate==8f) then (
	frameRate = 24f
	rendNThFrame =3
	setranges=animationRange.end * 2
	print setranges
	animationRange = (interval 0f setranges)
	)

-- 当前帧率为 10 改为帧率 30 并设置 隔 3 渲染
if (frameRate==10f)then (
	frameRate = 30f
	rendNThFrame =3
	setranges=animationRange.end * 2
	print setranges
	animationRange = (interval 0f setranges)
	)