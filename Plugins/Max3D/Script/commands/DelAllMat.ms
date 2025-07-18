sel = getcurrentselection()
macros.run "Medit Tools" "clear_medit_slots"
geometry.material = undefined
for i = 1 to sel.count do (
	sel[i].material = MatteShadow()
)