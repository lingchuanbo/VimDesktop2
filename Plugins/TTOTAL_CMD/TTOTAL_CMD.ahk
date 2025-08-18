#requires AutoHotkey v2.0

/*
[PluginInfo]
PluginName=TC
Author=Kawvin
Version=0.1_2025.06.17
Comment=Total Commander
*/

global TC_Global := object()

; 从插件配置文件读取TC路径信息
TC_GetConfig() {
    ; 优先从插件独立配置文件读取
    if (PluginConfigs.HasOwnProp("TTOTAL_CMD") && PluginConfigs.TTOTAL_CMD.HasOwnProp("TTOTAL_CMD")) {
        return PluginConfigs.TTOTAL_CMD.TTOTAL_CMD
    }
    ; 如果插件配置不存在，尝试从主配置文件读取（向后兼容）
    else if (INIObject.HasOwnProp("TTOTAL_CMD")) {
        return INIObject.TTOTAL_CMD
    }
    ; 如果都没有，返回空对象
    return {}
}

tcConfig := TC_GetConfig()
TC_Global.TcPath := tcConfig.HasOwnProp("tc_path") ? tcConfig.tc_path : "D:\BoBO\WorkFlow\tools\TotalCMD\TOTALCMD.EXE"
TC_Global.TcINI := tcConfig.HasOwnProp("tc_ini_path") ? tcConfig.tc_ini_path : "D:\BoBO\WorkFlow\tools\TotalCMD\WinCMD.ini"
TC_Global.TcDir := tcConfig.HasOwnProp("tc_dir_path") ? tcConfig.tc_dir_path : "D:\BoBO\WorkFlow\tools\TotalCMD"
TC_Global.TcExe := "TOTALCMD.EXE"
TC_Global.LastView := ""  ;最后视图

if RegExMatch(TC_Global.TcPath, "i)totalcmd64\.exe$") {
    TC_Global.TCListBox := "LCLListBox"
    TC_Global.TCEdit := "Edit2"
    TC_Global.TInEdit := "TInEdit1"
    TC_Global.TCPanel1 := "Window1"
    TC_Global.TCPanel2 := "Window11"
    TC_Global.TcPathPanel := "TPathPanel2"
} else {
    TC_Global.TCListBox := "TMyListBox"
    TC_Global.TCEdit := "Edit1"
    TC_Global.TInEdit := "TInEdit1"
    TC_Global.TCPanel1 := "Window1"
    TC_Global.TCPanel2 := "TMyPanel8"
    TC_Global.TcPathPanel := "TPathPanel1"
    TC_Global.TcPathPanelRight := "TPathPanel2"
}

TTOTAL_CMD() {
    KeyArray := Array()
    ; 模式选择=========================================================
    KeyArray.push({ Key: "<insert>", Mode: "普通模式", Group: "模式", Func: "ModeChange", Param: "VIM模式", Comment: "切换到【VIM模式】" })
    KeyArray.push({ Key: "<insert>", Mode: "VIM模式", Group: "模式", Func: "ModeChange", Param: "普通模式", Comment: "切换到【普通模式】" })
    KeyArray.push({ Key: "<capslock>", Mode: "VIM模式", Group: "模式", Func: "VIMD_清除输入键", Param: "", Comment: "清除输入键及提示" })
    KeyArray.push({ Key: "<c-1>", Mode: "VIM模式", Group: "模式", Func: "MsgBoxTest", Param: "12345", Comment: "清除输入键及提示" })
    KeyArray.push({ Key: "?", Mode: "VIM模式", Group: "模式", Func: "ShowAllKeys", Param: "TTOTAL_CMD", Comment: "清除输入键及提示" })
    ; 控制===========================================================
    KeyArray.push({ Key: "w", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "{up}", Comment: "向上" })
    KeyArray.push({ Key: "s", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "{down}", Comment: "向下" })
    KeyArray.push({ Key: "*h", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "{left}", Comment: "向左" })
    KeyArray.push({ Key: "*l", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "{right}", Comment: "向右" })
    KeyArray.push({ Key: "z", Mode: "VIM模式", Group: "控制", Func: "SendKeyInput", Param: "{Enter}", Comment: "确认（Enter）" })
    KeyArray.push({ Key: "gg", Mode: "VIM模式", Group: "控制", Func: "TC_GotoLine", Param: 1, Comment: "VIM_移动第一行" })
    KeyArray.push({ Key: "G", Mode: "VIM模式", Group: "控制", Func: "TC_GotoLine", Param: 0, Comment: "VIM_移动到最后一行" })
    KeyArray.push({ Key: "gd", Mode: "VIM模式", Group: "控制", Func: "TC_GotoLine", Param: "", Comment: "VIM_移动到[ 输入 ]行" })
    ;KeyArray.push({Key:"*``", Mode: "VIM模式", Group: "提示", Func: "TC_ToggleShowInfo", Param: "", Comment: "VIM_显示/隐藏按键提示"})
    ; 注释===========================================================
    KeyArray.push({ Key: "m", Mode: "VIM模式", Group: "注释", Func: "TC_MarkFile", Param: "", Comment: "注释_文件添加注释" })
    KeyArray.push({ Key: "M", Mode: "VIM模式", Group: "注释", Func: "TC_UnMarkFile", Param: "", Comment: "注释_文件删除注释" })

    vim.SetWin("TTOTAL_CMD", "TTOTAL_CMD", "TOTALCMD.exe")

    vim.SetTimeOut(500, "TTOTAL_CMD")
    for k, v in KeyArray {
        if (v.Key != "")
            vim.map(v.Key, "TTOTAL_CMD", v.Mode, v.Func, v.Param, v.Group, v.Comment)
    }
}

TTOTAL_CMD_Before() {   ;未使用
    ; Global TC_SendPos
    ;Tooltip TC_SendPos
    ;MenuID:=WinGetID("AHK_CLASS #32768")
    ;if MenuID And (TC_SendPos != 572)
    ;    return True
    ctrl := ControlGetClassNN(ControlGetFocus("ahk_class TTOTAL_CMD"), "ahk_class TTOTAL_CMD")
    if (InStr(ctrl, TC_Global.TCListBox))
        return False
    return True
}

/* TC_ToggleTC【切换TC】
    函数:  TC_ToggleTC
    作用:  切换TC
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_ToggleTC(AlwaysMax := 1) {
    if WinExist("Ahk_Class TTOTAL_CMD") {
        AC := WinGetMinMax("Ahk_Class TTOTAL_CMD")
        if (Ac = -1) {
            WinActivate "Ahk_Class TTOTAL_CMD"
        } else {
            if (!WinActivate("Ahk_Class TTOTAL_CMD"))
                WinActivate "Ahk_Class TTOTAL_CMD"
            else
                WinMinimize "Ahk_Class TTOTAL_CMD"
        }
        if AlwaysMax
            PostMessage 1075, 2015, 0, , "Ahk_Class TTOTAL_CMD"	;最大化
    } else {
        if (!FileExist(TC_Global.TcPath)) {
            MsgBox "请指定TC的路径及相关信息。", "错误", "4112"
            run Format('"{1}" "{2}"', VimDesktop_Global.Editor, A_ScriptDir "\Plutins\TC\TC.ahk")
        }

        Run TC_Global.TcPath
        loop 4 {
            if (!WinActive("Ahk_Class TTOTAL_CMD"))
                WinActivate "Ahk_Class TTOTAL_CMD"
            else
                break
            Sleep 500
        }
        if AlwaysMax
            PostMessage 1075, 2015, 0, , "Ahk_Class TTOTAL_CMD"	;最大化
    }
}

/* TC_FocusTC【激活TC】
    函数:  TC_FocusTC
    作用:  激活TC
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_FocusTC() {
    if WinExist("Ahk_Class TTOTAL_CMD")
        WinActivate "Ahk_Class TTOTAL_CMD"
    else {
        Run TC_Global.TcPath
        loop 4 {
            if (!WinActive("Ahk_Class TTOTAL_CMD"))
                WinActivate "Ahk_Class TTOTAL_CMD"
            else
                break
            Sleep 500
        }
    }
}

/* TC_FocusTCCmd【激活TC，并定位到命令行】
    函数:  TC_FocusTCCmd
    作用:  激活TC，并定位到命令行
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_FocusTCCmd() {
    TC_FocusTC()
    TC_SendPos(4003)
}

/* TC_CopyOrMoveFilesAndSubDirFilesToOtherPanel【制或移动所选文件及文件夹内所有文件到另一个Panel】
    函数:  TC_CopyOrMoveFilesAndSubDirFilesToOtherPanel
    作用:  复制或移动所选文件及文件夹内所有文件到另一个Panel，合并文件夹用的
    参数:  isMove:=0 ;0为复制，1为移动
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.18
    AHK版本: 2.0.18
*/
TC_CopyOrMoveFilesAndSubDirFilesToOtherPanel(isMove := 0) {
    ; sleep 300
    TC_SendPos(2018) ;获取路径
    sleep 100
    FileList := A_Clipboard
    sleep 100
    TC_SendPos(2030) ;获取路径
    sleep 100
    DesDir := ClipboardAll()
    MsgRst := MsgBox("确认合并文件？", "询问", "4132")
    if (MsgRst = "No") {
        return
    }
    loop parse, FileList, "`n", "`r" {
        if (A_LoopField = "")
            continue
        if InStr(FileExist(A_LoopField), "D") {
            if isMove {
                FileMove A_LoopField "*.*", DesDir
            } else {
                FileCopy A_LoopField "*.*", DesDir
            }
        } else {
            if isMove {
                FileMove A_LoopField, DesDir
            } else {
                FileCopy A_LoopField, DesDir
            }
        }
    }
}

/* TC_CopyOrMoveToHotListDirectory【复制或移动所选文件及文件夹内到常用文件夹】
    函数:  TC_CopyOrMoveToHotListDirectory
    作用:  复制或移动所选文件及文件夹内到常用文件夹
    参数:  isMove:=0 ;0为复制，1为移动
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.18
    AHK版本: 2.0.18
*/
TC_CopyOrMoveToHotListDirectory(isMove := 0) { ;复制到常用文件夹
    CurrentFocus := ControlGetFocus("ahk_class TTOTAL_CMD")
    sleep 100
    if (!InStr(TC_Global.LCLListBox2, CurrentFocus) && !InStr(TC_Global.LCLListBox1, CurrentFocus))
        return
    if (InStr(TC_Global.LCLListBox2, CurrentFocus))
        otherList := TC_Global.LCLListBox1
    else
        otherList := TC_Global.LCLListBox2
    ControlFocus otherList, "ahk_class TTOTAL_CMD"
    sleep 100
    TC_SendPos(526)
    SetTimer TC_Timer_WaitMenuPop, 300

    TC_Timer_WaitMenuPop() {
        menuPop := WinGetID("ahk_class #32768")
        if (menuPop) {
            SetTimer TC_Timer_WaitMenuPop, 0
            SetTimer TC_Timer_WaitMenuOff, 300
        }
    }

    TC_Timer_WaitMenuOff() {
        menuPop := WinGetID("ahk_class #32768")
        if ( not menuPop) {
            SetTimer TC_Timer_WaitMenuOff, 0
            TC_Global.CurrentFocus := ControlFocus("ahk_class TTOTAL_CMD")
            sleep 100
            if isMove
                TC_SendPos(1005) ;移动到常用文件夹
            else
                TC_SendPos(3101) ;复制到常用文件夹
        }
    }
}

/* TC_CopyNameOnly【仅复制文件名，不含后缀】
    函数:  TC_CopyNameOnly
    作用:  仅复制文件名，不含后缀
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_CopyNameOnly() {  ;
    A_Clipboard := ""
    TC_SendPos(2018)
    ClipWait
    if Not RegExMatch(A_Clipboard, "^\..*") {
        A_Clipboard := RegExReplace(A_Clipboard, "m)\.[^.]*$")
        A_Clipboard := RegExReplace(A_Clipboard, "m)\\$")
    }
}

/* TC_FileCopyForBak【将当前光标下的文件复制一份作为作为备份】
    函数:  TC_FileCopyForBak
    作用:  将当前光标下的文件复制一份作为作为备份
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_FileCopyForBak() { ;将当前光标下的文件复制一份作为作为备份
    A_Clipboard := ""
    TC_SendPos(2018)
    ClipWait
    filecopy A_Clipboard, A_Clipboard ".bak"
}

/* TC_FileMoveForBak【将当前光标下的文件重命名为备份】
    函数:  TC_FileMoveForBak
    作用:  将当前光标下的文件重命名为备份
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
TC_FileMoveForBak() { ;将当前光标下的文件重命名为备份
    A_Clipboard := ""
    TC_SendPos(2018)
    ClipWait
    SplitPath A_Clipboard, &name, &dir, &ext, &name_no_ext

    if (A_Clipboard != dir . "\")
        FileMove A_Clipboard, A_Clipboard ".bak"
    else
        DirMove dir, dir ".bak"
}

/* TC_MultiFilePersistOpen【多个文件一次性连续打开】
    函数:  TC_MultiFilePersistOpen
    作用:  多个文件一次性连续打开
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_MultiFilePersistOpen() { ;多个文件一次性连续打开
    A_Clipboard := ""
    TC_SendPos(2018)
    ClipWait
    TC_SendPos(524)
    sleep 200
    loop parse, A_Clipboard, "`n", "`r" {
        run A_LoopField
    }
}

/* TC_CopyFileContents【不打开文件就复制文件内容】
    函数:  TC_CopyFileContents
    作用:  不打开文件就复制文件内容
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
TC_CopyFileContents() { ;不打开文件就复制文件内容
    A_Clipboard := ""
    TC_SendPos(2018)
    ClipWait
    Contents := FileRead(A_Clipboard)
    A_Clipboard := ""
    A_Clipboard := Contents
}

/* TC_OpenDirAndPaste【不打开目录，直接把复制的文件贴进去】
    函数:  TC_OpenDirAndPaste
    作用:  不打开目录，直接把复制的文件贴进去
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_20250619
    AHK版本: 2.0.18
*/
TC_OpenDirAndPaste() { ;不打开目录，直接把复制的文件贴进去
    TC_SendPos(1001)
    TC_SendPos(2009)
    TC_SendPos(2002)
}

/* TC_CreateFileShortcut【创建当前光标下文件的快捷方式，可发送到桌面或启动文件夹】
    函数:  TC_CreateFileShortcut
    作用:  创建当前光标下文件的快捷方式，可发送到桌面或启动文件夹
    参数:  CopyTo，0=无操作，1=发送到桌面，2=发送到启动文件夹
    返回:
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
TC_CreateFileShortcut(CopyTo := 0) { ;创建当前光标下文件的快捷方式
    A_Clipboard := ""
    TC_SendPos(2018)
    ClipWait
    SplitPath A_Clipboard, &name, &dir, &ext, &name_no_ext
    ExtLen := StrLen(ext)
    if (ExtLen != 0) {
        _linkPath := dir "\" name_no_ext ".lnk"
        FileCreateShortcut A_Clipboard, _linkPath
    } else {
        _linkPath := dir ".lnk"
        FileCreateShortcut dir, _linkPath
    }
    switch CopyTo {
        case 1: ;发送到桌面
            FileMove _linkPath, A_Desktop
        case 2: ;发送到启动文件夹
            FileMove _linkPath, A_Startup
            ; 打开启动目录
            run A_Startup
    }
}

/* TC_TwoFileExchangeName【两个文件互换文件名】
    函数:  TC_TwoFileExchangeName
    作用:  两个文件互换文件名
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_20250619
    AHK版本: 2.0.18
*/
TC_TwoFileExchangeName() { ;两个文件互换文件名
    A_Clipboard := ""
    TC_SendPos(2018)
    ClipWait
    PathArray := StrSplit(A_Clipboard, "`r`n")
    FirstName := PathArray[1]
    SecondName := PathArray[2]
    TC_SendPos(524)
    sleep 200
    FileMove FirstName, FirstName ".bak"
    FileMove SecondName, FirstName
    FileMove FirstName ".bak", SecondName
}

/* TC_OpenPath【TC打开路径】
    函数:  TC_OpenPath
    作用:  TC打开路径
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
TC_OpenPath(Path, InNewTab := true, LeftOrRight := "") {
    if (LeftOrRight = "") {
        LeftOrRight := "/R"
        if Mod(TC_LeftRight(), 2) {
            LeftOrRight := "/L"
        }
    }
    if (InNewTab) {
        Run Format('"{1}%" /O /T /A "{2}"="{3}"', TC_Global.TcPath, LeftOrRight, Path)
    } else {
        Run Format('"{1}%" /O /A "{2}"="{3}"', TC_Global.TcPath, LeftOrRight, Path)
    }

    TC_LeftRight() {
        location := 0
        ControlGetPos &x1, &y1, , , TC_Global.TCPanel1, "AHK_CLASS TTOTAL_CMD"
        if x1 > y1
            location += 2
        TLB := ControlGetFocus("ahk_class TTOTAL_CMD")
        ControlGetPos &x2, &y2, &wn, , TLB, "AHK_CLASS TTOTAL_CMD"
        if location {
            if x1 > x2
                location += 1
        } else {
            if y1 > y2
                location += 1
        }
        return location
    }
}

/* TC_Run【TC运行命令】
    函数:  TC_Run
    作用:  TC运行命令
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_Run(cmd) {
    ControlSetText TC_Global.TCEdit, cmd, "ahk_class TTOTAL_CMD"
    ControlSend TC_Global.TCEdit, " {Enter}", "ahk_class TTOTAL_CMD"
}

/* TC_CreateNewFile【新建文件，可根据模板】
    函数:  TC_CreateNewFile
    作用:  新建文件，可根据模板
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
TC_CreateNewFile() { ;
    TLB := ControlGetFocus("ahk_class TTOTAL_CMD")
    ;获取控件的位置和大小
    ControlGetPos &OutX, &OutY, &OutWidth, &OutHeight, TLB, "ahk_class TTOTAL_CMD"
    tMyMenu := Menu()
    try
        tMyMenu.Delete()

    tMyMenu.Add("1 文件夹", (*) => TC_SendPos(907))
    tMyMenu.SetIcon("1 文件夹", A_WinDir "\system32\Shell32.dll", 4)
    tMyMenu.Add("2 快捷方式", (*) => TC_SendPos(1004))
    tMyMenu.SetIcon("2 快捷方式", A_WinDir "\system32\Shell32.dll", 264)
    tMyMenu.Add("3 添加到新模板", TC_AddToTempFiles)
    tMyMenu.SetIcon("3 添加到新模板", A_WinDir "\system32\Shell32.dll", -155)
    tMyMenu.Add("4 打开模板文件夹", TC_OpenTempfilesDir)
    tMyMenu.SetIcon("4 打开模板文件夹", A_WinDir "\system32\Shell32.dll", 4)
    ;添加模板----------------------
    SplitPath TC_Global.TCPath, , &_TCDir
    shellNewDir := _TCDir "\shellNew"
    if (!DirExist(shellNewDir))
        DirCreate shellNewDir
    loop files shellNewDir "\*.*", "F" {
        if (A_Index = 1)
            tMyMenu.Add()
        ft := chr(64 + A_Index) . " >> " . A_LoopFileName
        tMyMenu.Add(ft, TC_FileTempNew)
        Ext := "." . A_LoopFileExt
        IconFile := TC_RegGetNewFileIcon(Ext)
        if (IconFile != "") {
            IconFile := RegExReplace(IconFile, "i)%SystemRoot%", A_WinDir)
            IconFilePath := RegExReplace(IconFile, ",-?\d*", "")
            IconFilePath := StrReplace(IconFilePath, '"', "")
            IconFileIndex := RegExReplace(IconFile, ".*,", "")
            IconFileIndex := IconFileIndex >= 0 ? IconFileIndex + 1 : IconFileIndex
        } else {
            IconFilePath := A_WinDir "\system32\Shell32.dll"
            IconFileIndex := 1
        }
        tMyMenu.SetIcon(ft, IconFilePath, IconFileIndex)
    }

    tMyMenu.Show(OutX, OutY)

    TC_AddToTempFiles(Item, *) { ; 添加到文件模板中
        ClipSaved := ClipboardAll()
        A_Clipboard := ""
        TC_SendPos(2018)    ;复制文件路径
        ClipWait 2
        if A_Clipboard
            SrcPath := A_Clipboard
        else
            return
        A_Clipboard := ClipSaved
        if FileExist(SrcPath)
            SplitPath SrcPath, &FileName, , &FileExt, &fileNameNoExt
        else
            return

        tGui := Gui("+AlwaysOnTop", "添加模板")
        tGui.OnEvent("Escape", (*) => tGui.Destroy())
        tGui.OnEvent("Close", (*) => tGui.Destroy())
        tGui.SetFont("s10", "Consolas")	;等宽字体
        tGui.Add("Text", "Hidden vSrcPath", SrcPath)
        tGui.Add("Text", "x12 y20 w50 h20 +Center", "模板源")
        tGui.Add("Edit", "x72 y20 w300 h20 Disabled", FileName)
        tGui.Add("Text", "x12 y50 w50 h20 +Center", "模板名")
        tGui.Add("Edit", "x72 y50 w300 h20 vNewFileName", FileName)
        tGui.Add("Button", "x162 y80 w90 h30 default", "确认(&S)").OnEvent("Click", TC_AddTempOK)
        tGui.Add("Button", "x282 y80 w90 h30", "取消(&C)").OnEvent("Click", (*) => tGui.Destroy())
        tGui.Show()
        if FileExt {
            nf := ControlGetHwnd("edit2", "A")
            PostMessage 0x0B1, 0, Strlen(fileNameNoExt), "Edit2", "A"
        }

        TC_AddTempOK(*) {
            SrcPath := tGui["SrcPath"].text
            SplitPath SrcPath, &FileName, , &FileExt, &FileNameNoExt
            NewFileName := tGui["NewFileName"].text
            SNDir := RegExReplace(TC_Global.TCPath, "[^\\]*$") . "ShellNew\"
            if Not FileExist(SNDir)
                DirCreate SNDir
            NewFile := SNDir . NewFileName
            FileCopy SrcPath, NewFile, 1
            tGui.Destroy()
        }
    }

    TC_OpenTempfilesDir(Item, *) { ;打开模板文件夹
        SplitPath TC_Global.TCPath, , &_TCDir
        shellNewDir := _TCDir "\shellNew"
        Sleep 300
        CurrentFocus := ControlGetFocus("AHK_CLASS TTOTAL_CMD")
        if (!InStr(TC_Global.LCLListBox1, CurrentFocus)) && (!InStr(TC_Global.LCLListBox2, CurrentFocus))
            return
        if (InStr(TC_Global.LCLListBox2, CurrentFocus))
            otherList := TC_Global.LCLListBox1
        else
            otherList := TC_Global.LCLListBox2
        ControlFocus otherList, "ahk_class TTOTAL_CMD"
        TC_SendPos(3001)  ;新建标签
        ControlSetText "cd " shellNewDir, "Edit1", , "ahk_class TTOTAL_CMD"
        Sleep 200
        ControlSend "{Enter}", "Edit1", , "ahk_class TTOTAL_CMD"
    }

    TC_FileTempNew(Item, *) { ; 新建文件模板
        SrcFile := RegExReplace(Item, ".\s>>\s", RegExReplace(TC_Global.TCPath, "\\[^\\]*$", "\shellNew\"))
        SplitPath SrcFile, &FileName, , &FileExt, &FileNameNoExt

        tGui := Gui("+AlwaysOnTop", "新建文件")
        tGui.OnEvent("Escape", (*) => tGui.Destroy())
        tGui.OnEvent("Close", (*) => tGui.Destroy())
        tGui.SetFont("s9", "Consolas")	;等宽字体
        tGui.Add("Text", "x12 y20 h20 +Center", "模 板 源")
        tGui.Add("Edit", "x72 y20 w300 h20 vSrcFile Disabled", SrcFile)
        tGui.Add("Text", "x12 y50 h20 +Center", "新建文件")
        tGui.Add("Edit", "x72 y50 w300 h20 vNewFileName", FileName)
        tGui.Add("Button", "x162 y80 w90 h30 default", "确认(&S)").OnEvent("Click", TC_NewFileOK)
        tGui.Add("Button", "x282 y80 w90 h30", "取消(&C)").OnEvent("Click", (*) => tGui.Destroy())
        tGui.Show()
        if FileExt {
            nf := ControlGetHwnd("Edit2", "A")
            PostMessage 0x0B1, 0, Strlen(FileNameNoExt), "Edit2", "A"
        }

        TC_NewFileOK(*) { ;确认新建文件
            SrcPath := tGui["SrcFile"].Text
            NewFileName := tGui["NewFileName"].Text
            ClipSaved := ClipboardAll()
            A_Clipboard := ""
            TC_SendPos(2029)    ;复制源路径cm_CopySrcPathToClip
            ClipWait 2
            if A_Clipboard
                DstPath := A_Clipboard
            else
                return
            A_Clipboard := ClipSaved
            if RegExMatch(DstPath, "^\\\\计算机$")
                return
            if RegExMatch(DstPath, "^\\\\此电脑$")
                return
            if RegExMatch(DstPath, "i)\\\\所有控制面板项$")
                return
            if RegExMatch(DstPath, "i)\\\\Fonts$")
                return
            if RegExMatch(DstPath, "i)\\\\网络$")
                return
            if RegExMatch(DstPath, "i)\\\\打印机$")
                return
            if RegExMatch(DstPath, "i)\\\\回收站$")
                return
            if RegExMatch(DstPath, "^\\\\桌面$")
                DstPath := A_Desktop
            NewFile := DstPath . "\" . NewFileName
            if FileExist(NewFile) {
                MsgRst := MsgBox("新建文件已存在，是否覆盖？", "询问", "4132")
                if (MsgRst = "No") {
                    return
                }
            }
            if !FileExist(SrcPath)
                return
            else
                FileCopy SrcPath, NewFile, 1
            tGui.Destroy()
            WinActivate "AHK_CLASS TTOTAL_CMD"
            FocusCtrl := ControlGetFocus("AHK_Class TTOTAL_CMD")
            if RegExMatch(FocusCtrl, TC_Global.TCListBox) {
                TC_SendPos(540) ;刷新源面板
                Items := ControlGetItems(FocusCtrl, "AHK_CLASS TTOTAL_CMD")
                for k, v in Items {
                    if RegExMatch(v, NewFileName) {
                        Index := k - 1
                        PostMessage 0x19E, Index - 1, 1, FocusCtrl, "AHK_CLASS TTOTAL_CMD"
                        break
                    }
                }
            }
        }
    }
}

TC_RegGetNewFileIcon(reg) { ; 获取文件对应的图标 ; reg 为后缀
    IconPath := TC_RegGetNewFileType(reg) . "\DefaultIcon"
    try {
        FileIcon := RegRead("HKEY_CLASSES_ROOT" "\" IconPath)
    } catch {
        FileIcon := ""
        ; FileIcon:=A_WinDir "\system32\shell32.dll"
    }
    return FileIcon

}

TC_RegGetNewFileType(reg) { ; 获取新建文件类型名 ; reg 为后缀
    try {
        FileType := RegRead("HKEY_CLASSES_ROOT" "\" Reg)
    } catch {
        FileType := ""
    }
    return FileType
}

/* TC_GoToParent【返回到上层文件夹】
    函数:  TC_GoToParent
    作用:  返回到上层文件夹
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
TC_GoToParent() {
    SendInput "{Backspace}"
}

/* TC_OpeDriver【打开盘符根目录】
    函数:  TC_OpeDriver
    作用:  打开盘符根目录
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_OpeDriver(DriveLetter) {
    TC_SendPos(2061 + Ord(StrUpper(DriveLetter)) - 65)
}

/* TC_Delete【TC删除文件，自动确认】
    函数:  TC_Delete
    作用:  TC删除文件，自动确认
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_Delete() { ;
    TC_SendPos(908) ;删除文件

    SetTimer TC_Timer_WaitMenuPop_Delete, 100

    TC_Timer_WaitMenuPop_Delete() {
        TC_Delete_iHwnd := WinExist("删除文件")
        if (TC_Delete_iHwnd != "") {
            WinActivate "ahk_pid " TC_Delete_iHwnd
            Sleep 300
            Send "{enter}"
            SetTimer TC_Timer_WaitMenuPop_Delete, 0
        }
    }
}

/* TC_CloseAllTabs【关闭所有标签】
    函数:  TC_CloseAllTabs
    作用:  关闭所有标签
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_CloseAllTabs() {
    TC_SendPos(3008)
    SetTimer TC_Timer_WaitMenuPop_CloseAllTabs, 100
    return

    TC_Timer_WaitMenuPop_CloseAllTabs() {
        menuPop := WinGetID("ahk_class #32770")
        if (menuPop) {
            SetTimer TC_Timer_WaitMenuPop_CloseAllTabs, 0
            send "{enter}"
        }
    }
}

/* TC_ReOpenTab【重新打开之前关闭的标签页】
    函数:  TC_ReOpenTab
    作用:  重新打开之前关闭的标签页
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
TC_ReOpenTab() {
    TC_SendPos(3001)
    TC_SendPos(570)
}

/* TC_GoLastTab【切换到最后一个标签】
    函数:  TC_GoLastTab
    作用:  切换到最后一个标签
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
TC_GoLastTab() {     ;定位最后一个标签
    TC_SendPos(5001)
    TC_SendPos(3006)
}

/* TC_Toggle_50_100Percent【还原当前窗口显示状态50-100】
    函数:  TC_Toggle_50_100Percent
    作用:  还原当前窗口显示状态50-100
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_Toggle_50_100Percent() { ;切换当前（纵向）窗口显示状态50%~100%"
    ControlGetPos &OutX, &OutY, &wp, &hp, "Window1", "ahk_class TTOTAL_CMD"
    ControlGetPos &OutX, &OutY, &w1, &h1, "LCLListBox1", "ahk_class TTOTAL_CMD"
    ControlGetPos &OutX, &OutY, &w2, &h2, "LCLListBox2", "ahk_class TTOTAL_CMD"
    if (wp < hp) {
        ;纵向
        if (abs(w1 - w2) > 2)
            TC_SendPos(909)
        else
            TC_SendPos(910)
    } else {
        ;横向
        if (abs(h1 - h2) > 2)
            TC_SendPos(909)
        else
            TC_SendPos(910)
    }
}

/* TC_Toggle_50_100Percent_V【切换当前（纵向）窗口显示状态50-100】
    函数:  TC_Toggle_50_100Percent_V
    作用:  切换当前（纵向）窗口显示状态50-100
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_Toggle_50_100Percent_V() {
    ; 切换当前（纵向）窗口显示状态50%~100%"
    ; 横向分割的窗口使用 TC_Toggle_50_100Percent 即可
    ControlGetPos &OutX, &OutY, &wp, &hp, "Window1", "ahk_class TTOTAL_CMD"
    ControlGetPos &OutX, &OutY, &w1, &h1, "LCLListBox1", "ahk_class TTOTAL_CMD"
    ControlGetPos &OutX, &OutY, &w2, &h2, "LCLListBox2", "ahk_class TTOTAL_CMD"
    if (wp < hp) { ;纵向
        if (abs(w1 - w2) > 2) {
            TC_SendPos(909)
        } else {
            TC_SendPos(910)
            TC_SendPos(305)
        }
    } else {         ;横向
        if (abs(h1 - h2) > 2) {
            TC_SendPos(305)
            TC_SendPos(909)
        }
        /*
        横向切换会错乱
        else {
            TC_SendPos(910)
        }
        */
    }
}

/* TC_WinMaxLR【最大化左侧/上部窗口 最大化右侧/下部窗口】
    函数:  TC_WinMaxLR
    作用:  最大化左侧/上部窗口 最大化右侧/下部窗口
    参数:  lr:1=最大化左侧/上部窗口 0=最大化右侧/下部窗口
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_WinMaxLR(lr) {      ;最大化面板-主函数
    ControlGetPos &OutX, &OutY, &wBar, &hBar, "Window1", "ahk_class TTOTAL_CMD"
    CurrentFocus := ControlGetFocus("ahk_class TTOTAL_CMD")
    if (wBar <= hBar) {
        if lr
            TC_GoPercentX(1)
        else
            TC_GoPercentX(0)
    } else {
        if lr
            TC_GoPercentY(1)
        else
            TC_GoPercentY(0)
    }

    TC_GoPercentX(Percent := 0.5) {	;改变左右方向的比例
        WinGetPos &OutX, &OutY, &hTC, &wTC, "ahk_class TTOTAL_CMD"
        ControlMove , , Round(Percent * wTC), , "Window1", "ahk_class TTOTAL_CMD"
        ControlClick "Window1", "ahk_class TTOTAL_CMD"
        WinActivate "ahk_class TTOTAL_CMD"
    }

    TC_GoPercentY(Percent := 0.5) {	;改变上下方向的比例
        WinGetPos &OutX, &OutY, &hTC, &wTC, "ahk_class TTOTAL_CMD"
        ControlMove , , , Round(Percent * hTC), "Window1", "ahk_class TTOTAL_CMD"
        ControlClick "Window1", "ahk_class TTOTAL_CMD"
        WinActivate "ahk_class TTOTAL_CMD"
        return
    }
}

/* TC_AlwayOnTop【设置TC顶置】
    函数:  TC_AlwayOnTop
    作用:  设置TC顶置
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_AlwayOnTop() {
    ExStyle := WinGetExStyle("ahk_class TTOTAL_CMD")
    if (ExStyle & 0x8)
        WinSetAlwaysOnTop 0, "ahk_class TTOTAL_CMD"
    else
        WinSetAlwaysOnTop 1, "ahk_class TTOTAL_CMD"
}

/* TC_Toggle_AutoPercent【自动扩大本侧窗口】
    函数:  TC_Toggle_AutoPercent
    作用:  自动扩大本侧窗口
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
TC_Toggle_AutoPercent() { ;TC_VIM:启用/关闭：自动扩大本侧窗口
    if (FileExist(A_ScriptDir "\vimd.exe")) {
        Run Format('{1}\vimd.exe {1}\Apps\TC自动扩大本侧窗口\TC自动扩大本侧窗口Kawvin.ahk', A_ScriptDir)
    } else {
        Run A_ScriptDir "\Apps\TC自动扩大本侧窗口\TC自动扩大本侧窗口Kawvin.ahk"
    }
}

/* TC_GotoLine【TC跳转到指定行】
    函数:  TC_GotoLine
    作用:  TC跳转到指定行
    参数:  Index - 行号, 如果为空则弹出输入框
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_GotoLine(Index) {
    if (Index = "") {
        IB := InputBox("请输入要跳到的行号", "输入", "w200 h100")
        if (IB.Result = "Cancel")
            return
        Index := IB.Value
        if (Index = "")
            Index := 1
    }
    Ctrl := ControlGetFocus("AHK_CLASS TTOTAL_CMD")
    _Arr := ControlGetItems(Ctrl, "AHK_CLASS TTOTAL_CMD")
    if Index {
        if Index > _Arr.Length
            Index := _Arr.Length
    } else {
        Index := _Arr.Length
    }
    PostMessage 0x19E, Index - 1, 1, Ctrl, "AHK_CLASS TTOTAL_CMD"
}

/* TC_SrcViewChange【切换视图布局】
    函数:  TC_SrcViewChange
    作用:  切换视图布局
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_SrcViewChange() { ;显示模式切换，详细信息-列表-缩略图
    if (TC_Global.LastView = "Long") {
        TC_Global.LastView := "Short"
        TC_SendPos(302)
    } else if (TC_Global.LastView = "Short") {
        TC_Global.LastView := "Thumbs"
        TC_SendPos(269)
    } else {
        TC_Global.LastView := "Long"
        TC_SendPos(301)
    }
}

/* TC_UnpackFilesToCurrentDir【解压文件到当前文件夹】
    函数:  TC_UnpackFilesToCurrentDir
    作用:  解压文件到当前文件夹
    参数:  aFolder：是否含文件夹解压
    返回:
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
TC_UnpackFilesToCurrentDir(aFolder := 1) {
    TC_SendPos(509)
    WinWaitActive "ahk_class TDLGUNZIPALL"
    SendInput "{del}"
    sleep 100
    if (aFolder = 0) {
        ; control,Uncheck,,TCheckBox1,ahk_class TDLGUNZIPALL    ;TC9
        ControlSetChecked 0, "Button1", "ahk_class TDLGUNZIPALL" ; TC10.52
    } else {
        ; control,check,,TCheckBox1,ahk_class TDLGUNZIPALL  ;TC9
        ControlSetChecked 1, "Button1", "ahk_class TDLGUNZIPALL" ; TC10.52
    }
    sleep 100
    SendInput "{enter}"
}

/* TC_PackFilesToCurrentDir【压缩文件到当前文件夹】
    函数:  TC_PackFilesToCurrentDir
    作用:  压缩文件到当前文件夹
    参数:  aPanel：0=当前面板，1=另一侧面板
    返回:
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
TC_PackFilesToCurrentDir(aPanel := 0) {
    TC_SendPos(2018)   ;获取完整路径和文件名
    sleep 100
    MySel := A_Clipboard
    TC_SendPos(332)   ;光标定位到焦点地址栏
    sleep 100
    TC_SendPos(2029)   ;获取来源路径
    sleep 100
    CurDir := A_Clipboard
    if (InStr(MySel, "`n")) {     ;如果多行文本，则以父文件夹为压缩文件名，否则以当前文件名
        SplitPath CurDir, , , &MyOutExt, &MyOutNameNoExt
    } else {
        FileAttrib := FileExist(MySel)
        if (InStr(FileAttrib, "D")) {         ;如果是文件夹
            if (substr(MySel, 0) != "\")
                MySel .= "\"
            pos := InStr(MySel, "\", , -1, 1)
            MyOutNameNoExt := substr(MySel, pos + 1)
            MyOutNameNoExt := StrReplace(MyOutNameNoExt, "\", "")
        } else {
            SplitPath MySel, , , &MyOutExt, &MyOutNameNoExt
        }
    }
    if (aPanel = 1) {
        TC_SendPos(2030)   ;获取目标路径
        sleep 100
        CurDir := A_Clipboard
    }

    A_Clipboard := Format("rar:{1}\{2}.rar", CurDir, MyOutNameNoExt)
    TC_SendPos(508)
    WinWaitActive "ahk_class TDLGZIP"
    SendInput "^v"
    ;SendInput "{enter}"
}

/* TC_PackFilesToCurrentDirWithVersion【压缩文件到当前文件夹_带版本】
    函数:  TC_PackFilesToCurrentDirWithVersion
    作用:  压缩文件到当前文件夹_带版本
    参数:  aPanel：0=当前面板，1=另一侧面板
    返回:
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
TC_PackFilesToCurrentDirWithVersion(aPanel := 0) {
    TC_SendPos(2018)   ;获取完整路径和文件名
    sleep 100
    MySel := A_Clipboard
    TC_SendPos(332)   ;光标定位到焦点地址栏
    sleep 100
    TC_SendPos(2029)   ;获取来源路径
    sleep 100
    CurDir := A_Clipboard
    if (InStr(MySel, "`n")) {      ;如果多行文本，则以父文件夹为压缩文件名，否则以当前文件名
        SplitPath CurDir, , , &MyOutExt, &MyOutNameNoExt
    } else {
        FileAttrib := FileExist(MySel)
        if (InStr(FileAttrib, "D")) {         ;如果是文件夹
            if (substr(MySel, 0) != "\")
                MySel .= "\"
            Pos := InStr(MySel, "\", , -1, 1)
            MyOutNameNoExt := substr(MySel, Pos + 1)
            MyOutNameNoExt := StrReplace(MyOutNameNoExt, "\", "")
        } else {
            SplitPath MySel, , , &MyOutExt, &MyOutNameNoExt
        }
    }
    if (aPanel = 1) {
        TC_SendPos(2030)   ;获取目标路径
        sleep 100
        CurDir := A_Clipboard
    }
    FileList := ""
    loop files, CurDir "\*.rar", "F"		;R：子文件夹；D：目录，F：文件
        FileList .= A_LoopFileFullPath "`n"
    FindFile := ""
    loop parse, FileList, "`n", "`r" {
        if (A_LoopField = "")
            continue
        if (A_LoopField > FindFile and instr(A_LoopField, MyOutNameNoExt) > 0)
            FindFile := A_LoopField
    }
    if (FindFile != "") {
        SplitPath FindFile, , , &MyOutExt, &MyOutNameNoExt
        aPos := RegExMatch(MyOutNameNoExt, "i)_(\d{8})V(\d+)", &m)
        if (m[1] = A_Year . A_MM . A_DD) {
            MyOutNameNoExt := StrReplace(MyOutNameNoExt, m[0], "_" . A_Year . A_MM . A_DD . "V" . m[2] + 1)
        } else {
            MyOutNameNoExt := StrReplace(MyOutNameNoExt, m[0], "_" . A_Year . A_MM . A_DD . "V1")
        }
    }
    A_Clipboard := Format("rar:{1}\{2}.rar", CurDir, MyOutNameNoExt)
    TC_SendPos(508)
    WinWaitActive "ahk_class TDLGZIP"
    SendInput "^v"
    ;SendInput "{enter}"
}

/* TC_MoveSelectedFilesToPrevFolder【TC将当前文件夹下的选定文件移动到上层目录中】
    函数:  TC_MoveSelectedFilesToPrevFolder
    作用:  TC将当前文件夹下的选定文件移动到上层目录中
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_MoveSelectedFilesToPrevFolder() { ;
    Send "^x"
    TC_SendPos(2002)    ;返回上一级
    sleep 800
    Send "^v"
}

/* TC_DeleteByExt_GUI【删除文件-界面选择类型】
    函数:  TC_DeleteByExt_GUI
    作用:  删除文件-界面选择类型
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_DeleteByExt_GUI() {
    ; TC_Global:=Object()
    ; TC_Global.TcCPath:="D:\aaa.txt"
    SplitPath TC_Global.TcCPath, , &_TCDir
    batchDelete_INI := _TCDir . "\batchDelete.ini"

    if !FileExist(batchDelete_INI) {
        batchDelete_Txt := "
		(
		[批量列表]
		类型1=jpg,jpeg,gif,png
		类型2=torrent,txt,html,url
		类型3=
		[后缀名列表]
		图片=bmp,tif,jpg,png,gif,jpeg,tiff
		视频=flv,mp4,mpg,rm,mpeg,avi,rmvb,dat,mkv,wmv
		音频=mp3,cue,mid,wav,wma,ape,flac
		压缩文件=gt,rar,zip,7z,bds
		文本文件=txt,xml,bat,vbs,vba,lst,ini,bas,json,md,ahk
		Office文件=doc,docx,rtf,xls,xlsx,xlsm,ppt,pptx
		网页文件=html,htm,mht,url
		其他文件=bak,torrent
		)"
        fileAppend batchDelete_Txt, batchDelete_INI, "UTF-16"
    }
    batchDelete_List := IniRead(batchDelete_INI, "批量列表")
    batchDelete_Exts := IniRead(batchDelete_INI, "后缀名列表")

    tGui := Gui("+AlwaysOnTop", "删除文件-选择类型")
    tGui.OnEvent("Escape", (*) => tGui.Destroy())
    tGui.OnEvent("Close", (*) => tGui.Destroy())
    tGui.SetFont("s10", "Consolas")	;等宽字体
    loop parse, batchDelete_List, "`n", "`r" {
        if (A_LoopField = "")
            continue
        TemStr := "(&" A_index ") " substr(A_LoopField, 5)
        if (A_index = 1) {
            t1 := tGui.Add("Radio", "x15 y15 h23 vbatchDelete", TemStr)
            t1.OnEvent("Click", batchDelete_DeleteList_click)
            t1.OnEvent("DoubleClick", batchDelete_DeleteList_DoubleClick)
        } else {
            t2 := tGui.Add("Radio", "x15 yp+25 h23", TemStr)
            t2.OnEvent("Click", batchDelete_DeleteList_click)
            t2.OnEvent("DoubleClick", batchDelete_DeleteList_DoubleClick)
        }
    }
    loop parse, batchDelete_Exts, "`n", "`r" {
        if (A_LoopField = "")
            continue
        ExtsString := A_LoopField
        MyVar_Key := RegExReplace(ExtsString, "=.*?$")
        MyVar_Val := RegExReplace(ExtsString, "^.*?=")
        if (MyVar_Key && MyVar_Val) {
            tGui.Add("Text", "x15 yp+30 h23", MyVar_Key)
            loop parse, MyVar_Val, ",", "`r" {
                if (A_index = 1) {
                    tGui.Add("checkbox", "xp+80 yp-3 h23", A_LoopField).OnEvent("Click", batchDelete_AddExts)
                } else {
                    tGui.Add("checkbox", "xp+80 yp h23", A_LoopField).OnEvent("Click", batchDelete_AddExts)
                }
            }
        }
    }
    tGui.Add("Text", "x15 yp+30", "文件后缀")
    tGui.Add("Edit", "x90 yp-3 w600 vbatchDelete_Exts", "")
    tGui.Add("Button", "x90 yp+30 w100 h40 Default", "(&Z) 确认").OnEvent("Click", batchDelete_OK)
    tGui.Add("Button", "xp+150 yp w100 h40", "取消").OnEvent("Click", (*) => tGui.Destroy())
    tGui.Add("Button", "xp+130 yp w30 h40", ">>").OnEvent("Click", (*) => Run(batchDelete_INI))
    tGui.Show()

    batchDelete_DeleteList_click(CtrlObj, *) {
        _tStr := tGui["batchDelete_Exts"].text
        if (CtrlObj.value = 1) {
            if (!InStr(_tStr, SubStr(CtrlObj.text, 6)))
                _tStr .= "," SubStr(CtrlObj.text, 6)
        } else {
            _tStr := StrReplace(_tStr, SubStr(CtrlObj.text, 6), "")
        }
        _tStr := RegExReplace(_tStr, ",{2,}", ",")
        _tStr := RegExReplace(_tStr, "^,", "")
        _tStr := RegExReplace(_tStr, ",$", "")
        tGui["batchDelete_Exts"].text := _tStr
    }

    batchDelete_DeleteList_DoubleClick(CtrlObj, *) {
        TC_DeleteByExt(SubStr(CtrlObj.text, 6))
        tGui.Destroy()
    }

    batchDelete_AddExts(CtrlObj, *) {
        _tStr := tGui["batchDelete_Exts"].text
        if (CtrlObj.value = 1) {
            if (!InStr(_tStr, CtrlObj.text))
                _tStr .= "," CtrlObj.text
        } else {
            _tStr := StrReplace(_tStr, CtrlObj.text, "")
        }
        _tStr := RegExReplace(_tStr, ",{2,}", ",")
        _tStr := RegExReplace(_tStr, "^,", "")
        _tStr := RegExReplace(_tStr, ",$", "")
        tGui["batchDelete_Exts"].text := _tStr
    }

    batchDelete_OK(*) {
        TC_DeleteByExt(tGui["batchDelete_Exts"].text)
        tGui.Destroy()
    }
}

/* TC_DeleteByExt【TC删除指定类型文件】
    函数:  TC_DeleteByExt
    作用:  TC删除指定类型文件
    参数:  Exts:后缀名
            DefDir:指定目录
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_DeleteByExt(Exts := "", DefDir := "") { ;
    if (Exts = "")
        return
    if (DefDir = "") {
        TC_SendPos(332)  ;光标定位到焦点地址栏
        sleep 100
        TC_SendPos(2029) ;获取路径
        sleep 100
        DefDir := A_Clipboard
    }
    loop files, DefDir "\*.*" {
        if (instr(Exts, a_LoopFileExt))
            FileDelete A_LoopFileFullPath
    }
    TC_SendPos(540) ;刷新来源面板
}

/* TC_MarkFile【文件添加注释】
    函数:  TC_MarkFile
    作用:  文件添加注释
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_MarkFile() {
    IB := InputBox("请输入备注内容", "如果原文件有备注则直接替换", "w400 h130", "")
    if (IB.Result = "Cancel")
        return
    MyTemInput := IB.Value
    if (MyTemInput = "")
        return
    TC_SendPos(2700)
    ; 将备注设置为 m，可以通过将备注为 m 的文件显示成不同颜色，实现标记功能
    ; 不要在已有备注的文件使用
    Send "^+{end}"
    Send "{Text}" MyTemInput
    Send "{f2}"
}

/* TC_UnMarkFile【文件删除注释】
    函数:  TC_UnMarkFile
    作用:  文件添加注释
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_UnMarkFile() {
    TC_SendPos(2700)
    ; 删除 TC_MarkFile 的文件标记，也可用于清空文件备注
    Send "^+{end}"
    Send "{del}"
    Send "{f2}"
}

/* TC_OtherPanel_GotoPreviousDir【[另一侧]上一个文件夹】
    函数:  TC_OtherPanel_GotoPreviousDir
    作用:  【另一侧】上一个文件夹
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
TC_OtherPanel_GotoPreviousDir() {
    Send "{Tab}"
    TC_SendPos(570)
    Send "{Tab}"
}

/* TC_OtherPanel_GotoNextDir【[另一侧]下一个文件夹】
    函数:  TC_OtherPanel_GotoNextDir
    作用:  【另一侧】下一个文件夹
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1
    AHK版本: 2.0.18
*/
TC_OtherPanel_GotoNextDir() {
    Send "{Tab}"
    TC_SendPos(571)
    Send "{Tab}"
}

/* TC_LaunchOrShow 激活/显示/隐藏_TC】
    函数:  TC_LaunchOrShow
    作用:  激活/显示/隐藏_TC
    参数:
    返回:
    作者:  BoBO
    版本:  0.1
    AHK版本: 2.0.18
*/

Run_TotalCommander(*) {
    ; 从插件配置文件获取TC路径
    tcPath := ""
    try {
        ; 优先从插件独立配置文件读取
        if (PluginConfigs.HasOwnProp("TTOTAL_CMD") && PluginConfigs.TTOTAL_CMD.HasOwnProp("TTOTAL_CMD")) {
            tcPath := PluginConfigs.TTOTAL_CMD.TTOTAL_CMD.tc_path
        }
        ; 如果插件配置不存在，尝试从主配置文件读取（向后兼容）
        else if (INIObject.HasOwnProp("TTOTAL_CMD")) {
            tcPath := INIObject.TTOTAL_CMD.tc_path
        }
    } catch {
        ; 配置读取失败，使用默认路径
    }
    
    ; 如果配置中没有路径，尝试默认路径
    if (!tcPath) {
        defaultPaths := [
            "C:\Program Files\TotalCMD\TOTALCMD.EXE",
            "D:\WorkFlow\tools\TotalCMD\TOTALCMD.EXE",
            "D:\BoBO\WorkFlow\tools\TotalCMD\TOTALCMD.EXE"
        ]

        for path in defaultPaths {
            if FileExist(path) {
                tcPath := path
                break
            }
        }
    }
    
    ; 如果找到了TC路径，运行它
    if (tcPath && FileExist(tcPath)) {
        LaunchOrShow(tcPath, "TTOTAL_CMD")
    } else {
        MsgBox("未找到Total Commander程序，请检查插件配置文件或在主配置文件中设置正确的路径。", "错误", "Icon!")
    }
}

/* TC_ToggleMenu【显示/隐藏_菜单栏】
    函数:  TC_ToggleMenu
    作用:  显示/隐藏_菜单栏
    参数:
    返回:
    作者:  Kawvin
    版本:  0.1_2025.06.19
    AHK版本: 2.0.18
*/
TC_ToggleMenu() {
    MainMenu := IniRead(TC_Global.TcINI, "Configuration", "MainMenu", "")
    if (MainMenu = "WCMD_CHN.MNU") {
        TChwnd := WinGetId("ahk_class TTOTAL_CMD")
        DllCall("SetMenu", "uint", TChwnd, "uint", 0)
        IniWrite "NONE.MNU", TC_Global.TcINI, "Configuration", "MainMenu"
        IniWrite 1, TC_Global.TcINI, "Configuration", "RestrictInterface"
        noneMnuPath := RegExReplace(TC_Global.TCPath, "i)totalcmd6?4?.exe$", "LANGUAGE\NONE.MNU")
        if (!FileExist(noneMnuPath))
            FileAppend "", noneMnuPath, "UTF-8"
    } else {
        IniWrite "WCMD_CHN.MNU", TC_Global.TcINI, "Configuration", "MainMenu"
        IniWrite 0, TC_Global.TcINI, "Configuration", "RestrictInterface"
        WinClose "AHK_CLASS TTOTAL_CMD"
        Sleep 50
        Run TC_Global.TCPath
        loop 4 {
            if (!WinActive("AHK_CLASS TTOTAL_CMD"))
                WinActivate "AHK_CLASS TTOTAL_CMD"
            else
                break
            Sleep 100
        }
    }
}

TotalCMD_Menu := Menu()
GameDevSet_Menu := Menu()

GameDevSet_Menu.Add("打包 H5_WEBP" , (*) => TotalCMD("em_BoBO_webp"))
GameDevSet_Menu.Add("打包 H5" , (*) => TotalCMD("TC_打包工具_打包Atlas"))
GameDevSet_Menu.Add("打包 H5_大图集" , (*) => TotalCMD("TC_打包工具_打包Atlas2"))
GameDevSet_Menu.Add()
GameDevSet_Menu.Add("修正 fxjID" , (*) => TotalCMD("Tc_项目功能_FxjID修改"))
GameDevSet_Menu.Add("修正 ATtlas" , (*) => TotalCMD("GameDevSetAtlas"))
GameDevSet_Menu.Add("SSP  转 PNG" , (*) => TotalCMD("TC_打包工具_ssp转png"))
GameDevSet_Menu.Add("TXT  转 PNG" , (*) => TotalCMD("em_python_TxtAniToAni"))
GameDevSet_Menu.Add("WebP 转 PNG" , (*) => TotalCMD("em_python_TxtAniToAniWebp"))
GameDevSet_Menu.Add()
GameDevSet_Menu.Add("传奇资源-转PNG" , (*) => TotalCMD("em_python_PlacementsTxt"))
GameDevSet_Menu.Add("传奇资源-转PNG-界面" , (*) => TotalCMD("em_python_PlacementsTxtShow"))
GameDevSet_Menu.Add("传奇资源-提取人物600" , (*) => TotalCMD("em_python_PlacementsTxtAni"))
GameDevSet_Menu.Add()
GameDevSet_Menu.Add("复制txt目录结构" , (*) => TotalCMD("em_BoBO_txtCopy"))

GameDevSet_Menu.Add()
; GameDevSet_Menu.Add("修正 ATtlas" , (*) => ExitApp("em_Magic_MergeJPG2PDF"))
GameDevSet_Menu.Add("创建info.txt文件" , (*) => TotalCMD("em_python_InfoTxt"))
GameDevSet_Menu.Add("创建extra.txt文件" , (*) => TotalCMD("em_python_ExtraTxt"))
TotalCMD_Menu.Add("项目开发", GameDevSet_Menu)

ReName_Menu := Menu()
ReName_Menu.Add("命名为: 标准00000" , (*) => TotalCMD("em_python_rename_png_00000"))
ReName_Menu.Add("命名为: 标准10000" , (*) => TotalCMD("em_python_rename_png_10000"))
ReName_Menu.Add("命名为: b+文件名" , (*) => TotalCMD("em_python_rename_png_b1"))
ReName_Menu.Add("命名为: b1b+文件名" , (*) => TotalCMD("em_python_rename_png_b2"))
ReName_Menu.Add("命名为: b2b1b+文件名" , (*) => TotalCMD("em_python_rename_png_b3"))
ReName_Menu.Add("命名为: 拼音" , (*) => TotalCMD("em_python_PinyinRenameFiles"))
TotalCMD_Menu.Add("重命名", ReName_Menu)

Spine_Menu := Menu()
Spine_Menu.Add("三国传奇-霸刀" , (*) => TotalCMD("em_python_spine_1"))
Spine_Menu.Add("QBL" , (*) => TotalCMD("em_python_spine_2"))
Spine_Menu.Add("大天神" , (*) => TotalCMD("em_python_spine_3"))
Spine_Menu.Add("大天神-台湾" , (*) => TotalCMD("em_python_spine_4"))
Spine_Menu.Add("大天神-韩国" , (*) => TotalCMD("em_python_spine_5"))
TotalCMD_Menu.Add("SPINE导出", Spine_Menu)

; 设置全局右键热键 (但通过条件限制)
#HotIf WinActive("ahk_class TTOTAL_CMD")
+RButton:: {
    ; 显示菜单在鼠标位置
    TotalCMD_Menu.Show()
}
#HotIf  ; 结束条件限制

; 用法 TC_Command("tem(`cm_MkDir`)")

TotalCMD(CommandName) {
    ; 使用TC_Global中的配置路径
    Run(TC_Global.TcDir . "\Tools\TCFS2\TCFS2.exe /ef " . "tem(" . CommandName . ")")
}

#Include *i A_ScriptDir "\Lib\vimd_API.ahk"