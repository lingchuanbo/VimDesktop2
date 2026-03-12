(
	persistent global mbHide_lastHidden
	on isEnabled do ((classof mbHide_lastHidden)==Array)
	on execute do (
		if (classof mbHide_lastHidden)==Array then (
			for o in mbHide_lastHidden do (
			if isValidNode o then o.isHidden = false
			)
			mbHide_lastHidden = undefined
		)
	)
)
