
global rot = eulerToQuat(eulerAngles 90 0 0)
function Y_UP obj =
(
   Select obj
   ResetXForm obj
   modPanel.addModToSelection (XForm ()) ui:on

   obj.modifiers[#XForm].gizmo.rotation += rot as quat

   rotate obj (inverse rot as quat)

   -- for obj in (selection as array) do ( convertToPoly obj)  
)

selectedObjects = getCurrentSelection()

if selectedObjects.count > 0 then for obj in selectedObjects do Y_UP obj

else Messagebox "No object selected" title: "Unity Tool"