--------------------------------------------------------------------------------------------------------
						--pos to 0
--------------------------------------------------------------------------------------------------------

		for s in selection do 
			(
				if maxOps.pivotMode == #pivotOnly then  
					(
						s.pivot = [0,0,0]
						) else 
						(
							if iskindof s.transform.controller Link_Constraint ==true then 
								(
									
									num=s.transform.controller.getNumTargets()
									if num!=0 then 
										(
											for i=1 to num do 
												(
													if i+1 <= s.transform.controller.getNumTargets() then 
														(
															if currenttime<(s.transform.controller.getFrameNo (i+1)) do 
																(
																	try 
																		(
																			ro=s.rotation
																			sc=s.scale
																			s.transform=(s.transform.controller.getNode i).transform
																			po=s.pos
																			s.rotation=ro
																			s.pos=po
																			s.scale=sc
																			) catch 
																			(
																				s.pos=[0,0,0]
																				messagebox ("Error \n------------log:-----------\n"+(getCurrentException()))
																				)
																	exit
																	)
															) else 
															(
																try 
																	(
																			ro=s.rotation
																			sc=s.scale
																			s.transform=(s.transform.controller.getNode i).transform
																			po=s.pos
																			s.rotation=ro
																			s.pos=po
																			s.scale=sc
																		) catch 
																		(
																			s.pos=[0,0,0]
																			)
																)
													)
											) else 
											(
												print "5"
												s.pos=[0,0,0]
												)
									) else 
									(
										in coordsys parent 
											(
												s.pos=[0,0,0]
												)
										)
							)
				)
			redrawviews()
-- 		if maxOps.pivotMode == #pivotOnly then  
-- 			(
-- 				selection.pivot = [0,0,0]
-- 				) else 
-- 				(
-- 					in coordsys parent 
-- 						(
-- 							selection.pos=[0,0,0]
-- 							)
-- 					)
