--设置本地环境$maxScripts.
    --读取workflow ini地址
    evnPath="D:\WorkFlow\\plugins\\3DsMax\\Script"
    global getTCExePath = "D:\WorkFlow\\tools\\TotalCMD\\TOTALCMD.EXE"

    if symbolicPaths.isUserPathName "$maxScripts" == false do symbolicPaths.addUserPath "$maxScripts" evnPath

    symbolicPaths.getUserPathValue "$maxScripts"

    try(fileIn ((symbolicPaths.getUserPathValue "$maxScripts") + "\MenuScript\PruneScene\PRUNESCENE_ACTIVE_PROTECTION_MONITOR.ms"))catch(print ("加载场景主动保护时出错!"))
