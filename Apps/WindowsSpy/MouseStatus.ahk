thiscursor := ""  ; Global variable to store cursor info

SetTimer(CursorShape, 20)

CursorShape() {
    global thiscursor
    thiscursor := GetCursorShape()
    ToolTip("thiscursor=" . thiscursor . "`nA_Cursor=" . A_Cursor . "`n按F5复制全部 F6复制状态码 F7复制状态名")
}

GetCursorShape() {   ;获取光标特征码 by nnrxin
    PCURSORINFO := Buffer(20, 0) ;为鼠标信息 结构 设置出20字节空间
    NumPut("UInt", 20, PCURSORINFO, 0)  ;*声明出 结构 的大小cbSize = 20字节
    DllCall("GetCursorInfo", "Ptr", PCURSORINFO) ;获取 结构-光标信息
    if (NumGet(PCURSORINFO, 4, "UInt") = 0) ;当光标隐藏时，直接输出特征码为0
    {
        return 0
    }
    ICONINFO := Buffer(20, 0) ;创建 结构-图标信息
    DllCall("GetIconInfo", "Ptr", NumGet(PCURSORINFO, 8), "Ptr", ICONINFO)  ;获取 结构-图标信息
    lpvMaskBits := Buffer(128, 0) ;创造 数组-掩图信息（128字节）
    DllCall("GetBitmapBits", "Ptr", NumGet(ICONINFO, 12), "UInt", 128, "Ptr", lpvMaskBits)  ;读取 数组-掩图信息
    MaskCode := 0
    Loop 128 { ;掩图码
        MaskCode += NumGet(lpvMaskBits, A_Index - 1, "UChar")  ;累加拼合
    }
    if (NumGet(ICONINFO, 16, "UInt") != 0) { ;颜色图不为空时（彩色图标时）
        lpvColorBits := Buffer(4096, 0)  ;创造 数组-色图信息（4096字节）
        DllCall("GetBitmapBits", "Ptr", NumGet(ICONINFO, 16), "UInt", 4096, "Ptr", lpvColorBits)  ;读取 数组-色图信息
        ColorCode := 0
        Loop 256 { ;色图码
            ColorCode += NumGet(lpvColorBits, A_Index * 16 - 4, "UChar")  ;累加拼合
        }
    } else {
        ColorCode := "0"
    }
    DllCall("DeleteObject", "Ptr", NumGet(ICONINFO, 12))  ; *清理掩图
    DllCall("DeleteObject", "Ptr", NumGet(ICONINFO, 16))  ; *清理色图
    return MaskCode // 2 . ColorCode  ;输出特征码
}

F5:: {
    global thiscursor
    A_Clipboard := thiscursor . " " . A_Cursor
}

F6:: {
    global thiscursor
    A_Clipboard := thiscursor
}

F7:: {
    A_Clipboard := A_Cursor
}

