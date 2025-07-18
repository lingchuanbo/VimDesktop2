(
	fn DetachAllFaces obj =
	(
		if classof obj == editable_poly do
		(
			local nf=obj.numfaces
			while nf !=0 do
			(
				local newObjName=uniquename (obj.name+"_00")
				polyop.detachFaces obj #(nf) delete:true asNode:true name:newObjName
				centerpivot (getnodebyname newObjName)
				nf=obj.numfaces
			)
		)
	)
objs=for o in selection collect o
selcnt=objs.count
 
for i=1 to selcnt do
(
	convertTo objs[i] Editable_Poly
	DetachAllFaces objs[i]
	delete objs[i]
)
)
