/*
 增强版贴图收集脚本
 功能：
 1. 列表展示当前场景所有 BitmapTexture 使用的贴图文件
 2. 可选择性收集贴图到当前 .max 文件同级目录下的 Textures 文件夹
 3. 自动重定向贴图路径
 4. 带 UI + 进度条 + 贴图列表
*/

rollout TextureCollectorAdvanced "增强版贴图收集工具" width:500 height:400
(
    -- UI 控件
    label lbl_info "场景贴图列表：" pos:[10,10] width:480
    multiListBox mlb_textures "" pos:[10,30] width:480 height:15
    
    button btn_selectAll "全选" pos:[10,280] width:60
    button btn_selectNone "全不选" pos:[80,280] width:60
    button btn_refresh "刷新列表" pos:[150,280] width:80
    
    progressbar pb_progress "" pos:[10,310] width:480 height:20 color:(color 100 180 250)
    label lbl_status "等待开始..." pos:[10,340] width:480
    
    button btn_collect "收集选中贴图" pos:[190,365] width:120
    
    -- 全局变量
    local textureList = #()
    local textureObjects = #()
    
    -- 刷新贴图列表
    function refreshTextureList = (
        textureList = #()
        textureObjects = #()
        
        local maps = getClassInstances BitmapTexture
        local displayNames = #()
        
        for m in maps do (
            if m != undefined and m.filename != undefined and m.filename != "" do (
                local filename = filenameFromPath m.filename
                local exists = if (doesFileExist m.filename) then "✓" else "✗"
                local displayName = exists + " " + filename + " (" + m.filename + ")"
                
                append textureList m.filename
                append textureObjects m
                append displayNames displayName
            )
        )
        
        mlb_textures.items = displayNames
        -- 默认全选
        local selArray = #()
        for i = 1 to displayNames.count do append selArray i
        mlb_textures.selection = selArray
        
        lbl_status.text = "找到 " + maps.count as string + " 个贴图，其中 " + textureList.count as string + " 个有效"
    )
    
    -- 界面初始化
    on TextureCollectorAdvanced open do (
        refreshTextureList()
    )
    
    -- 全选按钮
    on btn_selectAll pressed do (
        local selArray = #()
        for i = 1 to mlb_textures.items.count do append selArray i
        mlb_textures.selection = selArray
    )
    
    -- 全不选按钮
    on btn_selectNone pressed do (
        mlb_textures.selection = #()
    )
    
    -- 刷新按钮
    on btn_refresh pressed do (
        refreshTextureList()
    )
    
    -- 收集贴图按钮
    on btn_collect pressed do (
        local sceneFile = maxFilePath
        if sceneFile == "" then (
            messageBox "请先保存场景文件！"
            return false
        )
        
        local selectedIndices = mlb_textures.selection as array
        if selectedIndices.count == 0 then (
            messageBox "请至少选择一个贴图！"
            return false
        )
        
        local texDir = sceneFile + "Textures\\"
        if not (doesFileExist texDir) do (makeDir texDir)
        
        local total = selectedIndices.count
        pb_progress.value = 0
        lbl_status.text = "开始收集 " + total as string + " 个选中贴图..."
        
        local copiedCount = 0
        local skippedCount = 0
        local errorCount = 0
        
        for i = 1 to total do (
            local idx = selectedIndices[i]
            local src = textureList[idx]
            local texObj = textureObjects[idx]
            
            try (
                if doesFileExist src then (
                    local filename = getFilenameFile src + getFilenameType src
                    local dest = texDir + filename
                    
                    -- 复制文件
                    if not (doesFileExist dest) then (
                        copyFile src dest
                        copiedCount += 1
                    ) else (
                        skippedCount += 1
                    )
                    
                    -- 更新路径
                    texObj.filename = dest
                ) else (
                    errorCount += 1
                )
            ) catch (
                errorCount += 1
            )
            
            -- 更新进度条
            pb_progress.value = (i as float / total) * 100
            lbl_status.text = "正在处理第 " + i as string + " / " + total as string + " 个贴图..."
            windows.processPostedMessages() -- 刷新 UI
        )
        
        local resultMsg = "贴图收集完成！\n"
        resultMsg += "新复制: " + copiedCount as string + " 个\n"
        resultMsg += "已存在: " + skippedCount as string + " 个\n"
        if errorCount > 0 do resultMsg += "错误: " + errorCount as string + " 个\n"
        resultMsg += "目标目录: " + texDir
        
        lbl_status.text = "完成！新复制 " + copiedCount as string + " 个，已存在 " + skippedCount as string + " 个"
        messageBox resultMsg
        
        -- 刷新列表显示最新状态
        refreshTextureList()
    )
)

createDialog TextureCollectorAdvanced style:#(#style_titlebar, #style_sysmenu, #style_minimizebox)