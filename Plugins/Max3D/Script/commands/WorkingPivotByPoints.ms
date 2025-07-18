(
	local pts = #(), view_types = #(#view_top, #view_bottom, #view_right, #view_left, #view_front , #view_back), DrawText
	fn DrawText = (
		gw.setTransform(Matrix3 1)
		for p = 1 to pts.count do (
			gw.marker pts[p] #hollowBox color:(color 225 165 80)
			gw.SetColor #line (color 70 170 200)
			if pts[p+1] != undefined then (gw.hPolyline #(gw.hTransPoint pts[p], gw.hTransPoint pts[p+1]) false)
		)
		gw.enlargeUpdateRect #whole ; gw.updateScreen()
	)
	fn PickPoints = (
		local state = false, p1, p2, savesnap = snapMode.active , savesnapmode = snapMode.type ; pts = #()
		snapMode.active = true ; if (findItem view_types (viewport.getType()) != 0) then snapMode.type = #2_5D else  snapMode.type = #3D
		unregisterRedrawViewsCallback DrawText ; registerRedrawViewsCallback DrawText
		p1 = pickpoint snap:#3d ; if classof p1 == point3 do (
			append pts p1 ; state = true
			p2 = pickpoint rubberBand:p1 snap:#3d ; if classof p2 == point3 do (
				append pts p2
				p3 = pickpoint rubberBand:p1 snap:#3d ; if classof p3 == point3 do append pts p3
			)
		)
		unregisterRedrawViewsCallback DrawText
		snapMode.active = savesnap ; snapMode.type = savesnapmode
		state
	)
	fn GetMatrixbyPoints p1 p2 p3: = (
		local v1, v2, v3, p, mtx, dv = (units.decodeValue "1.0cm")/100
		if p3 == unsupplied or p3 == undefined then (p = (p1+p2)/2 ; p3 = [p.x+dv,p.y+dv,p1.z]) else p = p1
		v1 = normalize (p2 - p1)
		v3 = normalize (cross v1 (normalize (p1 - p3)))
		v2 = normalize (cross v3 v1)
		mtx = matrix3 v1 v2 v3 p1 ; mtx.translation = p
		mtx
	)
	if (PickPoints()) do (
		if pts.count == 1 then (
			local mtx = WorkingPivot.getTM() ; mtx.translation = pts[1] ; WorkingPivot.setTM mtx
		)
		else WorkingPivot.setTM (GetMatrixbyPoints pts[1] pts[2] p3:pts[3])
		toolMode.coordsys #working_pivot --; setCoordCenter #system
	)
	clearListener()
)