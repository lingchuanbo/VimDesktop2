;DynamicFileMenu.ahk - AutoHotkey V2 版本
;原作者: BGM V1 http://www.autohotkey.com/board/topic/95219-dynamicfilemenuahk/
;修改者: BoBO 
;功能: 从文件系统创建动态菜单，支持多种文件格式和子文件夹，支持多格式 *.ms|*.mse [|]分开
;AHK v2适配: 更新为AHK v2兼容版本 调用示例文件 ..\doc\DynamicMenuExample.ahk
/**
 * 从指定目录创建动态文件菜单
 * @param submenuname 子菜单名称
 * @param menutitle 菜单标题
 * @param callbackFunc 点击菜单项时调用的函数对象或函数名
 * @param whatdir 要扫描的目录路径
 * @param filemask 文件掩码，可用"|"分隔多个格式，如 "*.txt|*.ini"
 * @param parentmenu 父菜单名称
 * @param folders 是否包含子文件夹 (1=是, 0=否)
 * @return 添加的菜单项数量
 *
 * 注意: 在AHK v2中，此函数不再直接创建全局变量。
 * 如需使用创建的菜单，请使用返回的菜单项数量判断是否成功，
 * 并使用ScanDirectoryForMenu函数的方式创建菜单。
 */
menu_fromfiles(submenuname, menutitle, callbackFunc, whatdir, filemask := "*", parentmenu := "", folders := 1) {
    menucount := 0
    filemasks := filemask
    filemasksArray := StrSplit(filemasks, "|") ; 裁减支持格式

    ; 创建子菜单
    subMenu := Menu()

    ; 扫描文件
    for i, mask in filemasksArray {
        Loop Files, whatdir "\" mask, "F" {
            ; 添加文件到菜单
            try {
                if (Type(callbackFunc) = "Func" || IsObject(callbackFunc)) {
                    ; 如果是函数对象，直接使用
                    subMenu.Add(A_LoopFileName, callbackFunc)
                } else if (Type(callbackFunc) = "String") {
                    ; 如果是字符串，尝试获取函数对象
                    try {
                        funcObj := Func(callbackFunc)
                        subMenu.Add(A_LoopFileName, funcObj)
                    } catch {
                        ; 如果获取函数对象失败，尝试直接使用字符串
                        subMenu.Add(A_LoopFileName, callbackFunc)
                    }
                }
                menucount++
            } catch as err {
                ; 忽略错误
            }
        }
    }

    ; 扫描子文件夹
    if (folders) {
        Loop Files, whatdir "\*", "D" {
            ; 为子文件夹创建子菜单
            folderMenu := Menu()

            ; 递归处理子文件夹
            subCount := menu_fromfiles(A_LoopFileName, A_LoopFileName, callbackFunc, A_LoopFileFullPath, filemask, "", folders)

            ; 如果子文件夹有文件，添加到主菜单
            if (subCount > 0) {
                try {
                    subMenu.Add(A_LoopFileName, folderMenu)
                    menucount += subCount
                } catch as err {
                    ; 忽略错误
                }
            }
        }
    }

    ; 如果有父菜单且有菜单项，将子菜单添加到父菜单
    if (parentmenu && menucount) {
        try {
            parentMenuObj := Menu(parentmenu)
            parentMenuObj.Add(menutitle, subMenu)
        } catch as err {
            ; 忽略错误
        }
    }

    ; 注意: 在AHK v2中，不再尝试创建全局变量
    ; 这是与AHK v1版本的主要区别

    return menucount
}

/**
 * 获取菜单项对应的完整文件路径
 * @param whatmenu 菜单名称 (在AHK V2中不再使用)
 * @param whatdir 目录路径
 * @param menuItem 菜单项名称 (可选，默认使用A_ThisMenuItem)
 * @return 菜单项对应的完整文件路径
 */
menu_itempath(whatmenu, whatdir, menuItem := "") {
    ; 如果提供了菜单项，使用它
    if (menuItem)
        return whatdir "\" menuItem

    ; 尝试使用A_ThisMenuItem（仅在菜单回调中有效）
    try {
        if (IsSet(A_ThisMenuItem))
            return whatdir "\" A_ThisMenuItem
    } catch {
        ; A_ThisMenuItem不可用
    }

    ; 如果无法获取菜单项，返回目录路径
    return whatdir
}

/**
 * 检查路径是否为文件夹
 * @param whatfile 要检查的文件路径
 * @return 如果是文件夹返回true，否则返回false
 */
file_isfolder(whatfile) {
    ; 在AHK V2中，使用DirExist函数
    return DirExist(whatfile) ? true : false
}

/**
 * 默认菜单回调函数
 * 当点击菜单项时，打开对应的文件
 * @param dir 文件所在目录
 */
MenuDefaultCallback(dir) {
    ; 在AHK v2中，我们需要使用一个闭包来捕获dir变量
    ; 创建一个函数对象，而不是使用箭头函数
    defaultCallback := MenuItemCallback.Bind(dir)
    return defaultCallback
}

/**
 * 菜单项点击回调函数
 * @param dir 文件所在目录
 */
MenuItemCallback(dir, *) {
    filePath := menu_itempath("", dir)
    if (FileExist(filePath))
        Run(filePath)
}

/**
 * 递归扫描目录并创建菜单 (AHK v2推荐方法)
 * 这是menu_fromfiles函数的替代实现，更适合AHK v2的对象模型
 * @param menuObj 菜单对象
 * @param dir 要扫描的目录
 * @param fileMask 文件掩码，可用"|"分隔多个格式
 * @param callbackFunc 点击菜单项时调用的函数对象或函数名
 * @param includeFolders 是否包含子文件夹 (true=是, false=否)
 * @return 添加的菜单项数量
 */
ScanDirectoryForMenu(menuObj, dir, fileMask, callbackFunc := "", includeFolders := true) {
    ; 如果没有提供回调函数，使用默认的
    if (!callbackFunc) {
        ; 创建一个默认的回调函数
        callbackFunc := MenuDefaultCallback(dir)
    }

    ; 计数器，记录添加的菜单项数量
    itemCount := 0

    ; 分割文件掩码
    fileMasks := StrSplit(fileMask, "|")

    ; 添加文件到菜单
    for _, mask in fileMasks {
        loop files, dir "\" mask, "F" {
            try {
                menuObj.Add(A_LoopFileName, callbackFunc)
                itemCount++
            } catch as err {
                ; 忽略错误
            }
        }
    }

    ; 扫描子目录
    if (includeFolders) {
        loop files, dir "\*", "D" {
            ; 为子目录创建子菜单
            subMenu := Menu()

            ; 递归扫描子目录
            subItemCount := ScanDirectoryForMenu(subMenu, A_LoopFileFullPath, fileMask, callbackFunc, includeFolders)

            ; 如果子菜单有项目，添加到主菜单
            if (subItemCount > 0) {
                try {
                    menuObj.Add(A_LoopFileName, subMenu)
                    itemCount += subItemCount
                } catch as err {
                    ; 忽略错误
                }
            }
        }
    }

    ; 返回添加的菜单项数量
    return itemCount
}