/* EasyINI Class说明 - 内存优化版本
	作者: Kawvin (优化: Kiro)
	版本: 1.1.0 (Memory Optimized)
	日期: 2025-03-21
	说明: 用于读取和写入ini文件的类 - 内存优化版本
*/

class EasyIni
{
	__New(sFile:="", sLoadFromStr:="") { ; 内存优化版本
		; 直接设置属性，避免不必要的方法调用
		this.EasyIni_ReservedFor_m_sFile := sFile
		this.EasyIni_TopComments := []  ; 使用更轻量的数组字面量
		
		if (sFile == "" && sLoadFromStr == "")
			return this

		; 优化文件扩展名检查
		if (sFile != "" && !InStr(sFile, ".ini"))
			this.EasyIni_ReservedFor_m_sFile := sFile := sFile . ".ini"

		sIni := sLoadFromStr || FileRead(sFile)

		sCurSec := ""
		sPrevKeyForThisSec := ""
		
		Loop Parse, sIni, "`n", "`r"
		{
			line := A_LoopField
			trimmed := Trim(line)
			
			; 空行或注释处理 - 优化条件检查
			if (!trimmed || SubStr(trimmed, 1, 1) == ";") {
				processedLine := line || Chr(14)
				
				if (!sCurSec) {
					this.EasyIni_TopComments.Push(processedLine)
				} else if (processedLine != "" && processedLine != Chr(14)) {
					if (!sPrevKeyForThisSec) {
						; Section注释
						if (this.%sCurSec%.HasOwnProp("EasyIni_SectionComment"))
							this.%sCurSec%.EasyIni_SectionComment .= "`n" processedLine
						else
							this.%sCurSec%.EasyIni_SectionComment := processedLine
					} else {
						; Key注释 - 延迟创建Map
						if (!this.%sCurSec%.HasOwnProp("EasyIni_KeyComment"))
							this.%sCurSec%.EasyIni_KeyComment := Map()
						
						if (this.%sCurSec%.EasyIni_KeyComment.Has(sPrevKeyForThisSec))
							this.%sCurSec%.EasyIni_KeyComment[sPrevKeyForThisSec] .= "`n" processedLine
						else
							this.%sCurSec%.EasyIni_KeyComment[sPrevKeyForThisSec] := processedLine
					}
				}
				continue
			}
			
			; Section处理 - 优化正则匹配
			if (SubStr(trimmed, 1, 1) == "[" && (bracketPos := InStr(trimmed, "]"))) {
				sCurSec := SubStr(trimmed, 2, bracketPos - 2)
				if (sCurSec && !this.HasOwnProp(sCurSec))
					this.%sCurSec% := {}  ; 使用轻量对象字面量
				sPrevKeyForThisSec := ""
				continue
			}

			; Key=Value处理
			eqPos := InStr(trimmed, "=")
			if (eqPos) {
				key := Trim(SubStr(trimmed, 1, eqPos - 1))
				val := Trim(SubStr(trimmed, eqPos + 1))
				
				; 优化变量替换 - 只在需要时执行
				if (InStr(val, "%A_ScriptDir%"))
					val := StrReplace(val, "%A_ScriptDir%", A_ScriptDir)
				if (InStr(val, "%A_WorkingDir%"))
					val := StrReplace(val, "%A_WorkingDir%", A_ScriptDir)
				
				this.%sCurSec%.%key% := val
				sPrevKeyForThisSec := key
			} else {
				; 无值键
				this.%sCurSec%.%trimmed% := ""
				sPrevKeyForThisSec := trimmed
			}
		}
		
		; 处理空Section
		if (sCurSec && !this.HasOwnProp(sCurSec))
			this.%sCurSec% := {}
		
		return this
	}

	; 优化的辅助方法 - 减少内存占用
	_CreateSection(secName) {
		if (!this.HasOwnProp(secName))
			this.%secName% := {}
		return this.%secName%
	}

	; 添加字段 - 内存优化版本
	AddSection(sec, key:="", val:="", &rsError:="") {
		if (this.HasOwnProp(sec)) {
			rsError := "错误！无法添加新字段 [" sec "], 因为该字段已经存在。"
			return false
		}
		
		this.%sec% := {}
		if (key != "")
			this.%sec%.%key% := val
		return true
	}

	; 重命名字段 - 内存优化版本
	RenameSection(sOldSec, sNewSec, &rsError:="") {
		if (!this.HasOwnProp(sOldSec)) {
			rsError := "错误！无法重命名字段 [" sOldSec "], 因为该字段不存在。"
			return false
		}

		; 直接移动引用，避免复制
		this.%sNewSec% := this.%sOldSec%
		this.DeleteProp(sOldSec)
		return true
	}

	; 删除字段
	DeleteSection(sec) {
		this.DeleteProp(sec)
	}

	; 获取所有字段 - 优化版本
	GetSections(sDelim:="`n", sSort:="") {
		sections := []
		for sec in this.OwnProps() {
			if (sec != "EasyIni_TopComments" && sec != "EasyIni_ReservedFor_m_sFile")
				sections.Push(sec)
		}

		if (sSort) {
			; 使用内置排序，更高效
			if (sSort == "R")
				sections := sections.Clone().Reverse()
			else
				sections := sections.Clone().Sort()
		}

		return sections.Length ? sections.Join(sDelim) : ""
	}

	; 正则查找字段 - 优化版本
	FindSecs(sExp, iMaxSecs:="") {
		aSecs := []
		for sec in this.OwnProps() {
			if (sec != "EasyIni_TopComments" && sec != "EasyIni_ReservedFor_m_sFile") {
				if (RegExMatch(sec, sExp)) {
					aSecs.Push(sec)
					if (iMaxSecs && aSecs.Length == iMaxSecs)
						break
				}
			}
		}
		return aSecs
	}

	; 添加键值 - 优化版本
	AddKey(sec, key, val:="", &rsError:="") {
		if (!this.HasOwnProp(sec)) {
			rsError := "错误！无法添加键值, " key " 因为字段, " sec " 不存在。"
			return false
		}
		
		if (this.%sec%.HasOwnProp(key)) {
			rsError := "错误！无法添加键值, " key " 因为在已有键值在相同字段内:`n字段: " sec "`n键值: " key
			return false
		}
		
		this.%sec%.%key% := val
		return true
	}

	; 重命名键值
	RenameKey(sec, OldKey, NewKey, &rsError:="") {
		if (!this.%sec%.HasOwnProp(OldKey)) {
			rsError := "错误！特定键值 " OldKey " 不能被修改，因为不存在！"
			return false
		}

		this.%sec%.%NewKey% := this.%sec%.%OldKey%
		this.%sec%.DeleteProp(OldKey)
		return true
	}

	; 删除键值
	DeleteKey(sec, key) {
		this.%sec%.DeleteProp(key)
	}

	; 获取字段的所有键值 - 优化版本
	GetKeys(sec, sDelim:="`n", sSort:="", &rsError:="") {
		if (!this.HasOwnProp(sec)) {
			rsError := "错误！无法获取字段的键值，因为字段不存在。"
			return ""
		}
		
		keys := []
		for key in this.%sec%.OwnProps() {
			if (key != "EasyIni_KeyComment" && key != "EasyIni_SectionComment")
				keys.Push(key)
		}
		
		if (sSort) {
			if (sSort == "R")
				keys := keys.Clone().Reverse()
			else
				keys := keys.Clone().Sort()
		}
		
		return keys.Length ? keys.Join(sDelim) : ""
	}

	; 获取值 - 简化版本
	GetValue(sec, key) {
		return this.%sec%.%key%
	}

	; 获取文件路径
	GetFileName() {
		return this.EasyIni_ReservedFor_m_sFile
	}

	; 获取文件名
	GetOnlyIniFileName() {
		fileName := this.EasyIni_ReservedFor_m_sFile
		return SubStr(fileName, InStr(fileName, "\", false, -1) + 1)
	}

	; 是否为空
	IsEmpty() {
		return (!this.GetSections() && !this.EasyIni_TopComments.Length)
	}

	; 重载
	Reload() {
		if (FileExist(this.GetFileName())) {
			; 清理现有数据
			for prop in this.OwnProps() {
				if (prop != "EasyIni_ReservedFor_m_sFile")
					this.DeleteProp(prop)
			}
			; 重新加载
			this.__New(this.GetFileName())
		}
		return this
	}

	; 保存 - 优化版本
	Save(sSaveAs:="", bWarnIfExist:=false) {
		sFile := sSaveAs || this.GetFileName()
		
		if (sSaveAs && !InStr(sFile, ".ini"))
			sFile .= ".ini"

		if (bWarnIfExist && FileExist(sFile)) {
			result := MsgBox(Format("文件 {1} 已经存在。`n`n是否要覆盖？", sFile), "询问", "YesNo")
			if (result = "No")
				return false
		}

		; 构建内容
		content := ""
		
		; 顶部注释
		for comment in this.EasyIni_TopComments {
			content .= (A_Index == 1 ? "" : "`n") . (comment == Chr(14) ? "" : comment)
		}

		; 各个Section
		for secName in this.OwnProps() {
			if (secName == "EasyIni_TopComments" || secName == "EasyIni_ReservedFor_m_sFile")
				continue
				
			section := this.%secName%
			content .= "`n[" . secName . "]`n"
			
			; Section注释
			if (section.HasOwnProp("EasyIni_SectionComment")) {
				comment := section.EasyIni_SectionComment
				if (comment != Chr(14))
					content .= comment . "`n"
			}
			
			; 键值对
			for key in section.OwnProps() {
				if (key == "EasyIni_KeyComment" || key == "EasyIni_SectionComment")
					continue
					
				content .= key . " = " . section.%key% . "`n"
				
				; 键值注释
				if (section.HasOwnProp("EasyIni_KeyComment") && section.EasyIni_KeyComment.Has(key)) {
					comment := section.EasyIni_KeyComment[key]
					if (comment != Chr(14))
						content .= comment . "`n"
				}
			}
		}

		; 一次性写入文件
		try {
			FileDelete(sFile)
			FileAppend(content, sFile, "UTF-8")
			return true
		} catch {
			return false
		}
	}

	; 转换为字符串 - 优化版本
	ToVar() {
		; 使用临时变量而不是临时文件
		content := ""
		
		; 顶部注释
		for comment in this.EasyIni_TopComments {
			content .= (A_Index == 1 ? "" : "`n") . (comment == Chr(14) ? "" : comment)
		}

		; 各个Section
		for secName in this.OwnProps() {
			if (secName == "EasyIni_TopComments" || secName == "EasyIni_ReservedFor_m_sFile")
				continue
				
			section := this.%secName%
			content .= "`n[" . secName . "]`n"
			
			; 键值对
			for key in section.OwnProps() {
				if (key == "EasyIni_KeyComment" || key == "EasyIni_SectionComment")
					continue
				content .= key . " = " . section.%key% . "`n"
			}
		}
		
		return content
	}
}