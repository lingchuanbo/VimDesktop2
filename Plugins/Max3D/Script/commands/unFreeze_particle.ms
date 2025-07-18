for o in objects where ((classof o == PF_Source or classof o == SuperSpray or classof o == PArray or classof o == ParticleFlow or classof o == Snow or classof o == PCloud or classof o==Blizzard) and (o.isHidden == false)) do
(
    if o.isFrozen then
    (
        unfreeze o -- 解冻粒子系统
    )
    else
    (
        freeze o -- 冻结粒子系统
        o.showFrozenInGray = off
    )
)
