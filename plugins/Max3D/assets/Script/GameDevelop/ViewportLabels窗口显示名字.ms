-- mbViewportLabels v0.17 for 3ds Max 9-2023 // 07.-08.07.2021 - 2022
-- (c) Martin Breidt (martin@breidt.net)
--
-- This code is released under "Quote ware" license:
--      If you use this tool in a production environment with a group of more than two people,
--      or have used it in the past under such conditions, then you are obliged to tell 
--      me (martin@breidt.net) about it and allow me to list that project title and your 
--      company name as a reference on my website http://scripts.breidt.net
--
-- mbViewportLabels will allow you to attach viewport text labels to any scene object.
-- Just install as any other macroscript (look in "MB Tools" category). 
-- Then either select the nodes to be labeled and run the script, or just run it without a 
-- selection and use the node selection dialog.
-- Afterwards, each node will have a new rollout (go to Modify panel to see it) which 
-- controls how the label is displayed in the viewport (text color, text placement...).
-- Since the label is implemented as Custom Attribute, it will travel with the scene, no
-- additional scripts needed. Also works for merged and Xref'ed objects.
-- 
-- To edit many labels at once, you can use MAXScript like this:
-- 		for o in selection do try ( o.mbViewportLabelCA.textColor = white) catch ()		-- change label colors for selected objects to white
-- 		for o in selection do try ( o.mbViewportLabelCA.showLabel = false) catch ()		-- turn off labels for selected objects
-- 		for o in selection do try ( o.mbViewportLabelCA.drawBG = true) catch ()			-- turn on label background color for selected objects
-- 		for i = 1 to selection.count do try ( o.mbViewportLabelCA.textLabel = (i as string) ) catch ()		-- assign numbers as labels
--
-- Known limitations:
-- * Instanced objects will share a label - not anymore in v0.15
-- * Modifier converts primitives to editable_mesh / SplineShape - known limitation of EmptyModifier
-- * Text labels will not render; this is by design. 
-- * Font size cannot be changed - this is a limitation of the viewport text drawing in 3ds Max.
-- * Might be SLOW for many (> 1000) object labels and/or large amounts of text?
-- * Does not work for Scene Xref (3ds Max limitation), use Object Xref instead
--
-- History:
-- v0.17: 	gamma correction, text background option, UI cleanup
-- v0.16: 	Bug fix in delete button 
-- v0.15: 	Reworked to apply as modifier 
-- v0.13: 	Added button to delete CA
-- v0.12: 	Added global ID for CA so it can be updated later
-- v0.11: 	added option to treat text label as MAXScript expression
-- v0.1: 	first beta release
--
-- To Do:


--macroScript mbViewportLabels
--category:"MB Tools" 
--buttonText:"mbViewportLabels" 
--toolTip:"Add viewport labels to selection"
(

	global mbViewportLabelCAFn				-- global var that holds the redraw callback function value
	global mbViewportLabelCAdef 			-- global var to hold the CA definition
	
	mbViewportLabelCAdef = attributes mbViewportLabelCA attribID:#(0x5711e62d, 0x77cf30eb) (

		fn mbRegisterViewportLabelCallback = (
			-- format "==== mbViewportLabel: Registering callback in global mbRegisterViewportLabelCallback...\n"
			global mbViewportLabelCAFn		-- make sure we have a global ref
			unregisterRedrawViewsCallback mbViewportLabelCAFn		-- try to unregister first, to avoid multiple callbacks
			
			-- (re)define global callback function 
			fn mbViewportLabelCAFn  = (
				-- this function will be called on each viewport redraw
				fn gammaCorrect colVal gamma:0.4545 = (
					color (((colVal.r/255.0)^gamma)*255.0) (((colVal.g/255.0)^gamma)*255.0) (((colVal.b/255.0)^gamma)*255.0) colVal.a
				)
			
				try (
					-- collect all scene nodes that carry our CA
					local allMyNodes = #()
					for o in objects where (not o.isHiddenInVpt) and (o.modifiers.count > 0) do (
						local theMod = undefined
						-- get the top-most EmptyModifier that carries our CA
						for m in o.modifiers where ( (classof m == EmptyModifier) and (isProperty m "mbViewportLabelCA") ) while (theMod==undefined) do theMod = m
						local myCA = undefined
						if (classOf theMod)==EmptyModifier then myCA = theMod.mbViewportLabelCA
						-- myCA = o.baseobject.custAttributes[#mbViewportLabelCA]
						if ( (myCA!=undefined) and (myCA.showLabel==true) and (myCA.textLabel!=udefined) ) then append allMyNodes #(o, myCA)
					)
					if allMyNodes.count > 0 then (
						local inv_vtm = inverse (getViewTM())						
						gw.setTransform (matrix3 1)
						for itm in allMyNodes do (
							local mypos = gw.wTransPoint itm[1].transform.pos		-- screen coords of object pivot
							
							-- compute world-space delta vector for text label as offset from object pivot
							local camShift = [itm[2].xOffset, itm[2].yOffset, 0] * inv_vtm					-- view-relative offset vector in world coordinates
							local shiftVec = camShift - inv_vtm.pos						-- delta vector (from view cam to offset), world coords							
							local textPos = gw.wTransPoint ( itm[1].pos + shiftVec )	-- screen coords of offsetted text
							
							-- shadow shift (w-coordinates, screen space)
							local dx = 0.2 
							local dy = 1 
							
							local lbl = itm[2].textlabel
							if itm[2].useMXS==true then (
								-- treat string as MAXScript and store result - somewhat dangerous!
								try (
									lbl = (execute lbl) as string
								) catch (
									lbl = "ERROR"
								)
							)
							local txtCol = (gammaCorrect itm[2].textColor)
							gw.wtext (textPos+[dx,dy,0]) lbl color:black applyUIScaling:true 	-- black shadow, slightly shifted down and right
							gw.wtext textPos lbl color:txtCol applyUIScaling:true

							if itm[2].drawLine==true then (
								gw.wMarker (mypos+[dx,dy,0]) #hollowBox color:black applyUIScaling:true
								gw.wMarker mypos #hollowBox color:txtCol applyUIScaling:true
								gw.setColor #line black
								gw.wPolyline #(mypos+[dx,dy,0], textpos+[dx,dy,0]) false applyUIScaling:true		-- line shadow
								gw.setColor #line txtCol
								gw.wPolyline #(mypos, textpos) false applyUIScaling:true
							)
							if itm[2].drawBG==true then (
								local margin = [10,10]	-- total margin for background box
								local txtDim = margin + (gw.getTextExtent lbl applyUIScaling:true)		-- 2D size of text
								local oneLineDim = gw.getTextExtent "Ay"								-- Size of one single line
								local txtBox = Box2 (textPos.x - margin.x/2.0) (textPos.y - oneLineDim.y + 3 - margin.y/2.0) txtDim.x txtDim.y
								local border = 1	-- width of black border
								local shadowBox = Box2 (textPos.x - margin.x/2.0 - border) (textPos.y - oneLineDim.y + 3 - margin.y/2.0 - border) (txtDim.x + 2*border) (txtDim.y + 2*border)
								gw.wRect shadowBox black applyUIScaling:true								
								local rectCol = (gammaCorrect itm[2].backColor)
								gw.wRect txtBox rectCol applyUIScaling:true
							) 
						)
						gw.enlargeUpdateRect #whole  
					)
				) catch (
					format "Error in mbViewportLabelCAFn: %\n" (getCurrentException())
				)
			) -- end: fn mbViewportLabelCAFn		
			-- now (re)register redraw callback
			registerRedrawViewsCallback mbViewportLabelCAFn
		) -- end: fn mbRegisterViewportLabelCallback

		parameters mbPointHelperParam rollout:params (
			textLabel type:#string ui:txtBox
			showLabel type:#boolean ui:showChk default:false
			textColor type:#color ui:colPick default:(color 255 180 0)
			backColor type:#color ui:bgPick default:(color 32 32 32)
			xOffset type:#float default:10 ui:xShiftSpn
			yOffset type:#float default:10 ui:yShiftSpn
			drawLine type:#boolean ui:lineChk default:false 
			drawBG type:#boolean ui:bgChk default:false 
			useMXS type:#boolean ui:mxsChk default:false

			on textLabel postSet val do (
				showLabel=true
				val
			)
		)
		
		rollout params "mbViewportLabels" (
			label l1 "v0.17 - (c) 2022 Martin Breidt"
			edittext txtBox "" height:(2*17) width:160 offset:[-15,0] tooltip:"Text to display in viewport"
			checkbox showChk "On" offset:[-8,1] across:3 tooltip:"Turn viewport visibility on/off"
			checkbox lineChk "Line" offset:[-8,1] tooltip:"Draw a line between the pivot and the text label"
			checkbutton mxsChk "MXS" offset:[15,0] tooltip:"Evaluate text as MAXSript"
			
			colorpicker colPick "FG: " offset:[-5,0] across:3 width:50 modal:false tooltip:"Color of the viewport text label"
			checkbox bgChk "" offset:[20,2] tooltip:"Draw text label with solid background"
			colorpicker bgPick "BG: " offset:[0,0] width:50 modal:false tooltip:"Color of the viewport text label background"
			
			label l2 "Offset: " offset:[-10,0] across:3 tooltip:"2D text label displacement"
			spinner xShiftSpn "" range:[-10000,10000,0] width:55 offset:[-15,0] tooltip:"Horizontal shift"
			spinner yShiftSpn "" range:[-10000,10000,0] width:55 tooltip:"Vertical shift"
			button delBtn "Delete label" tooltip:"Permanently delete mbViewportLabels from this object"

			on delBtn pressed do (
				if selection.count > 0 then (
					local myObj = selection[1]
					if isValidNode myObj then (
						format "Deleting mbViewportLabels from %\n" myObj.name
						for m in myObj.modifiers where ( (classof m == EmptyModifier) and (isProperty m "mbViewportLabelCA") ) do (
							custAttributes.delete m mbViewportLabelCAdef
						)
						completeRedraw() 	-- make sure the label is gone immediately
					)
				) else format "Nothing selected, cannot remove CA\n"
			)
		)
				
		on postCreate do (
			-- format "on postCreate\n"
			mbRegisterViewportLabelCallback()
		)
		
		on postLoad do (
			-- format "on postLoad\n"
			mbRegisterViewportLabelCallback()
		)
		
		on deleted do (
			format "mbViewportLabel CA was deleted.\n"
		)
	) -- end: attributes
	
	on execute do (
		local targetNodes
		if selection.count > 0 then (
			targetNodes = selection as Array
		) else (
			targetNodes = selectByName title:"Select objects to add viewport labels to" buttonText:"Select" single:false
		)
		
		if targetNodes !=undefined then (
--			registerViewportLabelCallback()
			-- add CA to all nodes that do not have it already
			for o in targetNodes do (
				-- set up modifier to hold CA
				local theMod		-- the emptyModifier to add the CA to
				local allMods = for m in o.modifiers where classof m == EmptyModifier collect m
				if allMods.count>0 then (
					theMod=allMods[1] 
				) else ( 
					theMod=(emptyModifier name:"mbVieportLabels")
					addModifier o theMod
				)
				
				-- default parameter values
				local oldText = o.name		-- use node name as default label text
				local oldShow = true 
				local oldCol = (color 255 180 0)
				local oldBGCol = (color 32 32 32)
				local oldxOffset = 10
				local oldyOffset = 10
				local olddrawLine = true
				local olddrawBG = false
				
				if (isProperty theMod "mbViewportLabelCA") then (
					-- object already has our CA --> remove it, so we can re-apply
					format "Removing existing viewport label attribute from % - %\n" o.name theMod.name
					-- store old params
					try (
						oldText = o.mbViewportLabelCA.textLabel
						oldShow = o.mbViewportLabelCA.showLabel
						oldCol = o.mbViewportLabelCA.textColor
						oldBGCol = o.mbViewportLabelCA.backColor
						oldxOffset =  o.mbViewportLabelCA.xOffset
						oldyOffset = o.mbViewportLabelCA.yOffset
						olddrawLine = o.mbViewportLabelCA.drawLine
						olddrawBG = o.mbViewportLabelCA.drawBG
					) catch ()
					custAttributes.delete theMod mbViewportLabelCAdef
				)
				format "Adding viewport label modifier to %\n" o.name
				custAttributes.add theMod mbViewportLabelCAdef
				-- restore any old values or use defaults
				theMod.mbViewportLabelCA.textLabel = oldText 
				theMod.mbViewportLabelCA.showLabel = oldShow 
				theMod.mbViewportLabelCA.textColor = oldCol
				theMod.mbViewportLabelCA.backColor = oldBGCol
				theMod.mbViewportLabelCA.xOffset = oldxOffset 
				theMod.mbViewportLabelCA.yOffset = oldyOffset 
				theMod.mbViewportLabelCA.drawLine = olddrawLine 
				theMod.mbViewportLabelCA.drawBG = olddrawBG
			)
		) else (
			format "Nothing selected.\n"
		) -- end: if
	) -- end: on execute
)
