-- mb_collapse v0.3 - (c) 2003-07 M. Breidt (martin@breidt.net)
-- Macro for 3ds Max 4-9, to be assigned as shortcut, quad menu entry or toolbar icon
--
-- This code is released under "Quote ware" license:
--      If you use this tool in a production environment with a group of more than two people,
--      or have used it in the past under such conditions, then you are obliged to tell 
--      me (martin@breidt.net) about it and allow me to list that project title and your 
--      company name as a reference on my website http://scripts.breidt.net
--
-- Just select one or more animated objects and invoke macro.
-- This will collapse position, rotation and scale of all selected objects into 
-- keyframes for the current time range so that afterwards, there will be one 
-- keyframe per frame, and the object's PRS controllers will be default. 
-- Linked objects will be unlinked afterwards with the motion resulting from the 
-- link collapsed into their own motion. Grouped objects will remain in their groups.
-- This macro is in addition to the standard Motion > Trajectories > Collapse Tool 
-- since this does not work well with linked objects, for example.
--
-- Changes in 0.3: 
--      When SHIFT is pressed, a full viewport update is enforced to ensure that all controllers are updated. This
--      can be necessary when baking complex animation created from scripted controllers, for example. The script
--      will run much slower and redraw everything for each selected object but this will ensure correct updating 
--      of any transformations.

--macroscript mb_collapse category:"MB Tools" buttonText:"MB Collapse"
--toolTip:"Collapse Transformations - hold SHIFT to force viewport update"
(
	on isEnabled do return $selection.count > 0

	on execute do (
		local forceUpdate = keyboard.shiftPressed -- if SHIFT is pressed when the macro is called, a viewport redraw is enforced for each timestep to ensure a full update of all controllers
		if forceUpdate then format "MB Collapse: Enforcing full viewport update. This might be slow but will ensure proper updating of all controllers\n"
		
		objlist = $selection as array
		for bake_obj in objlist do (	-- for every select object do
			format "MB Collapse: Collapsing transformation of object %\n" bake_obj.name
			local p = undefined
			local old_prs_ctrl = copy bake_obj.transform.controller		-- store old controller for catch()
			with undo on (
				if not forceUpdate then disableSceneRedraw();	-- not using redraw context for max4 compatibility
				-- disableSceneRedraw is problematic as not all scripted controllers are updated!
				try (
					p = Point()			-- create temp point object
					-- copy global transform of source object into temp object
					for i = animationRange.start to animationRange.end do (
						if forceUpdate then sliderTime = i	-- set slider time to force a global update of all animation data
						at time i (
							with animate on p.transform = bake_obj.transform
						)
					)
					-- kill old transform controller and assign new, clean one
					bake_obj.transform.controller = transform_script()	
					bake_obj.transform.controller = prs()	
					
					if not (isGroupMember bake_obj) then bake_obj.parent = undefined	-- unlink if not in a group
					-- copy temp object animation back into source object
					for i = animationRange.start to animationRange.end do (
						at time i (
							with animate on	bake_obj.transform = p.transform
						)
					)
					delete p			-- delete temp point obj
					p = undefined
					if not forceUpdate then enableSceneRedraw()
				) catch (
					format "MB Collapse: Fatal error - exiting\n"
					if p!=undefined then delete p
					bake_obj.transform.controller = old_prs_ctrl
					if not forceUpdate then enableSceneRedraw()
				) -- catch 
			) -- with undo on
		) -- for bake_obj in...
		if objlist.count == 0 then (
			format "MB Collapse: No object selected\n"
		)
	) -- on execute
) -- macroscript
