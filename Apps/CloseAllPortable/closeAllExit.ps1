# 读取 closeAllExit.ini 文件内容
$processList = Get-Content -Path "closeAllExit.ini" | Where-Object { $_ -ne "" }

# 遍历并强制终止所有进程
foreach ($process in $processList) {
    try {
        Stop-Process -Name $process.Replace(".exe", "") -Force -ErrorAction Stop
        Write-Host "已终止进程: $process" -ForegroundColor Green
    }
    catch {
        Write-Host "未找到进程: $process" -ForegroundColor Yellow
    }
}

Write-Host "所有进程处理完成！" -ForegroundColor Cyan
