-- 批量渲染工具
-- 批量打开Max文件并执行渲染脚本
-- Author: Kiro Assistant
-- Version: 1.0

try(destroyDialog batchRenderRollout)catch()

rollout batchRenderRollout "批量渲染工具ByBoBO" width:600 height:500
(
    local currentDir = maxFilePath
    local maxFiles = #()
    local isPaused = false
    local isProcessing = false
    local processedCount = 0
    local successCount = 0
    local failedCount = 0
    
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
    groupBox grpRenderOptions "渲染选项" pos:[15,335] width:570 height:80
    checkbox chkSilentRender "静默渲染（不显示渲染窗口）" pos:[25,355] checked:false
    label lblRenderScript "渲染脚本路径:" pos:[25,375] width:100
    edittext edtRenderScript "" pos:[130,375] width:350 readonly:false
    button btnBrowseRender "浏览..." pos:[490,375] width:60 height:20
    
    -- 操作控制区域
    groupBox grpOperations "操作控制" pos:[15,425] width:570 height:60
    button btnStartRender "开始批量渲染" pos:[25,445] width:120 height:30
    button btnPauseResume "暂停" pos:[155,445] width:60 height:30 enabled:false
    button btnStop "停止" pos:[225,445] width:60 height:30 enabled:false
    progressbar pbProgress pos:[295,450] width:280 height:20
    
    -- 获取指定目录的Max文件
    function getMaxFiles targetDir =
    (
        maxFiles = #()
        if targetDir != "" and doesDirectoryExist targetDir then
        (
            local files = getFiles (targetDir + "\\*.max")
            for f in files do
                append maxFiles f
        )
        
        -- 更新多选列表框
        local fileNames = for f in maxFiles collect (filenameFromPath f)
        mlbMaxFiles.items = fileNames
        
        -- 默认全选
        local selections = #{}
        for i = 1 to fileNames.count do
            selections[i] = true
        mlbMaxFiles.selection = selections
        
        return maxFiles.count
    )
    
    -- 添加日志信息到3ds Max监听器
    function addLog msg =
    (
        print msg
        format "%\n" msg
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
                        throw e
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
                addLog ("    错误: 渲染脚本不存在 - " + renderScriptPath)
                return false
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
    
    -- 批量渲染主函数
    function startBatchRender =
    (
        local selectedIndices = mlbMaxFiles.selection as array
        if selectedIndices.count == 0 then
        (
            messageBox "请先勾选要渲染的文件！"
            return false
        )
        
        if edtRenderScript.text == "" or not doesFileExist edtRenderScript.text then
        (
            messageBox "请先选择有效的渲染脚本！"
            return false
        )
        
        -- 设置处理状态
        isProcessing = true
        isPaused = false
        processedCount = 0
        successCount = 0
        failedCount = 0
        
        btnStartRender.enabled = false
        btnPauseResume.enabled = true
        btnPauseResume.text = "暂停"
        btnStop.enabled = true
        
        pbProgress.value = 0
        local totalFiles = selectedIndices.count
        
        addLog ("========================================")
        addLog ("开始批量渲染，共 " + totalFiles as string + " 个文件")
        addLog ("渲染脚本: " + edtRenderScript.text)
        addLog ("========================================")
        
        for i = 1 to totalFiles do
        (
            -- 检查是否需要停止处理
            if not checkPauseState() then
            (
                addLog "用户停止了渲染过程"
                exit
            )
            
            local fileIndex = selectedIndices[i]
            local targetFile = maxFiles[fileIndex]
            local fileName = filenameFromPath targetFile
            
            processedCount += 1
            
            addLog ("----------------------------------------")
            addLog ("渲染文件 " + processedCount as string + "/" + totalFiles as string + ": " + fileName)
            
            -- 更新进度条
            pbProgress.value = (processedCount as float / totalFiles as float) * 100
            
            -- 清理状态
            gc()
            windows.processPostedMessages()
            
            -- 检查暂停状态
            if not checkPauseState() then exit
            
            try
            (
                -- 打开文件
                if loadMaxFile targetFile quiet:true then
                (
                    addLog ("  文件已打开: " + fileName)
                    
                    -- 检查暂停状态
                    if not checkPauseState() then exit
                    
                    -- 执行渲染
                    local renderSuccess = executeRenderScript targetFile
                    
                    if renderSuccess then
                    (
                        successCount += 1
                        addLog ("  ✓ 渲染成功: " + fileName)
                    )
                    else
                    (
                        failedCount += 1
                        addLog ("  ✗ 渲染失败: " + fileName)
                    )
                )
                else
                (
                    failedCount += 1
                    addLog ("  ✗ 无法打开文件: " + fileName)
                )
            )
            catch (e)
            (
                failedCount += 1
                addLog ("  ✗ 处理异常: " + fileName + " - " + e as string)
            )
        )
        
        -- 完成处理
        isProcessing = false
        btnStartRender.enabled = true
        btnPauseResume.enabled = false
        btnStop.enabled = false
        pbProgress.value = 100
        
        addLog ("========================================")
        addLog ("批量渲染完成！")
        addLog ("总计: " + processedCount as string + " 个文件")
        addLog ("成功: " + successCount as string + " 个文件")
        addLog ("失败: " + failedCount as string + " 个文件")
        addLog ("成功率: " + ((successCount as float / processedCount as float) * 100) as string + "%")
        addLog ("========================================")
        
        -- 显示完成消息
        messageBox ("批量渲染完成！\n\n总计: " + processedCount as string + " 个文件\n成功: " + successCount as string + " 个\n失败: " + failedCount as string + " 个") title:"渲染完成"
    )

    on batchRenderRollout open do
    (
        -- 初始化当前目录
        currentDir = maxFilePath
        if currentDir == "" then
            currentDir = "C:\\"
        
        edtCurrentDir.text = currentDir
        
        -- 获取文件列表
        local fileCount = getMaxFiles currentDir
        addLog ("初始化完成，找到 " + fileCount as string + " 个Max文件")
        
        -- 设置默认渲染脚本路径
        local defaultRenderScript = currentDir + "Render53.ms"
        if doesFileExist defaultRenderScript then
        (
            edtRenderScript.text = defaultRenderScript
            addLog ("已找到默认渲染脚本: " + defaultRenderScript)
        )
        else
        (
            addLog ("未找到默认渲染脚本，请手动选择")
        )
    )
    
    on btnBrowseDir pressed do
    (
        local selectedDir = getSavePath caption:"选择包含Max文件的目录" initialDir:currentDir
        if selectedDir != undefined then
        (
            currentDir = selectedDir
            edtCurrentDir.text = currentDir
            local fileCount = getMaxFiles currentDir
            addLog ("目录已更改，找到 " + fileCount as string + " 个Max文件")
            
            -- 尝试找到渲染脚本
            local defaultRenderScript = currentDir + "\\Render53.ms"
            if doesFileExist defaultRenderScript then
            (
                edtRenderScript.text = defaultRenderScript
                addLog ("已找到渲染脚本: " + defaultRenderScript)
            )
        )
    )
    
    on btnRefresh pressed do
    (
        local fileCount = getMaxFiles currentDir
        addLog ("文件列表已刷新，找到 " + fileCount as string + " 个Max文件")
    )
    
    on btnSelectAll pressed do
    (
        local selections = #{}
        for i = 1 to mlbMaxFiles.items.count do
            selections[i] = true
        mlbMaxFiles.selection = selections
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
        if renderFile != undefined then
        (
            edtRenderScript.text = renderFile
            addLog ("渲染脚本路径已更新: " + (filenameFromPath renderFile))
        )
    )
    
    on btnStartRender pressed do
    (
        local selectedCount = (mlbMaxFiles.selection as array).count
        if selectedCount > 0 then
        (
            local result = queryBox ("确定要开始批量渲染 " + selectedCount as string + " 个文件吗？\n\n这可能需要较长时间，请确保：\n1. 渲染脚本路径正确\n2. 文件没有被其他程序占用\n3. 有足够的磁盘空间") title:"确认批量渲染"
            if result then
                startBatchRender()
        )
        else
        (
            messageBox "请先选择要渲染的文件！"
        )
    )
    
    on btnPauseResume pressed do
    (
        if isPaused then
        (
            isPaused = false
            btnPauseResume.text = "暂停"
            addLog "渲染已恢复"
        )
        else
        (
            isPaused = true
            btnPauseResume.text = "恢复"
            addLog "渲染已暂停"
        )
    )
    
    on btnStop pressed do
    (
        local result = queryBox "确定要停止批量渲染吗？" title:"确认停止"
        if result then
        (
            isProcessing = false
            isPaused = false
            btnStartRender.enabled = true
            btnPauseResume.enabled = false
            btnStop.enabled = false
            addLog "用户停止了批量渲染"
        )
    )
    
    -- 双击文件列表项预览文件信息
    on mlbMaxFiles doubleClicked index do
    (
        if index > 0 and index <= maxFiles.count then
        (
            local selectedFile = maxFiles[index]
            local fileName = filenameFromPath selectedFile
            local fileSize = getFileSize selectedFile
            local fileSizeMB = fileSize / (1024.0 * 1024.0)
            
            messageBox ("文件信息：\n\n文件名: " + fileName + "\n路径: " + selectedFile + "\n大小: " + (fileSizeMB as string) + " MB") title:"文件信息"
        )
    )
)

-- 创建并显示对话框
createDialog batchRenderRollout

-- 使用说明
print "========================================="
print "批量渲染工具 v1.0 使用说明："
print "1. 选择包含Max文件的目录"
print "2. 勾选要渲染的文件"
print "3. 选择渲染脚本（通常是Render53.ms）"
print "4. 点击'开始批量渲染'"
print "5. 可以随时暂停/恢复或停止渲染"
print "6. 双击文件名可查看文件信息"
print "========================================="