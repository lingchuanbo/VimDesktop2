/*
    函数: HasValue
    作用: 检查数组中是否包含指定值
    参数: 
        - haystack: 要搜索的数组
        - needle: 要查找的值
    返回: 如果找到则返回true，否则返回false
    作者: BoBO
    版本: 1.0
    AHK版本: 2.0
*/
HasValue(haystack, needle) {
    if !IsObject(haystack)
        return false
    
    for index, value in haystack {
        if (value = needle)
            return true
    }
    return false
}