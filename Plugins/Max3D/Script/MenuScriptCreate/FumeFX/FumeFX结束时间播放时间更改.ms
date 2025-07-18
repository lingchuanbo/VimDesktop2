if classof $ != FumeFX Then (Messagebox "Please select FumeFX")
	else(

		
	setTime=animationRange.end


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
			FFXGrp[i].Playto = setTime
			FFXGrp[i].endframe = setTime
		)
	
)

