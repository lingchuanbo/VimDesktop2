-- 按 层渲染输出

-- BoBO

useEnvironmentMap = off --去掉环境贴图

rendAtmosphere = on --打开大气效果

rendSaveFile =on --打开保存选项

scanlineRender.antiAliasFilter =Catmull_Rom()


fn replaceSub str1 str2 str3=(
    while ((i=findstring str1 str2) != undefined) do
    (
        str1 = replace str1 i str2.count str3
    )
    return str1
)
layername=layermanager.current.name

theName = "10000"
Prefix = ".tga"
str=maxfilename
strName=replaceSub str ".max" ""
outPutDir=maxfilepath + strName+"_RenderOut" + "\\" + layername 
-- 创建文件夹
makeDir outPutDir
print outPutDir
outPutFiledir =  outPutDir + "\\" + theName + Prefix 
rendOutputFileName = outPutFiledir
actionMan.executeAction 0 "50031"  -- Render: Render
