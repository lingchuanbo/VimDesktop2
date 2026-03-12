
		if keyboard.shiftPressed then (
			local file = (GetDir #maxScripts) + "\commands\WorkingPivotByPoints.ms"
			print file
			if doesFileExist file do fileIn file
		)
		else if keyboard.controlpressed then (
			local obj = pickObject message:"Pick Object as Coordinate Reference"
			if isValidNode obj do (
				WorkingPivot.setTM obj.transform ; toolMode.coordsys #working_pivot ; setCoordCenter #system
			)
		)
		else if keyboard.altpressed then (
			local obj = pickObject message:"Pick Object as Coordinate Reference"
			if isValidNode obj do (
				local mtx = WorkingPivot.getTM() ; mtx.translation = obj.pivot ; WorkingPivot.setTM mtx
				toolMode.coordsys #working_pivot ; setCoordCenter #system
			)
		)
		else (
			actionMan.executeAction 0 "40848" ; toolMode.coordsys #working_pivot
		)

