class RuntimeMenu {
    static TryAcquire(owner := "") {
        global g_MenuActive, g_MenuLockToken, g_MenuLockOwner, g_LastMenuOpenTick
        static nextToken := 0

        if (g_MenuActive) {
            this.ReportReject("active:" . g_MenuLockOwner, owner)
            return 0
        }

        if (this.IsRequestThrottled()) {
            this.ReportReject("throttled", owner)
            return 0
        }

        nextToken += 1
        if (nextToken > 0x7FFFFFFF) {
            nextToken := 1
        }

        g_MenuActive := true
        g_MenuLockToken := nextToken
        g_MenuLockOwner := owner
        g_LastMenuOpenTick := A_TickCount
        RuntimeLog.LogMessage("菜单锁获取: owner=" . owner . ", token=" . nextToken, "DEBUG")
        return nextToken
    }

    static Release(lockToken := 0) {
        global g_MenuActive, g_MenuLockToken, g_MenuLockOwner

        if (lockToken != 0 && lockToken != g_MenuLockToken) {
            RuntimeLog.LogMessage("忽略过期菜单解锁: token=" . lockToken . ", current=" . g_MenuLockToken, "DEBUG")
            return
        }

        if (g_MenuActive) {
            RuntimeLog.LogMessage("菜单锁释放: owner=" . g_MenuLockOwner . ", token=" . g_MenuLockToken, "DEBUG")
        }

        g_MenuActive := false
        g_MenuLockToken := 0
        g_MenuLockOwner := ""
    }

    static ScheduleUnlock(lockToken, delayMs := 150) {
        if (delayMs <= 0) {
            this.Release(lockToken)
            return
        }
        SetTimer(this.Release.Bind(this, lockToken), -delayMs)
    }

    static IsRequestThrottled() {
        global g_LastMenuOpenTick, g_MenuCooldownMs

        if (g_LastMenuOpenTick = 0) {
            return false
        }
        return (A_TickCount - g_LastMenuOpenTick) < g_MenuCooldownMs
    }

    static ReportReject(reason, owner := "") {
        global g_LastMenuLockRejectTick, g_LastMenuLockRejectReason

        nowTick := A_TickCount
        if (reason = g_LastMenuLockRejectReason && (nowTick - g_LastMenuLockRejectTick) < 500) {
            return
        }

        g_LastMenuLockRejectReason := reason
        g_LastMenuLockRejectTick := nowTick
        RuntimeLog.LogMessage("菜单锁拒绝: reason=" . reason . ", owner=" . owner, "DEBUG")
    }
}
