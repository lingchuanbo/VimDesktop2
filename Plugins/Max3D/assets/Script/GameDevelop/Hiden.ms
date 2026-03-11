(
	persistent global mbHide_lastHidden
	on isEnabled do (selection.count>0)
	on execute do (
		if selection.count>0 then mbHide_lastHidden = #()
		for o in selection do (
			append mbHide_lastHidden o
			o.isHidden = true
		)
		clearSelection()
	)
)