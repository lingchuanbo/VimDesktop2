# ��ȡ closeAllExit.ini �ļ�����
$processList = Get-Content -Path "closeAllExit.ini" | Where-Object { $_ -ne "" }

# ������ǿ����ֹ���н���
foreach ($process in $processList) {
    try {
        Stop-Process -Name $process.Replace(".exe", "") -Force -ErrorAction Stop
        Write-Host "����ֹ����: $process" -ForegroundColor Green
    }
    catch {
        Write-Host "δ�ҵ�����: $process" -ForegroundColor Yellow
    }
}

Write-Host "���н��̴�����ɣ�" -ForegroundColor Cyan
