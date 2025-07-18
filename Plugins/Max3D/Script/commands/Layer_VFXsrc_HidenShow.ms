--Òþ²ØÏÔÊ¾---VFXsrc---²ã
try
(
	local toggleLayer
	toggleLayer = LayerManager.getLayerFromName "---VFXsrc---"
	if toggleLayer.on then
	(
		toggleLayer.on = off
	)
	else
	(
		toggleLayer.on = on
	)
)
catch()