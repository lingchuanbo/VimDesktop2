--创建基础FX默认参数
newLayer=LayerManager.newLayerFromName  "---VFXsrc_FumeFX---" 
toggleLayer=LayerManager.getLayerFromName "---VFXsrc_FumeFX---"
toggleLayer.current = on
	
i=FumeFX()
i.name="vfx_FumeFX_1"
i.width = 140
i.length = 140
i.height = 200
i.pwQuality = 5
i.UseFFX4SOLVER = on
i.showFire = off
i.showDensities = on


i.endframe = animationRange.end
i.Playto = animationRange.end

Src=Object_Src ()
Src.name="vfx_FumeFX_Object_Src"
Src.iconSize=100
Src.pos = [200,0,200]

gra=gravityhelper ()
gra.name="vfx_FumeFX_gravity"
gra.iconSize=60
gra.pos = [200,0,100]

i.AddSource Src
i.AddForce gra
