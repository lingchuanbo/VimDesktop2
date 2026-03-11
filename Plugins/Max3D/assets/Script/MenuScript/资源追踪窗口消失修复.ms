fn showAssetTracking =
(

   if ATSOps != undefined then
   (
      ATSOps.Visible = false
      local maxIni = getMAXIniFile()
      ATpos = "0 0 800 600"
      setINISetting maxIni "WindowState" "ATSPosProto" ATpos
      ATSOps.Visible = true
   )
   OK
)

showAssetTracking()