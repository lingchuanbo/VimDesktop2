fn rotateSelectedObjects angle = (
    selected = selection as array

    if selected.count == 0 then (
        messagebox "请选中虚拟体"
        return false
    ) else (
        for obj in selected do (
            rotate obj (angleaxis angle [0,0,1])
        )
        return true
    )
)

-- 调用函数并传入旋转角度
rotateSelectedObjects -45