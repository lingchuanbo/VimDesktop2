#Requires AutoHotkey v2.0
#Include ..\Lib\DynamicFileMenu.ahk

/**
 * 动态文件菜单示例 - AutoHotkey V2
 * 此示例演示如何使用DynamicFileMenu.ahk创建动态文件菜单
 * 包含三种不同的菜单模式
 */

; 全局变量，存储要扫描的目录
global scanDir := A_ScriptDir  ; 当前目录

/**
 * 处理菜单点击
 * @param ItemName 菜单项名称
 * @param ItemPos 菜单项位置
 * @param MenuName 菜单名称
 */
HandleMenuClick(ItemName, ItemPos, MenuName) {
    ; 获取点击的文件完整路径
    ; 在AHK v2中，我们通过参数接收菜单项文本
    filePath := scanDir "\" ItemName  ; 构建完整文件路径

    ; 显示选择的文件
    MsgBox("您选择了文件: " filePath)

    ; 可以在这里打开文件
    ; Run(filePath)
}

/**
 * 模式1: 基本菜单
 * 使用AHK v2的Menu对象直接创建简单菜单
 */
ShowBasicMenu(*) {
    ; 创建菜单
    fileMenu := Menu()

    ; 扫描目录中的.ahk文件并添加到菜单
    loop files, scanDir "\*.ahk", "F" {
        fileMenu.Add(A_LoopFileName, HandleMenuClick)
    }

    ; 显示菜单
    try {
        fileMenu.Show()
    } catch as err {
        MsgBox("显示菜单时出错: " err.Message)
    }
}

/**
 * 模式2: 使用menu_fromfiles函数
 * 使用DynamicFileMenu.ahk库中的menu_fromfiles函数创建菜单
 * 并返回创建的菜单对象
 */
ShowLibraryMenu(*) {
    try {
        ; 创建主菜单
        mainMenu := Menu()

        ; 使用menu_fromfiles函数创建菜单
        ; 注意：在AHK v2中，我们需要修改使用方式
        menuCount := menu_fromfiles("FileMenu", "文件菜单", HandleMenuClick, A_ScriptDir, "*.ahk|*.txt", "", 1)

        ; 由于AHK v2中动态变量创建的限制，我们需要使用另一种方式来显示菜单
        ; 这里我们使用第三种模式来展示
        if (menuCount > 0) {
            MsgBox("menu_fromfiles函数已添加 " menuCount " 个菜单项，但在AHK v2中需要修改使用方式。`n`n请按F3查看推荐的实现方式。")
        } else {
            MsgBox("没有找到匹配的文件")
        }
    } catch as err {
        MsgBox("创建菜单时出错: " err.Message)
    }
}

/**
 * 模式3: 推荐的AHK v2实现方式
 * 使用DynamicFileMenu.ahk库中的ScanDirectoryForMenu函数
 */
ShowSubmenuMode(*) {
    try {
        ; 创建一个新的菜单
        dynamicMenu := Menu()

        ; 使用库中的ScanDirectoryForMenu函数扫描目录及子目录
        ; 参数说明:
        ; 1. 菜单对象
        ; 2. 要扫描的目录
        ; 3. 文件掩码 (可用"|"分隔多个格式)
        ; 4. 回调函数 (可选，这里我们传入自定义的HandleMenuClick函数)
        ; 5. 是否包含子文件夹 (可选，默认为true)
        itemCount := ScanDirectoryForMenu(dynamicMenu, A_ScriptDir, "*.ahk|*.md", HandleMenuClick)

        ; 显示菜单
        if (itemCount > 0) {
            dynamicMenu.Show()
        } else {
            MsgBox("没有找到匹配的文件")
        }
    } catch as err {
        MsgBox("显示子菜单时出错: " err.Message)
    }
}

; 注意: 我们不再需要自己实现ScanDirectoryForMenu函数
; 因为它已经在更新后的DynamicFileMenu.ahk库中提供

; 热键: F1 显示基本菜单
F1:: ShowBasicMenu

; 热键: F2 显示使用menu_fromfiles函数的菜单
F2:: ShowLibraryMenu

; 热键: F3 显示推荐的AHK v2实现方式
F3:: ShowSubmenuMode

; 显示提示信息
MsgBox("动态文件菜单示例 - 三种实现方式:`n`n"
    . "F1: 基本菜单 - 仅显示当前目录中的.ahk文件`n"
    . "F2: 使用menu_fromfiles函数 - 展示库函数用法`n"
    . "F3: AHK v2推荐实现 - 扫描目录及子目录中的.ahk和.md文件`n`n"
    . "注意: 由于AHK v1到v2的变化，menu_fromfiles函数需要修改才能完全适配AHK v2")