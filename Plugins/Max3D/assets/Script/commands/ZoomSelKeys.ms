--------------------------------------------------------------------------------------------------------
						--ZoomSelKeys
--------------------------------------------------------------------------------------------------------
global key_arr=#()

struct adder
	(
		fn map t = 
			(
				appendifunique key_arr t
				return t
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
					animationRange = interval key_arr[1] key_arr[key_arr.count]
-- 					messagebox ""
					) else 
					(
						animationRange = interval key_arr[1] (key_arr[key_arr.count]+1)
						)
			)

	)

