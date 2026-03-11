for o in objects where (((classof o == Editable_mesh) or (classof o == Editable_Poly) or (classof o == PolyMeshObject)) and (o.isHidden == false)) do
(
    if o.isFrozen then -- 检查对象是否被冻结
    (
        unfreeze o -- 如果已被冻结，则解冻
    )
    else -- 如果未冻结
    (
        freeze o -- 冻结对象
        o.showFrozenInGray = off -- 设置冻结对象不显示为灰色
    )
)
