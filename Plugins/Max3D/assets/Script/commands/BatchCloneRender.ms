-- 场景设置克隆工具 (优化版)
-- 将当前文件的材质、环境、灯光设置克隆到其他Max文件
-- Author: Kiro Assistant
-- Version: 2.0 重构优化版

try(destroyDialog sceneCloneRollout)catch()

rollout sceneCloneRollout "场景设置克隆工具ByBoBO" width:700 height:600
(
    -- ==================== 配置常量 ====================
    local VFX_PREFIX = "vfx_"
    local SAVE_RETRY_DELAY = 1.0
    local PROCESS_DELAY = 0.5
    
    -- ==================== 状态变量 ====================
    local currentDir = maxFilePath
    local currentFileName = maxFileName
    local maxFiles = #()
    local isPaused = false
    local isProcessing = false
    
    -- ==================== UI 控件 ====================
    -- 左侧文件列表区域
    label lblCurrentFileTitle "当前文件:" pos:[15,15] width:100
    edittext edtCurrentFile "" pos:[15,35] width:300 readonly:true
    
    label lblFileListTitle "目标文件列表 (勾选要处理的文件，双击可切换源文件):" pos:[15,65] width:300
    multiListBox mlbMaxFiles "" pos:[15,85] width:300 height:18
    button btnRefresh "刷新文件列表" pos:[15,420] width:90 height:25
    button btnSelectAll "全选" pos:[115,420] width:60 height:25
    button btnSelectNone "全不选" pos:[185,420] width:60 height:25
    
    -- 右侧选项和控制区域
    groupBox grpCloneOptions "克隆选项" pos:[330,15] width:350 height:140
    checkbox chkMaterials "克隆材质" pos:[340,35] checked:true
    checkbox chkEnvironment "克隆环境设置" pos:[340,60] checked:true
    checkbox chkLights "融合灯光（删除现有+从源文件融合）" pos:[340,85] checked:true
    checkbox chkModels "融合VFX模型（vfx_开头的对象）[暂时禁用]" pos:[340,110] checked:false enabled:false
    checkbox chkRenderSettings "克隆渲染设置" pos:[340,135] checked:false
    checkbox chkSaveFile "Save File (激活Render Output)" pos:[500,135] checked:true
    
    groupBox grpRenderOptions "渲染选项" pos:[330,165] width:350 height:120
    checkbox chkAutoRender "克隆后自动渲染" pos:[340,185] checked:true
    checkbox chkSilentRender "静默渲染（不显示渲染窗口）" pos:[340,210] checked:false
    label lblRenderScript "渲染脚本路径:" pos:[340,235] width:100
    edittext edtRenderScript "" pos:[340,255] width:250 readonly:false
    button btnBrowseRender "浏览..." pos:[600,255] width:60 height:20
    
    groupBox grpOperations "操作控制" pos:[330,295] width:350 height:80
    button btnCloneToSelected "克隆到勾选文件" pos:[340,315] width:140 height:30
    button btnPauseResume "暂停" pos:[490,315] width:60 height:30 enabled:false
    button btnStop "停止" pos:[560,315] width:60 height:30 enabled:false
    progressbar pbProgress pos:[340,350] width:300 height:20
    
    groupBox grpLog "处理日志" pos:[15,460] width:665 height:120
    edittext edtLog "" pos:[25,480] width:645 height:90 readonly:true
    
    -- ==================== 工具函数 ====================
    
    -- 添加日志信息
    fn addLog msg =
    (
        edtLog.text = edtLog.text + msg + "\r\n"
        windows.processPostedMessages()
    )
    
    -- 清理内存和场景状态
    fn cleanupScene silent:false =
    (
        try (
            gc()
            gc light:true
            redrawViews()
            windows.processPostedMessages()
            sleep 0.1
            if not silent do addLog "      场景清理完成"
            true
        ) catch (
            if not silent do addLog ("      场景清理异常: " + (getCurrentException()))
            false
        )
    )
    
    -- 安全获取对象属性
    fn safeGetProperty obj propName defaultVal =
    (
        try (
            getProperty obj propName
        ) catch (
            defaultVal
        )
    )

    -- ==================== 文件操作函数 ====================
    
    -- 获取当前目录的Max文件
    fn getMaxFiles =
    (
        maxFiles = #()
        if currentDir != "" then (
            local files = getFiles (currentDir + "*.max")
            for f in files where (filenameFromPath f) != currentFileName do
                append maxFiles f
        )
        
        mlbMaxFiles.items = for f in maxFiles collect (filenameFromPath f)
        
        -- 默认全选
        local selections = #{1..mlbMaxFiles.items.count}
        mlbMaxFiles.selection = selections
    )
    
    -- 可靠的保存文件函数
    fn saveFileReliably targetFile =
    (
        gc()
        windows.processPostedMessages()
        
        -- 方法1: saveMaxFile
        try (
            saveMaxFile targetFile quiet:true
            addLog ("    保存成功: " + (filenameFromPath targetFile))
            return true
        ) catch ()
        
        -- 方法2: max file save
        try (
            addLog "    尝试备用保存方法..."
            redrawViews()
            windows.processPostedMessages()
            maxFileName = filenameFromPath targetFile
            maxFilePath = getFilenamePath targetFile
            max file save
            addLog "    备用方法保存成功"
            return true
        ) catch ()
        
        -- 方法3: 延迟重试
        try (
            addLog "    尝试延迟保存..."
            sleep SAVE_RETRY_DELAY
            saveMaxFile targetFile
            addLog "    延迟保存成功"
            return true
        ) catch (
            addLog "    所有保存方法都失败，请手动保存文件"
            return false
        )
    )
    
    -- ==================== 材质处理函数 ====================
    
    -- 收集材质信息
    fn collectMaterialData =
    (
        local materialAssignments = #()
        local materialLib = #()
        
        for obj in geometry where obj.material != undefined do (
            append materialAssignments #(obj.name, obj.material)
            
            -- 去重添加到材质库
            local matExists = false
            for mat in materialLib where mat == obj.material do (matExists = true; exit)
            if not matExists do append materialLib obj.material
        )
        
        addLog ("  材质分配: " + materialAssignments.count as string + " 个对象")
        addLog ("  材质库: " + materialLib.count as string + " 个材质")
        
        #(materialLib, materialAssignments)
    )
    
    -- 应用材质到目标场景
    fn applyMaterials materialData =
    (
        if materialData == undefined or materialData.count != 2 do return false
        
        local materialLib = materialData[1]
        local materialAssignments = materialData[2]
        
        addLog "  应用材质分配..."
        
        -- 添加材质到场景材质库
        for mat in materialLib where mat != undefined do (
            append sceneMaterials mat
            addLog ("    添加材质到库: " + mat.name)
        )
        
        -- 根据对象名称分配材质
        for assignment in materialAssignments do (
            local objName = assignment[1]
            local sourceMaterial = assignment[2]
            local targetObj = getNodeByName objName
            
            if targetObj != undefined then (
                for mat in sceneMaterials where mat != undefined and mat.name == sourceMaterial.name do (
                    targetObj.material = mat
                    addLog ("    分配材质: " + objName + " -> " + mat.name)
                    exit
                )
            ) else (
                addLog ("    警告: 未找到对象 " + objName)
            )
        )
        true
    )
    
    -- ==================== 环境设置函数 ====================
    
    -- 收集环境设置
    fn collectEnvironmentData =
    (
        addLog "正在保存环境设置..."
        local envSettings = #()
        append envSettings #(#backgroundColor, backgroundColor)
        append envSettings #(#ambientColor, ambientColor)
        if environmentMap != undefined do
            append envSettings #(#environmentMap, environmentMap)
        envSettings
    )
    
    -- 应用环境设置
    fn applyEnvironment envSettings =
    (
        addLog "  应用环境设置..."
        for setting in envSettings do (
            case setting[1] of (
                #backgroundColor: backgroundColor = setting[2]
                #ambientColor: ambientColor = setting[2]
                #environmentMap: environmentMap = setting[2]
            )
        )
        true
    )
    
    -- ==================== 灯光处理函数 ====================
    
    -- 收集灯光数据
    fn collectLightData =
    (
        addLog "正在保存灯光设置..."
        local lightData = #()
        
        for lightObj in lights do (
            try (
                append lightData #(#(#name, lightObj.name), #(#sourceObject, lightObj))
            ) catch ()
        )
        
        addLog ("  保存完成，共 " + lightData.count as string + " 个灯光")
        lightData
    )
    
    -- 删除目标场景所有灯光
    fn deleteAllLights =
    (
        local lightCountBefore = lights.count
        if lightCountBefore == 0 do (
            addLog "    目标文件无灯光需要删除"
            return true
        )
        
        try (
            delete lights
            addLog ("    删除完成，删除了 " + lightCountBefore as string + " 个灯光")
            return true
        ) catch (
            addLog "    批量删除失败，尝试逐个删除..."
            local deletedCount = 0
            local lightArray = for light in lights collect light
            
            for light in lightArray do (
                try (
                    if isValidNode light do (delete light; deletedCount += 1)
                ) catch ()
            )
            addLog ("    逐个删除完成，删除了 " + deletedCount as string + " 个灯光")
            return true
        )
    )
    
    -- 融合灯光到目标场景
    fn mergeLights sourceLightData =
    (
        addLog "  融合灯光设置..."
        
        -- 删除现有灯光
        addLog "    第一步：删除目标文件中的所有现有灯光"
        deleteAllLights()
        
        redrawViews()
        windows.processPostedMessages()
        
        -- 导入源灯光
        if sourceLightData.count == 0 do (
            addLog "    源文件无灯光"
            return true
        )
        
        addLog ("    第二步：导入 " + sourceLightData.count as string + " 个灯光")
        local fusedCount = 0
        
        for lightInfo in sourceLightData do (
            try (
                local lightName = lightInfo[1][2]
                local sourceLight = lightInfo[2][2]
                
                if sourceLight != undefined do (
                    local newLight = copy sourceLight
                    if newLight != undefined do (
                        newLight.name = uniqueName lightName
                        fusedCount += 1
                    )
                )
            ) catch ()
        )
        
        addLog ("    导入完成，成功导入 " + fusedCount as string + " 个灯光")
        true
    )

    -- ==================== 渲染设置函数 ====================
    
    -- 收集渲染设置
    fn collectRenderSettings =
    (
        addLog "正在保存渲染设置..."
        local settings = #(
            #(#renderWidth, renderWidth),
            #(#renderHeight, renderHeight),
            #(#pixelaspect, renderPixelAspect)
        )
        
        -- Save File 选项 (Render Output)
        if chkSaveFile.checked do (
            append settings #(#saveFile, rendSaveFile)
            append settings #(#outputFilename, rendOutputFilename)
            addLog ("  Render Output: " + (if rendSaveFile then "启用" else "禁用"))
            if rendOutputFilename != "" do
                addLog ("  输出路径: " + rendOutputFilename)
        )
        
        settings
    )
    
    -- 应用渲染设置
    fn applyRenderSettings renderSettings =
    (
        addLog "  应用渲染设置..."
        for setting in renderSettings do (
            case setting[1] of (
                #renderWidth: renderWidth = setting[2]
                #renderHeight: renderHeight = setting[2]
                #pixelaspect: renderPixelAspect = setting[2]
                #saveFile: (
                    rendSaveFile = setting[2]
                    addLog ("    Render Output: " + (if setting[2] then "启用" else "禁用"))
                )
                #outputFilename: (
                    rendOutputFilename = setting[2]
                    if setting[2] != "" do addLog ("    输出路径: " + setting[2])
                )
            )
        )
        true
    )
    
    -- ==================== 核心业务函数 ====================
    
    -- 保存当前场景设置
    fn saveCurrentSettings =
    (
        local settings = #()
        
        -- 材质
        if chkMaterials.checked do (
            addLog "正在保存材质信息..."
            append settings #(#materials, collectMaterialData())
        )
        
        -- 环境
        if chkEnvironment.checked do
            append settings #(#environment, collectEnvironmentData())
        
        -- 灯光
        if chkLights.checked do
            append settings #(#lights, collectLightData())
        
        -- 渲染设置
        if chkRenderSettings.checked do
            append settings #(#renderSettings, collectRenderSettings())
        
        settings
    )
    
    -- 应用设置到目标文件
    fn applySettingsToFile targetFile settings =
    (
        addLog ("正在处理文件: " + (filenameFromPath targetFile))
        
        try (
            if not (loadMaxFile targetFile quiet:true) do (
                addLog ("  错误: 无法打开文件 " + (filenameFromPath targetFile))
                return false
            )
            
            -- 应用各项设置
            for setting in settings do (
                case setting[1] of (
                    #materials: applyMaterials setting[2]
                    #environment: applyEnvironment setting[2]
                    #lights: mergeLights setting[2]
                    #renderSettings: applyRenderSettings setting[2]
                )
            )
            
            -- 保存文件
            addLog "  正在保存文件..."
            local saveSuccess = saveFileReliably targetFile
            if not saveSuccess do
                addLog "  警告: 文件保存失败，请手动保存"
            
            true
        ) catch (
            addLog ("  严重错误: " + (getCurrentException()))
            false
        )
    )
    
    -- 执行渲染脚本
    fn executeRenderScript targetFile =
    (
        try (
            local renderScriptPath = edtRenderScript.text
            if not (doesFileExist renderScriptPath) do (
                addLog "    渲染脚本不存在，跳过渲染"
                return true
            )
            
            addLog ("    执行渲染脚本: " + (filenameFromPath renderScriptPath))
            
            -- 检查必要对象
            local helperObj = getNodeByName "台"
            local cameraObj = getNodeByName "Camera"
            
            if helperObj != undefined then addLog ("      找到目标对象: " + helperObj.name)
            else addLog "      警告: 未找到'台'对象"
            
            if cameraObj != undefined then addLog ("      找到摄像机: " + cameraObj.name)
            else addLog "      警告: 未找到'Camera'摄像机"
            
            -- 执行渲染
            if chkSilentRender.checked then (
                addLog "      启用静默渲染模式"
                local oldQuietMode = quietMode
                local oldRenderDialogMode = renderDialogMode
                
                quietMode = true
                renderDialogMode = false
                
                try (fileIn renderScriptPath) catch (addLog ("      静默渲染异常: " + (getCurrentException())))
                
                quietMode = oldQuietMode
                renderDialogMode = oldRenderDialogMode
            ) else (
                redrawViews()
                windows.processPostedMessages()
                addLog "      开始执行渲染脚本..."
                fileIn renderScriptPath
            )
            
            addLog "      渲染脚本执行完成"
            true
        ) catch (
            addLog ("    渲染错误: " + (getCurrentException()))
            false
        )
    )
    
    -- 检查暂停状态
    fn checkPauseState =
    (
        while isPaused and isProcessing do (
            sleep 0.1
            windows.processPostedMessages()
        )
        isProcessing
    )
    
    -- 更新UI状态
    fn setProcessingState processing =
    (
        isProcessing = processing
        isPaused = false
        btnCloneToSelected.enabled = not processing
        btnPauseResume.enabled = processing
        btnPauseResume.text = "暂停"
        btnStop.enabled = processing
    )
    
    -- 克隆到勾选的文件
    fn cloneToSelectedFiles =
    (
        local selectedIndices = mlbMaxFiles.selection as array
        if selectedIndices.count == 0 do (
            messageBox "请先勾选要处理的文件！"
            return false
        )
        
        setProcessingState true
        
        local settings = saveCurrentSettings()
        
        if settings.count == 0 do (
            messageBox "请至少选择一个克隆选项！"
            setProcessingState false
            return false
        )
        
        pbProgress.value = 0
        local successCount = 0
        local totalFiles = selectedIndices.count
        
        for i = 1 to totalFiles do (
            if not checkPauseState() do (
                addLog "用户停止了处理过程"
                exit
            )
            
            local fileIndex = selectedIndices[i]
            local targetFile = maxFiles[fileIndex]
            
            addLog "========================================"
            addLog ("开始处理文件 " + i as string + "/" + totalFiles as string)
            addLog ("目标文件: " + (filenameFromPath targetFile))
            
            cleanupScene silent:true
            
            if not checkPauseState() do exit
            
            local cloneSuccess = applySettingsToFile targetFile settings
            
            if not checkPauseState() do exit
            
            -- 自动渲染
            if cloneSuccess and chkAutoRender.checked do (
                addLog "  重新打开文件进行渲染..."
                if loadMaxFile targetFile quiet:true then (
                    addLog "  文件已重新打开，开始渲染..."
                    
                    if not checkPauseState() do exit
                    
                    if executeRenderScript targetFile do (
                        addLog "  渲染完成，正在保存文件..."
                        if saveFileReliably targetFile then
                            addLog ("  渲染完成，文件已保存: " + (filenameFromPath targetFile))
                        else
                            addLog "  警告: 渲染后文件保存失败"
                    )
                ) else (
                    addLog "  错误: 无法重新打开文件进行渲染"
                )
            )
            
            if cloneSuccess then (
                successCount += 1
                addLog ("文件 " + i as string + " 处理成功")
            ) else (
                addLog ("文件 " + i as string + " 处理失败")
            )
            
            pbProgress.value = (100.0 * i / totalFiles)
            windows.processPostedMessages()
            
            if not checkPauseState() do exit
            
            sleep PROCESS_DELAY
        )
        
        addLog ("批量处理完成！成功: " + successCount as string + "/" + totalFiles as string)
        setProcessingState false
    )

    -- ==================== 事件处理器 ====================
    
    on sceneCloneRollout open do
    (
        edtCurrentFile.text = if currentFileName != "" then currentFileName else "未保存的文件"
        
        -- 设置默认渲染脚本路径
        local scriptDir = getFilenamePath (getThisScriptFilename())
        local defaultRenderScript = scriptDir + "Render53.ms"
        edtRenderScript.text = defaultRenderScript
        
        getMaxFiles()
        addLog "工具已启动，准备就绪。"
        
        if doesFileExist defaultRenderScript then
            addLog ("已找到渲染脚本: " + defaultRenderScript)
        else
            addLog ("警告: 未找到渲染脚本 " + defaultRenderScript)
    )
    
    on btnRefresh pressed do
    (
        getMaxFiles()
        addLog "文件列表已刷新。"
    )
    
    on btnSelectAll pressed do
    (
        mlbMaxFiles.selection = #{1..mlbMaxFiles.items.count}
        addLog "已全选所有文件。"
    )
    
    on btnSelectNone pressed do
    (
        mlbMaxFiles.selection = #{}
        addLog "已取消选择所有文件。"
    )
    
    on mlbMaxFiles doubleClicked index do
    (
        if index < 1 or index > maxFiles.count do return()
        
        local selectedFile = maxFiles[index]
        local selectedFileName = filenameFromPath selectedFile
        
        local confirmMsg = "是否要将 \"" + selectedFileName + "\" 设置为新的源文件？\n\n"
        confirmMsg += "当前源文件: " + currentFileName + "\n新源文件: " + selectedFileName
        
        if not (queryBox confirmMsg title:"切换源文件") do return()
        
        -- 保存当前文件
        if maxFileName != "" and (queryBox "是否要先保存当前文件？" title:"保存确认") do (
            max file save
            addLog "当前文件已保存。"
        )
        
        -- 打开新源文件
        if loadMaxFile selectedFile quiet:true then (
            currentDir = maxFilePath
            currentFileName = maxFileName
            edtCurrentFile.text = currentFileName
            getMaxFiles()
            
            addLog "========================================"
            addLog ("源文件已切换为: " + currentFileName)
            addLog ("工作目录: " + currentDir)
            addLog "========================================"
        ) else (
            addLog ("错误: 无法打开文件 " + selectedFileName)
        )
    )
    
    on btnBrowseRender pressed do
    (
        local renderFile = getOpenFileName caption:"选择渲染脚本" types:"MAXScript (*.ms)|*.ms|所有文件 (*.*)|*.*"
        if renderFile != undefined do (
            edtRenderScript.text = renderFile
            addLog ("渲染脚本路径已更新: " + renderFile)
        )
    )
    
    on btnPauseResume pressed do
    (
        if not isProcessing do return()
        
        isPaused = not isPaused
        btnPauseResume.text = if isPaused then "恢复" else "暂停"
        addLog (if isPaused then "暂停处理..." else "恢复处理...")
    )
    
    on btnStop pressed do
    (
        if isProcessing do (
            setProcessingState false
            addLog "用户停止了处理过程"
        )
    )
    
    on btnCloneToSelected pressed do
    (
        local selectedCount = (mlbMaxFiles.selection as array).count
        if selectedCount == 0 do (
            messageBox "请先勾选要处理的文件！"
            return()
        )
        
        local confirmMsg = "确定要处理 " + selectedCount as string + " 个文件吗？"
        if chkAutoRender.checked do (
            confirmMsg += "\n注意：启用了自动渲染功能。"
            if chkSilentRender.checked do confirmMsg += "\n静默渲染模式已启用。"
        )
        confirmMsg += "\n这个操作不可撤销！"
        
        if queryBox confirmMsg title:"确认操作" do
            cloneToSelectedFiles()
    )
)

-- 创建并显示对话框
createDialog sceneCloneRollout
