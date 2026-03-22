/*
    功能: 【最终完整版】自动寻找并旋转名为"大"的虚拟体，在特定角度进行渲染输出。
    作者: BoBO
    日期: 2025-6-8
*/

-- ===================================================================
-- 1. 配置项
-- ===================================================================
targetHelperName = "大"              -- 目标虚拟体名称
rotationStepDegrees = -45.0          -- 对齐阶段的单次旋转角度
renderCameraName = "Camera"          -- 场景中要求存在的摄像机名称

direction5_MinAngle = -50.0
direction5_MaxAngle = -40.0
direction5_OutputSuffix = "5"

direction3_MinAngle = -140.0
direction3_MaxAngle = -130.0
direction3_OutputSuffix = "3"

direction2_MinAngle = 40.0
direction2_MaxAngle = 50.0
direction2_OutputSuffix = "2"

direction4_MinAngle = -95.0
direction4_MaxAngle = -85.0
direction4_OutputSuffix = "4"

direction6_MinAngle = -5.0
direction6_MaxAngle = 5.0
direction6_OutputSuffix = "6"

renderFileBaseName = "10000"
renderFileExtension = ".tga"

-- ===================================================================
-- 2. 基础工具函数
-- ===================================================================
fn rotateObjectZ obj angle =
(
    if isValidNode obj then
    (
        rotate obj (angleaxis angle [0,0,1])
        true
    )
    else
    (
        false
    )
)

fn getCorrectedZRotation obj =
(
    -((obj.rotation as eulerangles).z_rotation)
)

fn isAngleInRange angle minAngle maxAngle =
(
    angle >= minAngle and angle <= maxAngle
)

fn ensureOutputFolder outputFolder =
(
    if not (doesFileExist outputFolder) do makeDir outputFolder
)

fn buildOutputFolder sceneFolder sceneName suffix =
(
    sceneFolder + sceneName + suffix
)

-- ===================================================================
-- 3. 渲染与对齐函数
-- ===================================================================
fn executeRender outputFolder =
(
    ensureOutputFolder outputFolder

    local renderOutputPath = outputFolder + "\\" + renderFileBaseName + renderFileExtension
    local targetCamera = getNodeByName renderCameraName

    if targetCamera == undefined then
    (
        format "错误: 未找到摄像机 '%'.\n" renderCameraName
        return false
    )

    try
    (
        renderers.current = Default_Scanline_Renderer()
        tgaio.setAlphaSplit false
        tgaio.setPreMultAlpha true
        rendOutputFileName = renderOutputPath

        format "准备渲染, 输出路径: %\n" renderOutputPath
        actionMan.executeAction 0 "50031"  -- Render: Render
        format "渲染完成! 文件已保存到: %\n" renderOutputPath
        true
    )
    catch
    (
        format "--- 渲染失败 ---\n\n"
        false
    )
)

fn alignNodeToAngleRange targetNode stageLabel minAngle maxAngle stepAngle maxAttempts =
(
    local currentAngle = getCorrectedZRotation targetNode
    local attemptCount = 0

    format "[%] 当前角度: %.2f°\n" stageLabel currentAngle

    while (not (isAngleInRange currentAngle minAngle maxAngle)) and attemptCount < maxAttempts do
    (
        format "[%] 角度 %.2f° 不在范围 [%.2f°, %.2f°] 内, 正在旋转...\n" stageLabel currentAngle minAngle maxAngle

        if not (rotateObjectZ targetNode stepAngle) do
        (
            format "[%] 目标虚拟体无效，无法继续旋转。\n" stageLabel
            return #(false, currentAngle)
        )

        sleep 0.1
        currentAngle = getCorrectedZRotation targetNode
        attemptCount += 1

        format "[%] 第 % 次旋转后角度: %.2f°\n" stageLabel attemptCount currentAngle
    )

    if isAngleInRange currentAngle minAngle maxAngle then
    (
        #(true, currentAngle)
    )
    else
    (
        messageBox ("警告: " + stageLabel + " 旋转超过 " + (maxAttempts as string) + " 次仍未达到目标范围，脚本已中止。")
        #(false, currentAngle)
    )
)

fn processDirection targetNode stageLabel minAngle maxAngle outputSuffix preRotateAngle maxAttempts sceneFolder sceneName =
(
    format "\n--- 开始处理 % ---\n" stageLabel

    if preRotateAngle != 0.0 then
    (
        format "[%] 先旋转 %.2f°。\n" stageLabel preRotateAngle

        if not (rotateObjectZ targetNode preRotateAngle) do
        (
            format "[%] 目标虚拟体无效，无法执行预旋转。\n" stageLabel
            return false
        )

        sleep 0.1
    )

    local alignResult = alignNodeToAngleRange targetNode stageLabel minAngle maxAngle rotationStepDegrees maxAttempts

    if not alignResult[1] do return false

    local currentAngle = alignResult[2]
    local outputPath = buildOutputFolder sceneFolder sceneName outputSuffix

    format "[%] 已到达目标范围，当前角度: %.2f°\n" stageLabel currentAngle
    format "[%] 渲染目录: %\n" stageLabel outputPath

    if not (executeRender outputPath) then
    (
        messageBox ("错误: " + stageLabel + " 渲染失败。")
        return false
    )

    true
)

-- ===================================================================
-- 4. 主流程
-- ===================================================================
fn main =
(
    clearListener()
    format "脚本开始执行...\n"

    local targetNode = getNodeByName targetHelperName
    if targetNode == undefined then
    (
        messageBox ("错误：场景中未找到名为 \"" + targetHelperName + "\" 的 Point Helper。")
        return false
    )

    if maxFilePath == "" then
    (
        messageBox "错误: MAX 文件尚未保存，无法确定输出路径。请先保存文件。"
        return false
    )

    local sceneName = getFilenameFile maxFileName
    local sceneFolder = maxFilePath

    format "成功找到虚拟体: '%'\n" targetNode.name
    select targetNode

    if not (processDirection targetNode "方向 5" direction5_MinAngle direction5_MaxAngle direction5_OutputSuffix 0.0 8 sceneFolder sceneName) do
    (
        return false
    )

    if not (processDirection targetNode "方向 3" direction3_MinAngle direction3_MaxAngle direction3_OutputSuffix -90.0 2 sceneFolder sceneName) do
    (
        return false
    )

    if not (processDirection targetNode "方向 2" direction2_MinAngle direction2_MaxAngle direction2_OutputSuffix -90.0 2 sceneFolder sceneName) do
    (
        return false
    )

    if not (processDirection targetNode "方向 4" direction4_MinAngle direction4_MaxAngle direction4_OutputSuffix -90.0 2 sceneFolder sceneName) do
    (
        return false
    )

    if not (processDirection targetNode "方向 6" direction6_MinAngle direction6_MaxAngle direction6_OutputSuffix -90.0 2 sceneFolder sceneName) do
    (
        return false
    )

    format "所有任务已完成。\n"
    true
)

main()
