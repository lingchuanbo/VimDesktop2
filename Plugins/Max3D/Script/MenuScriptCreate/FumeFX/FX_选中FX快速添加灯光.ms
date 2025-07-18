-- 快速添加FX灯光
-- ByBoBO

fn createLight =
	(
-- delete all lights t = $.transform
	delete lights
	-- if $RGB_Rig != undefined do (delete $RGB_Rig)[0.709569,-0.704636,0] [0.510811,0.514387,0.688824] [-0.48537,-0.488768,0.724929] [-508.599,-512.16,759.623]
	_Fumefx	 = $ 
-- Construct Lights 灯光位置 为摄像机
	-- TargetDirectionallight name:"Spot_BackLight1"  transform:(matrix3 [-0.342328,0.939581,0] [-0.330589,-0.120447,0.936058] [0.879502,0.320439,0.351847] [316.223,102.167,120.162]) target:(Targetobject transform:(matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]))
	-- TargetDirectionallight name:"Spot_BackLight2"  transform:(matrix3 [-0.563888,-0.825851,0] [0.344059,-0.234922,0.909085] [-0.750769,0.512622,0.416611] [-225.134,148.736,120.162]) target:(Targetobject transform:(matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]))
	--TargetDirectionallight name:"FXLight_VFX"   transform: (matrix3 [0.758336,-0.651864,0] [0.439158,0.510887,0.739009] [-0.481734,-0.560417,0.673695] [-146.621,-170.569,205.047]) target:(Targetobject name:"FXLight_VFX.Target" transform:(matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]))
	TargetDirectionallight name:"FXLight_VFX"   transform: cameras[1].transform target:(Targetobject name:"FXLight_VFX.Target" transform:(matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]))
	-- TargetDirectionallight name:"Spot_Fill" transform: (matrix3 [1,0,0] [0,-1.62921e-007,1] [0,-1,-1.62921e-007] [1.73965,-229.537,54.691])
	-- point name:"RGB_Rig" position:[0,0,0]
	$FXLight_VFX.wirecolor=(color 255 0 0)

	RGBLights = #()
	-- RGBLights[1] = $spot_BackLight1
	-- RGBLights[2] = $spot_BackLight2
	RGBLights[1] = $FXLight_VFX
	-- RGBLights[4] = $spot_Fill
	-- RGBLights.parent = $RGB_Rig

	for i = 1 to rgbLights.count do
	(
		-- if vray == undefined then 
		-- 	(
				
		RGBLights[i].baseobject.multiplier = 1
		RGBLights[i].baseobject.falloff = 80
		RGBLights[i].baseobject.hotspot = 50
		RGBLights[i].baseobject.castshadows = on
		RGBLights[i].baseobject.shadowmultiplier = 3
		RGBLights[i].baseobject.atmosShadows = on
		RGBLights[i].baseobject.showCone = on
		RGBLights[i].baseobject.overshoot = on
			-- RGBLights[i].shadowGenerator = raytraceShadow()	
		RGBLights[i].shadowGenerator = shadowMap()
		RGBLights[i].lightAffectsShadow = on
		RGBLights[i].rgb = color 255 255 255
				

			-- )
			-- else
			-- (
				
			-- 	RGBLights[i].baseobject.multiplier = 1
			-- 	RGBLights[i].baseobject.falloff = 80
			-- 	RGBLights[i].baseobject.hotspot = 50
			-- 	RGBLights[i].baseobject.castshadows = on
			-- 	RGBLights[i].baseobject.atmosShadows = on
			-- 	RGBLights[i].baseobject.showCone = on
			-- 	RGBLights[i].baseobject.overshoot = on
			-- 	RGBLights[i].baseobject.shadowmultiplier = 3
			-- 	RGBLights[i].shadowGenerator = vrayShadow()
			-- )
	)
	
	FFXGrp = #()
	MyLights = #()
	tmpLights = lights as array

	-- Collect all Fume Grids
		for obj in ($* as array) do
		(
			if classof obj == fumefx do
			(
				append FFXGrp obj
			)
		)

	-- Sort through lights, exclude Target Lights
		for lights in tmplights do
		(
			if classof lights != TargetObject do
			(
				append MyLights Lights
			)
		)

	-- Modify Fume Color Properties
		for i = 1 to ffxGrp.count do
		(
			FFXGrp[i].gridSpacing = 2
			
			FFXGrp[i].EnableFuel = off
			
			FFXGrp[i].standard.ShadeFire = off
			
			FFXGrp[i].standard.SmokeColorSource = 0
			FFXGrp[i].standard.SmokeAmbientColor = [15,15,15]
			FFXGrp[i].standard.smoke_color_gradient.key_0.color = [0,0,0]
			FFXGrp[i].standard.smoke_color_gradient.key_1.color = [0,0,0]

			FFXGrp[i].standard.castShadows = on
			FFXGrp[i].standard.receiveshadows = on
		-- 	FFXGrp[i].standard.SmokeDensity = 1
			for L = 1 to myLights.count do
			(
			FFXGrp[i].addlight mylights[L]
			)
			--set animate on
			--FFXGrp[i].standard.SmokeDensity = 0
			--sliderTime = 5f
			--FFXGrp[i].standard.SmokeDensity = 1
			--sliderTime = 10f
			--FFXGrp[i].standard.SmokeDensity = 1
		)

		-- $RGB_Rig.transform   = _FumeFX.transform 
	)

if classof $ != FumeFX Then (Messagebox "Please select FumeFX")
	else(CreateLight())