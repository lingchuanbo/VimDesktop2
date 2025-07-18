(
    function killCurrentMax =
    (
        MaxStartUI = cui.getConfigFile()
        deleteFile MaxStartUI
        cui.saveConfigAs MaxStartUI
        proc = dotNetObject "System.Diagnostics.Process"
        info=proc.GetCurrentProcess()
        pid=info.Id

        hiddenDosCommand ("taskkill /F /PID " + pid as string)
    )
    
    isSecenSaved = getSaveRequired()
    if isSecenSaved == false then killCurrentMax()
    else 
    (
        local cksave = checkForSave()
        if cksave != false then killCurrentMax()
    )
    
)