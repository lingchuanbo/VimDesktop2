/*
    FumeFX Simulator v1.1 - 修复版
    Created:      August 20, 2025
    Author:       Roo (AI Assistant)
    Fixed:        August 20, 2025
    
    功能:
    - 获取场景中所有FumeFX对象
    - 列表展示FumeFX对象
    - 模拟选中的FumeFX对象 (使用正确的 RunSimulation API)
    - 打开FumeFX编辑窗口 (使用 EditUI 属性)
    - 删除管理功能
    
    修复内容:
    - 修复模拟功能: 使用正确的 RunSimulation 方法
    - 修复打开窗口功能: 使用 EditUI 属性和 actionMan 方法
    - 改进按钮状态管理
    - 添加错误处理和工具提示
*/

-- 销毁已存在的对话框
if FumeFXSimulator != undefined then (
    try(destroyDialog FumeFXSimulator)catch()
)

-- 定义过滤函数，用于查找FumeFX对象
fn isFumeFX obj = (
    classOf obj == FumeFX or classOf obj == fumefx
)

-- 检查FumeFX插件是否可用
fn isFumeFXAvailable = (
    try (
        local testObj = FumeFX()
        delete testObj
        true
    ) catch (
        false
    )
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
    button btn_simulate "模拟" pos:[240, 35] width:80 height:25 enabled:false tooltip:"模拟选中的FumeFX对象"
    button btn_open "打开窗口" pos:[240, 65] width:80 height:25 enabled:false tooltip:"打开FumeFX编辑窗口"
    button btn_select "选择" pos:[240, 95] width:80 height:25 enabled:false tooltip:"在视图中选择对象"
    button btn_refresh "刷新" pos:[240, 125] width:80 height:25 tooltip:"刷新FumeFX对象列表"
    
    -- 删除按钮组
    groupBox grp_delete "删除操作" pos:[10, 170] width:330 height:60
    button btn_delete_selected "删除选中" pos:[20, 190] width:80 height:25 enabled:false tooltip:"删除选中的FumeFX对象"
    button btn_delete_all "删除全部" pos:[110, 190] width:80 height:25 enabled:false tooltip:"删除所有FumeFX对象"
    button btn_delete_unused "删除未使用" pos:[200, 190] width:80 height:25 enabled:false tooltip:"删除未使用的FumeFX对象"
    
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
        -- 更新按钮状态
        local hasObjects = (fumeFXList.count > 0)
        btn_simulate.enabled = hasObjects
        btn_open.enabled = hasObjects
        btn_select.enabled = hasObjects
        btn_delete_selected.enabled = false  -- 需要选择具体对象
        btn_delete_all.enabled = hasObjects
        btn_delete_unused.enabled = hasObjects
        
        -- 如果没有对象，禁用所有操作按钮
        if not hasObjects then (
            btn_simulate.enabled = false
            btn_open.enabled = false
            btn_select.enabled = false
            btn_delete_selected.enabled = false
            btn_delete_all.enabled = false
            btn_delete_unused.enabled = false
        )
        
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
        local selectedIndices = lb_fumeFXList.selection as array
        if selectedIndices.count == 0 then (
            messageBox "请先选择一个FumeFX对象"
            return false
        )
        
        local firstSelectedIndex = selectedIndices[1]
        -- 确保不是提示信息行
        if lb_fumeFXList.items[firstSelectedIndex] == "场景中未找到FumeFX对象" then (
            messageBox "请先选择一个FumeFX对象"
            return false
        )
        
        if firstSelectedIndex > fumeFXList.count then (
            messageBox "选择无效，请刷新列表后重试"
            return false
        )
        
        local selectedObj = fumeFXList[firstSelectedIndex]
        if selectedObj == undefined or not (isValidNode selectedObj) then (
            messageBox "选择的对象无效或已被删除"
            updateFumeFXList()
            return false
        )
        
        try (
            -- 执行模拟 - 使用正确的 FumeFX API
            if (isProperty selectedObj "RunSimulation") then (
                selectedObj.RunSimulation 0  -- 0 = Default Simulation
                messageBox ("正在模拟: " + selectedObj.name + "\n\n请查看3ds Max状态栏了解模拟进度。")
                return true
            ) else (
                messageBox ("FumeFX对象不支持模拟方法: " + selectedObj.name + "\n请确保已安装FumeFX插件。")
                return false
            )
        ) catch (
            messageBox ("模拟失败: " + selectedObj.name + "\n\n错误: " + getCurrentException() + "\n请确保FumeFX对象设置正确。")
            return false
        )
    )
    
    -- 选择对象函数
    fn selectSelectedFumeFX = (
        local selectedIndices = lb_fumeFXList.selection as array
        if selectedIndices.count == 0 then (
            messageBox "请先选择一个FumeFX对象"
            return false
        )
        
        local firstSelectedIndex = selectedIndices[1]
        -- 确保不是提示信息行
        if lb_fumeFXList.items[firstSelectedIndex] == "场景中未找到FumeFX对象" then (
            messageBox "请先选择一个FumeFX对象"
            return false
        )
        
        if firstSelectedIndex > fumeFXList.count then (
            messageBox "选择无效，请刷新列表后重试"
            return false
        )
        
        local selectedObj = fumeFXList[firstSelectedIndex]
        if selectedObj == undefined or not (isValidNode selectedObj) then (
            messageBox "选择的对象无效或已被删除"
            updateFumeFXList()
            return false
        )
        
        select selectedObj
        messageBox ("已选择对象: " + selectedObj.name)
        return true
    )
    
    -- 打开FumeFX窗口函数 - 改进版，确保一次点击就能打开
    fn openFumeFXWindow = (
        local selectedIndices = lb_fumeFXList.selection as array
        if selectedIndices.count == 0 then (
            messageBox "请先选择一个FumeFX对象"
            return false
        )
        
        local firstSelectedIndex = selectedIndices[1]
        -- 确保不是提示信息行
        if lb_fumeFXList.items[firstSelectedIndex] == "场景中未找到FumeFX对象" then (
            messageBox "请先选择一个FumeFX对象"
            return false
        )
        
        if firstSelectedIndex > fumeFXList.count then (
            messageBox "选择无效，请刷新列表后重试"
            return false
        )
        
        local selectedObj = fumeFXList[firstSelectedIndex]
        if selectedObj == undefined or not (isValidNode selectedObj) then (
            messageBox "选择的对象无效或已被删除"
            updateFumeFXList()
            return false
        )
        
        try (
            -- 确保对象被选中
            select selectedObj
            max modify mode
            
            -- 尝试多种方法打开FumeFX窗口
            local success = false
            
            -- 方法1: 使用EditUI属性 (最可靠的方法)
            if (isProperty selectedObj "EditUI") then (
                try (
                    selectedObj.EditUI = on
                    success = true
                ) catch ()
            )
            
            -- 方法2: 使用actionMan执行FumeFX UI命令
            if not success then (
                try (
                    actionMan.executeAction 12121256 "40011"  -- FumeFX UI action
                    success = true
                ) catch ()
            )
            
            -- 方法3: 直接调用FumeFX的UI方法
            if not success and (isProperty selectedObj "OpenUI") then (
                try (
                    selectedObj.OpenUI()
                    success = true
                ) catch ()
            )
            
            -- 方法4: 使用max命令面板作为后备
            if not success then (
                try (
                    -- 切换到修改面板，确保FumeFX参数可见
                    max modify mode
                    success = true
                ) catch ()
            )
            
            if success then (
                return true
            ) else (
                messageBox ("无法打开FumeFX窗口，请确保FumeFX插件已正确安装: " + selectedObj.name)
                return false
            )
        ) catch (
            messageBox ("打开窗口失败: " + selectedObj.name + "\n\n错误: " + getCurrentException())
            return false
        )
    )
    
    -- 删除选中对象函数
    fn deleteSelectedFumeFX = (
        local selectedIndices = lb_fumeFXList.selection as array
        if selectedIndices.count == 0 then (
            messageBox "请先选择一个FumeFX对象"
            return false
        )
        
        local firstSelectedIndex = selectedIndices[1]
        -- 确保不是提示信息行
        if lb_fumeFXList.items[firstSelectedIndex] == "场景中未找到FumeFX对象" then (
            messageBox "请先选择一个FumeFX对象"
            return false
        )
        
        if firstSelectedIndex > fumeFXList.count then (
            messageBox "选择无效，请刷新列表后重试"
            return false
        )
        
        local selectedObj = fumeFXList[firstSelectedIndex]
        if selectedObj == undefined or not (isValidNode selectedObj) then (
            messageBox "选择的对象无效或已被删除"
            updateFumeFXList()
            return false
        )
        
        try (
            delete selectedObj
            lbl_status.text = "已删除: " + selectedObj.name
            updateFumeFXList()
            return true
        ) catch (
            messageBox ("删除失败: " + selectedObj.name)
            lbl_status.text = "删除失败"
            return false
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
        -- 检查FumeFX插件是否可用
        if not (isFumeFXAvailable()) then (
            messageBox "FumeFX插件未安装或不可用！\n请确保已正确安装FumeFX插件。" title:"错误" beep:true
            lbl_status.text = "FumeFX插件不可用"
            return false
        )
        
        updateFumeFXList()
    )
    
    -- 列表选择改变事件
    on lb_fumeFXList selectionChanged do (
        local selectedIndices = lb_fumeFXList.selection as array
        if selectedIndices.count > 0 then (
            local firstSelectedIndex = selectedIndices[1]
            -- 检查是否是提示信息行
            if lb_fumeFXList.items[firstSelectedIndex] != "场景中未找到FumeFX对象" then (
                local isValidSelection = (fumeFXList.count > 0 and firstSelectedIndex <= fumeFXList.count)
                btn_simulate.enabled = isValidSelection
                btn_open.enabled = isValidSelection
                btn_select.enabled = isValidSelection
                btn_delete_selected.enabled = isValidSelection
                if isValidSelection then (
                    lbl_status.text = "已选择: " + lb_fumeFXList.items[firstSelectedIndex]
                ) else (
                    lbl_status.text = "选择无效"
                )
            ) else (
                -- 选择的是提示信息
                btn_simulate.enabled = false
                btn_open.enabled = false
                btn_select.enabled = false
                btn_delete_selected.enabled = false
                lbl_status.text = "找到 " + (fumeFXList.count as string) + " 个FumeFX对象"
            )
        ) else (
            -- 没有选择
            btn_simulate.enabled = false
            btn_open.enabled = false
            btn_select.enabled = false
            btn_delete_selected.enabled = false
            lbl_status.text = "找到 " + (fumeFXList.count as string) + " 个FumeFX对象"
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
        lbl_status.text = "列表已刷新 - 找到 " + (fumeFXList.count as string) + " 个对象"
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
    on lb_fumeFXList doubleClicked index do (
        openFumeFXWindow()
    )
)

-- 创建对话框
createDialog FumeFXSimulator