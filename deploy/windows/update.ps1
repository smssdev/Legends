# Legends home server update (docs/HOME_SERVER.md). Safe for the data:
# it backs up the databases first, only runs forward migrations, and never
# wipes anything. It waits for the live matches to end first. Run in PowerShell as Administrator:
#   powershell -ExecutionPolicy Bypass -File C:\Legends\deploy\windows\update.ps1

param([string]$Root = 'C:\Legends')
$ErrorActionPreference = 'Stop'
function Step($text) { Write-Host "`n==> $text" -ForegroundColor Yellow }

Set-Location "$Root\backend"
# No deploy while a match is being played (PLAN 2.12): wait for the live ones to end.
Step 'Waiting for the live matches to end'
# Matches kicking off in the next 15 minutes count too: the update takes a few minutes [Sprint 37].
while ([int](php artisan matches:live --soon=15) -gt 0) { Write-Host '  a match is live or about to start, waiting a minute...'; Start-Sleep -Seconds 60 }

# The watchdog leaves the tasks alone while this works (it would start them again).
$flag = "$Root\backend\storage\app\maintenance.flag"
Set-Content $flag 'update'

Step 'Backing up the databases'
php artisan db:backup

Step 'Stopping the game'
foreach ($task in 'Legends Web', 'Legends Live', 'Legends Queue', 'Legends Matches') { Stop-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue }
Get-CimInstance Win32_Process -Filter "Name = 'php.exe'" | Where-Object { $_.CommandLine -match 'artisan serve|server\.php|reverb:start|queue:work|matches:run' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

Step 'Getting the latest version'
git -C $Root pull --ff-only
composer install --no-dev --optimize-autoloader --no-interaction
php artisan migrate --force
# The nightly engine calibration (docs/ENGINE.md 9) runs on this machine.
if (-not (Select-String -Path '.env' -Pattern '^GAME_NIGHTLY_BALANCE=' -Quiet)) { Add-Content '.env' 'GAME_NIGHTLY_BALANCE=true' }

Step 'Building the web app'
Set-Location "$Root\web"
npm ci
npm run build
Set-Location "$Root\backend"
php artisan web:publish

Step 'Starting the game'
# Older installs have no live or queue task yet: setup.ps1 adds them (it is safe to run again).
if (-not (Get-ScheduledTask -TaskName 'Legends Matches' -ErrorAction SilentlyContinue)) {
    Write-Host 'Run setup.ps1 once more to add the live connection (Reverb), the queue and the match runner.' -ForegroundColor Yellow
}
foreach ($task in 'Legends Web', 'Legends Live', 'Legends Queue', 'Legends Matches', 'Legends Replica') { Start-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue }
Remove-Item $flag -ErrorAction SilentlyContinue
if (-not (Get-ScheduledTask -TaskName 'Legends Watchdog' -ErrorAction SilentlyContinue)) {
    Write-Host 'Run setup.ps1 once more to add the watchdog and the phone alerts (Sprint 21).' -ForegroundColor Yellow
}
Write-Host "`nUpdated. Your link is the same as before." -ForegroundColor Green
