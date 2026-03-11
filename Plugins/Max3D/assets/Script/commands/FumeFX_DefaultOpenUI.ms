/*
    FumeFX 打开UI脚本
    功能：
    - 如果选中了FumeFX对象，打开选中对象的UI
    - 如果没有选中任何对象，查找"vfx_FumeFX_1"并打开其UI
*/

(
    -- 获取当前选中的对象
    selected = selection as array
    
    -- 过滤出FumeFX对象
    fumeFXSelected = for obj in selected where (classof obj == FumeFX) collect obj
    
    if fumeFXSelected.count > 0 then (
        -- 有选中的FumeFX对象，打开第一个选中对象的UI
        local targetObj = fumeFXSelected[1]
        print ("打开UI: " + targetObj.name)
        

        
        -- 打开UI
        targetObj.EditUI = on
        
        -- 刷新视图
        redrawViews()
        completeRedraw()

        -- 重新选中对象以刷新界面
        clearSelection()
        select targetObj
        
    ) else (
        -- 没有选中FumeFX对象，查找默认的vfx_FumeFX_1
        fumeFXObj = getNodeByName "vfx_FumeFX_1"
        
        if fumeFXObj != undefined then (
            -- 打开UI
            fumeFXObj.EditUI = on
            
            -- 刷新视图
            redrawViews()
            completeRedraw()
            
            -- 重新选中对象以刷新界面
            clearSelection()
            select fumeFXObj
            
            print "已打开 vfx_FumeFX_1 的UI"
        ) else (
            messageBox "没有选中FumeFX对象，也没找到名为 'vfx_FumeFX_1' 的FX对象，请检查！" title:"提示" beep:true
        )
    )
)






