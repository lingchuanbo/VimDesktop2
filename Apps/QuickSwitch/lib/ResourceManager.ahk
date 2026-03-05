;===========================================================
; ResourceManager.ahk - 资源管理模块
;===========================================================
; 功能：
; 1. 统一管理系统资源（文件、句柄、对象等）
; 2. 自动清理临时资源
; 3. 防止内存泄漏
; 4. 程序退出时自动释放所有资源
;===========================================================

class ResourceManager {
    ; 资源列表
    static resources := []
    
    ; 资源类型定义
    static types := Map(
        "file", "FileResource",
        "handle", "HandleResource",
        "object", "ObjectResource",
        "timer", "TimerResource",
        "gui", "GuiResource",
        "menu", "MenuResource"
    )
    
    ; 统计信息
    static stats := {
        totalAllocated: 0,
        totalReleased: 0,
        currentActive: 0
    }
    
    ; 初始化资源管理器
    static Init() {
        ; 注册退出清理函数
        OnExit((*) => this.CleanupAll())
        
        ; 定期检查资源泄漏
        SetTimer((*) => this.CheckLeaks(), 10000)
        
        if (IsSet(ErrorHandler))
            ErrorHandler.Info("资源管理器已初始化", "ResourceManager")
    }
    
    ; 注册资源
    static Register(resource, resourceType, cleanupFunc, description := "") {
        resourceEntry := {
            resource: resource,
            type: resourceType,
            cleanup: cleanupFunc,
            description: description,
            createTime: A_TickCount,
            id: this.GenerateId()
        }
        
        this.resources.Push(resourceEntry)
        this.stats.totalAllocated++
        this.stats.currentActive++
        
        if (IsSet(ErrorHandler))
            ErrorHandler.Debug("资源已注册: " . (description != "" ? description : resourceType) . " (ID: " . resourceEntry.id . ")", "ResourceManager")
        
        return resourceEntry.id
    }
    
    ; 释放资源
    static Release(resourceId) {
        index := this.FindResourceIndex(resourceId)
        
        if (index > 0) {
            resourceEntry := this.resources[index]
            
            try {
                ; 执行清理函数
                resourceEntry.cleanup(resourceEntry.resource)
                
                ; 从列表中移除
                this.resources.RemoveAt(index)
                
                this.stats.totalReleased++
                this.stats.currentActive--
                
                if (IsSet(ErrorHandler))
                    ErrorHandler.Debug("资源已释放: " . (resourceEntry.description != "" ? resourceEntry.description : resourceEntry.type) . " (ID: " . resourceId . ")", "ResourceManager")
                
                return true
            } catch as e {
                if (IsSet(ErrorHandler))
                    ErrorHandler.Error("释放资源失败: " . e.message . " (ID: " . resourceId . ")", "ResourceManager")
                
                return false
            }
        }
        
        return false
    }
    
    ; 清理所有资源
    static CleanupAll() {
        if (this.resources.Length = 0)
            return
        
        if (IsSet(ErrorHandler))
            ErrorHandler.Info("开始清理 " . this.resources.Length . " 个资源", "ResourceManager")
        
        ; 逆序释放资源（后进先出）
        released := 0
        failed := 0
        
        loop this.resources.Length {
            resourceEntry := this.resources[this.resources.Length - A_Index + 1]
            
            try {
                resourceEntry.cleanup(resourceEntry.resource)
                released++
            } catch as e {
                failed++
                
                if (IsSet(ErrorHandler))
                    ErrorHandler.Error("清理资源失败: " . e.message, "ResourceManager")
            }
        }
        
        ; 清空资源列表
        this.resources.Clear()
        this.stats.currentActive := 0
        
        if (IsSet(ErrorHandler))
            ErrorHandler.Info("资源清理完成 - 成功: " . released . ", 失败: " . failed, "ResourceManager")
    }
    
    ; 检查资源泄漏
    static CheckLeaks() {
        if (this.resources.Length = 0)
            return
        
        now := A_TickCount
        leakThreshold := 300000 ; 5分钟未使用的资源视为潜在泄漏
        
        potentialLeaks := []
        
        for resourceEntry in this.resources {
            age := now - resourceEntry.createTime
            
            if (age > leakThreshold) {
                potentialLeaks.Push({
                    type: resourceEntry.type,
                    description: resourceEntry.description,
                    age: age
                })
            }
        }
        
        if (potentialLeaks.Length > 0 && IsSet(ErrorHandler)) {
            ErrorHandler.Warning("发现 " . potentialLeaks.Length . " 个潜在资源泄漏", "ResourceManager")
            
            for leak in potentialLeaks {
                ErrorHandler.Debug("泄漏资源: " . leak.type . " - " . leak.description . " (存活: " . leak.age . "ms)", "ResourceManager")
            }
        }
    }
    
    ; 查找资源索引
    static FindResourceIndex(resourceId) {
        for index, resourceEntry in this.resources {
            if (resourceEntry.id = resourceId) {
                return index
            }
        }
        return 0
    }
    
    ; 生成资源ID
    static GenerateId() {
        static counter := 0
        counter++
        return "RES_" . A_TickCount . "_" . counter
    }
    
    ; 获取统计信息
    static GetStats() {
        return {
            totalAllocated: this.stats.totalAllocated,
            totalReleased: this.stats.totalReleased,
            currentActive: this.stats.currentActive,
            resourceCount: this.resources.Length
        }
    }
    
    ; 获取资源报告
    static GetReport() {
        stats := this.GetStats()
        
        report := "资源管理报告`n"
        report .= "================`n"
        report .= "已分配: " . stats.totalAllocated . "`n"
        report .= "已释放: " . stats.totalReleased . "`n"
        report .= "当前活跃: " . stats.currentActive . "`n"
        report .= "资源数量: " . stats.resourceCount . "`n`n"
        
        if (this.resources.Length > 0) {
            report .= "活跃资源列表:`n"
            
            for resourceEntry in this.resources {
                age := (A_TickCount - resourceEntry.createTime) / 1000
                report .= "  • [" . resourceEntry.type . "] " . resourceEntry.description
                report .= " (存活: " . Format("{:.1f}", age) . "s)`n"
            }
        }
        
        return report
    }
    
    ; ==================== 便捷方法 ====================
    
    ; 注册文件资源
    static RegisterFile(filePath, description := "") {
        return this.Register(filePath, "file", (f) => this.CleanupFile(f), description)
    }
    
    ; 注册句柄资源
    static RegisterHandle(handle, description := "") {
        return this.Register(handle, "handle", (h) => this.CleanupHandle(h), description)
    }
    
    ; 注册对象资源
    static RegisterObject(obj, description := "") {
        return this.Register(obj, "object", (o) => this.CleanupObject(o), description)
    }
    
    ; 注册定时器资源
    static RegisterTimer(timerFunc, description := "") {
        return this.Register(timerFunc, "timer", (t) => this.CleanupTimer(t), description)
    }
    
    ; 注册GUI资源
    static RegisterGui(guiObj, description := "") {
        return this.Register(guiObj, "gui", (g) => this.CleanupGui(g), description)
    }
    
    ; 注册菜单资源
    static RegisterMenu(menuObj, description := "") {
        return this.Register(menuObj, "menu", (m) => this.CleanupMenu(m), description)
    }
    
    ; ==================== 清理函数 ====================
    
    ; 清理文件
    static CleanupFile(filePath) {
        if (FileExist(filePath)) {
            try {
                FileDelete(filePath)
                
                if (IsSet(ErrorHandler))
                    ErrorHandler.Debug("已删除文件: " . filePath, "ResourceManager")
            } catch as e {
                if (IsSet(ErrorHandler))
                    ErrorHandler.Error("删除文件失败: " . e.message, "ResourceManager")
            }
        }
    }
    
    ; 清理句柄
    static CleanupHandle(handle) {
        if (handle && handle != 0) {
            try {
                DllCall("CloseHandle", "Ptr", handle)
                
                if (IsSet(ErrorHandler))
                    ErrorHandler.Debug("已关闭句柄: " . handle, "ResourceManager")
            } catch as e {
                if (IsSet(ErrorHandler))
                    ErrorHandler.Error("关闭句柄失败: " . e.message, "ResourceManager")
            }
        }
    }
    
    ; 清理对象
    static CleanupObject(obj) {
        ; 对象由垃圾回收器自动处理
        ; 如果对象有Dispose方法，调用它
        try {
            if (HasMethod(obj, "Dispose")) {
                obj.Dispose()
            }
        } catch {
            ; 忽略错误
        }
    }
    
    ; 清理定时器
    static CleanupTimer(timerFunc) {
        try {
            SetTimer(timerFunc, 0)
            
            if (IsSet(ErrorHandler))
                ErrorHandler.Debug("已停止定时器", "ResourceManager")
        } catch as e {
            if (IsSet(ErrorHandler))
                ErrorHandler.Error("停止定时器失败: " . e.message, "ResourceManager")
        }
    }
    
    ; 清理GUI
    static CleanupGui(guiObj) {
        try {
            if (guiObj && HasMethod(guiObj, "Destroy")) {
                guiObj.Destroy()
                
                if (IsSet(ErrorHandler))
                    ErrorHandler.Debug("已销毁GUI", "ResourceManager")
            }
        } catch as e {
            if (IsSet(ErrorHandler))
                ErrorHandler.Error("销毁GUI失败: " . e.message, "ResourceManager")
        }
    }
    
    ; 清理菜单
    static CleanupMenu(menuObj) {
        try {
            if (menuObj && HasMethod(menuObj, "Delete")) {
                menuObj.Delete()
                
                if (IsSet(ErrorHandler))
                    ErrorHandler.Debug("已删除菜单", "ResourceManager")
            }
        } catch as e {
            if (IsSet(ErrorHandler))
                ErrorHandler.Error("删除菜单失败: " . e.message, "ResourceManager")
        }
    }
}

; 全局资源管理便捷函数
RegisterResource(resource, resourceType, cleanupFunc, description := "") {
    return ResourceManager.Register(resource, resourceType, cleanupFunc, description)
}

ReleaseResource(resourceId) {
    return ResourceManager.Release(resourceId)
}

CleanupAllResources() {
    ResourceManager.CleanupAll()
}
