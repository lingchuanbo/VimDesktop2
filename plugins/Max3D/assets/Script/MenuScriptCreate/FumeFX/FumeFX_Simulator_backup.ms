/*
    FumeFX Simulator v1.0
    Created:      August 20, 2025
    Author:       Roo (AI Assistant)
    
    功能:
    - 获取场景中所有FumeFX对象
    - 列表展示FumeFX对象
    - 模拟选中的FumeFX对象
*/

-- 销毁已存在的对话框
if FumeFXSimulator != undefined then (
    try(destroyDialog FumeFXSimulator)catch()
)

-- 定义过滤函数，用于查找FumeFX对象
fn isFumeFX obj = (
    classOf obj == FumeFX
)

-- 主界面
rollout FumeFXSimulator "FumeFX 管理器" width:350 height:250
(
    -- 全局变量
    global fumeFXList = #()
    
    -- UI控件
    groupBox grp_list "FumeFX 对象列表" pos:[10, 5] width:330 height:170
    multiListBox lb_fumeFXList "" pos:[20, 25] width:200 height:10
    
    -- 操作按钮组
    groupBox grp_actions "" pos:[230, 20] width:100 height:150
    button btn_simulate "模拟" pos:[240, 35] width:80 height:25 enabled:false
    button btn_open "打开窗口" pos:[240, 65] width:80 height:25 enabled:false
    button btn_select "选择" pos:[240, 95] width:80 height:25 enabled:false
    button btn_refresh "刷新" pos:[240, 125] width:80 height:25
    
    -- 删除按钮组
    groupBox grp_delete "删除操作" pos:[10, 170] width:330 height:60
    button btn_delete_selected "删除选中" pos:[20, 190] width:80 height:25 enabled:false
    button btn_delete_all "删除全部" pos:[110, 190] width:80 height:25 enabled:false
    button btn_delete_unused "删除未使用" pos:[200, 190] width:80 height:25 enabled:false
    
    -- 状态栏
    label lbl_status "就绪" pos:[10, 233] width:330 height:20
    
    -- 更新列表函数
    fn updateFumeFXList = (
        -- 清空现有列表
        fumeFXList = #()
        lb_fumeFXList.items = #()
        
        -- 查找场景中所有FumeFX对象
        fumeFXObjects = for obj in objects where isFumeFX obj collect obj
        
        -- 添加到列表
        for obj in fumeFXObjects do (
            append fumeFXList obj
        )
        
        -- 更新UI
        lb_fumeFXList.items = for obj in fumeFXList collect obj.name
        btn_simulate.enabled = (fumeFXList.count > 0)
        btn_open.enabled = (fumeFXList.count > 0)
        btn_select.enabled = (fumeFXList.count > 0)
        btn_delete_selected.enabled = false
        btn_delete_all.enabled = (fumeFXList.count > 0)
        btn_delete_unused.enabled = (fumeFXList.count > 0)
        
        -- 更新状态栏
        lbl_status.text = "找到 " + (fumeFXList.count as string) + " 个FumeFX对象"
        
        -- 如果没有FumeFX对象，显示提示信息
        if fumeFXList.count == 0 then (
            lb_fumeFXList.items = #("场景中未找到FumeFX对象")
            lbl_status.text = "未找到FumeFX对象"
        )
    )
    
    -- 模拟选中对象函数
    fn simulateSelectedFumeFX = (
        selectedIndex = lb_fumeFXList.selection
        -- 处理selectedIndex可能为整数的情况
        if selectedIndex != undefined then (
            -- 如果selectedIndex是整数，转换为数组
            if (classOf selectedIndex) != Array then (
                selectedIndex = #(selectedIndex)
            )
            
            if selectedIndex.count > 0 then (
                -- 确保不是提示信息行
                if lb_fumeFXList.items[selectedIndex[1]] != "场景中未找到FumeFX对象" then (
                    selectedObj = fumeFXList[selectedIndex[1]]
                    if selectedObj != undefined then (
                        try (
                    -- 执行模拟 - 使用正确的方法名和参数
                    if (isProperty selectedObj "simulate") then (
                        selectedObj.simulate()
                        messageBox ("正在模拟: " + selectedObj.name + "\n\n请查看3ds Max状态栏了解模拟进度。")
                    ) else (
                        messageBox ("FumeFX对象不支持模拟方法: " + selectedObj.name)
                    )
                ) catch (
                    messageBox ("模拟失败: " + selectedObj.name + "\n\n错误: " + getCurrentException() + "\n请确保FumeFX对象设置正确。")
                )
                    )
                ) else (
                    messageBox "请先选择一个FumeFX对象"
                )
            ) else (
                messageBox "请先选择一个FumeFX对象"
            )
        ) else (
            messageBox "请先选择一个FumeFX对象"
        )
    )
    
    -- 选择对象函数
    fn selectSelectedFumeFX = (
        selectedIndex = lb_fumeFXList.selection
        -- 处理selectedIndex可能为整数的情况
        if selectedIndex != undefined then (
            -- 如果selectedIndex是整数，转换为数组
            if (classOf selectedIndex) != Array then (
                selectedIndex = #(selectedIndex)
            )
            
            if selectedIndex.count > 0 then (
                -- 确保不是提示信息行
                if lb_fumeFXList.items[selectedIndex[1]] != "场景中未找到FumeFX对象" then (
                    selectedObj = fumeFXList[selectedIndex[1]]
                    if selectedObj != undefined then (
                        select selectedObj
                        messageBox ("已选择对象: " + selectedObj.name)
                    )
                ) else (
                    messageBox "请先选择一个FumeFX对象"
                )
            ) else (
                messageBox "请先选择一个FumeFX对象"
            )
        ) else (
            messageBox "请先选择一个FumeFX对象"
        )
    )
    
    -- 打开FumeFX窗口函数
    fn openFumeFXWindow = (
        selectedIndex = lb_fumeFXList.selection
        -- 处理selectedIndex可能为整数的情况
        if selectedIndex != undefined then (
            -- 如果selectedIndex是整数，转换为数组
            if (classOf selectedIndex) != Array then (
                selectedIndex = #(selectedIndex)
            )
            if selectedIndex.count > 0 then (
                -- 确保不是提示信息行
                if lb_fumeFXList.items[selectedIndex[1]] != "场景中未找到FumeFX对象" then (
                    selectedObj = fumeFXList[selectedIndex[1]]
                    if selectedObj != undefined then (
                        try (
                            -- 选择对象
                            select selectedObj
                            -- 切换到修改面板
                            max modify mode
                            messageBox ("已打开对象属性窗口: " + selectedObj.name)
                        ) catch (
                            messageBox ("打开窗口失败: " + selectedObj.name + "\n\n错误: " + getCurrentException())
                        )
                    )
                ) else (
                    messageBox "请先选择一个FumeFX对象"
                )
            ) else (
                messageBox "请先选择一个FumeFX对象"
            )
        ) else (
            messageBox "请先选择一个FumeFX对象"
        )
    )
    
    -- 删除选中对象函数
    fn deleteSelectedFumeFX = (
        selectedIndex = lb_fumeFXList.selection
        if selectedIndex != undefined then (
            if (classOf selectedIndex) != Array then (
                selectedIndex = #(selectedIndex)
            )
            
            if selectedIndex.count > 0 then (
                if lb_fumeFXList.items[selectedIndex[1]] != "场景中未找到FumeFX对象" then (
                    selectedObj = fumeFXList[selectedIndex[1]]
                    if selectedObj != undefined then (
                        try (
                            delete selectedObj
                            lbl_status.text = "已删除: " + selectedObj.name
                            updateFumeFXList()
                        ) catch (
                            messageBox ("删除失败: " + selectedObj.name)
                            lbl_status.text = "删除失败"
                        )
                    )
                )
            )
        )
    )
    
    -- 删除所有对象函数
    fn deleteAllFumeFX = (
        if fumeFXList.count > 0 then (
            if (queryBox "确定要删除所有FumeFX对象吗？此操作不可撤销！" title:"确认删除") then (
                try (
                    for obj in fumeFXList do (
                        try(delete obj)catch()
                    )
                    lbl_status.text = "已删除所有FumeFX对象"
                    updateFumeFXList()
                ) catch (
                    messageBox "删除所有对象时发生错误"
                    lbl_status.text = "删除失败"
                )
            )
        ) else (
            messageBox "没有FumeFX对象可删除"
        )
    )
    
    -- 删除未使用对象函数
    fn deleteUnusedFumeFX = (
        -- 这里可以添加逻辑来识别和删除未使用的FumeFX对象
        -- 暂时实现为删除所有对象
        deleteAllFumeFX()
    )
    
    -- 对话框打开事件
    on FumeFXSimulator open do (
        updateFumeFXList()
    )
    
    -- 列表选择改变事件
    on lb_fumeFXList selectionChanged do (
        selectedIndex = lb_fumeFXList.selection
        -- 处理selectedIndex可能为整数的情况
        if selectedIndex != undefined then (
            -- 如果selectedIndex是整数，转换为数组
            if (classOf selectedIndex) != Array then (
                selectedIndex = #(selectedIndex)
            )
            
            -- 检查是否是提示信息行
            if selectedIndex.count > 0 and lb_fumeFXList.items[selectedIndex[1]] != "场景中未找到FumeFX对象" then (
                btn_simulate.enabled = true
                btn_open.enabled = true
                btn_select.enabled = true
                btn_delete_selected.enabled = true
                lbl_status.text = "已选择: " + lb_fumeFXList.items[selectedIndex[1]]
            ) else (
                btn_simulate.enabled = false
                btn_open.enabled = false
                btn_select.enabled = false
                btn_delete_selected.enabled = false
                lbl_status.text = "找到 " + (fumeFXList.count as string) + " 个FumeFX对象"
            )
        ) else (
            btn_simulate.enabled = false
            btn_select.enabled = false
        )
    )
    
    -- 模拟按钮点击事件
    on btn_simulate pressed do (
        simulateSelectedFumeFX()
    )
    
    -- 打开窗口按钮点击事件
    on btn_open pressed do (
        openFumeFXWindow()
    )
    
    -- 刷新按钮点击事件
    on btn_refresh pressed do (
        updateFumeFXList()
        lbl_status.text = "列表已刷新"
    )
    
    -- 选择按钮点击事件
    on btn_select pressed do (
        selectSelectedFumeFX()
    )
    
    -- 删除选中按钮点击事件
    on btn_delete_selected pressed do (
        deleteSelectedFumeFX()
    )
    
    -- 删除全部按钮点击事件
    on btn_delete_all pressed do (
        deleteAllFumeFX()
    )
    
    -- 删除未使用按钮点击事件
    on btn_delete_unused pressed do (
        deleteUnusedFumeFX()
    )
    
    -- 列表双击事件 - 改为打开FumeFX窗口
    on lb_fumeFXList doubleClicked do (
        openFumeFXWindow()
    )
)

-- 创建对话框
createDialog FumeFXSimulator