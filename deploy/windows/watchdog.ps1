# Legends watchdog (PLAN 2.19, Sprint 21): runs every minute as the task 'Legends Watchdog'.
# 1. Starts any always-on task that is not running (a crash, or a clean exit such as the queue
#    worker's hourly restart: Windows only restarts a task by itself after a failure).
# 2. Runs the health check, which alerts the phones by ntfy when a service goes down or comes back.
# While update.ps1 works it leaves storage\app\maintenance.flag, and the watchdog waits.

param([string]$Root = 'C:\Legends', [string]$PhpDir = 'C:\php84')
$ErrorActionPreference = 'Continue'
$backend = "$Root\backend"
$log = "$backend\storage\logs\watchdog.log"
function Log($text) { Add-Content -Path $log -Value ("{0:yyyy-MM-dd HH:mm:ss} {1}" -f (Get-Date), $text) -Encoding UTF8 }

$flag = "$backend\storage\app\maintenance.flag"
if ((Test-Path $flag) -and ((Get-Item $flag).LastWriteTime -gt (Get-Date).AddHours(-2))) { exit 0 }

foreach ($task in 'Legends Web', 'Legends Live', 'Legends Queue', 'Legends Matches', 'Legends Replica') {
    $t = Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue
    if ($t -and $t.State -ne 'Running') {
        Log "$task was $($t.State): starting it"
        Start-ScheduledTask -TaskName $task
    }
}

Set-Location $backend
& "$PhpDir\php.exe" artisan server:health --notify | Out-Null
if ($LASTEXITCODE -ne 0) { Log 'health check: a service is down (details: php artisan server:health)' }

# Keep the log small: the last 2000 lines.
if ((Test-Path $log) -and (Get-Item $log).Length -gt 500KB) {
    $keep = Get-Content $log -Tail 2000
    Set-Content -Path $log -Value $keep -Encoding UTF8
}
