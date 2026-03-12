--------------- close Groups -----
					
					sel = getcurrentselection() 


					for i = 1 to sel.count do (
						
						
						dada = classof sel[i]
						bo = sel[i].baseObject

						
							if dada == Dummy then (

							
								if isGroupHead sel[i] then (
									setGroupOpen sel[i] false
								)					
							)		
						) 
						
					----------------------------------
					
					--try (
					
					sel = getcurrentselection() 
					

					for i = 1 to sel.count do (
						
						
						dada = classof sel[i]
						bo = sel[i].baseObject
						
							if dada == Dummy then (

							
								if isGroupHead sel[i] then (
									
									--actionMan.executeAction 0 "40141"  -- Groups: Ungroup

										
									unGroup sel[i]
									
								)					
							)		
						) 
				
						--) catch()