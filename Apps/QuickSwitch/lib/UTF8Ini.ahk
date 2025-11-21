;===========================================================
; UTF8Ini.ahk - UTF-8兼容的INI文件读写函数
;===========================================================

UTF8IniRead(iniFile, section, key, defaultValue := "") {
    ; 读取整个INI文件内容（UTF-8编码）
    iniContent := FileRead(iniFile, "UTF-8")

    ; 查找指定section
    sectionPattern := "\[" . section . "\][\s\S]*?(?=\n\[|\Z)"
    if !RegExMatch(iniContent, sectionPattern, &sectionMatch) {
        return defaultValue
    }

    ; 获取section内容字符串
    sectionContent := sectionMatch[]

    ; 在section中查找指定key
    keyPattern := "^\s*" . key . "\s*=\s*(.*?)\s*$"
    if RegExMatch(sectionContent, "m)" . keyPattern, &keyMatch) {
        return keyMatch[1]
    }

    return defaultValue
}

UTF8IniWrite(value, iniFile, section, key) {
    ; 读取整个INI文件内容（UTF-8编码）
    iniContent := FileRead(iniFile, "UTF-8")

    ; 构建新的键值对
    newLine := key . "=" . value

    ; 查找指定section
    sectionPattern := "(\[" . section . "\][\s\S]*?)(?=\n\[|\Z)"
    if RegExMatch(iniContent, sectionPattern, &sectionMatch) {
        ; 获取section内容字符串
        sectionContent := sectionMatch[]

        ; 检查key是否已存在
        keyPattern := "^\s*" . key . "\s*=.*$"
        if RegExMatch(sectionContent, "m)" . keyPattern, &keyMatch) {
            ; 替换现有的key
            newSectionContent := RegExReplace(sectionContent, "m)^\s*" . key . "\s*=.*$", newLine)
            newContent := RegExReplace(iniContent, sectionPattern, newSectionContent)
        } else {
            ; 在section末尾添加新的key
            newSectionContent := sectionContent . "`n" . newLine
            newContent := RegExReplace(iniContent, sectionPattern, newSectionContent)
        }
    } else {
        ; section不存在，创建新的section
        newContent := iniContent . "`n`n[" . section . "]`n" . newLine
    }

    ; 写入更新后的内容（UTF-8编码）
    FileDelete(iniFile)
    FileAppend(newContent, iniFile, "UTF-8")
}

UTF8IniDelete(iniFile, section, key := "") {
    ; 读取整个INI文件内容（UTF-8编码）
    iniContent := FileRead(iniFile, "UTF-8")

    if (key = "") {
        ; 删除整个section
        sectionPattern := "\[" . section . "\][\s\S]*?(?=\n\[|\Z)"
        newContent := RegExReplace(iniContent, sectionPattern, "")
    } else {
        ; 删除指定section中的指定key
        sectionPattern := "(\[" . section . "\][\s\S]*?)(?=\n\[|\Z)"
        if RegExMatch(iniContent, sectionPattern, &sectionMatch) {
            ; 获取section内容字符串
            sectionContent := sectionMatch[]

            ; 删除指定的key
            keyPattern := "^\s*" . key . "\s*=.*$\n?"
            newSectionContent := RegExReplace(sectionContent, "m)" . keyPattern, "")

            ; 替换回原内容
            newContent := RegExReplace(iniContent, sectionPattern, newSectionContent)
        } else {
            ; section不存在，无需删除
            return
        }
    }

    ; 写入更新后的内容（UTF-8编码）
    FileDelete(iniFile)
    FileAppend(newContent, iniFile, "UTF-8")
}
