-- 尝试获取名为"vfx_FumeFX_1"的对象
fumeFXObj = getNodeByName "vfx_FumeFX_1"

-- 检查对象是否存在
if fumeFXObj != undefined then
(
    -- 取消选择所有对象
    clearSelection()
    
    -- 选择FumeFX对象
    selectMore fumeFXObj
	
	fumeFXObj.EditUI = on 

    print "已选中 vfx_FumeFX_1 对象"
)
else
(
	messageBox "没找到名为 'vfx_FumeFX_1' 的FX对象，请重命名" title:"错误" beep:true
)


 






