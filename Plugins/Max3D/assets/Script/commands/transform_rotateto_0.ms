
		for s in selection do 
			(
				if maxOps.pivotMode == #pivotOnly then  
					(
						WorldAlignPivot s
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
																			po=s.pos
																			in coordsys (s.transform.controller.getNode i)
																				(
																					s.rotation=eulerangles 0 0 0
																					)
																			s.pos=po
																			) catch 
																			(
																				po=s.pos
																				in coordsys world
																					(
																						s.rotation=eulerangles 0 0 0
																						)
																				s.pos=po
																				)
																	exit
																	)
															) else 
															(
																try 
																	(
																		po=s.pos
																		in coordsys (s.transform.controller.getNode i)
																			(
																				s.rotation=eulerangles 0 0 0
																				)
																		s.pos=po
																		) catch 
																		(
																			po=s.pos
																			in coordsys world
																				(
																					s.rotation=eulerangles 0 0 0
																					)
																			s.pos=po
																			)
																)
													)
											) else 
											(
												po=s.pos
												in coordsys world
													(
														s.rotation=eulerangles 0 0 0
														)
												s.pos=po
												)
									) else 
									(
										po=s.pos
										in coordsys parent
											(
												s.rotation=eulerangles 0 0 0
												)
										s.pos=po
										)
							)
				)
			redrawviews()