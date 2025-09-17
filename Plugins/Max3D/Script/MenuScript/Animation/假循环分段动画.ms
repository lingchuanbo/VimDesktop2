rollout FakeLoopRollout "假循环动画-V1.1 ByBoBo"
(
    spinner spnSegments "分段数量: " type:#integer range:[2,20,4] value:2 pos:[60, 10]  width:50 height:30
    button btnGenerate "生成分段动画" pos:[20, 40] width:100 height:30
    button btnUndo "删除" pos:[140, 40] width:50 height:30
    checkbox chkDebug "显示调试信息" checked:false pos:[120, 80] width:100 height:20
    checkbox chkVisibility "前后透明度渐变" checked:true pos:[20, 80] width:100 height:20
    checkbox chkLinear "保持线性插值" checked:true pos:[20, 100] width:100 height:20
    
    local lastGenerated = #()
    
    -- 检测控制器是否使用线性插值
    fn isLinearController ctrl = (
        try (
            if ctrl.keys != undefined and ctrl.keys.count > 0 then (
                local firstKey = ctrl.keys[1]
                if hasProperty firstKey "inTangentType" then (
                    return (firstKey.inTangentType == #linear and firstKey.outTangentType == #linear)
                )
            )
            return false
        ) catch (
            return false
        )
    )
    
    -- 强制设置控制器为线性插值
    fn forceLinearController ctrl = (
        try (
            if ctrl.keys != undefined and ctrl.keys.count > 0 then (
                for i = 1 to ctrl.keys.count do (
                    local key = ctrl.keys[i]
                    try (
                        if hasProperty key "inTangentType" then (
                            key.inTangentType = #linear
                            key.outTangentType = #linear
                        )
                    ) catch ()
                )
                return true
            )
            return false
        ) catch (
            return false
        )
    )
    
    -- 获取实际控制器（穿透SubAnim）
    fn getRealController ctrl = (
        try (
            if classOf ctrl == SubAnim then (
                local realCtrl = undefined
                try (realCtrl = ctrl.controller) catch ()
                if realCtrl == undefined then
                    try (realCtrl = ctrl.value) catch ()
                if realCtrl == undefined then
                    try (realCtrl = ctrl[1]) catch ()
                
                if realCtrl != undefined then
                    return realCtrl
            )
            return ctrl
        ) catch (
            return ctrl
        )
    )
    
    -- 检查Position_XYZ控制器是否使用线性插值
    fn checkPositionXYZLinear posCtrl = (
        try (
            if classOf posCtrl == Position_XYZ then (
                -- 检查每个子控制器
                for i = 1 to posCtrl.numSubs do (
                    local subCtrl = posCtrl[i]
                    local realCtrl = getRealController subCtrl
                    
                    if realCtrl != undefined and realCtrl.keys != undefined and realCtrl.keys.count > 0 then (
                        if not isLinearController realCtrl then (
                            return false  -- 如果任何一个轴不是线性的，返回false
                        )
                    )
                )
                return true  -- 所有轴都是线性的
            ) else (
                return isLinearController posCtrl
            )
        ) catch (
            return false
        )
    )
    
    -- 强制Position_XYZ控制器为线性插值
    fn forcePositionXYZLinear obj = (
        local posCtrl = obj.position.controller
        local converted = false
        
        try (
            if classOf posCtrl == Position_XYZ then (
                -- 处理每个子控制器
                for i = 1 to posCtrl.numSubs do (
                    local subCtrl = posCtrl[i]
                    local realCtrl = getRealController subCtrl
                    
                    if realCtrl != undefined then (
                        if forceLinearController realCtrl then (
                            converted = true
                            if chkDebug.checked then (
                                local axisName = case i of (1: "X"; 2: "Y"; 3: "Z"; default: "轴" + i as string)
                                format "  ✓ %轴已设为线性插值\n" axisName
                            )
                        )
                    )
                )
            ) else (
                converted = forceLinearController posCtrl
                if converted and chkDebug.checked then
                    format "  ✓ 位置控制器已设为线性插值\n"
            )
        ) catch (
            if chkDebug.checked then
                format "  ✗ 线性化失败: %\n" (getCurrentException())
        )
        
        return converted
    )
    
    -- 使用线性插值重新创建动画
    fn recreateLinearAnimation obj startTime endTime startValue endValue ctrlPath = (
        try (
            -- 保存当前默认切线类型
            local originalIn = #auto
            local originalOut = #auto
            maxops.getDefaultTangentType &originalIn &originalOut
            
            -- 设置线性为默认
            maxops.setDefaultTangentType #linear #linear
            
            -- 找到对应的控制器并设置关键帧
            local pathParts = filterString ctrlPath "."
            local currentCtrl = undefined
            
            -- 根据根路径找到起始控制器
            case pathParts[1] of (
                "position": currentCtrl = obj.position.controller
                "rotation": currentCtrl = obj.rotation.controller
                "scale": currentCtrl = obj.scale.controller
                "visibility": currentCtrl = obj.visibility.controller
                default: (
                    -- 处理修改器路径
                    if matchPattern pathParts[1] pattern:"modifier_*" then (
                        local parts = filterString pathParts[1] "_"
                        if parts.count >= 2 then (
                            local modIndex = parts[2] as integer
                            if modIndex <= obj.modifiers.count then (
                                local mod = obj.modifiers[modIndex]
                                if pathParts.count > 1 then (
                                    local paramName = pathParts[2]
                                    if hasProperty mod paramName then
                                        currentCtrl = (getProperty mod paramName).controller
                                )
                            )
                        )
                    )
                )
            )
            
            -- 如果有子路径，继续向下查找
            if currentCtrl != undefined and pathParts.count > 1 then (
                for i = 2 to pathParts.count do (
                    if currentCtrl != undefined then (
                        try (
                            -- 尝试通过索引或名称访问子控制器
                            for j = 1 to currentCtrl.numSubs do (
                                local subName = try (currentCtrl.getSubAnimName j) catch ("sub" + j as string)
                                if subName == pathParts[i] then (
                                    currentCtrl = getRealController currentCtrl[j]
                                    exit
                                )
                            )
                        ) catch (
                            currentCtrl = undefined
                        )
                    )
                )
            )
            
            -- 设置关键帧
            if currentCtrl != undefined then (
                animate on at time startTime (
                    currentCtrl.value = startValue
                )
                animate on at time endTime (
                    currentCtrl.value = endValue
                )
                
                if chkDebug.checked then
                    format "  ✓ 线性关键帧已创建: %\n" ctrlPath
            )
            
            -- 恢复原始默认切线类型
            maxops.setDefaultTangentType originalIn originalOut
            
        ) catch (
            if chkDebug.checked then
                format "  ✗ 线性关键帧创建失败: % - %\n" ctrlPath (getCurrentException())
        )
    )
    
    -- 递归搜索所有动画控制器
    fn findAllAnimatedControllers ctrl prefix controllers = (
        try (
            -- 检查当前控制器是否有关键帧
            if ctrl.keys != undefined and ctrl.keys.count > 0 then (
                append controllers #(prefix, ctrl)
                if chkDebug.checked then
                    format "找到动画控制器: % (% 个关键帧)\n" prefix ctrl.keys.count
            )
            
            -- 递归检查子控制器
            if ctrl.numSubs != undefined and ctrl.numSubs > 0 then (
                for i = 1 to ctrl.numSubs do (
                    local subCtrl = ctrl[i]
                    if subCtrl != undefined then (
                        local subName = try (ctrl.getSubAnimName i) catch ("sub" + i as string)
                        findAllAnimatedControllers subCtrl (prefix + "." + subName) controllers
                    )
                )
            )
        ) catch (
            if chkDebug.checked then
                format "检查控制器时出错: % - %\n" prefix (getCurrentException())
        )
    )
    
    -- 检查并获取所有动画控制器
    fn getAnimatedControllers obj = (
        local controllers = #()
        
        if chkDebug.checked then
            format "开始搜索对象的所有动画控制器...\n"
        
        -- 搜索变换控制器
        findAllAnimatedControllers obj.position.controller "position" controllers
        findAllAnimatedControllers obj.rotation.controller "rotation" controllers
        findAllAnimatedControllers obj.scale.controller "scale" controllers
        
        -- 搜索可见性控制器
        try (
            findAllAnimatedControllers obj.visibility.controller "visibility" controllers
        ) catch ()
        
        -- 搜索修改器控制器
        try (
            for i = 1 to obj.modifiers.count do (
                local mod = obj.modifiers[i]
                local modName = "modifier_" + i as string + "_" + (classOf mod as string)
                
                -- 尝试获取修改器的所有参数控制器
                try (
                    if hasProperty mod "angle" then
                        findAllAnimatedControllers mod.angle.controller (modName + ".angle") controllers
                    if hasProperty mod "direction" then
                        findAllAnimatedControllers mod.direction.controller (modName + ".direction") controllers
                    if hasProperty mod "amount" then
                        findAllAnimatedControllers mod.amount.controller (modName + ".amount") controllers
                ) catch ()
            )
        ) catch ()
        
        -- 搜索材质控制器
        try (
            if obj.material != undefined then (
                if chkDebug.checked then
                    format "检查材质动画: %\n" (classOf obj.material)
                
                -- 检查标准材质的常见动画属性
                if classOf obj.material == Standardmaterial then (
                    local mat = obj.material
                    if hasProperty mat "opacity" then
                        findAllAnimatedControllers mat.opacity.controller "material.opacity" controllers
                    if hasProperty mat "diffuse" then
                        findAllAnimatedControllers mat.diffuse.controller "material.diffuse" controllers
                    if hasProperty mat "ambient" then
                        findAllAnimatedControllers mat.ambient.controller "material.ambient" controllers
                    if hasProperty mat "specular" then
                        findAllAnimatedControllers mat.specular.controller "material.specular" controllers
                    if hasProperty mat "selfIllumAmount" then
                        findAllAnimatedControllers mat.selfIllumAmount.controller "material.selfIllum" controllers
                )
                -- 检查多维/子材质
                else if classOf obj.material == Multimaterial then (
                    local multiMat = obj.material
                    for i = 1 to multiMat.materialList.count do (
                        local subMat = multiMat.materialList[i]
                        if subMat != undefined and classOf subMat == Standardmaterial then (
                            if hasProperty subMat "opacity" then
                                findAllAnimatedControllers subMat.opacity.controller ("material.sub" + i as string + ".opacity") controllers
                            if hasProperty subMat "diffuse" then
                                findAllAnimatedControllers subMat.diffuse.controller ("material.sub" + i as string + ".diffuse") controllers
                        )
                    )
                )
            )
        ) catch (
            if chkDebug.checked then
                format "材质检查出错: %\n" (getCurrentException())
        )
        
        controllers
    )
    
    -- 获取控制器在指定时间的值
    fn getControllerValue ctrl timeValue = (
        at time timeValue ctrl.value
    )
    
    -- 设置控制器的值并创建关键帧
    fn setControllerValue ctrl timeValue value = (
        animate on at time timeValue (
            ctrl.value = value
        )
    )
    
    -- 复制约束设置
    fn copyConstraintSettings srcObj dupObj = (
        try (
            -- 复制路径约束设置
            if classOf srcObj.position.controller == Path_Constraint then (
                local srcPathCtrl = srcObj.position.controller
                local dupPathCtrl = Path_Constraint()
                dupObj.position.controller = dupPathCtrl
                
                -- 复制路径目标
                for i = 1 to srcPathCtrl.getNumTargets() do (
                    local target = srcPathCtrl.getNode i
                    dupPathCtrl.appendTarget target 100.0
                )
                
                -- 复制其他设置
                dupPathCtrl.follow = srcPathCtrl.follow
                dupPathCtrl.bank = srcPathCtrl.bank
                dupPathCtrl.bankAmount = srcPathCtrl.bankAmount
                dupPathCtrl.smoothness = srcPathCtrl.smoothness
                dupPathCtrl.axis = srcPathCtrl.axis
                dupPathCtrl.flip = srcPathCtrl.flip
                
                if chkDebug.checked then
                    format "复制了路径约束设置\n"
            )
        ) catch (
            if chkDebug.checked then
                format "警告: 无法复制约束设置\n"
        )
    )
    
    fn fakeLoopKFrames =
    (
        if selection.count != 1 then
        (
            messagebox "请只选择一个有动画的对象"
            return false
        )
        
        local src = selection[1]
        local startFrame = animationRange.start.frame
        local endFrame = animationRange.end.frame
        local totalFrames = endFrame - startFrame
        local numCopies = spnSegments.value
        
        -- 获取所有动画控制器
        local animControllers = getAnimatedControllers src
        
        if animControllers.count == 0 then (
            messagebox "选择的对象没有检测到动画关键帧"
            return false
        )
        
        -- 检查源对象是否使用线性插值
        local sourceIsLinear = false
        if chkLinear.checked then (
            sourceIsLinear = checkPositionXYZLinear src.position.controller
            if chkDebug.checked then (
                if sourceIsLinear then
                    format "✓ 源对象使用线性插值\n"
                else
                    format "⚠ 源对象使用非线性插值\n"
            )
        )
        
        if chkDebug.checked then (
            format "=== 开始生成分段动画 ===\n"
            format "原动画范围: %.1f 到 %.1f 帧 (总长度: %.1f 帧)\n" startFrame endFrame totalFrames
            format "分段数量: %\n" numCopies
            format "线性插值模式: %\n" (if chkLinear.checked then "启用" else "禁用")
            format "检测到 % 个动画控制器:\n" animControllers.count
            for ctrl in animControllers do
                format "  - %\n" ctrl[1]
        )
        
        lastGenerated = #()
        
        for i = 1 to numCopies do
        (
            -- 计算该段在原动画中的帧范围
            local segmentFrames = totalFrames as float / numCopies
            local originalStartFrame = startFrame + (i-1) * segmentFrames
            local originalEndFrame = startFrame + i * segmentFrames
            
            -- 转换为时间值
            local originalStartTime = originalStartFrame as time
            local originalEndTime = originalEndFrame as time
            
            if chkDebug.checked then (
                format "\n--- 副本% ---\n" i
                format "原动画时间段: %.1f 到 %.1f 帧\n" originalStartFrame originalEndFrame
            )
            
            -- 复制对象
            local dup = copy src
            local baseName = src.name + "_part" + (i as string)
            dup.name = uniquename baseName
            
            -- 清除副本的所有关键帧
            deleteKeys dup #allKeys
            
            -- 复制约束设置（如果有）
            copyConstraintSettings src dup
            
            -- 确保材质继承
            if src.material != undefined then (
                dup.material = src.material
                if chkDebug.checked then (
                    format "继承源材质: %\n" (classOf src.material)
                    if classOf src.material == Standardmaterial then
                        format "  材质名称: %\n" src.material.name
                    else if classOf src.material == Multimaterial then
                        format "  多维材质，包含 % 个子材质\n" src.material.materialList.count
                )
            )
            
            -- 为每个动画控制器创建分段动画
            for ctrlInfo in animControllers do (
                local ctrlName = ctrlInfo[1]
                local srcCtrl = ctrlInfo[2]
                
                -- 获取原动画在分段时间点的值
                local startValue = getControllerValue srcCtrl originalStartTime
                local endValue = getControllerValue srcCtrl originalEndTime
                
                if chkDebug.checked then
                    format "  %: % -> %\n" ctrlName startValue endValue
                
                -- 如果启用线性插值且源对象是线性的，使用线性方式创建关键帧
                if chkLinear.checked and sourceIsLinear then (
                    recreateLinearAnimation dup (startFrame as time) (endFrame as time) startValue endValue ctrlName
                ) else (
                    -- 使用原来的方式创建关键帧
                    local dupCtrl = undefined
                    try (
                        -- 解析控制器路径
                        local pathParts = filterString ctrlName "."
                        local currentCtrl = undefined
                        
                        -- 根据根路径找到起始控制器
                        case pathParts[1] of (
                            "position": currentCtrl = dup.position.controller
                            "rotation": currentCtrl = dup.rotation.controller
                            "scale": currentCtrl = dup.scale.controller
                            "visibility": currentCtrl = dup.visibility.controller
                            default: (
                                -- 处理修改器路径
                                if matchPattern pathParts[1] pattern:"modifier_*" then (
                                    local parts = filterString pathParts[1] "_"
                                    if parts.count >= 2 then (
                                        local modIndex = parts[2] as integer
                                        if modIndex <= dup.modifiers.count then (
                                            local mod = dup.modifiers[modIndex]
                                            if pathParts.count > 1 then (
                                                local paramName = pathParts[2]
                                                if hasProperty mod paramName then
                                                    currentCtrl = (getProperty mod paramName).controller
                                            )
                                        )
                                    )
                                )
                            )
                        )
                        
                        -- 如果有子路径，继续向下查找
                        if currentCtrl != undefined and pathParts.count > 1 then (
                            for j = 2 to pathParts.count do (
                                if currentCtrl != undefined then (
                                    try (
                                        -- 尝试通过索引或名称访问子控制器
                                        for k = 1 to currentCtrl.numSubs do (
                                            local subName = try (currentCtrl.getSubAnimName k) catch ("sub" + k as string)
                                            if subName == pathParts[j] then (
                                                currentCtrl = currentCtrl[k]
                                                exit
                                            )
                                        )
                                    ) catch (
                                        currentCtrl = undefined
                                    )
                                )
                            )
                        )
                        
                        dupCtrl = currentCtrl
                        
                        -- 设置关键帧
                        if dupCtrl != undefined then (
                            setControllerValue dupCtrl (startFrame as time) startValue
                            setControllerValue dupCtrl (endFrame as time) endValue
                        )
                        
                    ) catch (
                        if chkDebug.checked then
                            format "警告: 无法设置控制器 %\n" ctrlName
                    )
                )
            )
            
            -- 如果启用线性插值，强制设置副本为线性插值
            if chkLinear.checked then (
                if chkDebug.checked then
                    format "强制设置副本为线性插值...\n"
                forcePositionXYZLinear dup
            )
            
            if chkDebug.checked then (
                format "新动画: %.1f 帧到 %.1f 帧\n" startFrame endFrame
                local startPos = at time (startFrame as time) dup.position
                local endPos = at time (endFrame as time) dup.position
                format "最终位置变化: % -> %\n" startPos endPos
            )
            
            append lastGenerated dup
        )
        
        -- 添加透明度渐变效果
        if chkVisibility.checked then (
            local halfTime = (endFrame - startFrame) / 2.0
            local midFrame = startFrame + halfTime
            
            if chkDebug.checked then
                format "\n=== 添加透明度渐变效果 ===\n"
            
            -- 只对第一个和最后一个副本添加透明度动画
            if lastGenerated.count >= 1 then (
                -- 第一个副本：从透明到不透明（在时间的一半开始）
                local firstObj = lastGenerated[1]
                
                -- 分别设置每个关键帧（使用布尔值）
                animate on at time (startFrame as time) (
                    firstObj.visibility = false
                )
                animate on at time (midFrame as time) (
                    firstObj.visibility = true
                )
                
                if chkDebug.checked then (
                    format "副本1 (%): %.1f帧=false -> %.1f帧=true\n" firstObj.name startFrame midFrame
                    -- 验证设置的值
                    local val1 = at time (startFrame as time) firstObj.visibility
                    local val2 = at time (midFrame as time) firstObj.visibility
                    format "  验证: %.1f帧实际值=% , %.1f帧实际值=%\n" startFrame val1 midFrame val2
                )
                
                -- 最后一个副本：从不透明到透明（仅当有多个副本时）
                if lastGenerated.count > 1 then (
                    local lastObj = lastGenerated[lastGenerated.count]
                    
                    -- 分别设置每个关键帧（使用布尔值）
                    animate on at time (startFrame as time) (
                        lastObj.visibility = true
                    )
                    animate on at time (midFrame as time) (
                        lastObj.visibility = true
                    )
                    animate on at time (endFrame as time) (
                        lastObj.visibility = false
                    )
                    
                    if chkDebug.checked then (
                        format "副本% (%): %.1f帧=true -> %.1f帧=false\n" lastGenerated.count lastObj.name midFrame endFrame
                        -- 验证设置的值
                        local val1 = at time (midFrame as time) lastObj.visibility
                        local val2 = at time (endFrame as time) lastObj.visibility
                        format "  验证: %.1f帧实际值=% , %.1f帧实际值=%\n" midFrame val1 endFrame val2
                    )
                )
                
                -- 中间的副本保持默认可见性（不添加任何透明度关键帧）
                if chkDebug.checked and lastGenerated.count > 2 then (
                    format "副本2到%: 保持默认可见性（无透明度动画）\n" (lastGenerated.count - 1)
                )
            )
        )
        
        if chkDebug.checked then (
            format "\n=== 成功生成%个分段动画副本 ===\n" numCopies
            if chkLinear.checked then (
                if sourceIsLinear then
                    format "✓ 所有副本已保持线性插值\n"
                else
                    format "⚠ 源对象非线性，副本已强制设为线性\n"
            )
        ) else (
            format "成功生成%个分段动画副本\n" numCopies
        )
        
        true
    )
    
    fn undoLast =
    (
        if lastGenerated.count > 0 then
        (
            delete lastGenerated
            lastGenerated = #()
            format "已删除所有副本\n"
        )
    )
    
    on btnGenerate pressed do fakeLoopKFrames()
    on btnUndo pressed do undoLast()
)

createDialog FakeLoopRollout width:220 height:120