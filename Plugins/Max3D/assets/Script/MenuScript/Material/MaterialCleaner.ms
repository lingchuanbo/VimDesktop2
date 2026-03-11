rollout materialcleaner "Material Cleaner" width:160 height:336
(
	materialButton btn_pickmat "Select Custom Material" pos:[16,64] width:128 height:40
	radiobuttons rdo_select "" pos:[8,8] width:147 height:32 labels:#("Selected Geometry", "All Geometry (incl. Hidden)")
	button btn_clearmats "Clear Materials" pos:[8,240] width:144 height:40
	button btn_clearmedit "Clear Material Editor" pos:[8,288] width:144 height:40
	GroupBox grp "Custom Material" pos:[8,48] width:144 height:184
	button btn_assign "Assign Custom Material" pos:[16,184] width:128 height:40
	spinner spn_matslot "Editor Slot" pos:[32,160] width:104 height:16 range:[1,24,0] type:#integer scale:1
	checkbox chk_mateditput "Put in Material Editor" pos:[24,136] width:120 height:16
	checkbox chk_fxmatte "Assign FX Matte" pos:[24,112] width:120 height:16
	
	on materialcleaner open do
	(
		spn_matslot.value = 1
	)
	
	on btn_pickmat picked mtl do
	(
		btn_pickmat.caption = btn_pickmat.material as string
	)
	
	on btn_clearmats pressed do
	(
		if rdo_select.state == 1 then
		(
			for obj in selection do
			(	
				obj.material = undefined
			)
		)
		else 
		(
			geometry.material = undefined
		)
	)
	
	on btn_clearmedit pressed do   --taken from ClearMedit by Remi / Diego / Michael Comet
	(
		undo on
		(
			animButtonState = false;
			
			MatEditor.Open()  --guess it only works if the mateditor is open...?
			
			-- First clear out all materials in there
			for i in 1 to 24 do
			(
				local matStd = standardMaterial();	 -- make a standard material up.
				local matNumber = i as string
				
				-- 1 digit
				if (i < 10) then matNumber = "0" + matNumber 
				
				matStd.name = (matNumber + " - Default");
				meditmaterials[i] = matStd
			)
				
			slotcount = 1;
				
			medit.UpdateMtlEditorBrackets();		-- we need to do this sometimes...sigh.
																-- such as if the selected slot doesn't have a material from the
																-- selected objects...it won't "refresh" unless we move something
																-- or call this...
		)
	
	)
	
		on chk_fxmatte changed state do
	(
		if chk_fxmatte.state == true then btn_assign.caption = "Assign Fx Matte"
		else btn_assign.caption = "Assign Custom Material"
	)
	
	on btn_assign pressed do
	(	
		if rdo_select.state == 1 then
		(
			for obj in selection where superclassof obj == GeometryClass do 
			(	
				if chk_fxmatte.state == true then
				(
					tempMaterial=matteShadow()
					TempMaterial.applyAtmosphere = on
					TempMaterial.AtmosphereDepth = 1
					TempMaterial.AffectAlpha = off
					TempMaterial.receiveshadows = off
					TempMaterial.name = "FX_Matte"
					obj.material = tempmaterial
				)
				
				else	
				(
					obj.material = btn_pickmat.material
				)
				
				if chk_mateditput.state == true then
				( 
					if chk_fxmatte.state == true then 
					(
						setMeditMaterial spn_matslot.value tempmaterial
					)
					else 
					(
						setMeditMaterial spn_matslot.value btn_pickmat.material
					)
				)	
			)
		)
		
		else 
		(
			if chk_fxmatte.state == true then
				(
					tempMaterial=matteShadow()
					TempMaterial.applyAtmosphere = on
					TempMaterial.AtmosphereDepth = 1
					TempMaterial.AffectAlpha = off
					TempMaterial.receiveshadows = off
					TempMaterial.name = "FX_Matte"
					geometry.material = tempmaterial
				)
			else
			(
				geometry.material = btn_pickmat.material
			)
			if chk_mateditput.state == true then
				( 
					setMeditMaterial spn_matslot.value btn_pickmat.material
				)	
		)
	)
)

createdialog MaterialCleaner