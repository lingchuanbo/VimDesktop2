class RuntimeWindowState {
    static InitializeCurrentWindows() {
        global g_WindowHistory, g_LastTwoWindows, g_Config

        try {
            windowSnapshot := this.CollectWindowSnapshot()
            windowsInfo := windowSnapshot.VisibleWindows
            g_WindowHistory.Length := 0
            g_LastTwoWindows.Length := 0

            loop windowsInfo.Length {
                windowInfo := windowsInfo[windowsInfo.Length - A_Index + 1]
                g_WindowHistory.Push(windowInfo)

                if (g_WindowHistory.Length > g_Config.MaxHistoryCount) {
                    break
                }
            }

            if (g_WindowHistory.Length >= 1) {
                g_LastTwoWindows.Push(g_WindowHistory[1])
            }
            if (g_WindowHistory.Length >= 2) {
                g_LastTwoWindows.Push(g_WindowHistory[2])
            }
        } catch {
        }
    }

    static CollectWindowSnapshot() {
        snapshot := {
            AllWindowIds: WinGetList(),
            VisibleWindows: []
        }

        ; TODO: If Ctrl+Q profiling still shows pressure here, add a short-lived snapshot cache.
        for winID in snapshot.AllWindowIds {
            try {
                if (!WinExist("ahk_id " . winID)) {
                    continue
                }

                winTitle := WinGetTitle("ahk_id " . winID)
                processName := WinGetProcessName("ahk_id " . winID)

                if (ShouldExcludeWindow(processName, winTitle)) {
                    continue
                }

                if (!IsWindowVisible(winID)) {
                    continue
                }

                snapshot.VisibleWindows.Push({
                    ID: winID,
                    Title: winTitle,
                    ProcessName: processName,
                    Timestamp: A_Now
                })
            } catch {
                continue
            }
        }

        return snapshot
    }

    static MonitorActiveWindow() {
        static lastActiveWindow := ""

        try {
            currentWindow := WinExist("A")
            if (!currentWindow || currentWindow = lastActiveWindow) {
                return
            }

            winTitle := WinGetTitle("ahk_id " . currentWindow)
            processName := WinGetProcessName("ahk_id " . currentWindow)

            if (ShouldExcludeWindow(processName, winTitle)) {
                return
            }

            this.UpdateWindowHistory(currentWindow, winTitle, processName)
            lastActiveWindow := currentWindow
        } catch {
        }
    }

    static UpdateWindowHistory(winID, winTitle, processName) {
        global g_WindowHistory, g_Config

        windowInfo := {
            ID: winID,
            Title: winTitle,
            ProcessName: processName,
            Timestamp: A_Now
        }

        for i, existingWindow in g_WindowHistory {
            if (existingWindow.ID = winID) {
                g_WindowHistory.RemoveAt(i)
                break
            }
        }

        g_WindowHistory.InsertAt(1, windowInfo)

        while (g_WindowHistory.Length > g_Config.MaxHistoryCount) {
            g_WindowHistory.Pop()
        }

        this.UpdateLastTwoWindows(windowInfo)
    }

    static UpdateLastTwoWindows(currentWindow) {
        global g_LastTwoWindows

        if (g_LastTwoWindows.Length = 0) {
            g_LastTwoWindows.Push(currentWindow)
            return
        }

        if (g_LastTwoWindows[1].ID = currentWindow.ID) {
            return
        }

        if (g_LastTwoWindows.Length >= 2) {
            g_LastTwoWindows.RemoveAt(2)
        }

        g_LastTwoWindows.InsertAt(1, currentWindow)
    }

    static CollectPinnedWindowMenuItems(windowSnapshot := "") {
        pinnedMenuItems := []

        if !IsObject(windowSnapshot) {
            windowSnapshot := this.CollectWindowSnapshot()
        }

        ; TODO: Later we can merge pinned/history menu item creation behind a shared window-menu-item builder.
        for windowInfo in windowSnapshot.VisibleWindows {
            try {
                if (!IsPinnedApp(windowInfo.ProcessName)) {
                    continue
                }

                pinnedMenuItems.Push({
                    WindowId: windowInfo.ID,
                    ProcessName: windowInfo.ProcessName,
                    DisplayText: CreateDisplayText(windowInfo.Title, windowInfo.ProcessName)
                })
            } catch {
                continue
            }
        }

        return pinnedMenuItems
    }

    static CollectHistoryWindowMenuItems() {
        global g_WindowHistory

        historyMenuItems := []

        ; TODO: Later we can enrich this with ordering/debug metadata for Ctrl+Q diagnostics.
        for windowInfo in g_WindowHistory {
            try {
                if (!WinExist("ahk_id " . windowInfo.ID)) {
                    continue
                }

                if (IsPinnedApp(windowInfo.ProcessName)) {
                    continue
                }

                historyMenuItems.Push({
                    WindowId: windowInfo.ID,
                    ProcessName: windowInfo.ProcessName,
                    DisplayText: CreateDisplayText(windowInfo.Title, windowInfo.ProcessName)
                })
            } catch {
                continue
            }
        }

        return historyMenuItems
    }

    static QuickSwitchLastTwo() {
        global g_LastTwoWindows

        if (g_LastTwoWindows.Length < 2) {
            return
        }

        try {
            currentWindow := WinExist("A")

            if (currentWindow = g_LastTwoWindows[1].ID) {
                targetWindow := g_LastTwoWindows[2]
            } else {
                targetWindow := g_LastTwoWindows[1]
            }

            WinActivate("ahk_id " . targetWindow.ID)
            WinShow("ahk_id " . targetWindow.ID)

            if (WinGetMinMax("ahk_id " . targetWindow.ID) = -1) {
                WinRestore("ahk_id " . targetWindow.ID)
            }
        } catch {
            ShowWindowSwitchMenu()
        }
    }
}
