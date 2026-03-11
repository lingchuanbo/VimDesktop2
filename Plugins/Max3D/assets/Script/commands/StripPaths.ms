(
	local renderSD_state = false
	local render_outputs = #(), preset_files = #()
	local rc = renderers.current
	local prps = getPropNames rc
	local nmv = batchRenderMgr.numViews
	
	if renderSceneDialog.isOpen() do (renderSD_state = true ; renderSceneDialog.close())
		
    render_outputs = for i = 1 to prps.count where (try(classof (p = (getProperty rc prps[i])) == string)catch(false)) collect (#(prps[i],p))
		
	if nmv != 0 do (
		for i = 1 to nmv where (p = (batchRenderMgr.GetView i).presetFile) != "" do appendIfUnique preset_files (#(i,p))
	)
		
	--ATSOps.visible = true
	--ATSOps.Refresh()
	ATSOps.SetPath ""
	--ATSOps.visible = false
		
	prps = getPropNames rc
	local temp_arr = for i = 1 to prps.count where (try(classof (p = (getProperty rc prps[i])) == string)catch(false)) collect (#(prps[i],p))
		
	for i = 1 to render_outputs.count where (render_outputs[i][2] != temp_arr[i][2]) do setProperty rc render_outputs[i][1] render_outputs[i][2]
		
	if preset_files.count != 0 do (
		for i = 1 to preset_files.count do (
			(batchRenderMgr.GetView preset_files[i][1]).presetFile = preset_files[i][2]
		)
	)
		
	ATSOps.Refresh()
		
	if renderSD_state do renderSceneDialog.open()
)