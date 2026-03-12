if classof $ != FumeFX Then (Messagebox "Please select FumeFX")
	else(

		
	setTime=animationRange.end/2

	FFXGrps = #()

	for obj in ($* as array) do
		(
			if classof obj == fumefx do
			(
				append FFXGrps obj
			)
		)
	for i = 1 to ffxGrps.count do
		(
			FFXGrps[1].offset = -setTime
			-- 开始动画
			animate on
			(
				-- 在第1帧设置透明度为0
				sliderTime = 0f
				FFXGrps[1].standard.SmokeDensity = 1
				
				sliderTime = setTime/2
				FFXGrps[1].standard.SmokeDensity = 1
				
				-- 在第25帧设置透明度为100
				sliderTime = setTime
				FFXGrps[1].standard.SmokeDensity = 0
			)
			set animate off
			
		)
	
)

