/*
    FumeFX 默认模拟脚本
    功能：
    - 如果选中了FumeFX对象，对选中的对象执行模拟
    - 如果没有选中任何对象，查找"vfx_FumeFX_1"并执行模拟
*/

(
    -- 获取当前选中的对象
    selected = selection as array
    
    -- 过滤出FumeFX对象
    fumeFXSelected = for obj in selected where (classof obj == FumeFX) collect obj
    
    if fumeFXSelected.count > 0 then (
        -- 有选中的FumeFX对象，执行选中对象的模拟
        print "执行选中的FumeFX对象模拟..."
        for obj in fumeFXSelected do (
            print ("正在模拟: " + obj.name)
            obj.RunSimulation 0
        )
    ) else (
        -- 没有选中FumeFX对象，查找默认的vfx_FumeFX_1
        fumeFXObj = getNodeByName "vfx_FumeFX_1"
        
        if fumeFXObj != undefined then (
            -- 取消选择所有对象
            clearSelection()
            
            -- 选中FumeFX对象
            selectMore fumeFXObj
            
            -- 设置模拟模式并运行
            -- 0 - Default Simulation 
            -- 1 - Simulation from Initial State 
            -- 2 - Wavelet Simulation
            fumeFXObj.SimMode = 0
            fumeFXObj.RunSimulation 0
            
            print "已选中并模拟 vfx_FumeFX_1 对象"
        ) else (
            messageBox "没有选中FumeFX对象，也没找到名为 'vfx_FumeFX_1' 的FX对象，请检查！" title:"提示" beep:true
        )
    )
)
