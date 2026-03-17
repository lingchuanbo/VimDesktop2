class RuntimeLog {
    static LogMessage(message, level := "INFO") {
        global g_LogEnabled

        if (!g_LogEnabled) {
            return
        }

        try {
            this.AppendDailyLog("QuickSwitch", level, message)
        } catch {
        }
    }

    static LogPerfSummary(message, level := "INFO") {
        global g_LogEnabled

        if (!g_LogEnabled) {
            return
        }

        try {
            this.AppendDailyLog("QuickSwitchPerf", level, message)
        } catch {
        }
    }

    static AppendDailyLog(logPrefix, level, message) {
        this.EnsureDailyLogCleanup()
        logFile := this.GetDailyLogFilePath(logPrefix)
        timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")

        for line in StrSplit(message, "`n") {
            if (line = "") {
                continue
            }
            logEntry := timestamp . " [" . level . "] " . line
            FileAppend(logEntry . "`n", logFile, "UTF-8")
        }
    }

    static GetDailyLogFilePath(logPrefix) {
        logDir := A_ScriptDir . "\\logs"
        if !DirExist(logDir) {
            DirCreate(logDir)
        }

        dateText := FormatTime(A_Now, "yyyy-MM-dd")
        return logDir . "\\" . logPrefix . "_" . dateText . ".log"
    }

    static EnsureDailyLogCleanup() {
        global g_LogEnabled, g_LastLogCleanupDate

        if (!g_LogEnabled) {
            return
        }

        today := FormatTime(A_Now, "yyyy-MM-dd")
        if (g_LastLogCleanupDate = today) {
            return
        }

        this.CleanupExpiredLogFiles()
        g_LastLogCleanupDate := today
    }

    static CleanupExpiredLogFiles() {
        global g_LogRetentionDays

        logDir := A_ScriptDir . "\\logs"
        if !DirExist(logDir) {
            return
        }

        retentionDays := g_LogRetentionDays
        if (retentionDays < 1) {
            retentionDays := 1
        }

        cutoffTime := DateAdd(A_Now, -retentionDays, "Days")
        loop files, logDir . "\\QuickSwitch*.log" {
            try {
                if (A_LoopFileTimeModified < cutoffTime) {
                    FileDelete(A_LoopFileFullPath)
                }
            }
        }
    }

    static LogPathExtraction(winID, method, path, success := true) {
        global g_LogEnabled

        if (!g_LogEnabled) {
            return
        }

        try {
            winTitle := WinGetTitle("ahk_id " . winID)
            winClass := WinGetClass("ahk_id " . winID)
            status := success ? "成功" : "失败"

            message := "窗口路径提取 - 窗口ID: " . winID . ", 标题: " . winTitle . ", 类名: " . winClass
            message .= ", 方法: " . method . ", 路径: " . path . ", 状态: " . status

            this.LogMessage(message, "DEBUG")
        } catch {
        }
    }

    static LogMenuBuildElapsed(menuName, startTick, itemCount := 0) {
        global g_LogEnabled

        elapsedMs := A_TickCount - startTick
        if (!g_LogEnabled) {
            return
        }

        this.UpdateMenuPerfStats(menuName, "__TOTAL__", elapsedMs, itemCount)
        this.MaybeLogMenuPerfSummary()

        level := elapsedMs >= 150 ? "WARN" : "DEBUG"
        this.LogMessage("菜单构建耗时: " . menuName . ", elapsed=" . elapsedMs . "ms, items=" . itemCount, level)
    }

    static LogMenuStageElapsed(menuName, stageName, &stageTick, totalStartTick, itemCount := -1) {
        global g_LogEnabled

        nowTick := A_TickCount
        if (!g_LogEnabled) {
            stageTick := nowTick
            return
        }

        deltaMs := nowTick - stageTick
        totalMs := nowTick - totalStartTick
        this.UpdateMenuPerfStats(menuName, stageName, deltaMs, itemCount)

        level := deltaMs >= 120 ? "WARN" : "DEBUG"
        message := "菜单阶段耗时: " . menuName . ", stage=" . stageName . ", delta=" . deltaMs . "ms, total=" . totalMs . "ms"
        if (itemCount >= 0) {
            message .= ", items=" . itemCount
        }

        this.LogMessage(message, level)
        stageTick := nowTick
    }

    static ResetMenuPerfStats() {
        global g_MenuPerfStats, g_MenuPerfLastSummaryTick

        g_MenuPerfStats := Map()
        g_MenuPerfLastSummaryTick := 0
    }

    static UpdateMenuPerfStats(menuName, stageName, elapsedMs, itemCount := -1) {
        global g_MenuPerfStats

        statKey := menuName . "|" . stageName
        if (!g_MenuPerfStats.Has(statKey)) {
            g_MenuPerfStats[statKey] := {
                menu: menuName,
                stage: stageName,
                count: 0,
                total: 0,
                max: 0,
                last: 0,
                itemTotal: 0,
                itemSamples: 0
            }
        }

        stat := g_MenuPerfStats[statKey]
        stat.count += 1
        stat.total += elapsedMs
        stat.last := elapsedMs
        if (elapsedMs > stat.max) {
            stat.max := elapsedMs
        }
        if (itemCount >= 0) {
            stat.itemTotal += itemCount
            stat.itemSamples += 1
        }
    }

    static GetTopMenuPerfEntries(entries, topN) {
        topEntries := []
        if (topN <= 0) {
            return topEntries
        }

        for entry in entries {
            inserted := false
            loop topEntries.Length {
                if (entry.score > topEntries[A_Index].score) {
                    topEntries.InsertAt(A_Index, entry)
                    inserted := true
                    break
                }
            }

            if (!inserted) {
                topEntries.Push(entry)
            }

            while (topEntries.Length > topN) {
                topEntries.Pop()
            }
        }

        return topEntries
    }

    static BuildMenuPerfSummaryText(minSamples := 3, topN := 5) {
        global g_MenuPerfStats

        if (minSamples < 1) {
            minSamples := 1
        }
        if (topN < 1) {
            topN := 1
        }

        entries := []
        for statKey, stat in g_MenuPerfStats {
            if (stat.count < minSamples) {
                continue
            }

            avgMs := stat.total / stat.count
            entries.Push({
                menu: stat.menu,
                stage: stat.stage,
                count: stat.count,
                avg: Round(avgMs, 1),
                max: stat.max,
                last: stat.last,
                avgItems: stat.itemSamples > 0 ? Round(stat.itemTotal / stat.itemSamples, 1) : -1,
                score: avgMs + (stat.max * 0.2)
            })
        }

        if (entries.Length = 0) {
            return ""
        }

        finalTopN := Min(entries.Length, topN)
        topEntries := this.GetTopMenuPerfEntries(entries, finalTopN)
        if (topEntries.Length = 0) {
            return ""
        }

        summary := "菜单性能Top" . topEntries.Length . "慢段统计`n"
        for entry in topEntries {
            line := "- " . entry.menu . "/" . entry.stage
                . " avg=" . entry.avg . "ms"
                . " max=" . entry.max . "ms"
                . " count=" . entry.count
                . " last=" . entry.last . "ms"
            if (entry.avgItems >= 0) {
                line .= " avgItems=" . entry.avgItems
            }
            summary .= line . "`n"
        }

        return RTrim(summary, "`n")
    }

    static MaybeLogMenuPerfSummary(force := false) {
        global g_LogEnabled, g_MenuPerfLastSummaryTick
        global g_MenuPerfSummaryIntervalMs, g_MenuPerfTopN, g_MenuPerfMinSamples

        if (!g_LogEnabled) {
            return
        }

        nowTick := A_TickCount
        if (!force && g_MenuPerfLastSummaryTick != 0
            && (nowTick - g_MenuPerfLastSummaryTick) < g_MenuPerfSummaryIntervalMs) {
            return
        }

        summary := this.BuildMenuPerfSummaryText(g_MenuPerfMinSamples, g_MenuPerfTopN)
        if (summary = "") {
            g_MenuPerfLastSummaryTick := nowTick
            return
        }

        this.LogPerfSummary(summary, "INFO")
        g_MenuPerfLastSummaryTick := nowTick
    }
}
