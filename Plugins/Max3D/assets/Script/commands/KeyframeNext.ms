--------------------------------------------------------------------------------------------------------
						--KeyframeNext
--------------------------------------------------------------------------------------------------------

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
			for i=1 to key_arr.count do 
				(
					if sliderTime<key_arr[1] then  
						(
							try 
								(
									sliderTime=key_arr[1]
									) catch ()
							exit
							) else 
							(
								if i+1<=key_arr.count do
									(
										if sliderTime>=key_arr[i] and sliderTime<key_arr[i+1] do 
											(
												sliderTime=key_arr[i+1]
												exit
												)
										)
								if i==key_arr.count do 
									(
										sliderTime=key_arr[1]
										)
								)

					)
			)
		)
