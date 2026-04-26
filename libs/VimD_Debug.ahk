; VimD_Debug.ahk - 性能/状态监控面板
; 使用: VimD_ShowMonitor() 切换显示

class VimD_Monitor {
    static _gui := ""
    static _timer := ""
    static _visible := false
    static _pollMs := 200

    static Toggle() {
        if (this._visible) {
            this.Hide()
        } else {
            this.Show()
        }
    }

    static Show() {
        if (this._visible)
            return
        this._visible := true
        this._CreateGui()
        this._timer := SetTimer(ObjBindMethod(this, "_Refresh"), this._pollMs)
    }

    static Hide() {
        this._visible := false
        if (this._timer) {
            SetTimer(this._timer, 0)
            this._timer := ""
        }
        try {
            if (this._gui && this._gui.Hwnd)
                this._gui.Destroy()
        }
        this._gui := ""
    }

    static _CreateGui() {
        try {
            if (this._gui && this._gui.Hwnd)
                this._gui.Destroy()
        }
        this._gui := Gui("+AlwaysOnTop +ToolWindow -Caption +Border", "VimD Monitor")
        this._gui.SetFont("s9", "Consolas")
        this._gui.BackColor := "1E1E1E"
        this._gui.Add("Text", "x5 y3 w260 c00FF00 vTitle", "VimDesktop Monitor")
        this._gui.Add("Text", "x5 y21 w260 cCCCCCC vBody", "...")
        this._gui.Show("x0 y0 w270 h120 NoActivate")
    }

    static _Refresh() {
        if (!this._visible || !this._gui || !this._gui.Hwnd)
            return

        try {
            global vim
            winName := vim.CheckWin()
            winObj := vim.GetWin(winName)
            curMode := vim.GetCurMode(winName)
            lastKey := winObj.LastKey
            keyTemp := winObj.KeyTemp
            count := winObj.Count

            lines := ""
            lines .= "Window : " winName "`n"
            lines .= "Mode   : " curMode "`n"
            lines .= "Buffer : " (keyTemp ? keyTemp : "(empty)") "`n"
            lines .= "Count  : " count "`n"
            lines .= "LastKey: " (lastKey ? lastKey : "(none)") "`n"

            this._gui["Body"].Value := lines

            ; 智能定位：右下角
            MonitorGetWorkArea(, , &right, &bottom)
            this._gui.GetPos(&x, &y, &w, &h)
            newX := right - w - 10
            newY := bottom - h - 10
            if (x != newX || y != newY)
                this._gui.Move(newX, newY)
        }
    }
}

VimD_ShowMonitor() {
    VimD_Monitor.Toggle()
}
