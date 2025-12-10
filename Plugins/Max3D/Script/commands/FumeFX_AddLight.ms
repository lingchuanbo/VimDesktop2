-- FX快速设置
-- ByBoBO

fn createLight =
	(
	delete lights
	_Fumefx	 = $ 
	TargetDirectionallight name:"vfx_FxLight"   transform: cameras[1].transform target:(Targetobject name:"vfx_FxLight.Target" transform:(matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0]))
	$vfx_FxLight.wirecolor=(color 255 0 0)

	RGBLights = #()

	RGBLights[1] = $vfx_FxLight


	for i = 1 to rgbLights.count do
	(

		RGBLights[i].baseobject.multiplier = 1
		RGBLights[i].baseobject.falloff = 80
		RGBLights[i].baseobject.hotspot = 50
		RGBLights[i].baseobject.castshadows = on
		RGBLights[i].baseobject.shadowmultiplier = 3
		RGBLights[i].baseobject.atmosShadows = on
		RGBLights[i].baseobject.showCone = on
		RGBLights[i].baseobject.overshoot = on
		RGBLights[i].shadowGenerator = shadowMap()
		RGBLights[i].lightAffectsShadow = on
		RGBLights[i].rgb = color 255 255 255
				
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
			FFXGrp[i].pwQuality = 5
			
			FFXGrp[i].EnableFuel = off

			FFXGrp[i].UseFFX4SOLVER = on
			FFXGrp[i].TimeScale = 1.6
			FFXGrp[i].VorticityStrength = 0.1
			FFXGrp[i].VelDiffusion = 1

			FFXGrp[i].XAxisTurbulence = 0.02
			
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

cameraCount = 0
for i in cameras do
	cameraCount += 1

if cameraCount>0 then
	if classof $ != FumeFX Then (Messagebox "未选中FumeFX ")
	else(CreateLight())
else 
	Messagebox "没有摄像机 获取不到灯光位置哦"
	
