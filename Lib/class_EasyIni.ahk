
/* EasyINI Class说明
	作者: Kawvin
	版本: 1.0.0
	日期: 2025-03-21
	说明: 用于读取和写入ini文件的类
	原作者 : Verdlin

	INI文件格式:====================================
		; 顶部注释1
		; 顶部注释2

		[字段1]
		; 字段1注释1
		; 字段1注释2
		键值1=值1
		; 键值1注释
		键值2=值2

		[字段2]
		; 字段2注释
		键值1=值1
		键值2=值2
		; 键值2注释
		INI文件格式:====================================

	CreateProps【创建多个属性】
		函数:  CreateProps
		作用:  创建多个属性
		参数:  parms*：多个参数
		返回:  

	CreateObj【创建对象】
		函数:  CreateObj
		作用:  创建对象
		参数:  parms*：多个参数
		返回:  Object

	CreateIniObj【创建ini对象】
		函数: CreateIniObj
		作用: 创建ini对象
		参数: parms*：多个参数
		返回: Object

	AddSection【添加字段】
		函数:  AddSection
		作用:  添加字段
		参数:  sec：字段名称, key：键值, val：值, rsError：错误信息
		返回:  True/False, rsError：错误信息

	RenameSection【重命名字段】
		函数:  RenameSection
		作用:  重命名字段
		参数:  sOldSec：旧字段名称, sNewSec：新字段名称, rsError：错误信息
		返回:  True/False, rsError：错误信息

	DeleteSection【删除字段】
		函数:  DeleteSection
		作用:  删除字段
		参数:  sec：字段名称
		返回:  

	GetSections【获取所有字段】
		函数:  GetSections
		作用:  获取所有字段
		参数:  sDelim：分隔符, sSort：排序方式
		返回:  字段字符串

	FindSecs【正则查找字段】
		函数:  FindSecs
		作用:  正则查找字段
		参数:  sExp：正则表达式, iMaxSecs：最大字段数
		返回:  数组

	AddKey【创建键值】
		函数:  AddKey
		作用:  创建键值
		参数:  sec：字段名称, key：键值, val：值, rsError：错误信息
		返回:  True/False, rsError：错误信息

	RenameKey【重命名键值】
		函数:  RenameKey
		作用:  重命名键值
		参数:  sec：字段名称, OldKey：旧键值, NewKey：新键值, rsError：错误信息
		返回:  True/False, rsError：错误信息

	DeleteKey【删除键值】
		函数:  DeleteKey
		作用:  删除键值
		参数:  sec：字段名称, key：键值
		返回:  

	GetKeys【获取字段的所有键值】
		函数:  GetKeys
		作用:  获取字段的所有键值
		参数:  sec：字段名称, sDelim：分隔符, sSort：排序方式, rsError：错误信息
		返回:  键值字符串, rsError：错误信息

	FindKeys【正则查找键值】
		函数:  FindKeys
		作用:  正则查找键值
		参数:  sec：字段名称, sExp：正则表达式, iMaxKeys：最大键值数
		返回:  字符串

	FindExactKeys【查找Key与Value对】
		函数:  FindExactKeys
		作用:  查找Key与Value对
		参数:  key：键值, iMaxKeys：最大键值数
		返回:  Map()

	GetVals【获取字段的所有值】
		函数:  GetVals
		作用:  获取字段的所有值
		参数:  sec：字段名称, sDelim：分隔符, sSort：排序方式
		返回:  字符串

	GetValue【获取值】
		函数:  GetValue
		作用:  获取值
		参数:  sec：字段名称, key：键值
		返回:  字符串

	FindVals【正则查找字段下的值】
		函数:  FindVals
		作用:  正则查找字段下的值
		参数:  sec：字段名称, sExp：正则表达式, iMaxVals：最大值数
		返回:  数组

	HasVal【查找字段下是否含有指定值】
		函数:  HasVal
		作用:  查找字段下是否含有指定值
		参数:  sec：字段名称, FindVal：查找值
		返回:  True / False

	Copy【复制EasyIni类】	；未完成！！！！！！！
		函数:  Copy
		作用:  复制EasyIni类
		参数:  SourceIni：可以是EasyIni对象，也可以只是ini文件的路径。
				bCopyFileName=true：允许在不复制文件名的情况下复制数据。
		返回:  EasyIni类

	Merge【合并其他EasyIni类】	；未完成！！！！！！！
		函数:  Merge
		作用:  合并其他EasyIni类
		参数:  vOtherIni：另一个EasyIni对象，或者是一个包含键值对的数组。
				bRemoveNonMatching=false：如果为true，则删除不匹配的键值对。
				vExceptionsIni=""：另一个EasyIni对象，或者是一个包含键值对的数组。这些键值对不会被删除。
		返回:  

	GetFileName【获取EasyIni类的文件路径】
		函数:  GetFileName
		作用:  获取EasyIni类的文件路径
		参数:  
		返回:  文件路径

	GetOnlyIniFileName【获取EasyIni类的文件名（带后缀）】
		函数:  GetOnlyIniFileName
		作用:  获取EasyIni类的文件名（带后缀）
		参数:  
		返回:  文件名（带后缀）

	IsEmpty【是否为空】
		函数:  IsEmpty
		作用:  是否为空
		参数:  
		返回:  True / False

	Reload【重载】
		函数:  Reload
		作用:  重载
		参数:  
		返回:  

	Save【保存或另存为】
		函数:  Save
		作用:  保存或另存为
		参数:  sSaveAs：另存为的文件名, bWarnIfExist：如果文件已经存在，是否警告
		返回:  True / False

	ToVar【将EasyIni类转换为字符串】
    函数:  ToVar
    作用:  将EasyIni类转换为字符串
    参数:  
    返回:  字符串
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/

class EasyIni
{
	__New(sFile:="", sLoadFromStr:="") { ;将文件加载到内存中。
		;原始方法，失效，不知道原因
		; ; this := this.CreateIniObj("EasyIni_ReservedFor_m_sFile", sFile, "EasyIni_TopComments", Array()) ; 顶部注释可以存储在线性数组中，因为顺序将只是数字
		;改进方法1，直接创建属性,不方便，不推荐
		; this.EasyIni_ReservedFor_m_sFile:=sFile,
		; this.EasyIni_TopComments:=Array() ; 顶部注释可以存储在线性数组中，因为顺序将只是数字
		
		;改进方法2，调用方法，创建多个属性
		this.CreateProps("EasyIni_ReservedFor_m_sFile", sFile, "EasyIni_TopComments", Array()) ; 顶部注释可以存储在线性数组中，因为顺序将只是数字
		
		if (sFile == "" && sLoadFromStr == "")
			return this

		;如果“.ini”尚未存在，请添加它。
		if (SubStr(sFile, StrLen(sFile)-3, 4) != ".ini")
			this.EasyIni_ReservedFor_m_sFile := sFile := (sFile . ".ini")

		sIni := sLoadFromStr
		if (sIni == "")
			sIni:=FileRead(sFile)

		sCurSec:=""
		sPrevKeyForThisSec:=""
		Loop Parse, sIni, "`n", "`r"
		{
			sTrimmedLine := Trim(A_LoopField)
			OutputDebug sTrimmedLine "`n"
			; ini中的注释或换行
			if (SubStr(sTrimmedLine, 1, 1) == ";" || sTrimmedLine == "") ; A_Blank将是换行符
			{
				; Chr（14）只是一个神奇的字符，表示此行应该只是一个换行符“`n”
				LoopField := A_LoopField == "" ? Chr(14) : A_LoopField

				if (sCurSec == ""){
						this.EasyIni_TopComments.push( LoopField) ; 不使用sTrimmedLine以保持注释格式
				} else {
					if (LoopField!="" && LoopField != Chr(14)){
						if (sPrevKeyForThisSec == "") { ;如果第一个键之前的部分有注释，则会发生这种情况
							if (this.%sCurSec%.HasOwnProp("EasyIni_SectionComment"))
								this.%sCurSec%.EasyIni_SectionComment .= "`n" LoopField
							else
								this.%sCurSec%.EasyIni_SectionComment := LoopField
						} else {
							if (this.%sCurSec%.EasyIni_KeyComment.Has(sPrevKeyForThisSec)) {
								this.%sCurSec%.EasyIni_KeyComment[sPrevKeyForThisSec] .= "`n" LoopField
							} else {
								this.%sCurSec%.EasyIni_KeyComment[sPrevKeyForThisSec] := LoopField
							}
						}
					}
				}
				continue
			}
			
			; [Section]
			if (SubStr(sTrimmedLine, 1, 1) = "[" && InStr(sTrimmedLine, "]")){ ; 需要确保这不仅仅是一个以“[”开头的键
				sCurSec := SubStr(sTrimmedLine, 2, InStr(sTrimmedLine, "]", false, -1) - 2) ; -1从右向左搜索。我们想修剪*最后*次出现的“]”
				if (sCurSec != "" && !this.HasOwnProp(sCurSec)){
					this.%sCurSec% := this.CreateObj("EasyIni_KeyComment",Map())
				}
				sPrevKeyForThisSec := ""
				continue
			}

			; key=val
			iPosOfEquals := InStr(sTrimmedLine, "=")
			if (iPosOfEquals)
			{
				sPrevKeyForThisSec := Trim(SubStr(sTrimmedLine, 1, iPosOfEquals - 1)) ;所以这还不是前一个key。。。但它将在下一次迭代中：P
				val := Trim(SubStr(sTrimmedLine, iPosOfEquals + 1))
				val:=StrReplace(val, "%A_ScriptDir%", A_ScriptDir)
				val:=StrReplace(val, "%A_WorkingDir%", A_ScriptDir)
				
				this.%sCurSec%.%sPrevKeyForThisSec% := val
			} else { ;此时，我们知道它不是注释或换行符，也不是字段，也不是传统的键值对。将此行视为没有值的键
				sPrevKeyForThisSec := sTrimmedLine
				this.%sCurSec%.%sPrevKeyForThisSec% := ""
			}
		}
		;如果文件底部有一个没有键的部分，那么我们就错过了它
		if (sCurSec != "" && !this.HasOwnProp(sCurSec)){
			this.%sCurSec% :=this.CreateObj("EasyIni_KeyComment",Map())
		}
		
		return this
	}

	/* CreateProps【创建多个属性】
		函数:  CreateProps
		作用:  创建多个属性
		参数:  parms*：多个参数
		返回:  
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	CreateProps(parms*) {
		for k, v in parms
			Mod(k,2)=1 ? lastValue:=v : this.%lastValue%:=v
	}

	/* CreateObj【创建对象】
		函数:  CreateObj
		作用:  创建对象
		参数:  parms*：多个参数
		返回:  Object
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	CreateObj(parms*) {
		tObj:=Object()
		for k, v in parms
			Mod(k,2)=1 ? lastValue:=v : tObj.%lastValue%:=v
		return tObj
	}

	/* CreateIniObj【创建ini对象】
		函数: CreateIniObj
		作用: 创建ini对象
		参数: parms*：多个参数
		返回: Object
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	CreateIniObj(parms*) {
		; 为ini数组定义原型对象：
		static base := {__Set: "EasyIni_Set", __Enum: "EasyIni_Enum", Remove: "EasyIni_Remove"
		, Insert: "EasyIni_Insert", InsertBefore: "EasyIni_InsertBefore"
		, AddSection: "EasyIni.AddSection", RenameSection: "EasyIni.RenameSection", DeleteSection: "EasyIni.DeleteSection", GetSections: "EasyIni.GetSections", FindSecs: "EasyIni.FindSecs"
		, AddKey: "EasyIni.AddKey", RenameKey: "EasyIni.RenameKey", DeleteKey: "EasyIni.DeleteKey", GetKeys: "EasyIni.GetKeys", FindKeys: "EasyIni.FindKeys"
		, GetVals: "EasyIni.GetVals", FindVals: "EasyIni.FindVals", HasVal: "EasyIni.HasVal"
		, Copy: "EasyIni.Copy", Merge: "EasyIni.Merge"
		, GetFileName: "EasyIni.GetFileName", GetOnlyIniFileName:"EasyIni.GetOnlyIniFileName"
		, IsEmpty:"EasyIni.IsEmpty", Reload: "EasyIni.Reload", GetIsSaved: "EasyIni.GetIsSaved", Save: "EasyIni.Save"
		, ToVar: "EasyIni.ToVar", GetValue: "EasyIni.GetValue"}
		; 创建并返回新对象：
		tObj:=Object(), tObj.Base:=base, lastValue:=""
		for k, v in parms
			Mod(k,2)=1 ? lastValue:=v : tObj.%lastValue%:=v
		for k in tObj.Base.OwnProps()
			msgbox k
		return tObj
	}

	/* AddSection【添加字段】
		函数:  AddSection
		作用:  添加字段
		参数:  sec：字段名称, key：键值, val：值, rsError：错误信息
		返回:  True/False, rsError：错误信息
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	AddSection(sec, key:="", val:="", &rsError:="") {
		if (this.HasOwnProp(sec))
		{
			rsError := "错误！无法添加新字段 [" sec "], 因为该字段已经存在。"
			return false
		} else {
			this.%sec% := this.CreateObj("EasyIni_KeyComment",Map())
		}

		if (key != "")
			this.%sec%.%key% := val
		return true
	}

	/* RenameSection【重命名字段】
		函数:  RenameSection
		作用:  重命名字段
		参数:  sOldSec：旧字段名称, sNewSec：新字段名称, rsError：错误信息
		返回:  True/False, rsError：错误信息
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	RenameSection(sOldSec, sNewSec, &rsError:="") {
		if (!this.HasOwnProp(sOldSec))
		{
			rsError := "错误！无法重命名字段 [" sOldSec "], 因为该字段不存在。"
			return false
		}

		aKeyValsCopy := this.%sOldSec%
		this.DeleteSection(sOldSec)
		this.%sNewSec% := aKeyValsCopy
		return true
	}

	/* DeleteSection【删除字段】
		函数:  DeleteSection
		作用:  删除字段
		参数:  sec：字段名称
		返回:  
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	DeleteSection(sec) {
		this.DeleteProp(sec)
		return
	}

	/* GetSections【获取所有字段】
		函数:  GetSections
		作用:  获取所有字段
		参数:  sDelim：分隔符, sSort：排序方式
		返回:  字段字符串
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	GetSections(sDelim:="`n", sSort:="") {
		for sec in this.OwnProps(){
			if (sec!="EasyIni_TopComments" && sec!="EasyIni_ReservedFor_m_sFile")
				secs .= (A_Index == 1 ? sec : sDelim sec)
		}

		if (sSort)
			secs:=Sort(secs,"D" sDelim " " sSort)

		return secs
	}

	/* FindSecs【正则查找字段】
		函数:  FindSecs
		作用:  正则查找字段
		参数:  sExp：正则表达式, iMaxSecs：最大字段数
		返回:  数组
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	FindSecs(sExp, iMaxSecs:="") {
		aSecs := []
		for sec in this.OwnProps()
		{
			if (RegExMatch(sec, sExp))
			{
				if (sec!="EasyIni_TopComments" && sec!="EasyIni_ReservedFor_m_sFile")
					aSecs.push(sec)
				if (iMaxSecs&& aSecs.Length == iMaxSecs)
					return aSecs
			}
		}
		return aSecs
	}

	/* AddKey【创建键值】
		函数:  AddKey
		作用:  创建键值
		参数:  sec：字段名称, key：键值, val：值, rsError：错误信息
		返回:  True/False, rsError：错误信息
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	AddKey(sec, key, val:="", &rsError:="") {
		if (this.HasOwnProp(sec))
		{
			if (this.%sec%.HasOwnProp(key))
			{
				rsError := "错误！无法添加键值, " key " 因为在已有键值在相同字段内:`n字段: " sec "`n键值: " key
				return false
			}
		} else {
			rsError := "错误！无法添加键值, " key " 因为字段, " sec " 不存在。"
			return false
		}
		this.%sec%.%key% := val
		return true
	}

	/* RenameKey【重命名键值】
		函数:  RenameKey
		作用:  重命名键值
		参数:  sec：字段名称, OldKey：旧键值, NewKey：新键值, rsError：错误信息
		返回:  True/False, rsError：错误信息
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	RenameKey(sec, OldKey, NewKey, &rsError:="") {
		if (!this.%sec%.HasOwnProp(OldKey))
		{
			rsError := "错误！特定键值 " OldKey " 不能被修改，因为不存在！"
			return false
		}

		ValCopy := this.%sec%.%OldKey%
		this.DeleteKey(sec, OldKey)
		this.AddKey(sec, NewKey)
		this.%sec%.%NewKey% := ValCopy
		return true
	}

	/* DeleteKey【删除键值】
		函数:  DeleteKey
		作用:  删除键值
		参数:  sec：字段名称, key：键值
		返回:  
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	DeleteKey(sec, key) {
		this.%sec%.DeleteProp(key)
		return
	}

	/* GetKeys【获取字段的所有键值】
		函数:  GetKeys
		作用:  获取字段的所有键值
		参数:  sec：字段名称, sDelim：分隔符, sSort：排序方式, rsError：错误信息
		返回:  键值字符串, rsError：错误信息
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	GetKeys(sec, sDelim:="`n", sSort:="", &rsError:="") {
		if (!this.HasOwnProp(sec))
		{
			rsError := "错误！无法获取字段的键值，因为字段不存在。"
			return ""
		}
		for key in this.%sec%.OwnProps(){
			if (key != "EasyIni_KeyComment" && key != "EasyIni_SectionComment")	; 键值注释
				keys .= A_Index == 1 ? key : sDelim key
		}
		if (sSort)
			keys:=Sort(keys, "D" sDelim " " sSort)

		return keys
	}

	/* FindKeys【正则查找键值】
		函数:  FindKeys
		作用:  正则查找键值
		参数:  sec：字段名称, sExp：正则表达式, iMaxKeys：最大键值数
		返回:  字符串
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	FindKeys(sec, sExp, iMaxKeys:="") {
		aKeys := []
		for key in this.%sec%.OwnProps()
		{
			if (key = "EasyIni_KeyComment" || key = "EasyIni_SectionComment")	; 键值注释
				continue
			if (RegExMatch(key, sExp))
			{
				
					aKeys.push(key)
				if (iMaxKeys && aKeys.Length == iMaxKeys)
					return aKeys
			}
		}
		return aKeys
	}

	/* FindExactKeys【查找Key与Value对】
		函数:  FindExactKeys
		作用:  查找Key与Value对
		参数:  key：键值, iMaxKeys：最大键值数
		返回:  Map()
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	FindExactKeys(key, iMaxKeys:="") {
		aKeys := Map()
		for sec, aData in this
		{
			if (aData.HasOwnProp(key))
			{
				if (key = "EasyIni_KeyComment" && key = "EasyIni_SectionComment")	; 键值注释
					aKeys[sec]:= key
				if (iMaxKeys && aKeys.length == iMaxKeys)
					return aKeys
			}
		}
		return aKeys
	}

	/* GetVals【获取字段的所有值】
		函数:  GetVals
		作用:  获取字段的所有值
		参数:  sec：字段名称, sDelim：分隔符, sSort：排序方式
		返回:  字符串
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	GetVals(sec, sDelim:="`n", sSort:="") {
		for key in this.%sec%.OwnProps(){
			if (key = "EasyIni_KeyComment" || key = "EasyIni_SectionComment")	; 键值注释
				continue
			vals .= (A_Index == 1) ? (this.%sec%.%key%) : sDelim (this.%sec%.%key%)
		}

		if (sSort)
			vals:=Sort(vals, "D" sDelim " " sSort)

		return vals
	}

	/* GetValue【】
		函数:  GetValue
		作用:  获取值
		参数:  sec：字段名称, key：键值
		返回:  字符串
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	GetValue(sec, key) {
		return this.%sec%.%key%
	}

	/* FindVals【正则查找字段下的值】
		函数:  FindVals
		作用:  正则查找字段下的值
		参数:  sec：字段名称, sExp：正则表达式, iMaxVals：最大值数
		返回:  数组
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	FindVals(sec, sExp, iMaxVals:="") {
		aVals := []
		for key in this.%sec%.OwnProps()
		{
			if (key = "EasyIni_KeyComment"|| key = "EasyIni_SectionComment")	; 键值注释
				continue
			if (RegExMatch(this.%sec%.%key%, sExp))
			{
				aVals.push(this.%sec%.%key%)
				if (iMaxVals && aVals.length == iMaxVals)
					break
			}
		}
		return aVals
	}

	/* HasVal【查找字段下是否含有指定值】
		函数:  HasVal
		作用:  查找字段下是否含有指定值
		参数:  sec：字段名称, FindVal：查找值
		返回:  True / False
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	HasVal(sec, FindVal) {
		for k in this.%sec%.OwnProps()
			if (FindVal = this.%sec%.%k%)
				return true
		return false
	}

	/* Copy【复制EasyIni类】	；未完成！！！！！！！
		函数:  Copy
		作用:  复制EasyIni类
		参数:  SourceIni：可以是EasyIni对象，也可以只是ini文件的路径。
				bCopyFileName=true：允许在不复制文件名的情况下复制数据。
		返回:  EasyIni类
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	Copy(SourceIni, bCopyFileName := true) {
		; Get ini as string.
		if (IsObject(SourceIni))
			sIniString := SourceIni.ToVar()
		else 
			sIniString:=FileRead(SourceIni)

		; Effectively make this function static by allowing calls via EasyIni.Copy.
		; 通过允许通过EasyIni调用，有效地使此函数保持静态。复制。
		if (IsObject(this))
		{
			if (bCopyFileName)
				sOldFileName := this.GetFileName()
			this := "" ; 避免任何复制构造函数问题。

			; ObjClone doesn't work consistently. It's likely a problem with the meta-function overrides, but this is a nice, quick hack.
			; ObjClone工作不稳定。这可能是元函数重写的问题，但这是一个很好的快速破解。
			this := this.CreateObj(SourceIni.GetFileName(), sIniString)

			; 还原文件名。
			this.EasyIni_ReservedFor_m_sFile := sOldFileName
		}
		else
			return EasyIni(bCopyFileName ? SourceIni.GetFileName() : "", sIniString)

		return this
	}

	/* Merge【合并其他EasyIni类】	；未完成！！！！！！！
		函数:  Merge
		作用:  合并其他EasyIni类
		参数:  vOtherIni：另一个EasyIni对象，或者是一个包含键值对的数组。
				bRemoveNonMatching=false：如果为true，则删除不匹配的键值对。
				vExceptionsIni=""：另一个EasyIni对象，或者是一个包含键值对的数组。这些键值对不会被删除。
		返回:  
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	Merge(vOtherIni, bRemoveNonMatching := false, bOverwriteMatching := false, vExceptionsIni := "") {
		; TODO: Perhaps just save one ini, read it back in, and then perform merging? I think this would help with formatting.
		; [Sections]
		for sec, aKeysAndVals in vOtherIni
		{
			if (!this.HasOwnProp(sec))
				if (bRemoveNonMatching)
					this.DeleteSection(sec)
				else this.AddSection(sec)

			; key=val
			for key, val in aKeysAndVals
			{
				bMakeException := vExceptionsIni[sec].HasOwnProp(key)

				if (this.%sec%.HasOwnProp(key))
				{
					if (bOverwriteMatching && !bMakeException)
						this.%sec%.%key% := val
				}
				else
				{
					if (bRemoveNonMatching && !bMakeException)
						this.DeleteKey(sec, key)
					else if (!bRemoveNonMatching)
						this.AddKey(sec, key, val)
				}
			}
		}
		return
	}

	/* GetFileName【获取EasyIni类的文件路径】
		函数:  GetFileName
		作用:  获取EasyIni类的文件路径
		参数:  
		返回:  文件路径
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	GetFileName() {
		return this.EasyIni_ReservedFor_m_sFile
	}

	/* GetOnlyIniFileName【获取EasyIni类的文件名（带后缀）】
		函数:  GetOnlyIniFileName
		作用:  获取EasyIni类的文件名（带后缀）
		参数:  
		返回:  文件名（带后缀）
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	GetOnlyIniFileName() {
		return SubStr(this.EasyIni_ReservedFor_m_sFile, InStr(this.EasyIni_ReservedFor_m_sFile,"\", false, -1)+1)
	}

	/* IsEmpty【是否为空】
		函数:  IsEmpty
		作用:  是否为空
		参数:  
		返回:  True / False
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	IsEmpty() {
		return (this.GetSections() == "" ; No sections.
			&& !this.EasyIni_TopComments.HasOwnProp(1)) ; and no comments.
	}

	/* Reload【重载】
		函数:  Reload
		作用:  重载
		参数:  
		返回:  
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	Reload() {
		if (FileExist(this.GetFileName()))
			this := EasyIni(this.GetFileName()) ; else nothing to reload.
		return this
	}
	
	/* Save【保存或另存为】
		函数:  Save
		作用:  保存或另存为
		参数:  sSaveAs：另存为的文件名, bWarnIfExist：如果文件已经存在，是否警告
		返回:  True / False
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	Save(sSaveAs:="", bWarnIfExist:=false){
		if (sSaveAs == "")
			sFile := this.GetFileName()
		else
		{
			sFile := sSaveAs

			; Append ".ini" if it is not already there.
			if (SubStr(sFile, StrLen(sFile)-3, 4) != ".ini")
				sFile .= ".ini"

			if (bWarnIfExist && FileExist(sFile))
			{
				MsgRst:=MsgBox(Format("文件 {1} 已经存在。`n`n是否要覆盖？",sFile), "询问", "32")
				if (MsgRst="No") {
					Return false
				}

			}
		}

		; Formatting is preserved in ini object.
		try
			FileDelete sFile

		for k, v in this.EasyIni_TopComments
		{
			FileAppend  (A_Index == 1 ? "" : "`n") (v == Chr(14) ? "" : v), sFile , "UTF-8"
		}

		for key in this.OwnProps()
		{
			Switch key,false
			{
				Case "EasyIni_TopComments":	; 顶部注释
					continue
				Case "EasyIni_ReservedFor_m_sFile":	; 文件名
					continue
				default: 
					bIsFirstLine := true
					; 字段
					FileAppend  (bIsFirstLine? "`n[" : "[") key "]`n", sFile, "UTF-8"
					bIsFirstLine := false
					
					value:=this.%key%

					; 字段注释
					if value.HasProp("EasyIni_SectionComment"){
						sComments := value.EasyIni_SectionComment
						sComments == Chr(14) ? "" : sComments
						FileAppend  sComments "`n", sFile, "UTF-8"
					}

					; 键值及键值注释
					
					for k in value.OwnProps()
					{
						if (k = "EasyIni_KeyComment" || k = "EasyIni_SectionComment")	; 键值注释
							continue
						FileAppend Format("{1} = {2}`n", k, value.%k%), sFile, "UTF-8"
						; 键值注释
						if (value.HasOwnProp("EasyIni_KeyComment")){
							if value.EasyIni_KeyComment.Has(k){
								sComments := value.EasyIni_KeyComment[k]
								sComments == Chr(14) ? "" : sComments
								FileAppend  sComments "`n", sFile, "UTF-8"
							}
						}
					}
			}
		}
		return true
	}
	
	/* ToVar【将EasyIni类转换为字符串】
		函数:  ToVar
		作用:  将EasyIni类转换为字符串
		参数:  
		返回:  字符串
		作者:  Kawvin
		版本:  0.1
		AHK版本: 2.0.18
		*/
	ToVar() {
		sTmpFile := "$$$EasyIni_Temp.ini"
		this.Save(sTmpFile, !A_IsCompiled)
		sIniAsVar:=FileRead(sTmpFile)
		FileDelete sTmpFile
		return sIniAsVar
	}
}
