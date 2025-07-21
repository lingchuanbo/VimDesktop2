; =================================================================================
; 函数定义: LaunchOrShow(winIdentifier, exePath, newTitle := "")
; 功能: 检查一个窗口是否存在。如果存在，则激活它；如果不存在，则运行指定的程序。
;       如果提供了 newTitle, 则会尝试将窗口标题修改为新标题。
; 参数:
;   - winIdentifier: 用于识别窗口的字符串。强烈推荐使用 ahk_exe <程序名.exe> 的形式，
;                    因为它最稳定。也可以使用窗口标题或 ahk_class。
;   - exePath:       要运行的程序的可执行文件路径。
;   - newTitle:      (可选) 一个新的窗口标题。如果留空或不提供此参数，则不修改标题。
; =================================================================================
; 将V1版本的函数转换为V2版本，并增强错误处理
LaunchOrShow(ExePath, tClass, NewTitle := "") {
    ; 检查窗口是否存在
    if WinExist("ahk_class " . tClass) {
        try {
            ; 获取窗口状态（最小化、最大化等）
            minMax := WinGetMinMax("ahk_class " . tClass)

            ; 如果窗口最小化
            if (minMax == -1) {
                WinActivate("ahk_class " . tClass)
                ; 只有当NewTitle不为空时才设置标题
                if (NewTitle != "")
                    try WinSetTitle(NewTitle, "ahk_class " . tClass)
            }
            ; 如果窗口未激活
            else if !WinActive("ahk_class " . tClass) {
                WinActivate("ahk_class " . tClass)
                ; 只有当NewTitle不为空时才设置标题
                if (NewTitle != "")
                    try WinSetTitle(NewTitle, "ahk_class " . tClass)
            }
            ; 如果窗口已激活
            else {
                WinMinimize("ahk_class " . tClass)
                ; 只有当NewTitle不为空时才设置标题
                if (NewTitle != "")
                    try WinSetTitle(NewTitle, "ahk_class " . tClass)
            }
        } catch Error as e {
            ; 忽略错误，继续执行
        }
    }
    ; 如果窗口不存在，运行程序
    else {
        try {
            Run(ExePath)

            ; 等待窗口出现，最多等待5秒
            startTime := A_TickCount
            while (!WinExist("ahk_class " . tClass) && A_TickCount - startTime < 5000) {
                Sleep(100)
            }

            ; 如果窗口出现了，尝试激活它
            if WinExist("ahk_class " . tClass) {
                try {
                    WinActivate("ahk_class " . tClass)
                    Sleep(200) ; 给窗口一点时间来响应
                    ; 只有当NewTitle不为空时才设置标题
                    if (NewTitle != "")
                        try WinSetTitle(NewTitle, "ahk_class " . tClass)
                } catch Error as e {
                    ; 忽略错误，继续执行
                }
            }
        } catch Error as e {
            ; 忽略错误，继续执行
        }
    }

    ; 最后一次尝试设置标题，只有当NewTitle不为空时
    try {
        if (NewTitle != "" && WinExist("ahk_class " . tClass))
            WinSetTitle(NewTitle, "ahk_class " . tClass)
    } catch Error as e {
        ; 忽略错误
    }
}

; ; --- 示例 1: 启动/显示记事本 (不修改标题) ---
; ; 按下 F1，行为和之前一样，只是显示或启动记事本，不改变它的标题。
; F1:: {
;     MsgBox("即将启动或显示【记事本】（不修改标题）")
;     LaunchOrShow("ahk_exe notepad.exe", "notepad.exe")
; }

; ; --- 示例 2: 启动/显示记事本，并将其标题改为 "我的工作笔记" ---
; ; 按下 F2，会启动或显示记事本，并确保它的标题被设置为 "我的工作笔记"。
; ; 你可以手动把标题改掉，再按F2，会看到标题又被改回来了。
; F2:: {
;     MsgBox("即将启动或显示【记事本】，并修改其标题为'我的工作笔记'")
;     ; 注意第三个参数，我们提供了一个新的标题
;     LaunchOrShow("ahk_exe notepad.exe", "notepad.exe", "我的工作笔记")
; }

; ; --- 示例 3: 启动/显示 VS Code，并动态设置标题 ---
; ; 按下 F3，会启动或显示 VS Code，并把当前日期加入标题。
; ; 这展示了 newTitle 参数可以是动态生成的字符串。
; F3:: {
;     ; MsgBox("即将启动或显示【VS Code】，并动态修改标题")
;     vscodePath := "D:\BoBO\WorkFlow\tools\TotalCMD\Tools\Everything\Everything.exe" 
;     dynamicTitle := "Everything - 搜索 (" . A_YYYY . "-" . A_MM . "-" . A_DD . ")"
;     LaunchOrShow("ahk_exe Everything.exe", vscodePath, dynamicTitle)
; }

; =================================================================================