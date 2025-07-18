-- -- 删除 vfx_ 开头的所有对象

toBeDeleted = for obj in objects where (matchPattern obj.name pattern:"vfx_*") collect obj

delete toBeDeleted

