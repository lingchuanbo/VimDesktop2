toBeDeleted = for obj in objects where (classOf obj == BoneGeometry ) collect obj

delete toBeDeleted
