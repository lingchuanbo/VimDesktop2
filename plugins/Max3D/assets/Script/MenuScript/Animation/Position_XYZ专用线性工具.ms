rollout PositionXYZLinearRollout "Position_XYZ专用线性工具"
(
    label lblTitle "Position_XYZ控制器线性化专用工具" pos:[10,10] width:250 height:20 align:#center
    
    checkbox chkDebug "显示详细调试信息" pos:[20,40] width:150 height:20 checked:true
    
    button btnDeepAnalyze "深度分析Position_XYZ" pos:[20,70] width:200 height:25
    button btnDirectAccess "直接访问子控制器" pos:[20,100] width:200 height:25
    button btnForceLinear "强制线性化" pos:[20,130] width:200 height:30
    
    label lblInfo "专门处理Position_XYZ复合控制器" pos:[10,170] width:250 height:20 align:#center
    
    -- 深度分析Position_XYZ控制器
    fn deepAnalyzePositionXYZ obj = (
        format "=== 深度分析对象 % 的Position_XYZ控制器 ===\n" obj.name
        
        local posCtrl = obj.position.controller
        format "主控制器类型: %\n" (classOf posCtrl)
        
        -- 尝试多种方式访问子控制器
        format "\n方式1: 通过索引访问子控制器\n"
        try (
            for i = 1 to posCtrl.numSubs do (
                local subCtrl = posCtrl[i]
                local subName = try (posCtrl.getSubAnimName i) catch ("sub" + i as string)
                format "  [%] %: % (类型: %)\n" i subName subCtrl (classOf subCtrl)
                
                -- 尝试获取实际控制器
                try (
                    local realCtrl = subCtrl.controller
                    if realCtrl != undefined then (
                        format "    实际控制器: % (类型: %)\n" realCtrl (classOf realCtrl)
                        
                        -- 检查关键帧
                        if realCtrl.keys != undefined then (
                            format "    关键帧数: %\n" realCtrl.keys.count
                            if realCtrl.keys.count > 0 then (
                                local firstKey = realCtrl.keys[1]
                                format "    第一个关键帧: 时间=%, 值=%\n" firstKey.time firstKey.value
                                
                                -- 检查插值类型
                                try (
                                    if hasProperty firstKey "inTangentType" then (
                                        format "    插值类型: in=%, out=%\n" firstKey.inTangentType firstKey.outTangentType
                                    ) else (
                                        format "    插值类型: 无法读取\n"
                                    )
                                ) catch (
                                    format "    插值类型检查失败: %\n" (getCurrentException())
                                )
                            )
                        ) else (
                            format "    无关键帧数据\n"
                        )
                    )
                ) catch (
                    format "    无法获取实际控制器: %\n" (getCurrentException())
                )
            )
        ) catch (
            format "索引访问失败: %\n" (getCurrentException())
        )
        
        -- 方式2: 通过属性名访问
        format "\n方式2: 通过属性名访问\n"
        local propNames = #("x_position", "y_position", "z_position", "X_Position", "Y_Position", "Z_Position")
        for propName in propNames do (
            try (
                local subCtrl = getProperty posCtrl propName
                if subCtrl != undefined then (
                    format "  %: % (类型: %)\n" propName subCtrl (classOf subCtrl)
                    
                    if subCtrl.keys != undefined then (
                        format "    关键帧数: %\n" subCtrl.keys.count
                    )
                )
            ) catch ()
        )
        
        -- 方式3: 通过trackViewNodes访问
        format "\n方式3: 通过trackViewNodes访问\n"
        try (
            local tvn = refs.dependentNodes obj trackViewNodes:true
            if tvn.count > 0 then (
                format "  找到 % 个TrackView节点\n" tvn.count
                for node in tvn do (
                    format "    节点: %\n" node
                )
            )
        ) catch (
            format "TrackView访问失败: %\n" (getCurrentException())
        )
        
        format "\n=== 深度分析完成 ===\n\n"
    )
    
    -- 直接访问并操作子控制器
    fn directAccessSubControllers obj = (
        format "=== 直接访问对象 % 的子控制器 ===\n" obj.name
        
        local posCtrl = obj.position.controller
        local accessCount = 0
        
        try (
            for i = 1 to posCtrl.numSubs do (
                local subCtrl = posCtrl[i]
                local subName = try (posCtrl.getSubAnimName i) catch ("sub" + i as string)
                
                format "处理子控制器 [%] %...\n" i subName
                
                -- 尝试多种访问方式
                local realCtrl = undefined
                
                -- 方式1: .controller属性
                try (
                    realCtrl = subCtrl.controller
                    if realCtrl != undefined then (
                        format "  ✓ 通过.controller访问成功: %\n" (classOf realCtrl)
                        accessCount += 1
                    )
                ) catch ()
                
                -- 方式2: 直接使用subCtrl
                if realCtrl == undefined then (
                    try (
                        if subCtrl.keys != undefined then (
                            realCtrl = subCtrl
                            format "  ✓ 直接访问成功: %\n" (classOf realCtrl)
                            accessCount += 1
                        )
                    ) catch ()
                )
                
                -- 方式3: 通过obj的子属性
                if realCtrl == undefined then (
                    try (
                        case i of (
                            1: realCtrl = obj.position.x_position
                            2: realCtrl = obj.position.y_position  
                            3: realCtrl = obj.position.z_position
                        )
                        if realCtrl != undefined then (
                            format "  ✓ 通过obj属性访问成功: %\n" (classOf realCtrl)
                            accessCount += 1
                        )
                    ) catch ()
                )
                
                -- 如果成功访问，显示详细信息
                if realCtrl != undefined then (
                    if realCtrl.keys != undefined and realCtrl.keys.count > 0 then (
                        format "    关键帧数: %\n" realCtrl.keys.count
                        
                        -- 显示所有关键帧信息
                        for j = 1 to realCtrl.keys.count do (
                            local key = realCtrl.keys[j]
                            format "    关键帧%: 时间=%, 值=%\n" j key.time key.value
                            
                            try (
                                if hasProperty key "inTangentType" then (
                                    format "      插值: in=%, out=%\n" key.inTangentType key.outTangentType
                                )
                            ) catch ()
                        )
                    ) else (
                        format "    无关键帧\n"
                    )
                ) else (
                    format "  ✗ 无法访问实际控制器\n"
                )
            )
        ) catch (
            format "子控制器访问失败: %\n" (getCurrentException())
        )
        
        format "\n成功访问了 %/% 个子控制器\n" accessCount posCtrl.numSubs
        format "=== 直接访问完成 ===\n\n"
        
        return accessCount
    )
    
    -- 强制线性化Position_XYZ控制器
    fn forceLinearizePositionXYZ obj = (
        format "=== 强制线性化对象 % ===\n" obj.name
        
        local posCtrl = obj.position.controller
        local convertedCount = 0
        local totalKeys = 0
        
        -- 收集所有动画数据
        local animData = #()
        
        try (
            for i = 1 to posCtrl.numSubs do (
                local subCtrl = posCtrl[i]
                local subName = try (posCtrl.getSubAnimName i) catch ("sub" + i as string)
                local axisName = case i of (1: "X"; 2: "Y"; 3: "Z"; default: "轴" + i as string)
                
                format "处理%轴 (%控制器)...\n" axisName subName
                
                -- 尝试获取实际控制器
                local realCtrl = undefined
                try (realCtrl = subCtrl.controller) catch ()
                if realCtrl == undefined then realCtrl = subCtrl
                
                if realCtrl != undefined and realCtrl.keys != undefined and realCtrl.keys.count > 0 then (
                    format "  找到 % 个关键帧\n" realCtrl.keys.count
                    
                    -- 收集关键帧数据
                    local keyData = #()
                    for j = 1 to realCtrl.keys.count do (
                        local key = realCtrl.keys[j]
                        append keyData #(key.time, key.value)
                        totalKeys += 1
                    )
                    
                    append animData #(i, axisName, keyData)
                    format "  ✓ 收集了%轴的 % 个关键帧\n" axisName keyData.count
                ) else (
                    format "  ✗ %轴无关键帧数据\n" axisName
                )
            )
        ) catch (
            format "数据收集失败: %\n" (getCurrentException())
        )
        
        if animData.count == 0 then (
            format "没有找到动画数据，无法转换\n"
            return 0
        )
        
        format "\n开始重新创建线性动画...\n"
        
        -- 保存当前默认切线类型
        local originalIn = #auto
        local originalOut = #auto
        maxops.getDefaultTangentType &originalIn &originalOut
        
        -- 设置线性为默认
        maxops.setDefaultTangentType #linear #linear
        
        -- 清除现有动画
        deleteKeys obj #allKeys
        
        -- 重新创建动画
        local createdKeys = 0
        for axisData in animData do (
            local axisIndex = axisData[1]
            local axisName = axisData[2]
            local keyData = axisData[3]
            
            format "重新创建%轴动画...\n" axisName
            
            for keyInfo in keyData do (
                local keyTime = keyInfo[1]
                local keyValue = keyInfo[2]
                
                -- 获取当前位置
                local currentPos = at time keyTime obj.position
                
                -- 设置对应轴的值
                local newPos = case axisIndex of (
                    1: [keyValue, currentPos.y, currentPos.z]  -- X轴
                    2: [currentPos.x, keyValue, currentPos.z]  -- Y轴  
                    3: [currentPos.x, currentPos.y, keyValue]  -- Z轴
                    default: currentPos
                )
                
                animate on at time keyTime (
                    obj.position = newPos
                )
                
                createdKeys += 1
            )
            
            convertedCount += 1
            format "  ✓ %轴重新创建完成 (% 个关键帧)\n" axisName keyData.count
        )
        
        -- 恢复原始默认切线类型
        maxops.setDefaultTangentType originalIn originalOut
        
        format "\n=== 线性化完成 ===\n"
        format "转换轴数: %/%\n" convertedCount posCtrl.numSubs
        format "创建线性关键帧: %\n" createdKeys
        
        return createdKeys
    )
    
    on btnDeepAnalyze pressed do (
        if selection.count == 0 then (
            messageBox "请先选择一个对象！"
            return()
        )
        
        deepAnalyzePositionXYZ selection[1]
    )
    
    on btnDirectAccess pressed do (
        if selection.count == 0 then (
            messageBox "请先选择一个对象！"
            return()
        )
        
        directAccessSubControllers selection[1]
    )
    
    on btnForceLinear pressed do (
        if selection.count == 0 then (
            messageBox "请先选择一个或多个对象！"
            return()
        )
        
        local totalConverted = 0
        local totalKeys = 0
        
        for obj in selection do (
            local objKeys = forceLinearizePositionXYZ obj
            totalKeys += objKeys
            if objKeys > 0 then totalConverted += 1
        )
        
        local message = "Position_XYZ线性化完成！\n\n"
        message += "处理对象数: " + selection.count as string + "\n"
        message += "成功转换: " + totalConverted as string + " 个对象\n"
        message += "创建线性关键帧: " + totalKeys as string + "\n\n"
        
        if totalKeys > 0 then (
            message += "✓ 动画已重新创建为线性插值\n"
            message += "现在可以使用分段动画工具生成副本"
        ) else (
            message += "⚠ 没有找到可转换的动画数据"
        )
        
        messageBox message title:"转换结果"
    )
)

createDialog PositionXYZLinearRollout 270 200