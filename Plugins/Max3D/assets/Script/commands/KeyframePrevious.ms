
 global key_arr=#()

struct adder_step_next
	(
		fn map t = 
			(
				if t>=animationRange.start and t<=animationRange.end do 
					(
						appendifunique key_arr t
						)
				return t
				)
		)

if selection.count!=0 do 
	(
		for i in selection do 
			(
				mapKeys i (adder_step_next ()) 
				)
				
		if key_arr.count!=0 do
		(
			sort key_arr
			key_arr=makeUniqueArray key_arr
			for i=key_arr.count to 1 by -1 do 
				(
					if sliderTime>key_arr[key_arr.count] then
						(
							print "asdff"
							try 
								(
									sliderTime=key_arr[key_arr.count]
									exit
									) catch ()
							) else 
							(
								if i-1>=1 do
									(
										if sliderTime>key_arr[i-1] and sliderTime<=key_arr[i] do 
											(
												sliderTime=key_arr[i-1]
												exit
												)
										)
								if i==1 do 
									(
										sliderTime=key_arr[key_arr.count]
										)
						)
				)
		)
)
