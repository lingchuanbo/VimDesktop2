png2ico.exe -i "png" -o "png" -s 256 32bpp -noconfirm
XCOPY "png\*.ico" ".\ico\" /S /E /C /H /Q /Y
DEL  "png\*.ico"  /F /Q /S
DEL  "png\*.png"  /F /Q /S

