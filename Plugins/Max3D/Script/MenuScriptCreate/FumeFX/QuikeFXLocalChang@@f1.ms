fn replaceSub str1 str2 str3=(
    while ((i=findstring str1 str2) != undefined) do
    (
        str1 = replace str1 i str2.count str3
    )
    return str1
)


str=maxfilename

strName=replaceSub str ".max" ""

outPutDir=maxfilepath +"f1_FumeFXdate"
-- 创建文件夹
-- makeDir outPutDir
if selection.count==0 
	then messagebox "请选择FumeFX操作"
else
(
	makeDir(outPutDir+"\\"+"default")all:true
    makeDir(outPutDir+"\\"+"wavelet")all:true
    makeDir(outPutDir+"\\"+"retimer")all:true
    makeDir(outPutDir+"\\"+"illummap")all:true

	setPathDefault=outPutDir+"\\"+"default"+"\\a.fxd"
    setPathWavelet=outPutDir+"\\"+"wavelet"+"\\a.fxd"
    setPathRetimer=outPutDir+"\\"+"retimer"+"\\a.fxd"
    setPathIllummap=outPutDir+"\\"+"illummap"+"\\a.fxd"
	
	for obj in selection do
	(
		obj.SetPath setPathDefault #("default", "nocheck")
		obj.SetPath setPathWavelet #("wavelet", "nocheck")
		obj.SetPath setPathRetimer #("retimer", "nocheck")
		obj.SetPath setPathIllummap #("illummap", "nocheck")
	)
)



