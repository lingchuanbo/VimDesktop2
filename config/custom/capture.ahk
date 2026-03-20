FSCaptureSingleClick() {
    FSCaptureExe("Ctrl+Alt+F3")
}

FSCaptureDoubleClick() {
    Run "https://aistudio.google.com/"
}

fsCaptureAction := CreateSimpleClickHandler(FSCaptureSingleClick, FSCaptureDoubleClick)
Hotkey "$^!a", fsCaptureAction

FSCaptureExe(keymap) {
    /*
    激活窗口         "Alt+PrtSc"
    窗口或对象       "Shift+PrtSc"
    矩形区域         "Ctrl+PrtSc"
    手绘区域         "Ctrl+Shift+PrtSc"
    整个屏幕         "PrtSc"
    滚动窗口         "Ctrl+Alt+PrtSc"
    固定大小区域     "Ctrl+Alt+Shift+PrtSc"
    系统自带截图     "Ctrl+Alt+Shift+PrtSc"
    ;
    */
    fsCaptureExePath := "D:\WorkFlow\tools\TotalCMD\Tools\FSCapture\FSCLoader.exe "
    Run fsCaptureExePath keymap
}
