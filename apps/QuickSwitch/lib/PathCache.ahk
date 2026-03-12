;===========================================================
; PathCache.ahk - 路径缓存优化模块
;===========================================================
; 功能：
; 1. 缓存文件管理器路径，避免频繁查询
; 2. 自动失效过期缓存
; 3. 智能预加载
; 4. 内存优化管理
;===========================================================

class PathCache {
    ; 缓存数据结构
    static cache := Map()
    
    ; 缓存配置
    static config := {
        enabled: true,              ; 是否启用缓存
        timeout: 1000,              ; 缓存超时时间(毫秒)
        maxSize: 50,                ; 最大缓存条目数
        preloadEnabled: true        ; 是否启用预加载
    }
    
    ; 统计信息
    static stats := {
        hits: 0,                    ; 缓存命中次数
        misses: 0,                  ; 缓存未命中次数
        evictions: 0                ; 缓存驱逐次数
    }
    
    ; 初始化缓存
    static Init(enabled := true, timeout := 1000, maxSize := 50) {
        this.config.enabled := enabled
        this.config.timeout := timeout
        this.config.maxSize := maxSize
        
        ; 从配置文件读取设置
        try {
            if (IsSet(g_Config) && g_Config.HasOwnProp("IniFile")) {
                cacheEnabled := UTF8IniRead(g_Config.IniFile, "Cache", "Enabled", "1")
                this.config.enabled := (cacheEnabled = "1")
                
                cacheTimeout := UTF8IniRead(g_Config.IniFile, "Cache", "Timeout", "1000")
                this.config.timeout := Integer(cacheTimeout)
                
                cacheMaxSize := UTF8IniRead(g_Config.IniFile, "Cache", "MaxSize", "50")
                this.config.maxSize := Integer(cacheMaxSize)
            }
        } catch {
            ; 配置读取失败，使用默认值
        }
        
        ; 定期清理过期缓存
        SetTimer(this.CleanExpired.Bind(this), 5000)
    }
    
    ; 获取缓存路径
    static Get(winID, provider) {
        if (!this.config.enabled) {
            return provider()
        }
        
        cacheKey := this.GetCacheKey(winID)
        
        ; 检查缓存是否存在且未过期
        if (this.cache.Has(cacheKey)) {
            cacheEntry := this.cache[cacheKey]
            
            if (!this.IsExpired(cacheEntry)) {
                ; 缓存命中
                this.stats.hits++
                
                ; 更新访问时间
                cacheEntry.lastAccess := A_TickCount
                
                if (IsSet(ErrorHandler))
                    ErrorHandler.Debug("路径缓存命中: " winID, "PathCache")
                
                return cacheEntry.path
            } else {
                ; 缓存过期，删除
                this.cache.Delete(cacheKey)
            }
        }
        
        ; 缓存未命中，获取新路径
        this.stats.misses++
        
        path := provider()
        
        ; 存入缓存
        if (path != "") {
            this.Set(winID, path)
        }
        
        return path
    }
    
    ; 设置缓存
    static Set(winID, path) {
        if (!this.config.enabled || path = "")
            return
        
        ; 检查缓存大小，必要时驱逐旧条目
        if (this.cache.Length >= this.config.maxSize) {
            this.EvictOldest()
        }
        
        cacheKey := this.GetCacheKey(winID)
        
        this.cache[cacheKey] := {
            path: path,
            createTime: A_TickCount,
            lastAccess: A_TickCount,
            winID: winID
        }
        
        if (IsSet(ErrorHandler))
            ErrorHandler.Debug("路径已缓存: " winID " -> " path, "PathCache")
    }
    
    ; 删除缓存
    static Delete(winID) {
        cacheKey := this.GetCacheKey(winID)
        
        if (this.cache.Has(cacheKey)) {
            this.cache.Delete(cacheKey)
            
            if (IsSet(ErrorHandler))
                ErrorHandler.Debug("缓存已删除: " winID, "PathCache")
        }
    }
    
    ; 清空所有缓存
    static Clear() {
        count := this.cache.Length
        this.cache.Clear()
        
        if (IsSet(ErrorHandler))
            ErrorHandler.Info("已清空 " count " 个缓存条目", "PathCache")
    }
    
    ; 检查缓存是否过期
    static IsExpired(cacheEntry) {
        elapsed := A_TickCount - cacheEntry.createTime
        return elapsed > this.config.timeout
    }
    
    ; 驱逐最旧的缓存条目
    static EvictOldest() {
        if (this.cache.Length = 0)
            return
        
        oldestKey := ""
        oldestTime := A_TickCount
        
        for key, entry in this.cache {
            if (entry.lastAccess < oldestTime) {
                oldestTime := entry.lastAccess
                oldestKey := key
            }
        }
        
        if (oldestKey != "") {
            this.cache.Delete(oldestKey)
            this.stats.evictions++
            
            if (IsSet(ErrorHandler))
                ErrorHandler.Debug("驱逐最旧缓存: " oldestKey, "PathCache")
        }
    }
    
    ; 清理过期缓存
    static CleanExpired() {
        if (!this.config.enabled || this.cache.Length = 0)
            return
        
        expiredKeys := []
        
        for key, entry in this.cache {
            if (this.IsExpired(entry)) {
                expiredKeys.Push(key)
            }
        }
        
        ; 删除过期条目
        for key in expiredKeys {
            this.cache.Delete(key)
        }
        
        if (expiredKeys.Length > 0 && IsSet(ErrorHandler)) {
            ErrorHandler.Debug("清理了 " expiredKeys.Length " 个过期缓存", "PathCache")
        }
    }
    
    ; 生成缓存键
    static GetCacheKey(winID) {
        return "Path_" winID
    }
    
    ; 预加载路径 - 后台预加载常用路径
    static Preload(winIDs) {
        if (!this.config.preloadEnabled || !this.config.enabled)
            return
        
        ; 异步预加载
        SetTimer((*) => this.PreloadPaths(winIDs), -100)
    }
    
    ; 预加载路径实现
    static PreloadPaths(winIDs) {
        loaded := 0
        
        for winID in winIDs {
            ; 只预加载未缓存的窗口
            cacheKey := this.GetCacheKey(winID)
            
            if (!this.cache.Has(cacheKey)) {
                try {
                    ; 使用增强的路径获取方法
                    if (IsSet(GetExplorerPathEnhanced)) {
                        path := GetExplorerPathEnhanced(winID)
                        
                        if (path != "") {
                            this.Set(winID, path)
                            loaded++
                        }
                    }
                } catch {
                    ; 预加载失败，忽略
                }
            }
        }
        
        if (loaded > 0 && IsSet(ErrorHandler)) {
            ErrorHandler.Info("预加载了 " loaded " 个路径", "PathCache")
        }
    }
    
    ; 获取缓存统计信息
    static GetStats() {
        hitRate := 0
        total := this.stats.hits + this.stats.misses
        
        if (total > 0) {
            hitRate := (this.stats.hits / total) * 100
        }
        
        return {
            hits: this.stats.hits,
            misses: this.stats.misses,
            evictions: this.stats.evictions,
            hitRate: Format("{:.2f}", hitRate) "%",
            size: this.cache.Length,
            maxSize: this.config.maxSize
        }
    }
    
    ; 重置统计信息
    static ResetStats() {
        this.stats := {
            hits: 0,
            misses: 0,
            evictions: 0
        }
    }
    
    ; 获取缓存状态报告
    static GetReport() {
        stats := this.GetStats()
        
        report := "路径缓存报告`n"
        report .= "================`n"
        report .= "缓存状态: " (this.config.enabled ? "启用" : "禁用") "`n"
        report .= "缓存大小: " stats.size "/" stats.maxSize "`n"
        report .= "缓存命中: " stats.hits "`n"
        report .= "缓存未命中: " stats.misses "`n"
        report .= "命中率: " stats.hitRate "`n"
        report .= "驱逐次数: " stats.evictions "`n"
        report .= "超时时间: " this.config.timeout "ms`n"
        
        return report
    }
    
    ; 优化缓存配置
    static Optimize() {
        stats := this.GetStats()
        
        ; 根据命中率自动调整缓存大小
        hitRate := Float(StrReplace(stats.hitRate, "%", ""))
        
        if (hitRate < 30 && this.config.maxSize < 100) {
            ; 命中率低，增加缓存大小
            this.config.maxSize := Min(this.config.maxSize * 2, 100)
            
            if (IsSet(ErrorHandler))
                ErrorHandler.Info("缓存优化: 增加最大缓存到 " this.config.maxSize, "PathCache")
            
        } else if (hitRate > 80 && this.config.maxSize > 30) {
            ; 命中率高，可以减小缓存大小
            this.config.maxSize := Max(this.config.maxSize / 2, 30)
            
            if (IsSet(ErrorHandler))
                ErrorHandler.Info("缓存优化: 减少最大缓存到 " this.config.maxSize, "PathCache")
        }
        
        ; 根据缓存使用情况调整超时时间
        if (stats.evictions > stats.hits / 2) {
            ; 驱逐次数过多，增加超时时间
            this.config.timeout := Min(this.config.timeout * 1.5, 5000)
            
            if (IsSet(ErrorHandler))
                ErrorHandler.Info("缓存优化: 增加超时到 " this.config.timeout "ms", "PathCache")
        }
    }
}
