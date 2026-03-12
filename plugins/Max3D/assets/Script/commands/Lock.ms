
if selection.count != 0 then (
	TransformLockFlagsArray = (getTransformLockFlags selection[1])
	if TransformLockFlagsArray.isEmpty
	then (
		setTransformLockFlags $ #all
		if selection.count > 1
		then (
			displayTempPrompt ("已锁定这一堆") 10000
			print ("已锁定这一堆")
		)
		else (
			displayTempPrompt ("已锁定 " + $.name) 10000
			print ("已锁定 " + $.name)
		)
				
	)
	else (
		setTransformLockFlags $ #none
		if selection.count > 1
		then (
			displayTempPrompt ("已解锁这一堆") 10000
			print ("已解锁这一堆")
		)
		else (
			displayTempPrompt ("已解锁 " + $.name) 10000
			print ("已解锁 " + $.name)
		)
	)
)
else (
	displayTempPrompt "未选择对象" 10000
	print "未选择对象"
)
