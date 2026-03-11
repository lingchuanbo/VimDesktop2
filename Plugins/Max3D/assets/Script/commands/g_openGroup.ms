					--try (
					
					sel = getcurrentselection() 
					

					for i = 1 to sel.count do (
						
						
						dada = classof sel[i]
						bo = sel[i].baseObject

						--print dada
						
							if dada == Dummy then (

							
								if isGroupHead sel[i] then (
									
									--print (isGroupHead sel[i])
									
									
									--if alles == 0 then (
									--actionMan.executeAction 0 "40141"  -- Groups: Ungroup
										
									--) else (
									setGroupOpen sel[i] true
									--	)
										
									
									
								)					
							)		
						) 
				
						--) catch()