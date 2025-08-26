-- 场景设置克隆工具
-- 将当前文件的材质、环境、灯光设置克隆到其他Max文件
-- Author: Kiro Assistant
-- Version: 1.3 功能优化版

try(destroyDialog sceneCloneRollout)catch()

rollout sceneCloneRollout "场景设置克隆工具ByBoBO" width:700 height:600
(
    local currentDir = maxFilePath
    local currentFileName = maxFileName
    local maxFiles = #()
    local isPaused = false
    local isProcessing = false
    
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
    
    -- 获取当前目录的Max文件
    function getMaxFiles =
    (
        maxFiles = #()
        if currentDir != "" then
        (
            local files = getFiles (currentDir + "*.max")
            for f in files do
            (
                local fileName = filenameFromPath f
                if fileName != currentFileName then
                    append maxFiles f
            )
        )
        
        -- 更新多选列表框
        local fileNames = for f in maxFiles collect (filenameFromPath f)
        mlbMaxFiles.items = fileNames
        
        -- 默认全选
        local selections = #{}
        for i = 1 to fileNames.count do
            selections[i] = true
        mlbMaxFiles.selection = selections
    )
    
    -- 添加日志信息
    function addLog msg =
    (
        edtLog.text = edtLog.text + msg + "\r\n"
        windows.processPostedMessages()
    )
    
    -- VFX对象创建辅助函数
    function createVfxObject modelClass modelName =
    (
        local newObj = undefined
        local errorMsg = ""
        
        try
        (
            case modelClass of
            (
                Sphere: 
                (
                    newObj = Sphere radius:10
                    errorMsg = "球体创建成功"
                )
                Box: 
                (
                    newObj = Box length:20 width:20 height:20
                    errorMsg = "盒子创建成功"
                )
                SuperSpray: 
                (
                    newObj = SuperSpray()
                    errorMsg = "粒子系统创建成功"
                )
                Cylinder:
                (
                    newObj = Cylinder radius:10 height:20
                    errorMsg = "圆柱体创建成功"
                )
                Plane:
                (
                    newObj = Plane length:20 width:20
                    errorMsg = "平面创建成功"
                )
                default: 
                (
                    -- 尝试动态创建对象
                    local classStr = modelClass as string
                    newObj = execute (classStr + "()")
                    if newObj != undefined then
                        errorMsg = "动态创建对象成功: " + classStr
                    else
                        errorMsg = "不支持的对象类型: " + classStr
                )
            )
        )
        catch (createError)
        (
            errorMsg = "对象创建失败: " + createError as string
            newObj = undefined
        )
        
        return #(newObj, errorMsg)
    )
    
    -- 验证VFX对象数据
    function validateVfxData modelInfo =
    (
        local isValid = true
        local validationMsg = ""
        local modelName = ""
        local modelClass = undefined
        
        try
        (
            -- 首先检查modelInfo是否有效
            if modelInfo == undefined then
            (
                isValid = false
                validationMsg = "VFX对象数据为空"
                return #(isValid, validationMsg, "", undefined)
            )
            
            if (classof modelInfo) != Array then
            (
                isValid = false
                validationMsg = "VFX对象数据格式错误，期望数组类型，实际: " + (classof modelInfo) as string
                return #(isValid, validationMsg, "", undefined)
            )
            
            if modelInfo.count == 0 then
            (
                isValid = false
                validationMsg = "VFX对象数据数组为空"
                return #(isValid, validationMsg, "", undefined)
            )
            
            -- 解析基本信息
            for info in modelInfo do
            (
                if (classof info) == Array and info.count >= 2 then
                (
                    case info[1] of
                    (
                        #name: modelName = info[2]
                        #class: modelClass = info[2]
                    )
                )
            )
            
            -- 验证必要字段
            if modelName == "" or modelName == undefined then
            (
                isValid = false
                validationMsg = "对象名称无效: " + modelName as string
            )
            else if modelClass == undefined then
            (
                isValid = false
                validationMsg = "对象类型无效"
            )
            else
            (
                validationMsg = "数据验证通过: " + modelName + " (" + (classof modelClass) as string + ")"
            )
        )
        catch (validationError)
        (
            isValid = false
            validationMsg = "数据验证异常: " + validationError as string + " (数据类型: " + (classof modelInfo) as string + ")"
        )
        
        return #(isValid, validationMsg, modelName, modelClass)
    )
    
    -- 清理内存和场景状态
    function cleanupScene =
    (
        try
        (
            -- 强制垃圾回收
            gc()
            gc light:true
            
            -- 刷新视图
            redrawViews()
            
            -- 处理Windows消息
            windows.processPostedMessages()
            
            -- 等待一小段时间让系统稳定
            sleep 0.1
            
            addLog ("      场景清理完成")
            return true
        )
        catch (cleanupError)
        (
            addLog ("      场景清理异常: " + cleanupError as string)
            return false
        )
    )    

    -- 可靠的保存文件函数
    function saveFileReliably targetFile =
    (
        local saveSuccess = false
        
        -- 清理场景状态
        gc()
        windows.processPostedMessages()
        
        -- 方法1: 使用saveMaxFile
        try
        (
            saveMaxFile targetFile quiet:true
            addLog ("    方法1保存成功: " + (filenameFromPath targetFile))
            saveSuccess = true
        )
        catch (e)
        (
            addLog ("    方法1保存失败，错误类型: " + (classof e) as string)
            if (classof e) == Float then
                addLog ("    检测到数值错误，可能是场景状态问题")
        )
        
        -- 如果方法1失败，尝试方法2
        if not saveSuccess then
        (
            try
            (
                addLog ("    尝试方法2保存...")
                -- 强制刷新场景
                redrawViews()
                windows.processPostedMessages()
                
                -- 确保文件名正确设置
                maxFileName = filenameFromPath targetFile
                maxFilePath = getFilenamePath targetFile
                
                -- 使用max file save命令
                max file save
                addLog ("    方法2保存成功")
                saveSuccess = true
            )
            catch (e)
            (
                addLog ("    方法2保存失败: " + e as string)
            )
        )
        
        -- 如果还是失败，尝试方法3
        if not saveSuccess then
        (
            try
            (
                addLog ("    尝试方法3保存...")
                -- 等待一下再保存
                sleep 1
                saveMaxFile targetFile
                addLog ("    方法3保存成功")
                saveSuccess = true
            )
            catch (e)
            (
                addLog ("    方法3保存失败: " + e as string)
                addLog ("    所有保存方法都失败，请手动保存文件")
            )
        )
        
        return saveSuccess
    )
    
    -- 保存当前场景设置
    function saveCurrentSettings =
    (
        local settings = #()
        
        -- 保存材质分配关系和VFX模型信息（合并处理提高性能）
        local materialAssignments = #()
        local materialLib = #()
        local vfxModelData = #()
        local processedCount = 0
        local vfxCount = 0
        
        if chkMaterials.checked or (chkModels.checked and chkModels.enabled) then
        (
            addLog "正在保存对象信息..."
            
            -- 一次遍历处理材质和VFX模型
            for obj in geometry do
            (
                processedCount += 1
                
                -- 处理材质
                if chkMaterials.checked and obj.material != undefined then
                (
                    local assignment = #(obj.name, obj.material)
                    append materialAssignments assignment
                    
                    -- 收集材质到材质库（简化查找）
                    local found = false
                    for mat in materialLib do
                    (
                        if mat == obj.material then
                        (
                            found = true
                            exit
                        )
                    )
                    if not found then
                        append materialLib obj.material
                )
                
                -- 处理VFX模型信息（只处理vfx_开头的对象）
                if chkModels.checked and chkModels.enabled then
                (
                    local objNameLower = toLower obj.name
                    if (substring objNameLower 1 4) == "vfx_" then
                    (
                        try
                        (
                            -- 确保对象有效
                            if isValidNode obj and obj != undefined then
                            (
                                -- 只保存对象的基本信息，不创建副本
                                local modelInfo = #()
                                append modelInfo #(#name, obj.name)
                                append modelInfo #(#class, classof obj)
                                
                                -- 安全地保存变换矩阵
                                try
                                (
                                    append modelInfo #(#transform, obj.transform)
                                )
                                catch (transformError)
                                (
                                    addLog ("    警告: 无法保存 " + obj.name + " 的变换矩阵")
                                    append modelInfo #(#transform, matrix3 1) -- 使用单位矩阵作为默认值
                                )
                                
                                -- 安全地保存材质
                                try
                                (
                                    append modelInfo #(#material, obj.material)
                                )
                                catch (materialError)
                                (
                                    append modelInfo #(#material, undefined)
                                )
                                
                                append vfxModelData modelInfo
                                vfxCount += 1
                                addLog ("    保存VFX对象: " + obj.name + " (" + (classof obj) as string + ")")
                                addLog ("      数据结构: " + modelInfo.count as string + " 个属性")
                            )
                        )
                        catch(e)
                        (
                            -- Silently ignore errors for invalid VFX objects during save
                        )
                    )
                )
            )
            
            -- 也检查其他类型的对象（粒子系统等）
            if chkModels.checked and chkModels.enabled then
            (
                for obj in objects do
                (
                    if superClassOf obj != GeometryClass then
                    (
                        local objNameLower = toLower obj.name
                        if (substring objNameLower 1 4) == "vfx_" then
                        (
                            try
                            (
                                -- 确保对象有效
                                if isValidNode obj and obj != undefined then
                                (
                                    -- 只保存对象的基本信息，不创建副本
                                    local modelInfo = #()
                                    append modelInfo #(#name, obj.name)
                                    append modelInfo #(#class, classof obj)
                                    
                                    -- 安全地保存变换矩阵
                                    try
                                    (
                                        append modelInfo #(#transform, obj.transform)
                                    )
                                    catch (transformError)
                                    (
                                        addLog ("    警告: 无法保存 " + obj.name + " 的变换矩阵")
                                        append modelInfo #(#transform, matrix3 1) -- 使用单位矩阵作为默认值
                                    )
                                    
                                    -- 安全地保存材质
                                    try
                                    (
                                        append modelInfo #(#material, obj.material)
                                    )
                                    catch (materialError)
                                    (
                                        append modelInfo #(#material, undefined)
                                    )
                                    
                                    -- 保存额外的对象属性（如果是粒子系统）
                                    if superClassOf obj == ParticleSystem then
                                    (
                                        try
                                        (
                                            append modelInfo #(#particleType, obj.particleType)
                                        )
                                        catch (particleError)
                                        (
                                            append modelInfo #(#particleType, undefined)
                                        )
                                    )
                                    
                                    append vfxModelData modelInfo
                                    vfxCount += 1
                                    addLog ("    保存VFX对象: " + obj.name + " (" + (classof obj) as string + ")")
                                    addLog ("      数据结构: " + modelInfo.count as string + " 个属性")
                                )
                            )
                            catch (saveError)
                            (
                                addLog ("    VFX对象保存异常: " + obj.name + " - " + saveError as string)
                            )
                        )
                    )
                )
            )
            
            addLog ("  处理完成，共处理 " + processedCount as string + " 个几何体对象")
            
            if chkMaterials.checked then
            (
                addLog ("  材质分配: " + materialAssignments.count as string + " 个对象")
                addLog ("  材质库: " + materialLib.count as string + " 个材质")
                append settings #(#materials, #(materialLib, materialAssignments))
            )
            
            if chkModels.checked and chkModels.enabled then
            (
                addLog ("  VFX模型: " + vfxCount as string + " 个vfx_开头的对象")
            )
            else if chkModels.checked and not chkModels.enabled then
            (
                addLog ("  VFX模型功能已禁用，跳过保存")
                append settings #(#models, vfxModelData)
            )
        )
        
        -- 保存环境设置
        if chkEnvironment.checked then
        (
            addLog "正在保存环境设置..."
            local envSettings = #()
            append envSettings #(#backgroundColor, backgroundColor)
            append envSettings #(#ambientColor, ambientColor)
            if environmentMap != undefined then
                append envSettings #(#environmentMap, environmentMap)
            append settings #(#environment, envSettings)
        )
        
        -- 保存灯光设置用于融合
        if chkLights.checked then
        (
            addLog "正在保存灯光设置..."
            local lightData = #()
            local lightCount = lights.count
            
            if lightCount > 0 then
            (
                for lightObj in lights do
                (
                    try
                    (
                        local lightInfo = #()
                        append lightInfo #(#name, lightObj.name)
                        append lightInfo #(#sourceObject, lightObj)
                        append lightData lightInfo
                    )
                    catch(e)
                    (
                        -- Silently ignore errors for invalid light objects during save
                    )
                )
                addLog ("  保存完成，共 " + lightData.count as string + " 个灯光")
            )
            else
            (
                addLog "  当前场景无灯光"
            )
            
            append settings #(#lights, lightData)
        )
        

        
        -- 保存渲染设置
        if chkRenderSettings.checked then
        (
            addLog "正在保存渲染设置..."
            local renderSettings = #()
            append renderSettings #(#renderWidth, renderWidth)
            append renderSettings #(#renderHeight, renderHeight)
            append renderSettings #(#pixelaspect, renderPixelAspect)
            append settings #(#renderSettings, renderSettings)
        )
        
        return settings
    )    
    
-- 应用设置到目标文件
    function applySettingsToFile targetFile settings =
    (
        addLog ("正在处理文件: " + (filenameFromPath targetFile))
        
        try
        (
            -- 打开目标文件
            if loadMaxFile targetFile quiet:true then
            (
                -- 应用设置
                for setting in settings do
                (
                    case setting[1] of
                    (
                        #materials:
                        (
                            addLog "  应用材质分配..."
                            if setting[2] != undefined and setting[2].count == 2 then
                            (
                                local materialLib = setting[2][1]
                                local materialAssignments = setting[2][2]
                                
                                -- 先添加材质到材质库
                                for mat in materialLib do
                                (
                                    if mat != undefined then
                                    (
                                        append sceneMaterials mat
                                        addLog ("    添加材质到库: " + mat.name)
                                    )
                                )
                                
                                -- 根据对象名称分配材质
                                for assignment in materialAssignments do
                                (
                                    local objName = assignment[1]
                                    local sourceMaterial = assignment[2]
                                    
                                    -- 在当前场景中查找同名对象
                                    local targetObj = getNodeByName objName
                                    if targetObj != undefined then
                                    (
                                        -- 在材质库中查找对应的材质
                                        for mat in sceneMaterials do
                                        (
                                            if mat != undefined and mat.name == sourceMaterial.name then
                                            (
                                                targetObj.material = mat
                                                addLog ("    分配材质: " + objName + " -> " + mat.name)
                                                exit
                                            )
                                        )
                                    )
                                    else
                                    (
                                        addLog ("    警告: 未找到对象 " + objName)
                                    )
                                )
                            )
                        )
                        
                        #environment:
                        (
                            addLog "  应用环境设置..."
                            for envSetting in setting[2] do
                            (
                                case envSetting[1] of
                                (
                                    #backgroundColor: backgroundColor = envSetting[2]
                                    #ambientColor: ambientColor = envSetting[2]
                                    #environmentMap: environmentMap = envSetting[2]
                                )
                            )
                        )
                        
                        #lights:
                        (
                            addLog "  融合灯光设置..."
                            local sourceLightData = setting[2]
                            
                            -- 第一步：删除目标文件中的所有现有灯光
                            addLog "    第一步：删除目标文件中的所有现有灯光"
                            local lightCountBefore = lights.count
                            
                            if lightCountBefore > 0 then
                            (
                                try
                                (
                                    -- 使用简单的delete lights命令删除所有灯光
                                    delete lights
                                    local lightCountAfter = lights.count
                                    addLog ("    删除完成，删除了 " + (lightCountBefore - lightCountAfter) as string + " 个灯光")
                                )
                                catch (e)
                                (
                                    addLog ("    删除灯光异常，尝试逐个删除...")
                                    -- 如果批量删除失败，尝试逐个删除
                                    local deletedCount = 0
                                    local lightArray = #()
                                    for light in lights do append lightArray light
                                    
                                    for light in lightArray do
                                    (
                                        try
                                        (
                                            if isValidNode light then
                                            (
                                                delete light
                                                deletedCount += 1
                                            )
                                        )
                                        catch(e)
                                        (
                                            -- Silently ignore errors when deleting individual lights
                                        )
                                    )
                                    addLog ("    逐个删除完成，删除了 " + deletedCount as string + " 个灯光")
                                )
                            )
                            else
                            (
                                addLog "    目标文件无灯光需要删除"
                            )
                            
                            -- 强制刷新场景
                            redrawViews()
                            windows.processPostedMessages()
                            
                            -- 第二步：从源文件导入灯光（如果有的话）
                            if sourceLightData.count > 0 then
                            (
                                addLog ("    第二步：导入 " + sourceLightData.count as string + " 个灯光")
                                local fusedCount = 0
                                
                                for lightInfo in sourceLightData do
                                (
                                    try
                                    (
                                        local lightName = lightInfo[1][2]
                                        local sourceLight = lightInfo[2][2]
                                        
                                        if sourceLight != undefined then
                                        (
                                            local newLight = copy sourceLight
                                            if newLight != undefined then
                                            (
                                                newLight.name = uniqueName lightName
                                                fusedCount += 1
                                            )
                                        )
                                    )
                                    catch(e)
                                    (
                                        -- Silently ignore errors when copying individual lights
                                    )
                                )
                                
                                addLog ("    导入完成，成功导入 " + fusedCount as string + " 个灯光")
                            )
                            else
                            (
                                addLog "    源文件无灯光"
                            )
                        )
                        
                        #models:
                        (
                            addLog "  VFX模型融合功能已暂时禁用，跳过处理..."
                            -- VFX融合功能暂时禁用，直接跳过
                            continue
                            local sourceVfxData = setting[2]
                            local fusedCount = 0
                            
                            if sourceVfxData.count > 0 then
                            (
                                addLog ("    检查 " + sourceVfxData.count as string + " 个VFX对象")
                                addLog ("    VFX数据类型: " + (classof sourceVfxData) as string)
                                
                                -- 在开始处理前清理场景
                                cleanupScene()
                                
                                local processedCount = 0
                                for modelInfo in sourceVfxData do
                                (
                                    processedCount += 1
                                    addLog ("    处理第 " + processedCount as string + " 个VFX对象，数据类型: " + (classof modelInfo) as string)
                                    -- 首先验证VFX对象数据
                                    local validationResult = validateVfxData modelInfo
                                    local isValid = validationResult[1]
                                    local validationMsg = validationResult[2]
                                    local modelName = validationResult[3]
                                    local modelClass = validationResult[4]
                                    
                                    if not isValid then
                                    (
                                        addLog ("      跳过无效VFX对象: " + validationMsg)
                                        continue
                                    )
                                    
                                    try
                                    (
                                        local modelTransform = undefined
                                        local modelMaterial = undefined
                                        
                                        -- 解析VFX对象信息
                                        for info in modelInfo do
                                        (
                                            case info[1] of
                                            (
                                                #transform: modelTransform = info[2]
                                                #material: modelMaterial = info[2]
                                            )
                                        )
                                        
                                        -- 检查目标文件中是否已存在同名VFX对象
                                        local existingObj = getNodeByName modelName
                                        if existingObj == undefined and modelClass != undefined then
                                        (
                                            -- 创建基本的VFX对象
                                            local newObj = undefined
                                            
                                            try
                                            (
                                                -- 使用辅助函数创建VFX对象
                                                local createResult = createVfxObject modelClass modelName
                                                newObj = createResult[1]
                                                local createMsg = createResult[2]
                                                addLog ("      " + createMsg)
                                                
                                                if newObj != undefined then
                                                (
                                                    -- 设置对象属性
                                                    newObj.name = uniqueName modelName
                                                    
                                                    -- 安全地应用变换
                                                    if modelTransform != undefined then
                                                    (
                                                        try
                                                        (
                                                            newObj.transform = modelTransform
                                                        )
                                                        catch (transformError)
                                                        (
                                                            addLog ("      警告: 无法应用变换矩阵到 " + newObj.name)
                                                        )
                                                    )
                                                    
                                                    -- 安全地应用材质
                                                    if modelMaterial != undefined then
                                                    (
                                                        try
                                                        (
                                                            newObj.material = modelMaterial
                                                        )
                                                        catch (materialError)
                                                        (
                                                            addLog ("      警告: 无法应用材质到 " + newObj.name)
                                                        )
                                                    )
                                                    
                                                    fusedCount += 1
                                                    addLog ("      创建VFX对象: " + newObj.name + " (" + (classof newObj) as string + ")")
                                                    
                                                    -- 创建对象后进行轻量级清理
                                                    gc light:true
                                                    windows.processPostedMessages()
                                                )
                                                else
                                                (
                                                    addLog ("      错误: 对象创建失败 - " + modelName)
                                                )
                                            )
                                            catch (createError)
                                            (
                                                addLog ("      对象创建异常: " + modelName + " - " + createError as string)
                                                addLog ("      错误类型: " + (classof createError) as string)
                                            )
                                        )
                                        else if existingObj != undefined then
                                        (
                                            addLog ("      跳过已存在的VFX对象: " + modelName)
                                        )
                                        else
                                        (
                                            addLog ("      跳过无效的VFX对象定义: " + modelName)
                                        )
                                    )
                                    catch (e)
                                    (
                                        addLog ("      VFX对象处理异常: " + modelName + " - " + e as string)
                                        addLog ("      异常类型: " + (classof e) as string)
                                        if (classof e) == Float then
                                            addLog ("      检测到数值异常，可能是变换矩阵或参数问题")
                                    )
                                )
                                
                                -- 最终清理和总结
                                cleanupScene()
                                
                                local totalAttempted = sourceVfxData.count
                                local failedCount = totalAttempted - fusedCount
                                
                                addLog ("    VFX融合完成，成功融合 " + fusedCount as string + " 个VFX对象")
                                if failedCount > 0 then
                                    addLog ("    失败: " + failedCount as string + " 个对象未能成功创建")
                                addLog ("    成功率: " + ((fusedCount as float / totalAttempted as float) * 100) as string + "%")
                            )
                            else
                            (
                                addLog "    源文件无VFX对象（vfx_开头）"
                            )
                        )
                        
                        #renderSettings:
                        (
                            addLog "  应用渲染设置..."
                            for renderSetting in setting[2] do
                            (
                                case renderSetting[1] of
                                (
                                    #renderWidth: renderWidth = renderSetting[2]
                                    #renderHeight: renderHeight = renderSetting[2]
                                    #pixelaspect: renderPixelAspect = renderSetting[2]
                                )
                            )
                        )
                    )
                )
                
                -- 保存文件
                addLog ("  正在保存文件...")
                local saveSuccess = saveFileReliably targetFile
                if not saveSuccess then
                    addLog ("  警告: 文件保存失败，请手动保存")
                
                return true
            )
            else
            (
                addLog ("  错误: 无法打开文件 " + (filenameFromPath targetFile))
                return false
            )
        )
        catch (e)
        (
            addLog ("  严重错误: " + e as string)
            return false
        )
    )    

    -- 执行渲染脚本
    function executeRenderScript targetFile =
    (
        try
        (
            local renderScriptPath = edtRenderScript.text
            if doesFileExist renderScriptPath then
            (
                addLog ("    执行渲染脚本: " + (filenameFromPath renderScriptPath))
                
                -- 检查必要的对象
                local helperObj = getNodeByName "台"
                local cameraObj = getNodeByName "Camera"
                
                if helperObj != undefined then
                    addLog ("      找到目标对象: " + helperObj.name)
                else
                    addLog ("      警告: 未找到'台'对象")
                
                if cameraObj != undefined then
                    addLog ("      找到摄像机: " + cameraObj.name)
                else
                    addLog ("      警告: 未找到'Camera'摄像机")
                
                -- 设置静默渲染模式
                if chkSilentRender.checked then
                (
                    addLog ("      启用静默渲染模式")
                    -- 保存当前渲染设置
                    local oldQuietMode = quietMode
                    local oldRenderDialogMode = renderDialogMode
                    
                    -- 设置静默模式
                    quietMode = true
                    renderDialogMode = false
                    
                    try
                    (
                        -- 执行渲染脚本
                        fileIn renderScriptPath
                    )
                    catch (e)
                    (
                        addLog ("      静默渲染异常: " + e as string)
                    )
                    
                    -- 恢复原始设置
                    quietMode = oldQuietMode
                    renderDialogMode = oldRenderDialogMode
                )
                else
                (
                    -- 确保场景准备就绪
                    redrawViews()
                    windows.processPostedMessages()
                    
                    addLog ("      开始执行渲染脚本...")
                    
                    -- 执行渲染脚本
                    fileIn renderScriptPath
                )
                
                addLog ("      渲染脚本执行完成")
                return true
            )
            else
            (
                addLog "    渲染脚本不存在，跳过渲染"
                return true
            )
        )
        catch (e)
        (
            addLog ("    渲染错误: " + e as string)
            return false
        )
    )
    
    -- 检查暂停状态
    function checkPauseState =
    (
        while isPaused and isProcessing do
        (
            sleep 0.1
            windows.processPostedMessages()
        )
        return isProcessing -- 如果不再处理，返回false停止
    )
    
    -- 克隆到勾选的文件
    function cloneToSelectedFiles =
    (
        local selectedIndices = mlbMaxFiles.selection as array
        if selectedIndices.count == 0 then
        (
            messageBox "请先勾选要处理的文件！"
            return false
        )
        
        -- 设置处理状态
        isProcessing = true
        isPaused = false
        btnCloneToSelected.enabled = false
        btnPauseResume.enabled = true
        btnPauseResume.text = "暂停"
        btnStop.enabled = true
        
        local settings = saveCurrentSettings()
        
        if settings.count > 0 then
        (
            pbProgress.value = 0
            local successCount = 0
            local totalFiles = selectedIndices.count
            
            for i = 1 to totalFiles do
            (
                -- 检查是否需要停止处理
                if not checkPauseState() then
                (
                    addLog "用户停止了处理过程"
                    exit
                )
                
                local fileIndex = selectedIndices[i]
                local targetFile = maxFiles[fileIndex]
                
                addLog ("========================================")
                addLog ("开始处理文件 " + i as string + "/" + totalFiles as string)
                addLog ("目标文件: " + (filenameFromPath targetFile))
                
                -- 清理状态
                gc()
                windows.processPostedMessages()
                
                -- 检查暂停状态
                if not checkPauseState() then exit
                
                -- 克隆设置
                local cloneSuccess = applySettingsToFile targetFile settings
                
                -- 检查暂停状态
                if not checkPauseState() then exit
                
                -- 如果克隆成功且启用了自动渲染
                if cloneSuccess and chkAutoRender.checked then
                (
                    addLog "  重新打开文件进行渲染..."
                    if loadMaxFile targetFile quiet:true then
                    (
                        addLog "  文件已重新打开，开始渲染..."
                        
                        -- 检查暂停状态
                        if not checkPauseState() then exit
                        
                        local renderSuccess = executeRenderScript targetFile
                        
                        if renderSuccess then
                        (
                            addLog "  渲染完成，正在保存文件..."
                            local saveSuccess = saveFileReliably targetFile
                            if saveSuccess then
                                addLog ("  渲染完成，文件已保存: " + (filenameFromPath targetFile))
                            else
                                addLog ("  警告: 渲染后文件保存失败")
                        )
                    )
                    else
                    (
                        addLog ("  错误: 无法重新打开文件进行渲染")
                    )
                )
                
                if cloneSuccess then 
                (
                    successCount += 1
                    addLog ("文件 " + i as string + " 处理成功")
                )
                else
                (
                    addLog ("文件 " + i as string + " 处理失败")
                )
                
                pbProgress.value = (100.0 * i / totalFiles)
                windows.processPostedMessages()
                
                -- 检查暂停状态
                if not checkPauseState() then exit
                
                sleep 0.5
            )
            
            addLog ("批量处理完成！成功: " + successCount as string + "/" + totalFiles as string)
        )
        else
        (
            messageBox "请至少选择一个克隆选项！"
        )
        
        -- 恢复界面状态
        isProcessing = false
        isPaused = false
        btnCloneToSelected.enabled = true
        btnPauseResume.enabled = false
        btnPauseResume.text = "暂停"
        btnStop.enabled = false
    )
    
    -- 事件处理
    on sceneCloneRollout open do
    (
        edtCurrentFile.text = if currentFileName != "" then currentFileName else "未保存的文件"
        
        -- 设置默认渲染脚本路径为同级目录的Render53.ms
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
        local selections = #{}
        for i = 1 to mlbMaxFiles.items.count do
            selections[i] = true
        mlbMaxFiles.selection = selections
        addLog "已全选所有文件。"
    )
    
    on btnSelectNone pressed do
    (
        mlbMaxFiles.selection = #{}
        addLog "已取消选择所有文件。"
    )
    
    -- 双击文件列表项来设置为源文件
    on mlbMaxFiles doubleClicked index do
    (
        if index > 0 and index <= maxFiles.count then
        (
            local selectedFile = maxFiles[index]
            local selectedFileName = filenameFromPath selectedFile
            
            -- 询问用户是否要切换源文件
            local result = queryBox ("是否要将 \"" + selectedFileName + "\" 设置为新的源文件？\n\n当前源文件: " + currentFileName + "\n新源文件: " + selectedFileName) title:"切换源文件"
            
            if result then
            (
                -- 保存当前文件（如果有修改）
                if maxFileName != "" then
                (
                    local saveResult = queryBox "是否要先保存当前文件？" title:"保存确认"
                    if saveResult then
                    (
                        max file save
                        addLog "当前文件已保存。"
                    )
                )
                
                -- 打开新的源文件
                if loadMaxFile selectedFile quiet:true then
                (
                    -- 更新当前文件信息
                    currentDir = maxFilePath
                    currentFileName = maxFileName
                    edtCurrentFile.text = currentFileName
                    
                    -- 刷新文件列表（排除新的当前文件）
                    getMaxFiles()
                    
                    addLog ("========================================")
                    addLog ("源文件已切换为: " + currentFileName)
                    addLog ("工作目录: " + currentDir)
                    addLog ("========================================")
                )
                else
                (
                    addLog ("错误: 无法打开文件 " + selectedFileName)
                )
            )
        )
    )
    
    on btnBrowseRender pressed do
    (
        local renderFile = getOpenFileName caption:"选择渲染脚本" types:"MAXScript (*.ms)|*.ms|所有文件 (*.*)|*.*"
        if renderFile != undefined then
        (
            edtRenderScript.text = renderFile
            addLog ("渲染脚本路径已更新: " + renderFile)
        )
    )
    
    on btnPauseResume pressed do
    (
        if isProcessing then
        (
            if isPaused then
            (
                -- 恢复处理
                isPaused = false
                btnPauseResume.text = "暂停"
                addLog "恢复处理..."
            )
            else
            (
                -- 暂停处理
                isPaused = true
                btnPauseResume.text = "恢复"
                addLog "暂停处理..."
            )
        )
    )
    
    on btnStop pressed do
    (
        if isProcessing then
        (
            -- 停止处理
            isProcessing = false
            isPaused = false
            btnCloneToSelected.enabled = true
            btnPauseResume.enabled = false
            btnPauseResume.text = "暂停"
            btnStop.enabled = false
            addLog "用户停止了处理过程"
        )
    )
    
    on btnCloneToSelected pressed do
    (
        local selectedCount = (mlbMaxFiles.selection as array).count
        if selectedCount > 0 then
        (
            local confirmMsg = "确定要处理 " + selectedCount as string + " 个文件吗？"
            if chkAutoRender.checked then
            (
                confirmMsg += "\n注意：启用了自动渲染功能。"
                if chkSilentRender.checked then
                    confirmMsg += "\n静默渲染模式已启用。"
            )
            confirmMsg += "\n这个操作不可撤销！"
            
            if queryBox confirmMsg title:"确认操作" then
                cloneToSelectedFiles()
        )
        else
        (
            messageBox "请先勾选要处理的文件！"
        )
    )
)

-- 创建并显示对话框
createDialog sceneCloneRollout