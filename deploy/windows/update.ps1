# Legends home server update (docs/HOME_SERVER.md). Safe for the data:
# it backs up the databases first, only runs forward migrations, and never
# wipes anything. Run in PowerShell as Administrator, when no match is live:
#   powershell -ExecutionPolicy Bypass -File C:\Legends\deploy\windows\update.ps1

param([string]$Root = 'C:\Legends')
$ErrorActionPreference = 'Stop'
function Step($text) { Write-Host "`n==> $text" -ForegroundColor Yellow }

Set-Location "$Root\backend"
Step 'Backing up the databases'
php artisan db:backup

Step 'Stopping the game'
foreach ($task in 'Legends Web', 'Legends Live', 'Legends Queue') { Stop-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue }
Get-CimInstance Win32_Process -Filter "Name = 'php.exe'" | Where-Object { $_.CommandLine -match 'artisan serve|server\.php|reverb:start|queue:work' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }

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
if (-not (Get-ScheduledTask -TaskName 'Legends Live' -ErrorAction SilentlyContinue)) {
    Write-Host 'Run setup.ps1 once more to add the live connection (Reverb) and the queue.' -ForegroundColor Yellow
}
foreach ($task in 'Legends Web', 'Legends Live', 'Legends Queue') { Start-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue }
Write-Host "`nUpdated. Your link is the same as before." -ForegroundColor Green
