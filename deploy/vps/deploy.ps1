# One click from Suliman's Windows PC to our server (README.md section 8). Double-click deploy\vps\Deploy-GLM.cmd,
# or from the repository's root:
#
#   powershell -ExecutionPolicy Bypass -File deploy\vps\deploy.ps1           the latest main from GitHub, then the server
#   powershell -ExecutionPolicy Bypass -File deploy\vps\deploy.ps1 -Force    even with a match live (it restarts the game)
#
# What it does, in order, and it stops at the first problem:
#   1. Checks Git for Windows (its sh, ssh and tar) and the server's key (%USERPROFILE%\.ssh\legends_vps).
#   2. Changes here not committed (Unity work, a test): it lists them and asks to put them aside (git stash), safe and
#      brought back after with `git stash pop`. New files git does not track are left alone: they are not deployed.
#   3. Takes the latest main from GitHub (git pull, fast-forward only).
#   4. Runs deploy\vps\deploy.sh: "safe to deploy" (no match live or within 30 minutes), the disk, the code over SSH,
#      the image rebuilt, the game restarted. The database stays in its volume, never touched.
#   5. Asks the site's health and says whether the game answers.
# No password or key is written here or shown: the key stays in your .ssh folder.
param([switch]$Force)
$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$Site = 'https://nesr.site'   # [X70] the game's own domain
Set-Location $Root

function Step($text) { Write-Host ''; Write-Host "== $text" -ForegroundColor Cyan }
function Fail($text) { Write-Host ''; Write-Host $text -ForegroundColor Red; exit 1 }

Step 'Tools'
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail 'Git is missing: install Git for Windows (https://git-scm.com), then run this again.' }
$GitDir = Split-Path (Split-Path (Get-Command git).Source)
$Sh = @((Join-Path $GitDir 'bin\sh.exe'), 'C:\Program Files\Git\bin\sh.exe') | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Sh) { Fail 'sh.exe from Git for Windows was not found (it comes with Git for Windows).' }
$Key = Join-Path $env:USERPROFILE '.ssh\legends_vps'
if (-not (Test-Path $Key)) { Fail "The server's key is missing: $Key" }
Write-Host "Git: $GitDir"
Write-Host "Key: $Key"

Step 'This copy of the code'
# [X55] Only changes to files git tracks matter (they could stop the pull); the deploy itself sends what is committed.
$changed = git status --porcelain --untracked-files=no
if ($changed) {
    Write-Host 'These files changed here and are not committed:' -ForegroundColor Yellow
    git status --short --untracked-files=no
    $answer = Read-Host 'Put them aside and deploy? They stay safe: "git stash pop" brings them back after. [y/N]'
    if ($answer -notin @('y', 'Y', 'yes', 'Yes')) { Fail 'Not deployed. Commit the changes, or answer y to put them aside.' }
    git stash push -m ('before deploy ' + (Get-Date -Format 'yyyy-MM-dd HH:mm'))
    if ($LASTEXITCODE -ne 0) { Fail 'Could not put the changes aside (git stash).' }
    Write-Host 'Put aside. After the deploy, "git stash pop" brings them back.' -ForegroundColor Green
}
git fetch origin main
if ($LASTEXITCODE -ne 0) { Fail 'Could not reach GitHub (git fetch).' }
git checkout main
if ($LASTEXITCODE -ne 0) { Fail 'Could not switch to main.' }
git pull --ff-only origin main
if ($LASTEXITCODE -ne 0) { Fail 'main here has its own commits: it cannot simply take GitHub''s. Ask Claude.' }
Write-Host ('Deploying: ' + (git log -1 --format='%h %s'))

Step 'The server'
$env:LEGENDS_FORCE = $(if ($Force) { '1' } else { '0' })
& $Sh deploy/vps/deploy.sh
switch ($LASTEXITCODE) {
    0 { }
    2 { Fail 'Not deployed: a match is live or about to start. Run it again after the matches (or with -Force).' }
    default { Fail "The deploy stopped (code $LASTEXITCODE). The lines above say why; send them to Claude." }
}

Step 'Health'
for ($i = 1; $i -le 12; $i++) {
    try {
        $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 10 "$Site/api/v1/health"
        if ($r.StatusCode -eq 200) { Write-Host "The game answers: $Site" -ForegroundColor Green; exit 0 }
    } catch { }
    Start-Sleep -Seconds 5
}
Fail "The game did not answer at $Site/api/v1/health within a minute. Logs: ssh -i $Key root@2.24.47.100 docker logs --tail 50 legends-app-1"
