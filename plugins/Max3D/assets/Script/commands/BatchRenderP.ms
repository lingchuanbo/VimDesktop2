-- 批量渲染工具 (优化版)
-- 批量打开Max文件并执行渲染脚本
-- Author: Kiro Assistant
-- Version: 2.0 重构优化版

try(destroyDialog batchRenderRollout)catch()

rollout batchRenderRollout "批量渲染工具ByBoBO" width:600 height:550
(
    -- ==================== 配置常量 ====================
    local DEFAULT_RENDER_SCRIPT = "Render53.ms"
    local PROCESS_DELAY = 0.1
    
    -- ==================== 状态变量 ====================
    local currentDir = maxFilePath
    local maxFiles = #()
    local isPaused = false
    local isProcessing = false
    local processedCount = 0
    local successCount = 0
    local failedCount = 0
    
    -- ==================== UI 控件 ====================
    -- 文件列表区域
    label lblCurrentDirTitle "当前目录:" pos:[15,15] width:100
    edittext edtCurrentDir "" pos:[15,35] width:400 readonly:true
    button btnBrowseDir "浏览目录..." pos:[425,35] width:80 height:20
    
    label lblFileListTitle "Max文件列表 (勾选要渲染的文件):" pos:[15,65] width:300
    multiListBox mlbMaxFiles "" pos:[15,85] width:570 height:12
    button btnRefresh "刷新文件列表" pos:[15,300] width:90 height:25
    button btnSelectAll "全选" pos:[115,300] width:60 height:25
    button btnSelectNone "全不选" pos:[185,300] width:60 height:25
    
    -- 渲染选项区域
    groupBox grpRenderOptions "渲染选项" pos:[15,335] width:570 height:105
    checkbox chkSilentRender "静默渲染（不显示渲染窗口）" pos:[25,355] checked:false
    checkbox chkSaveFile "Save File (激活Render Output)" pos:[250,355] checked:true
    label lblRenderScript "渲染脚本路径:" pos:[25,375] width:100
    edittext edtRenderScript "Render53.ms" pos:[130,375] width:350 readonly:false
    button btnBrowseRender "浏览..." pos:[490,375] width:60 height:20
    
    -- 渲染尺寸设置
    checkbox chkCustomSize "自定义渲染尺寸:" pos:[25,400] checked:false
    label lblWidth "宽:" pos:[160,402] width:20
    spinner spnWidth "" pos:[180,400] width:70 range:[1,8192,1920] type:#integer enabled:false
    label lblHeight "高:" pos:[260,402] width:20
    spinner spnHeight "" pos:[280,400] width:70 range:[1,8192,1080] type:#integer enabled:false
    
    -- 操作控制区域
    groupBox grpOperations "操作控制" pos:[15,450] width:570 height:60
    button btnStartRender "开始批量渲染" pos:[25,470] width:120 height:30
    button btnPauseResume "暂停" pos:[155,470] width:60 height:30 enabled:false
    button btnStop "停止" pos:[225,470] width:60 height:30 enabled:false
    progressbar pbProgress pos:[295,475] width:280 height:20
    
    -- ==================== 工具函数 ====================
    
    -- 添加日志
    fn addLog msg = (print msg; format "%\n" msg)
    
    -- 获取指定目录的Max文件
    fn getMaxFiles targetDir =
    (
        maxFiles = #()
        if targetDir != "" and doesDirectoryExist targetDir do (
            for f in (getFiles (targetDir + "\\*.max")) do append maxFiles f
        )
        
        mlbMaxFiles.items = for f in maxFiles collect (filenameFromPath f)
        mlbMaxFiles.selection = #{1..mlbMaxFiles.items.count}
        maxFiles.count
    )
    
    -- 查找渲染脚本
    fn findRenderScript dir =
    (
        local scriptPath = dir + "\\" + DEFAULT_RENDER_SCRIPT
        if doesFileExist scriptPath then scriptPath else ""
    )
    
    -- 更新UI状态
    fn setProcessingState processing =
    (
        isProcessing = processing
        isPaused = false
        btnStartRender.enabled = not processing
        btnPauseResume.enabled = processing
        btnPauseResume.text = "暂停"
        btnStop.enabled = processing
    )
    
    -- 重置计数器
    fn resetCounters =
    (
        processedCount = 0
        successCount = 0
        failedCount = 0
        pbProgress.value = 0
    )

    -- 检查暂停状态
    fn checkPauseState =
    (
        while isPaused and isProcessing do (
            sleep PROCESS_DELAY
            windows.processPostedMessages()
        )
        isProcessing
    )
    
    -- 应用渲染设置
    fn applyRenderSettings =
    (
        -- Save File设置
        if chkSaveFile.checked do (
            rendSaveFile = true
            addLog "  Render Output 已激活"
        )
        
        -- 自定义渲染尺寸
        if chkCustomSize.checked then (
            renderWidth = spnWidth.value
            renderHeight = spnHeight.value
            addLog ("  渲染尺寸: " + renderWidth as string + " x " + renderHeight as string)
        ) else (
            addLog ("  渲染尺寸: 使用文件设置 (" + renderWidth as string + " x " + renderHeight as string + ")")
        )
    )
    
    -- 执行渲染脚本
    fn executeRenderScript =
    (
        local renderScriptPath = edtRenderScript.text
        if not (doesFileExist renderScriptPath) do (
            addLog ("    错误: 渲染脚本不存在 - " + renderScriptPath)
            return false
        )
        
        addLog ("    执行渲染脚本: " + (filenameFromPath renderScriptPath))
        
        -- 检查必要对象
        local helperObj = getNodeByName "台"
        local cameraObj = getNodeByName "Camera"
        
        if helperObj != undefined then addLog ("      找到目标对象: " + helperObj.name)
        else addLog "      警告: 未找到'台'对象"
        
        if cameraObj != undefined then addLog ("      找到摄像机: " + cameraObj.name)
        else addLog "      警告: 未找到'Camera'摄像机"
        
        try (
            if chkSilentRender.checked then (
                addLog "      启用静默渲染模式"
                local oldQuietMode = quietMode
                local oldRenderDialogMode = renderDialogMode
                
                quietMode = true
                renderDialogMode = false
                
                try (fileIn renderScriptPath) catch (
                    addLog ("      静默渲染异常: " + (getCurrentException()))
                    throw()
                )
                
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
    
    -- 处理单个文件
    fn processFile targetFile index total =
    (
        local fileName = filenameFromPath targetFile
        
        addLog "----------------------------------------"
        addLog ("渲染文件 " + index as string + "/" + total as string + ": " + fileName)
        
        pbProgress.value = (index as float / total as float) * 100
        
        gc()
        windows.processPostedMessages()
        
        if not checkPauseState() do return #stopped
        
        try (
            if not (loadMaxFile targetFile quiet:true) do (
                addLog ("  ✗ 无法打开文件: " + fileName)
                return #failed
            )
            
            addLog ("  文件已打开: " + fileName)
            applyRenderSettings()
            
            if not checkPauseState() do return #stopped
            
            if executeRenderScript() then (
                addLog ("  ✓ 渲染成功: " + fileName)
                #success
            ) else (
                addLog ("  ✗ 渲染失败: " + fileName)
                #failed
            )
        ) catch (
            addLog ("  ✗ 处理异常: " + fileName + " - " + (getCurrentException()))
            #failed
        )
    )
    
    -- 显示完成统计
    fn showCompletionStats =
    (
        local successRate = if processedCount > 0 then ((successCount as float / processedCount as float) * 100) else 0
        
        addLog "========================================"
        addLog "批量渲染完成！"
        addLog ("总计: " + processedCount as string + " 个文件")
        addLog ("成功: " + successCount as string + " 个文件")
        addLog ("失败: " + failedCount as string + " 个文件")
        addLog ("成功率: " + successRate as string + "%")
        addLog "========================================"
        
        messageBox ("批量渲染完成！\n\n总计: " + processedCount as string + " 个文件\n成功: " + successCount as string + " 个\n失败: " + failedCount as string + " 个") title:"渲染完成"
    )

    -- ==================== 核心业务函数 ====================
    
    -- 批量渲染主函数
    fn startBatchRender =
    (
        local selectedIndices = mlbMaxFiles.selection as array
        if selectedIndices.count == 0 do (
            messageBox "请先勾选要渲染的文件！"
            return false
        )
        
        if edtRenderScript.text == "" or not (doesFileExist edtRenderScript.text) do (
            messageBox "请先选择有效的渲染脚本！"
            return false
        )
        
        setProcessingState true
        resetCounters()
        
        local totalFiles = selectedIndices.count
        
        addLog "========================================"
        addLog ("开始批量渲染，共 " + totalFiles as string + " 个文件")
        addLog ("渲染脚本: " + edtRenderScript.text)
        addLog "========================================"
        
        for i = 1 to totalFiles do (
            if not checkPauseState() do (
                addLog "用户停止了渲染过程"
                exit
            )
            
            local fileIndex = selectedIndices[i]
            local targetFile = maxFiles[fileIndex]
            
            processedCount += 1
            
            local result = processFile targetFile processedCount totalFiles
            
            case result of (
                #success: successCount += 1
                #failed: failedCount += 1
                #stopped: exit
            )
        )
        
        pbProgress.value = 100
        setProcessingState false
        showCompletionStats()
    )
    
    -- ==================== 事件处理器 ====================
    
    on batchRenderRollout open do
    (
        currentDir = if maxFilePath != "" then maxFilePath else "C:\\"
        edtCurrentDir.text = currentDir
        
        local fileCount = getMaxFiles currentDir
        addLog ("初始化完成，找到 " + fileCount as string + " 个Max文件")
        
        local scriptPath = findRenderScript currentDir
        if scriptPath != "" do (
            edtRenderScript.text = scriptPath
            addLog ("已找到默认渲染脚本: " + scriptPath)
        )
    )
    
    on btnBrowseDir pressed do
    (
        local selectedDir = getSavePath caption:"选择包含Max文件的目录" initialDir:currentDir
        if selectedDir == undefined do return()
        
        currentDir = selectedDir
        edtCurrentDir.text = currentDir
        
        local fileCount = getMaxFiles currentDir
        addLog ("目录已更改，找到 " + fileCount as string + " 个Max文件")
        
        local scriptPath = findRenderScript currentDir
        if scriptPath != "" do (
            edtRenderScript.text = scriptPath
            addLog ("已找到渲染脚本: " + scriptPath)
        )
    )
    
    on btnRefresh pressed do
    (
        local fileCount = getMaxFiles currentDir
        addLog ("文件列表已刷新，找到 " + fileCount as string + " 个Max文件")
    )
    
    on btnSelectAll pressed do
    (
        mlbMaxFiles.selection = #{1..mlbMaxFiles.items.count}
        addLog ("已全选 " + mlbMaxFiles.items.count as string + " 个文件")
    )
    
    on btnSelectNone pressed do
    (
        mlbMaxFiles.selection = #{}
        addLog "已取消选择所有文件"
    )
    
    on btnBrowseRender pressed do
    (
        local renderFile = getOpenFileName caption:"选择渲染脚本" types:"MAXScript (*.ms)|*.ms|所有文件 (*.*)|*.*" initialDir:currentDir
        if renderFile != undefined do (
            edtRenderScript.text = renderFile
            addLog ("渲染脚本路径已更新: " + (filenameFromPath renderFile))
        )
    )
    
    on btnStartRender pressed do
    (
        local selectedCount = (mlbMaxFiles.selection as array).count
        if selectedCount == 0 do (
            messageBox "请先选择要渲染的文件！"
            return()
        )
        
        local confirmMsg = "确定要开始批量渲染 " + selectedCount as string + " 个文件吗？\n\n"
        confirmMsg += "这可能需要较长时间，请确保：\n"
        confirmMsg += "1. 渲染脚本路径正确\n"
        confirmMsg += "2. 文件没有被其他程序占用\n"
        confirmMsg += "3. 有足够的磁盘空间"
        
        if queryBox confirmMsg title:"确认批量渲染" do
            startBatchRender()
    )
    
    on btnPauseResume pressed do
    (
        isPaused = not isPaused
        btnPauseResume.text = if isPaused then "恢复" else "暂停"
        addLog (if isPaused then "渲染已暂停" else "渲染已恢复")
    )
    
    on btnStop pressed do
    (
        if queryBox "确定要停止批量渲染吗？" title:"确认停止" do (
            setProcessingState false
            addLog "用户停止了批量渲染"
        )
    )
    
    on chkCustomSize changed state do
    (
        spnWidth.enabled = state
        spnHeight.enabled = state
    )
    
    on mlbMaxFiles doubleClicked index do
    (
        if index < 1 or index > maxFiles.count do return()
        
        local selectedFile = maxFiles[index]
        local fileName = filenameFromPath selectedFile
        local fileSizeMB = (getFileSize selectedFile) / (1024.0 * 1024.0)
        
        messageBox ("文件信息：\n\n文件名: " + fileName + "\n路径: " + selectedFile + "\n大小: " + fileSizeMB as string + " MB") title:"文件信息"
    )
)

-- 创建并显示对话框
createDialog batchRenderRollout
