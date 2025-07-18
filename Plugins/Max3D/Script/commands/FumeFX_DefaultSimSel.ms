fn rotateSelectedObjects = (
    selected = selection as array

    if selected.count == 0 then (
        messagebox "请选中FX在执行"
        return false
    ) else (
        for obj in selected do (
			print(obj.name)
			obj.RunSimulation 0
        )
        return true
    )
)

rotateSelectedObjects()