
		for s in selection do 
			(
				if maxOps.pivotMode == #pivotOnly then  
					(
						s.pivot = [0,0,0]
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
																			s.transform=(s.transform.controller.getNode i).transform
																			) catch 
																			(
																				s.transform=matrix3 1
																				)
																	exit
																	)
															) else 
															(
																try 
																	(
																		s.transform=(s.transform.controller.getNode i).transform
																		) catch 
																		(
																			s.transform=matrix3 1
																			)
																)
													)
											) else 
											(
												s.transform=matrix3 1
												)
									) else 
									(
										if s.parent!=undefined then 
											(
												s.transform=s.parent.transform 
												) else 
												(
													s.transform=matrix3 1
													)
										)
							)
				)
		redrawviews()