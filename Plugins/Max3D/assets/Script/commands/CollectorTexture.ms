/*
 带进度条的贴图收集脚本
 功能：
 1. 收集当前场景所有 BitmapTexture 使用的贴图文件
 2. 复制到当前 .max 文件同级目录下的 Textures 文件夹
 3. 自动重定向贴图路径
 4. 带 UI + 进度条
*/

rollout TextureCollector "收集贴图工具" width:300 height:120
(
    progressbar pb_progress "" pos:[20,40] width:260 height:20 color:(color 100 180 250)
    label lbl_status "等待开始..." pos:[20,70] width:260
    
    button btn_start "开始收集贴图" pos:[90,90] width:120
    
    on btn_start pressed do (
        local sceneFile = maxFilePath
        if sceneFile == "" then (
            messageBox "请先保存场景文件！"
            return false
        )
        
        local texDir = sceneFile + "Textures\\"
        if not (doesFileExist texDir) do (makeDir texDir)
        
        local maps = getClassInstances BitmapTexture
        local total = maps.count
        if total == 0 then (
            messageBox "当前场景没有使用任何贴图。"
            return false
        )
        
        pb_progress.value = 0
        lbl_status.text = "开始收集 " + total as string + " 个贴图..."
        
        local copiedCount = 0
        
        for i = 1 to total do (
            local m = maps[i]
            if m != undefined and m.filename != undefined and m.filename != "" do (
                local src = m.filename
                if doesFileExist src then (
                    local filename = getFilenameFile src + getFilenameType src
                    local dest = texDir + filename
                    
                    -- 复制文件
                    if not (doesFileExist dest) do (
                        copyFile src dest
                    )
                    
                    -- 更新路径
                    m.filename = dest
                    copiedCount += 1
                )
            )
            
            -- 更新进度条
            pb_progress.value = (i as float / total) * 100
            lbl_status.text = "正在处理第 " + i as string + " / " + total as string + " 个贴图..."
            windows.processPostedMessages() -- 刷新 UI
        )
        
        lbl_status.text = "完成！共处理 " + copiedCount as string + " 个贴图。"
        messageBox ("贴图收集完成！\n共处理 " + copiedCount as string + " 个贴图。\n目标目录: " + texDir)
    )
)

createDialog TextureCollector style:#(#style_titlebar, #style_sysmenu, #style_minimizebox)
