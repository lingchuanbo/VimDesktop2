-- 参考ObjectRename
-- temp_name= maxFileName
-- numberofMax = findString temp_name ".max"
-- objName=replace temp_name numberofMax 4 ""
if maxFileName !="" then
(
	global temp_name= maxFileName
	global numberofMax = findString temp_name ".max"
if numberofMax !=undefined then
(
	global nameOfFile=replace temp_name numberofMax 4 ""
	global objName =replace temp_name numberofMax 4 ""
    objNumber = 0
    increment = 1 --间隔
    if selection.count == 1 then
    (
        for obj in selection do
        (
            renameString = objName + "_"

            numberString = objNumber as string
                            
            numberStringLength = "000"
                            
            if numberStringLength == 1 then
                (
                    if objNumber <10 and objNumber >= 0 then numberString = "0" + numberString
                )
                else
                    (
            if objNumber <10 and objNumber >= 0 then numberString = "00" + numberString
                        else if objNumber <100 and objNumber >= 10 then numberString = "0" + numberString
                    )
        (
                if objNumber <100 and objNumber >= 10 then numberString = "" + numberString
                )
            
            renameString += numberString
            obj.name = objName
            --objNumber += increment
        )
    )
    if selection.count >= 2 then
    (
        for obj in selection do
        (
            renameString = objName + "_"
    
            numberString = objNumber as string
                            
            numberStringLength = "000"
                            
            if numberStringLength == 1 then
                (
                    if objNumber <10 and objNumber >= 0 then numberString = "0" + numberString
                )
                else
                    (
            if objNumber <10 and objNumber >= 0 then numberString = "00" + numberString
                        else if objNumber <100 and objNumber >= 10 then numberString = "0" + numberString
                    )
        (
                if objNumber <100 and objNumber >= 10 then numberString = "" + numberString
                )
            
            renameString += numberString
            obj.name = renameString
            objNumber += increment
        )
    )
    actionMan.executeAction 0 "40021"  -- Selection: Select Al
)
)else(
	global nameOfFile = ""
    messagebox "请先保存文件!"
)					
