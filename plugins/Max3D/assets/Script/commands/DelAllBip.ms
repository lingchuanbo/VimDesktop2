toBeDeleted = for obj in objects where (classOf obj == Biped_Object ) collect obj

delete toBeDeleted
