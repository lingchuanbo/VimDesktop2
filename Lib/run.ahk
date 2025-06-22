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
LaunchOrShow(winIdentifier, exePath, newTitle := "") {
    ; 使用 WinExist 检查窗口是否存在
    if WinExist(winIdentifier) {
        ; --- 窗口已存在 ---
        WinActivate(winIdentifier) ; 激活窗口

        ; 检查是否需要修改标题
        if (newTitle != "") {
            ; 使用 WinSetTitle 修改标题
            WinSetTitle(winIdentifier, newTitle)
        }
    } else {
        ; --- 窗口不存在 ---
        Run(exePath) ; 启动程序

        ; 检查是否需要修改标题 (程序启动后需要一点时间来创建窗口)
        if (newTitle != "") {
            ; 等待窗口出现，最多等待2秒
            WinWait(winIdentifier, , 2)
            if WinExist(winIdentifier) { ; 再次确认窗口已存在
                WinSetTitle(winIdentifier, newTitle)
            }
        }
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
;     MsgBox("即将启动或显示【VS Code】，并动态修改标题")
;     vscodePath := A_Programs "\Microsoft VS Code\Code.exe" 
;     dynamicTitle := "VS Code - 项目进行中 (" . A_YYYY . "-" . A_MM . "-" . A_DD . ")"
;     LaunchOrShow("ahk_exe Code.exe", vscodePath, dynamicTitle)
; }

; =================================================================================