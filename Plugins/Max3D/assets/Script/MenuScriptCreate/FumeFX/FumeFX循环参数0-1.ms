if classof $ != FumeFX Then (Messagebox "Please select FumeFX")
	else(
	
	setTime=animationRange.end/2

	FFXGrp = #()

	for obj in ($* as array) do
		(
			if classof obj == fumefx do
			(
				append FFXGrp obj
			)
		)
	for i = 1 to ffxGrp.count do
		(
			-- 开始动画
			animate on
			(
				-- 在第1帧设置透明度为0
				sliderTime = 0f
				FFXGrp[1].standard.SmokeDensity = 0
				
				-- 中间设置透明度为100
				sliderTime = setTime/2
				FFXGrp[1].standard.SmokeDensity = 1
				
				-- 在最后一帧设置透明度为100
				sliderTime = setTime
				FFXGrp[1].standard.SmokeDensity = 1
			)
			set animate off
		)
)

