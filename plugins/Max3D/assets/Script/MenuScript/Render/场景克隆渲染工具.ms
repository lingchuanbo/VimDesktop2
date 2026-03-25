-- 场景设置克隆工具
-- 将当前文件的材质、环境、灯光设置克隆到其他 Max 文件
-- Author: Kiro Assistant
-- Version: 2.0 结构重构版

global SCENE_CLONE_DEFAULT_RENDER_SCRIPT = "Render53.ms"
global SCENE_CLONE_RENDER_HELPER_NAME = "台"
global SCENE_CLONE_RENDER_CAMERA_NAME = "Camera"
global sceneCloneRuntimeState

struct SceneCloneRuntimeStateV2
(
    currentDir = "",
    currentFileName = "",
    maxFiles = #(),
    isPaused = false,
    isProcessing = false,
    tempFiles = #()
)

struct SceneCloneOptions
(
    cloneMaterials = true,
    cloneEnvironment = true,
    cloneLights = true,
    cloneRenderSettings = false,
    autoRender = true,
    silentRender = false,
    renderScriptPath = ""
)

struct SceneCloneMaterialEntry
(
    name = "",
    material = undefined
)

struct SceneCloneMaterialAssignment
(
    objectName = "",
    materialName = ""
)

struct SceneCloneMaterialSettings
(
    library = #(),
    assignments = #()
)

struct SceneCloneEnvironmentSettings
(
    backgroundColor = black,
    ambientColor = black,
    environmentMap = undefined
)

struct SceneCloneLightSettings
(
    lightData = #()
)

struct SceneCloneRenderSettingsData
(
    renderWidth = 0,
    renderHeight = 0,
    pixelAspect = 1.0
)

struct SceneCloneSettings
(
    materials = undefined,
    environment = undefined,
    lights = undefined,
    renderSettings = undefined
)

fn sceneCloneEnsureState =
(
    if sceneCloneRuntimeState == undefined then
        sceneCloneRuntimeState = SceneCloneRuntimeStateV2()

    sceneCloneRuntimeState
)

fn sceneCloneResetStateFromScene =
(
    sceneCloneRuntimeState = SceneCloneRuntimeStateV2()
    sceneCloneRuntimeState.currentDir = maxFilePath
    sceneCloneRuntimeState.currentFileName = maxFileName
    sceneCloneRuntimeState
)

fn sceneCloneLog ui msg =
(
    ui.edtLog.text = ui.edtLog.text + msg + "\r\n"
    windows.processPostedMessages()
)

fn sceneCloneValueToString value =
(
    if value == undefined then
        "<undefined>"
    else
        (value as string)
)

fn sceneCloneGetDefaultRenderScript =
(
    local scriptDir = getFilenamePath (getThisScriptFilename())
    scriptDir + SCENE_CLONE_DEFAULT_RENDER_SCRIPT
)

fn sceneCloneBuildSelectAllBitArray itemCount =
(
    local selections = #{}
    for i = 1 to itemCount do
        selections[i] = true
    selections
)

fn sceneCloneScanMaxFiles state =
(
    local fileNames = #()
    state.maxFiles = #()

    if state.currentDir != "" then
    (
        local files = getFiles (state.currentDir + "*.max")
        for f in files do
        (
            local fileName = filenameFromPath f
            if fileName != state.currentFileName then
            (
                append state.maxFiles f
                append fileNames fileName
            )
        )
    )

    fileNames
)

fn sceneCloneRefreshFileList state ui =
(
    local fileNames = sceneCloneScanMaxFiles state
    ui.mlbMaxFiles.items = fileNames
    ui.mlbMaxFiles.selection = sceneCloneBuildSelectAllBitArray fileNames.count
)

fn sceneCloneBuildOptionsFromUi ui =
(
    local options = SceneCloneOptions()
    options.cloneMaterials = ui.chkMaterials.checked
    options.cloneEnvironment = ui.chkEnvironment.checked
    options.cloneLights = ui.chkLights.checked
    options.cloneRenderSettings = ui.chkRenderSettings.checked
    options.autoRender = ui.chkAutoRender.checked
    options.silentRender = ui.chkSilentRender.checked
    options.renderScriptPath = ui.edtRenderScript.text
    options
)

fn sceneCloneHasCloneWork options =
(
    options.cloneMaterials or options.cloneEnvironment or options.cloneLights or options.cloneRenderSettings
)

fn sceneCloneFindMaterialEntryByName entries materialName =
(
    for entry in entries do
    (
        if entry.name == materialName then
            return entry
    )
    undefined
)

fn sceneCloneCaptureMaterialSettings options ui =
(
    if not options.cloneMaterials then
        return undefined

    sceneCloneLog ui "正在保存材质设置..."

    local materialAssignments = #()
    local materialLibrary = #()
    local processedCount = 0

    for obj in geometry do
    (
        processedCount += 1

        if obj.material != undefined then
        (
            append materialAssignments (SceneCloneMaterialAssignment objectName:obj.name materialName:obj.material.name)

            if (sceneCloneFindMaterialEntryByName materialLibrary obj.material.name) == undefined then
            (
                local materialCopy = undefined
                try
                (
                    materialCopy = copy obj.material
                )
                catch
                (
                    materialCopy = obj.material
                )

                append materialLibrary (SceneCloneMaterialEntry name:obj.material.name material:materialCopy)
            )
        )
    )

    sceneCloneLog ui ("  已扫描 " + processedCount as string + " 个几何体对象")
    sceneCloneLog ui ("  材质分配: " + materialAssignments.count as string + " 个对象")
    sceneCloneLog ui ("  材质库: " + materialLibrary.count as string + " 个材质")

    SceneCloneMaterialSettings library:materialLibrary assignments:materialAssignments
)

fn sceneCloneCaptureEnvironmentSettings options ui =
(
    if not options.cloneEnvironment then
        return undefined

    sceneCloneLog ui "正在保存环境设置..."

    local environmentSettings = SceneCloneEnvironmentSettings()
    environmentSettings.backgroundColor = backgroundColor
    environmentSettings.ambientColor = ambientColor

    if environmentMap != undefined then
    (
        local envMapCopy = undefined
        try
        (
            envMapCopy = copy environmentMap
        )
        catch
        (
            envMapCopy = environmentMap
        )

        environmentSettings.environmentMap = envMapCopy
    )

    environmentSettings
)

fn sceneCloneBuildTempFile state prefix =
(
    local tempDir = getDir #temp
    local randomId = (random 100000 999999) as string
    local baseName = if state.currentFileName != "" then getFilenameFile state.currentFileName else "SceneClone"
    tempDir + "\\" + prefix + "_" + baseName + "_" + randomId + ".max"
)

fn sceneCloneTrackTempFile state filePath =
(
    if (findItem state.tempFiles filePath) == 0 then
        append state.tempFiles filePath
)

fn sceneCloneCaptureLightSettings state options ui =
(
    if not options.cloneLights then
        return undefined

    sceneCloneLog ui "正在保存灯光设置..."

    local lightCount = lights.count
    if lightCount == 0 then
    (
        sceneCloneLog ui "  当前场景无灯光"
        return SceneCloneLightSettings()
    )

    local lightData = #()
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
    sceneCloneLog ui ("  保存完成，共 " + lightData.count as string + " 个灯光")
    SceneCloneLightSettings lightData:lightData
)

fn sceneCloneCaptureRenderSettings options ui =
(
    if not options.cloneRenderSettings then
        return undefined

    sceneCloneLog ui "正在保存渲染设置..."

    local renderSettings = SceneCloneRenderSettingsData()
    renderSettings.renderWidth = renderWidth
    renderSettings.renderHeight = renderHeight
    renderSettings.pixelAspect = renderPixelAspect
    renderSettings
)

fn sceneCloneCaptureSettings state options ui =
(
    local settings = SceneCloneSettings()
    settings.materials = sceneCloneCaptureMaterialSettings options ui
    settings.environment = sceneCloneCaptureEnvironmentSettings options ui
    settings.lights = sceneCloneCaptureLightSettings state options ui
    settings.renderSettings = sceneCloneCaptureRenderSettings options ui
    settings
)

fn sceneCloneFindImportedMaterialByName importedMaterials materialName =
(
    for entry in importedMaterials do
    (
        if entry.name == materialName then
            return entry.material
    )
    undefined
)

fn sceneCloneApplyMaterialSettings materialSettings ui =
(
    if materialSettings == undefined then
        return true

    sceneCloneLog ui "  应用材质分配..."

    local importedMaterials = #()

    for materialEntry in materialSettings.library do
    (
        if materialEntry.material != undefined then
        (
            local importedMaterial = undefined
            try
            (
                importedMaterial = copy materialEntry.material
            )
            catch
            (
                importedMaterial = materialEntry.material
            )

            if importedMaterial != undefined then
            (
                importedMaterial.name = materialEntry.name
                append sceneMaterials importedMaterial
                append importedMaterials (SceneCloneMaterialEntry name:materialEntry.name material:importedMaterial)
                sceneCloneLog ui ("    添加材质到库: " + materialEntry.name)
            )
        )
    )

    for assignment in materialSettings.assignments do
    (
        local targetObj = getNodeByName assignment.objectName
        if targetObj == undefined then
        (
            sceneCloneLog ui ("    警告: 未找到对象 " + assignment.objectName)
            continue
        )

        local sourceMaterial = sceneCloneFindImportedMaterialByName importedMaterials assignment.materialName
        if sourceMaterial != undefined then
        (
            targetObj.material = sourceMaterial
            sceneCloneLog ui ("    分配材质: " + assignment.objectName + " -> " + assignment.materialName)
        )
        else
        (
            sceneCloneLog ui ("    警告: 未找到材质 " + assignment.materialName)
        )
    )

    true
)

fn sceneCloneApplyEnvironmentSettings environmentSettings ui =
(
    if environmentSettings == undefined then
        return true

    sceneCloneLog ui "  应用环境设置..."
    backgroundColor = environmentSettings.backgroundColor
    ambientColor = environmentSettings.ambientColor

    if environmentSettings.environmentMap != undefined then
    (
        try
        (
            environmentMap = copy environmentSettings.environmentMap
        )
        catch
        (
            environmentMap = environmentSettings.environmentMap
        )
    )
    else
    (
        environmentMap = undefined
    )

    true
)

fn sceneCloneDeleteExistingLights ui =
(
    local lightCountBefore = lights.count

    if lightCountBefore == 0 then
    (
        sceneCloneLog ui "    目标文件无灯光需要删除"
        return true
    )

    try
    (
        delete lights
    )
    catch
    (
        local lightArray = #()
        for lightObj in lights do append lightArray lightObj

        for lightObj in lightArray do
        (
            try
            (
                if isValidNode lightObj then
                    delete lightObj
            )
            catch()
        )
    )

    local deletedCount = lightCountBefore - lights.count
    sceneCloneLog ui ("    删除完成，删除了 " + deletedCount as string + " 个灯光")
    true
)

fn sceneCloneApplyLightSettings lightSettings ui =
(
    if lightSettings == undefined then
        return true

    sceneCloneLog ui "  融合灯光设置..."
    local sourceLightData = lightSettings.lightData

    -- 第一步：删除目标文件中的所有现有灯光
    sceneCloneLog ui "    第一步：删除目标文件中的所有现有灯光"
    sceneCloneDeleteExistingLights ui

    -- 强制刷新场景
    redrawViews()
    windows.processPostedMessages()

    -- 第二步：从源文件导入灯光（如果有的话）
    if sourceLightData.count > 0 then
    (
        sceneCloneLog ui ("    第二步：导入 " + sourceLightData.count as string + " 个灯光")
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

        sceneCloneLog ui ("    导入完成，成功导入 " + fusedCount as string + " 个灯光")
    )
    else
    (
        sceneCloneLog ui "    源文件无灯光"
    )

    true
)

fn sceneCloneApplyRenderSettings renderSettings ui =
(
    if renderSettings == undefined then
        return true

    sceneCloneLog ui "  应用渲染设置..."
    renderWidth = renderSettings.renderWidth
    renderHeight = renderSettings.renderHeight
    renderPixelAspect = renderSettings.pixelAspect
    true
)

fn sceneCloneSaveFileReliably targetFile ui =
(
    local saveSuccess = false

    -- 清理场景状态
    gc()
    windows.processPostedMessages()

    -- 方法1: 使用saveMaxFile
    try
    (
        saveMaxFile targetFile quiet:true
        sceneCloneLog ui ("    方法1保存成功: " + (filenameFromPath targetFile))
        saveSuccess = true
    )
    catch (e)
    (
        sceneCloneLog ui ("    方法1保存失败，错误类型: " + (classof e) as string)
        if (classof e) == Float then
            sceneCloneLog ui ("    检测到数值错误，可能是场景状态问题")
    )

    -- 如果方法1失败，尝试方法2
    if not saveSuccess then
    (
        try
        (
            sceneCloneLog ui ("    尝试方法2保存...")
            -- 强制刷新场景
            redrawViews()
            windows.processPostedMessages()

            -- 确保文件名正确设置
            maxFileName = filenameFromPath targetFile
            maxFilePath = getFilenamePath targetFile

            -- 使用max file save命令
            max file save
            sceneCloneLog ui ("    方法2保存成功")
            saveSuccess = true
        )
        catch (e)
        (
            sceneCloneLog ui ("    方法2保存失败: " + e as string)
        )
    )

    -- 如果还是失败，尝试方法3
    if not saveSuccess then
    (
        try
        (
            sceneCloneLog ui ("    尝试方法3保存...")
            -- 等待一下再保存
            sleep 1
            saveMaxFile targetFile
            sceneCloneLog ui ("    方法3保存成功")
            saveSuccess = true
        )
        catch (e)
        (
            sceneCloneLog ui ("    方法3保存失败: " + e as string)
            sceneCloneLog ui ("    所有保存方法都失败，请手动保存文件")
        )
    )

    return saveSuccess
)

fn sceneCloneApplySettingsToFile targetFile settings ui =
(
    sceneCloneLog ui ("正在处理文件: " + (filenameFromPath targetFile))

    local currentStage = "初始化"
    local finalResult = false
    local loadSuccess = false
    local applySuccess = true
    local saveSuccess = false

    currentStage = "打开目标文件"
    try
    (
        loadSuccess = loadMaxFile targetFile quiet:true
    )
    catch (loadError)
    (
        sceneCloneLog ui ("  严重错误（阶段: " + currentStage + "）: " + sceneCloneValueToString loadError)
    )

    if not loadSuccess then
    (
        sceneCloneLog ui ("  错误: 无法打开文件 " + (filenameFromPath targetFile))
        return false
    )

    if settings.materials != undefined then
    (
        currentStage = "应用材质"
        try
        (
            applySuccess = (sceneCloneApplyMaterialSettings settings.materials ui) and applySuccess
        )
        catch (materialsError)
        (
            sceneCloneLog ui ("  严重错误（阶段: " + currentStage + "）: " + sceneCloneValueToString materialsError)
            applySuccess = false
        )
    )

    if settings.environment != undefined then
    (
        currentStage = "应用环境"
        try
        (
            applySuccess = (sceneCloneApplyEnvironmentSettings settings.environment ui) and applySuccess
        )
        catch (environmentError)
        (
            sceneCloneLog ui ("  严重错误（阶段: " + currentStage + "）: " + sceneCloneValueToString environmentError)
            applySuccess = false
        )
    )

    if settings.lights != undefined then
    (
        currentStage = "应用灯光"
        try
        (
            applySuccess = (sceneCloneApplyLightSettings settings.lights ui) and applySuccess
        )
        catch (lightsError)
        (
            sceneCloneLog ui ("  严重错误（阶段: " + currentStage + "）: " + sceneCloneValueToString lightsError)
            applySuccess = false
        )
    )

    if settings.renderSettings != undefined then
    (
        currentStage = "应用渲染设置"
        try
        (
            applySuccess = (sceneCloneApplyRenderSettings settings.renderSettings ui) and applySuccess
        )
        catch (renderSettingsError)
        (
            sceneCloneLog ui ("  严重错误（阶段: " + currentStage + "）: " + sceneCloneValueToString renderSettingsError)
            applySuccess = false
        )
    )

    currentStage = "保存文件"
    sceneCloneLog ui "  正在保存文件..."
    try
    (
        saveSuccess = sceneCloneSaveFileReliably targetFile ui
    )
    catch (saveError)
    (
        sceneCloneLog ui ("  严重错误（阶段: " + currentStage + "）: " + sceneCloneValueToString saveError)
        saveSuccess = false
    )

    if not saveSuccess then
        sceneCloneLog ui "  警告: 文件保存失败，请手动保存"

    -- 只要文件加载成功就返回true（与旧版一致），保存失败不影响后续渲染
    return true
)

fn sceneCloneExecuteRenderScript options ui =
(
    try
    (
        if options.renderScriptPath == "" or not (doesFileExist options.renderScriptPath) then
        (
            sceneCloneLog ui "    渲染脚本不存在，跳过渲染"
            return true
        )

        sceneCloneLog ui ("    执行渲染脚本: " + (filenameFromPath options.renderScriptPath))

        local helperObj = getNodeByName SCENE_CLONE_RENDER_HELPER_NAME
        local cameraObj = getNodeByName SCENE_CLONE_RENDER_CAMERA_NAME

        if helperObj != undefined then
            sceneCloneLog ui ("      找到目标对象: " + helperObj.name)
        else
            sceneCloneLog ui ("      警告: 未找到'" + SCENE_CLONE_RENDER_HELPER_NAME + "'对象")

        if cameraObj != undefined then
            sceneCloneLog ui ("      找到摄像机: " + cameraObj.name)
        else
            sceneCloneLog ui ("      警告: 未找到'" + SCENE_CLONE_RENDER_CAMERA_NAME + "'摄像机")

        if options.silentRender then
        (
            local oldQuietMode = quietMode
            local oldRenderDialogMode = renderDialogMode

            sceneCloneLog ui "      启用静默渲染模式"
            quietMode = true
            renderDialogMode = false

            try
            (
                fileIn options.renderScriptPath
            )
            catch (silentRenderError)
            (
                sceneCloneLog ui ("      静默渲染异常: " + silentRenderError as string)
                quietMode = oldQuietMode
                renderDialogMode = oldRenderDialogMode
                return false
            )

            quietMode = oldQuietMode
            renderDialogMode = oldRenderDialogMode
        )
        else
        (
            redrawViews()
            windows.processPostedMessages()
            sceneCloneLog ui "      开始执行渲染脚本..."
            fileIn options.renderScriptPath
        )

        sceneCloneLog ui "      渲染脚本执行完成"
        return true
    )
    catch (renderError)
    (
        sceneCloneLog ui ("    渲染错误: " + renderError as string)
        return false
    )
)

fn sceneCloneCheckPauseState state =
(
    while state.isPaused and state.isProcessing do
    (
        sleep 0.1
        windows.processPostedMessages()
    )

    return state.isProcessing
)

fn sceneCloneResetUiState state ui =
(
    state.isProcessing = false
    state.isPaused = false
    ui.btnCloneToSelected.enabled = true
    ui.btnPauseResume.enabled = false
    ui.btnPauseResume.text = "暂停"
    ui.btnStop.enabled = false
)

fn sceneCloneCleanupTempFiles state ui =
(
    for tempFile in state.tempFiles do
    (
        if doesFileExist tempFile then
        (
            try
            (
                deleteFile tempFile
            )
            catch (cleanupError)
            (
                sceneCloneLog ui ("清理临时文件失败: " + tempFile + " - " + cleanupError as string)
            )
        )
    )

    state.tempFiles = #()
)

fn sceneCloneCloneToSelectedFiles state ui =
(
    local selectedIndices = ui.mlbMaxFiles.selection as array
    if selectedIndices.count == 0 then
    (
        messageBox "请先勾选要处理的文件！"
        return false
    )

    local options = sceneCloneBuildOptionsFromUi ui
    if not (sceneCloneHasCloneWork options) then
    (
        messageBox "请至少选择一个克隆选项！"
        return false
    )

    state.isProcessing = true
    state.isPaused = false
    state.tempFiles = #()

    ui.btnCloneToSelected.enabled = false
    ui.btnPauseResume.enabled = true
    ui.btnPauseResume.text = "暂停"
    ui.btnStop.enabled = true

    local settings = sceneCloneCaptureSettings state options ui
    local originalFilePath = maxFilePath + maxFileName
    local successCount = 0
    local totalFiles = selectedIndices.count
    local batchStage = "初始化"

    ui.pbProgress.value = 0

    for i = 1 to totalFiles do
    (
        if not (sceneCloneCheckPauseState state) then
        (
            sceneCloneLog ui "用户停止了处理过程"
            exit
        )

        local targetFile = state.maxFiles[selectedIndices[i]]

        sceneCloneLog ui "========================================"
        sceneCloneLog ui ("开始处理文件 " + i as string + "/" + totalFiles as string)
        sceneCloneLog ui ("目标文件: " + (filenameFromPath targetFile))

        gc()
        windows.processPostedMessages()

        if not (sceneCloneCheckPauseState state) then exit

        batchStage = "克隆设置"
        local cloneSuccess = sceneCloneApplySettingsToFile targetFile settings ui
        sceneCloneLog ui ("  克隆返回: " + sceneCloneValueToString cloneSuccess + ", 自动渲染: " + sceneCloneValueToString options.autoRender)

        if cloneSuccess and options.autoRender then
        (
            batchStage = "自动渲染"
            sceneCloneLog ui "  重新打开文件进行渲染..."
            if loadMaxFile targetFile quiet:true then
            (
                sceneCloneLog ui "  文件已重新打开，开始渲染..."

                if not (sceneCloneCheckPauseState state) then exit

                local renderSuccess = sceneCloneExecuteRenderScript options ui

                if renderSuccess then
                (
                    sceneCloneLog ui "  渲染完成，正在保存文件..."
                    if sceneCloneSaveFileReliably targetFile ui then
                        sceneCloneLog ui ("  渲染完成，文件已保存: " + (filenameFromPath targetFile))
                    else
                        sceneCloneLog ui "  警告: 渲染后文件保存失败"
                )
                else
                (
                    sceneCloneLog ui "  渲染未成功完成"
                )
            )
            else
            (
                sceneCloneLog ui "  错误: 无法重新打开文件进行渲染"
                cloneSuccess = false
            )
        )

        if cloneSuccess then
        (
            successCount += 1
            sceneCloneLog ui ("文件 " + i as string + " 处理成功")
        )
        else
        (
            sceneCloneLog ui ("文件 " + i as string + " 处理失败")
        )

        ui.pbProgress.value = 100.0 * i / totalFiles
        windows.processPostedMessages()

        if not (sceneCloneCheckPauseState state) then exit

        sleep 0.5
    )

    sceneCloneLog ui ("批量处理完成！成功: " + successCount as string + "/" + totalFiles as string)

    if originalFilePath != "" and doesFileExist originalFilePath then
    (
        if loadMaxFile originalFilePath quiet:true then
        (
            state.currentDir = maxFilePath
            state.currentFileName = maxFileName
            ui.edtCurrentFile.text = state.currentFileName
            sceneCloneRefreshFileList state ui
            sceneCloneLog ui ("已恢复源文件: " + state.currentFileName)
        )
        else
        (
            sceneCloneLog ui "警告: 批处理结束后未能恢复原始源文件"
        )
    )

    sceneCloneCleanupTempFiles state ui
    sceneCloneResetUiState state ui
    return true
)

fn sceneCloneSaveCurrentSceneIfNeeded ui =
(
    if maxFileName == "" then
        return true

    local saveResult = queryBox "是否要先保存当前文件？" title:"保存确认"
    if not saveResult then
        return true

    local currentFile = maxFilePath + maxFileName
    if currentFile == "" then
        return true

    if saveMaxFile currentFile useNewFile:false quiet:true then
    (
        sceneCloneLog ui "当前文件已保存。"
        true
    )
    else
    (
        sceneCloneLog ui "警告: 当前文件保存失败。"
        false
    )
)

fn sceneCloneSwitchSourceFile state ui fileIndex =
(
    if fileIndex <= 0 or fileIndex > state.maxFiles.count then
        return false

    local selectedFile = state.maxFiles[fileIndex]
    local selectedFileName = filenameFromPath selectedFile

    local confirmText = "是否要将 \"" + selectedFileName + "\" 设置为新的源文件？\n\n当前源文件: " + state.currentFileName + "\n新源文件: " + selectedFileName
    if not (queryBox confirmText title:"切换源文件") then
        return false

    if not (sceneCloneSaveCurrentSceneIfNeeded ui) then
        return false

    if loadMaxFile selectedFile quiet:true then
    (
        state.currentDir = maxFilePath
        state.currentFileName = maxFileName
        ui.edtCurrentFile.text = state.currentFileName

        sceneCloneRefreshFileList state ui

        sceneCloneLog ui "========================================"
        sceneCloneLog ui ("源文件已切换为: " + state.currentFileName)
        sceneCloneLog ui ("工作目录: " + state.currentDir)
        sceneCloneLog ui "========================================"
        true
    )
    else
    (
        sceneCloneLog ui ("错误: 无法打开文件 " + selectedFileName)
        false
    )
)

try(destroyDialog sceneCloneRollout)catch()

rollout sceneCloneRollout "场景设置克隆工具ByBoBO" width:700 height:600
(
    label lblCurrentFileTitle "当前文件:" pos:[15,15] width:100
    edittext edtCurrentFile "" pos:[15,35] width:300 readonly:true

    label lblFileListTitle "目标文件列表 (勾选要处理的文件，双击可切换源文件):" pos:[15,65] width:300
    multiListBox mlbMaxFiles "" pos:[15,85] width:300 height:18
    button btnRefresh "刷新文件列表" pos:[15,420] width:90 height:25
    button btnSelectAll "全选" pos:[115,420] width:60 height:25
    button btnSelectNone "全不选" pos:[185,420] width:60 height:25

    groupBox grpCloneOptions "克隆选项" pos:[330,15] width:350 height:140
    checkbox chkMaterials "克隆材质" pos:[340,35] checked:true
    checkbox chkEnvironment "克隆环境设置（背景色/环境光/环境贴图）" pos:[340,60] checked:true
    checkbox chkLights "融合灯光（删除现有+从源文件融合）" pos:[340,85] checked:true
    checkbox chkRenderSettings "克隆渲染设置" pos:[340,110] checked:false

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

    on sceneCloneRollout open do
    (
        local state = sceneCloneResetStateFromScene()

        edtCurrentFile.text = if state.currentFileName != "" then state.currentFileName else "未保存的文件"
        edtRenderScript.text = sceneCloneGetDefaultRenderScript()

        sceneCloneRefreshFileList state sceneCloneRollout
        sceneCloneLog sceneCloneRollout "工具已启动，准备就绪。"

        if doesFileExist edtRenderScript.text then
            sceneCloneLog sceneCloneRollout ("已找到渲染脚本: " + edtRenderScript.text)
        else
            sceneCloneLog sceneCloneRollout ("警告: 未找到渲染脚本 " + edtRenderScript.text)
    )

    on btnRefresh pressed do
    (
        sceneCloneRefreshFileList (sceneCloneEnsureState()) sceneCloneRollout
        sceneCloneLog sceneCloneRollout "文件列表已刷新。"
    )

    on btnSelectAll pressed do
    (
        mlbMaxFiles.selection = sceneCloneBuildSelectAllBitArray mlbMaxFiles.items.count
        sceneCloneLog sceneCloneRollout "已全选所有文件。"
    )

    on btnSelectNone pressed do
    (
        mlbMaxFiles.selection = #{}
        sceneCloneLog sceneCloneRollout "已取消选择所有文件。"
    )

    on mlbMaxFiles doubleClicked index do
    (
        sceneCloneSwitchSourceFile (sceneCloneEnsureState()) sceneCloneRollout index
    )

    on btnBrowseRender pressed do
    (
        local renderFile = getOpenFileName caption:"选择渲染脚本" types:"MAXScript (*.ms)|*.ms|所有文件 (*.*)|*.*"
        if renderFile != undefined then
        (
            edtRenderScript.text = renderFile
            sceneCloneLog sceneCloneRollout ("渲染脚本路径已更新: " + renderFile)
        )
    )

    on btnPauseResume pressed do
    (
        local state = sceneCloneEnsureState()
        if state.isProcessing then
        (
            if state.isPaused then
            (
                state.isPaused = false
                btnPauseResume.text = "暂停"
                sceneCloneLog sceneCloneRollout "恢复处理..."
            )
            else
            (
                state.isPaused = true
                btnPauseResume.text = "恢复"
                sceneCloneLog sceneCloneRollout "暂停处理..."
            )
        )
    )

    on btnStop pressed do
    (
        local state = sceneCloneEnsureState()
        if state.isProcessing then
        (
            state.isProcessing = false
            state.isPaused = false
            sceneCloneResetUiState state sceneCloneRollout
            sceneCloneLog sceneCloneRollout "用户停止了处理过程"
        )
    )

    on btnCloneToSelected pressed do
    (
        local selectedCount = (mlbMaxFiles.selection as array).count
        if selectedCount == 0 then
        (
            messageBox "请先勾选要处理的文件！"
            return()
        )

        local confirmMsg = "确定要处理 " + selectedCount as string + " 个文件吗？"
        if chkAutoRender.checked then
        (
            confirmMsg += "\n注意：启用了自动渲染功能。"
            if chkSilentRender.checked then
                confirmMsg += "\n静默渲染模式已启用。"
        )
        confirmMsg += "\n这个操作不可撤销！"

        if queryBox confirmMsg title:"确认操作" then
            sceneCloneCloneToSelectedFiles (sceneCloneEnsureState()) sceneCloneRollout
    )
)

createDialog sceneCloneRollout
