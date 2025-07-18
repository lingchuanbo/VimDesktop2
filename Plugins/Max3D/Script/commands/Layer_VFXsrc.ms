--LayerManager.newLayerFromName "---VFX---" --创建VFX层
--LayerManager.current.on

if sceneexplorermanager.ExplorerIsOpen "Scene Explorer" == false then 
(
	macros.run "Scene Explorer" "SESceneExplorer"
	sceneexplorermanager.OpenExplorer "Scene Explorer"
)
else
(
	sceneexplorermanager.CloseExplorer "Scene Explorer"
)

if sceneexplorermanager.ExplorerIsOpen "Layer Explorer" == false then 
(
	sceneexplorermanager.OpenExplorer "Layer Explorer"
	macros.run "Scene Explorer" "SELayerExplorer"
)
else
(
	sceneexplorermanager.CloseExplorer "Layer Explorer"
	--macros.run "Scene Explorer" "SELayerExplorer"
)

if (sceneexplorermanager.ExplorerIsOpen "Workspace: Default" == ture) then
(
	sceneexplorermanager.CloseExplorer "Workspace: Default"
)
	
for i = 0 to layerManager.count-1 do
(
	ilayer = layerManager.getLayer i
	layerName = ilayer.name

	if layerName == "---VFXsrc---" then
		(
			toggleLayer=LayerManager.getLayerFromName "---VFXsrc---"
			toggleLayer.current = on

		)else(
			
			layer1=LayerManager.newLayerFromName  "---VFXsrc---"
			layer2=LayerManager.newLayerFromName  "1-VFX-粒子"
			layer3=LayerManager.newLayerFromName  "2-VFX-烟雾"
			layer4=LayerManager.newLayerFromName  "3-VFX-外发光"
			layer5=LayerManager.newLayerFromName  "4-VFX-面片" 
			layer6=LayerManager.newLayerFromName  "5-VFX-拖尾" 
			toggleLayer=LayerManager.getLayerFromName "---VFXsrc---"
			toggleLayer.on = on
			toggleLayer.current = on
			toggleLayer.name
			
		)
	)
