rendAtmosphere = on -- 打开大气效果
rendSaveFile = on -- 打开保存选项
rendSuperBlack = off
fn replaceSub str1 str2 str3 = 
(	
	while( ( i = findstring str1 str2 )!= undefined ) do
	(		
		str1 = replace str1 i str2.count str3
	)
	str1 = substituteString str1 "\\" " " -- 移除所有反斜杠
	return str1
)
fn getOutputDirByRotation rotation baseName = 
(	
	print( "Rotation: " + rotation as string )
	print( "Base Name: " + baseName )
	if( 0.0 < rotation and rotation < 10.0 ) then
	(		
		result = baseName + "6"
		print( "Output Dir result: " + result )
		return result
	)
	else
		if( -10.0 < rotation and rotation < 0.0 ) then
	(		
		result = baseName + "6"
		print( "Output Dir result: " + result )
		return result
	)
	else
		if( -50.0 < rotation and rotation < -40.0 ) then
	(		
		result = baseName + "5"
		print( "输出方向: " + result )
		return result
	)
	else
		if( -140.0 < rotation and rotation < -130.0 ) then
	(		
		result = baseName + "3"
		print( "输出方向: " + result )
		return result
	)
	else
		if( 175.0 < rotation and rotation < 185.0 ) then
	(		
		result = baseName + "2"
		print( "输出方向: " + result )
		return result
	)
	else
		if( -95.0 < rotation and rotation < -85.0 ) then
	(		
		result = baseName + "4"
		print( "输出方向: " + result )
		return result
	)
	else
		if( 0.0 < rotation and rotation < 50.0 ) then
	(		
		result = baseName + "7"
		print( "输出方向: " + result )
		return result
	)
	else
		if( 85.0 < rotation and rotation < 95 ) then
	(		
		result = baseName + "8"
		print( "输出方向: " + result )
		return result
	)
	else
		if( 100.0 < rotation and rotation < 140.0 ) then
	(		
		result = baseName + "1"
		print( "输出方向: " + result )
		return result
	)
	else
	(		
		print( "非方向按基本文件名: " + baseName )
		return baseName
	)
)
fn BaseDefOutputDir = 
(	
	theName = "10000"
	Prefix = ".tga"
	str = maxfilename
	strName = replaceSub str ".max" "" + "\\"
	outPutDir = maxfilepath + strName
	-- 创建文件夹
	makeDir outPutDir
	outPutFiledir = outPutDir + theName + Prefix
	rendOutputFileName = outPutFiledir
	actionMan.executeAction 0 "50031" -- Render: Render
)
try
(	
	selectedObjects = getCurrentSelection()
	if selectedObjects.count > 0 then
	(		
		for i in selectedObjects do
		(			
			theName = "10000"
			Prefix = ".tga"
			str = maxfilename
			strName = replaceSub str ".max" "" + "\\"
			filenames = replaceSub str ".max" ""
			print( "文件名: " + filenames )
			outPutDir = ""
			-- 特定虚拟体
			if i.name == "Point01" or i.name == "大" then
			(				
				getZR = i.rotation.z_rotation
				newDir = getOutputDirByRotation getZR filenames
				outPutDir = maxfilepath + newDir + "\\"
				print( "渲染输出目录: " + outPutDir )
			)
			else
			(				
				-- 如果不是特定方向，则按照文件名输出
				outPutDir = maxfilepath + strName
				print( "渲染输出目录: " + outPutDir )
			)
			-- 创建文件夹
			makeDir outPutDir
			outPutFiledir = outPutDir + theName + Prefix
			rendOutputFileName = outPutFiledir
			actionMan.executeAction 0 "50031" -- Render: Render
		)
	)
	else
	(		
		BaseDefOutputDir()
	)
)
catch
(	
	print "错误！！！."
)