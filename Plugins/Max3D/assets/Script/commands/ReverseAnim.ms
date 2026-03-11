------------------------------------------------------------------------------------------------------
-- 						--ReverseAnim
------------------------------------------------------------------------------------------------------
global key_arr=#()

struct adder
	(
		fn map t = 
			(
				appendifunique key_arr t
				return t
				)
		)

struct scaler
	(
		scale,
		
		fn map t = 
			(
				return t * scale
				)
		)
		
if selection.count!=0 do 
	(
		for i in selection do 
			(
				mapKeys i (adder ()) #selection
				)
		sort key_arr

		if key_arr.count==0 then 
			(
				selectKeys selection
				for i in selection do 
					(
						mapKeys i (adder ()) #selection
						)
				sort key_arr
				)
				
		key_arr=makeuniquearray key_arr
		if key_arr.count!=0 do
		(
			if key_arr[1]!=key_arr[key_arr.count] then 
				(
					for i in selection do 
						(
							mapKeys i (scaler scale:-1) #selection
							)
					for i in selection do 
						(
							movekeys i (key_arr[1]*2+(key_arr[key_arr.count]-key_arr[1])) #selection
							)
					) else 
					(
						
						)
			)
							
	)
