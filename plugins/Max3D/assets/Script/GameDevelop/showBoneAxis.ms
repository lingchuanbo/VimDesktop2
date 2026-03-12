(
-- for 3ds max 5-7 - (c) 2004 by M. Breidt (martin@breidt.net)
-- Inspired by script from Borislav 'Bobo' Petrov (http://www.scriptspot.com/bobo/)
-- 
-- This code is released under "Quote ware" license:
--      If you use this tool in a production environment with a group of more than two people,
--      or have used it in the past under such conditions, then you are obliged to tell 
--      me (martin@breidt.net) about it and allow me to list that project title and your 
--      company name as a reference on my website http://scripts.breidt.net
--
-- This macroScript will toggle the display of a small local axis indicator for all
-- bone objects of the current scene.
-- 
-- Run the script, then install the macro 'showBoneAxis' from the category 'MB Tools'
-- into a toolbar, a quad menu, a hotkey or the menu bar
--
-- Known limitations: Axis icons will be drawn outside of the safeframe region

	global showBoneAxisEnabled
	if showBoneAxisEnabled == undefined then showBoneAxisEnabled = false

	fn drawBoneAxis = (
		gw.setTransform (matrix3 1)
		
		for obj in objects where obj.boneEnable do (
			local len = 10
			
			local m = obj.transform
			local o = m.translation

			local dx = [len,0,0] * m
			local dy = [0,len,0] * m
			local dz = [0,0,len] * m

			gw.setColor #line red
			gw.Polyline #(o,dx) false
			
			gw.setColor #line green
			gw.Polyline #(o,dy) false
		
			gw.setColor #line blue
			gw.Polyline #(o,dz) false
		) -- end: for obj
		
		gw.enlargeUpdateRect #whole
		gw.updateScreen()
	) -- end: fn drawLocalAxis 

	on isChecked return showBoneAxisEnabled

	on execute do (
		showBoneAxisEnabled = not showBoneAxisEnabled
		if showBoneAxisEnabled then 
			registerRedrawViewsCallback drawBoneAxis
		else
			unregisterRedrawViewsCallback drawBoneAxis
		max views redraw
	) -- end: on execute
	
) -- end: macroscript
