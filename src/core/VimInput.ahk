/* vim_Init【vim初始化】
    函数:  vim_Init
    作用:  vim初始化
    参数:
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
vim_Init() {
    #UseHook
    SetKeyDelay -1
}

/* vim_Key【hotkey注册对应函数，热键调用】
    函数:  vim_Key
    作用:  hotkey注册对应函数，热键调用
    参数:  aThisHotkey,未使用【v2 hotkey callback函数要求】
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
vim_Key(aThisHotkey) {
    vim.Key()
}

/* vim_TimeOut【热键超时】
    函数:  热键超时
    作用:  hotkey注册对应函数，热键调用
    参数:
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
vim_TimeOut() {
    vim.IsTimeOut()
}

/* VIMD_清除输入键【清除输入键】
    函数:  VIMD_清除输入键
    作用:  清除输入键
    参数:
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
VIMD_清除输入键() {
    vim.clear()
    HideInfo(true)  ; 强制隐藏，忽略配置规则
    ; 确保CapsLock状态被关闭，防止卡在大写状态
    SetCapsLockState "AlwaysOff"

    _VIMD_CleanupToolTips()
    _VIMD_MemoryCleanup()
}

_VIMD_CleanupToolTips() {
    ; BTT tooltip清理 - 清理所有tooltip实例
    try {
        BTTCleanupAll()
    } catch {
        ; 忽略BTT清理错误，不影响主功能
    }
}

_VIMD_MemoryCleanup() {
    ; 执行内存优化清理
    try {
        if (IsSet(MemoryOptimizer)) {
            MemoryOptimizer.ManualCleanup()
        }
    } catch {
        ; 忽略内存优化错误，不影响主功能
        try MemoryOptimizer.ManualCleanup()
    }
}

/* VIMD_重复上次热键【重复上次热键】
    函数:  VIMD_重复上次热键
    作用:  重复上次热键
    参数:
    返回:
    作者:  Kawvin
    版本:  1.0
    AHK版本: 2.0.18
*/
VIMD_重复上次热键() {
    SendInput vim.LastHotKey
}

