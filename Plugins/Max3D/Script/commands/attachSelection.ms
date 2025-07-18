-- while (getcurrentselection()).count > 1 do meshop.attach (converttomesh $[1]) $[2] attachMat:#IDToMat condenseMat:true


(
	--This script created by Morozov Anton
	-- Create emty Editable Poly and attach selected objects
try destroyDialog Quick_Attach catch()
seq = 300 -- how many objectts add to one part
struct objectsByMtl (mtl, objarr)

fn attachMashes arr seq =
(
	if arr.count <= 1 do return arr
	while arr.count > 1 do 
	(
		local count = 0
		local meshes=#()
		if Quick_Attach.rdo1.state == 3 then
			local b = splineShape()
		else
			local b = Editable_Mesh()
		if Quick_Attach.rdo1.state == 1 do convertTo b Editable_Poly
		b.name = arr[1].name
		append meshes b
		precents = 0 as float
		for i = 1 to arr.count do
		(
			count += 1
			if count >= seq do (
				count = 0
				if Quick_Attach.rdo1.state == 3 then
					b = splineShape()
				else
					b = Editable_Mesh()
				if Quick_Attach.rdo1.state == 1 do convertTo b Editable_Poly
				b.name = arr[i].name
				append meshes b
				precents = 1000/(arr.count*10 / i)
				Quick_Attach.pb1.value = precents
				gc()
				if (((maxVersion())[1] / 1000) >= 13) do windows.processPostedMessages() 
				if  (keyboard.EscPressed) and (queryBox "you want to abort the Quick_Attach?") then return b
			)
			if (Quick_Attach.rdo1.state == 3) and (IsValidNode (arr[i])) and (SuperClassOf (arr[i]) == Shape) do
				(
					convertTo arr[i] SplineShape
					addandweld b arr[i] -1
					continue
				)
			if (SuperClassOf (arr[i]) == GeometryClass) and (IsValidNode (arr[i])) then (
				case Quick_Attach.rdo1.state of (
					1: polyop.attach b arr[i]
					2: meshop.attach b arr[i] attachMat:#IDToMat condenseMat:true deleteSourceNode:true
				)
			) else 
			(
				if (Quick_Attach.chk1.checked) and (SuperClassOf (arr[i]) == Shape) and (arr[i].render_renderable) and (IsValidNode (arr[i])) do 
				(
					arr[i].render_displayRenderMesh = true
					case Quick_Attach.rdo1.state of (
						1: polyop.attach b arr[i]
						2: meshop.attach b arr[i] attachMat:#IDToMat condenseMat:true deleteSourceNode:true
					)
				)
			)
		)
	arr = meshes
	)
	b = meshes[1]
	mymax = b.max
	mymin = b.min
	b.pivot = [(mymax.x+mymin.x)/2, (mymax.y+mymin.y)/2, (mymax.z+mymin.z)/2]
	Quick_Attach.pb1.value = 0
	b
)

fn devidebymtl arr seq =
(
	mtlArr = #()
	ObjByMats = #()
	for obj in arr do
	(
		i = findItem mtlArr obj.material
		if i == 0 do 
		(
			append mtlArr (obj.material)
			append ObjByMats #(obj)
		)
		if i > 0 do append ObjByMats[i] obj
	)
	for i=1 to ObjByMats.count do 
	(
		b = attachMashes ObjByMats[i] seq
		if mtlArr[i] != undefined and b != undefined do b.name = mtlArr[i].name
	)
	messagebox ("Attach is done. Create "+ObjByMats.count as string+" objects")
)

function attachAll =
(
	if selection.count != 0 then (
	seq = Quick_Attach.spn1.value
	meshes = (selection as array)
	clearSelection()
	case Quick_Attach.attach_methods.state of (
		1: (
			b = attachMashes meshes seq
			select b
			messagebox ("Attach is done")
		)
		2: devidebymtl meshes seq
	)
	free meshes;
	b
	) else messagebox ("select objects first")
)

rollout Quick_Attach "Quick Attach v1.82" width:176 height:489
(
	button 'bt_attach' "Attach" pos:[39,247] width:96 height:29 toolTip:"all selected items will be combined to Editable poly" align:#left
	button 'bt_specify' "Specify" pos:[43,362] width:96 height:19 toolTip:"Edit normals object to Specify" align:#left
	progressBar 'pb1' "" pos:[8,473] width:163 height:8 align:#left
	label 'lbl1' "Selected objects:" pos:[8,8] width:160 height:16 align:#left
	label 'lbl2' "0" pos:[8,24] width:160 height:16 align:#left
	label 'lbl9' "To abort operation - hold Escape. You can not undo if selected more than objects in one part" pos:[8,282] width:162 height:54 align:#left
	label 'lbl10' "Object to be converted to Editable poly" pos:[17,421] width:128 height:32 align:#left
	checkbox 'chk1' "include renderable shapes" pos:[8,173] width:146 height:18 checked:false align:#left
	GroupBox 'grp1' "Normals" pos:[10,339] width:158 height:119 align:#left
	button 'bt_reset' "Reset" pos:[43,397] width:96 height:19 toolTip:"Reset normals" align:#left
	radiobuttons 'rdo1' "Create:" pos:[24,41] width:104 height:62 labels:#("Editable Poly", "Editable Mesh", "Splines / Shapes") columns:1 align:#left
	spinner 'spn1' "" pos:[6,205] width:62 height:16 enabled:true range:[1,10000,0] type:#integer align:#left
	label 'lbl11' "Objects in one part" pos:[72,205] width:101 height:17 align:#left
	label 'lbl19' "(reduce, if not enough memory)" pos:[8,221] width:155 height:17 align:#left
	radiobuttons 'attach_methods' "Attach methods:" pos:[24,109] width:109 height:46 labels:#("all in one mesh", "devide by Material") columns:1 align:#left
	on Quick_Attach open do
	(	
		spn1.value = seq
	)
	on bt_attach pressed do
	(
		undo "Quick_Attach" on (
			b = attachAll()
		)
		lbl2.caption = selection.count as string
	)
	on bt_specify pressed do
	(
		if selection.count == 1 then (
		b = selection[1]
		if (SuperClassOf (b) == GeometryClass) then (
		undo "Quick_Attach" on (
		if (ClassOf (b) != Editable_Poly) do convertTo b Editable_Poly
		modPanel.addModToSelection (Edit_Normals ()) ui:on
		normcount = b.edit_normals.EditNormalsMod.GetNumNormals ()
		b.edit_normals.EditNormalsMod.SetSelection #{1..normcount}
		b.edit_normals.EditNormalsMod.Specify ()
		subobjectLevel = 0
		maxOps.CollapseNodeTo $ 1 true
		)
		) else messagebox ("Selection is not geometry")
		) else messagebox ("pleas select 1 object")
	)
	on bt_reset pressed do
	(
			if selection.count == 1 then (
		b = selection[1]
		if (SuperClassOf (b) == GeometryClass) then (
		undo "Quick_Attach" on (
		if (ClassOf (b) != Editable_Poly) do convertTo b Editable_Poly
		modPanel.addModToSelection (Edit_Normals ()) ui:on
		normcount = b.edit_normals.EditNormalsMod.GetNumNormals ()
		b.edit_normals.EditNormalsMod.SetSelection #{1..normcount}
		b.edit_normals.EditNormalsMod.Reset ()
		subobjectLevel = 0
		maxOps.CollapseNodeTo $ 1 true
		)
		) else messagebox ("Selection is not geometry")
		) else messagebox ("pleas select 1 object")
	)
	on rdo1 changed stat do
	(
		if rdo1.state == 3 then	(attach_methods.enabled = false; chk1.enabled = false)
		else (attach_methods.enabled = true; chk1.enabled = true)
	)
)

if selection.count != 0 then (
	createDialog Quick_Attach;
	Quick_Attach.lbl2.caption = selection.count as string
	) else messagebox ("first select objects")
)
