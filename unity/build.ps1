# The Unity project from the command line, on Sliman's Windows PC (README.md 7.9). Claude runs these.
#
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 install   Unity Hub (winget), then the editor by hand
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 where     shows which Unity.exe the other steps will use
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 setup     opens the project once and adds the packages
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 demo      builds the Arena and the match scene
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 players   the players' materials from the Blender export, and unity\Captures\players.png
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 moves     every move of Animation\Moves on players of the three builds, to unity\Captures\moves
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 capture   plays the match and saves minutes 5, 20, 45, 70, 90 to unity\Captures
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 splash    the app's opening squad, our players under the lights, to mobile\assets\splash\squad.png
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 kits      minute 20 in the kits of five matches, far and close, and the bench (unity\Captures\kits-*.png)
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 plays     the first goal held at its moves: the pass, the shot, the keeper, the celebration (unity\Captures\play-*.png)
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 test     the EditMode then PlayMode tests (results in unity\Logs\tests-*.xml)
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 open      opens the editor on the match scene (then press Play)
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 webgl     the web build in unity\Builds\WebGL
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 serve     serves the web build on http://localhost:8090 and opens it
#   powershell -ExecutionPolicy Bypass -File unity\build.ps1 android   the test APK in unity\Builds\Android
#
# The log of every step goes to the window and to unity\Logs\<step>.log.
param(
    [Parameter(Position = 0)][ValidateSet('install', 'where', 'setup', 'demo', 'players', 'moves', 'splash', 'capture', 'kits', 'plays', 'test', 'serve', 'open', 'webgl', 'android')][string]$Step = 'demo',
    [string]$Unity = ''   # Unity.exe; found under Unity Hub's editors when empty
)
$ErrorActionPreference = 'Stop'
$Project = $PSScriptRoot

if ($Step -eq 'install') {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw 'winget is missing: install "App Installer" from the Microsoft Store.' }
    winget install --id Unity.UnityHub -e --accept-source-agreements --accept-package-agreements
    Write-Host ''
    Write-Host 'Now in Unity Hub (by hand, once):' -ForegroundColor Yellow
    Write-Host '  1. Sign in with your Unity account and take the free Personal licence.'
    Write-Host '  2. Installs > Install Editor > the newest Unity 6 marked LTS.'
    Write-Host '  3. Tick the modules: WebGL Build Support, Android Build Support (with OpenJDK and Android SDK & NDK).'
    Write-Host 'Then: build.ps1 setup'
    exit 0
}

if (-not $Unity) {
    # Every place Unity Hub may have put an editor: the default folder, the "Installs location" chosen in
    # Hub's settings (e.g. on D:), and the editors Hub lists in its own files.
    $hubData = Join-Path $env:APPDATA 'UnityHub'
    $roots = @('C:\Program Files\Unity\Hub\Editor')
    $custom = Join-Path $hubData 'secondaryInstallPath.json'
    if (Test-Path $custom) {
        $path = (Get-Content $custom -Raw).Trim().Trim('"') -replace '\\\\', '\'
        if ($path) { $roots += $path }
    }
    $exes = @()
    foreach ($root in $roots) {
        $exes += Get-ChildItem $root -Directory -ErrorAction SilentlyContinue |
            ForEach-Object { Join-Path $_.FullName 'Editor\Unity.exe' }
    }
    foreach ($list in @('editors-v2.json', 'editors.json')) {
        $file = Join-Path $hubData $list
        if (Test-Path $file) {
            # pull every "...Unity.exe" path out of the file without depending on its exact shape
            $exes += [regex]::Matches((Get-Content $file -Raw), '"([^"]*?Unity\.exe)"') |
                ForEach-Object { $_.Groups[1].Value -replace '\\\\', '\' }
        }
    }
    $editors = $exes | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique |
        ForEach-Object { [pscustomobject]@{ Exe = $_; Name = Split-Path (Split-Path (Split-Path $_)) -Leaf } } |
        Where-Object { $_.Name -like '6000.*' } |
        Sort-Object { [version]($_.Name -replace '[a-z].*$', '') } -Descending
    if (-not $editors) {
        throw "No Unity 6 editor found (looked in: $($roots -join ', ')). Run: build.ps1 install, or pass -Unity 'D:\...\Editor\Unity.exe'"
    }
    $Unity = $editors[0].Exe
}
if (-not (Test-Path $Unity)) { throw "Unity.exe not found: $Unity" }
Write-Host "Unity: $Unity"
if ($Step -eq 'where') { exit 0 }
if ($Step -eq 'serve') {
    # The web build from a plain local server: gzip with the decompression fallback needs no special headers.
    $web = Join-Path $Project 'Builds\WebGL'
    if (-not (Test-Path (Join-Path $web 'index.html'))) { throw 'No web build yet. Run: build.ps1 webgl' }
    $py = Get-Command python -ErrorAction SilentlyContinue
    if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
    if (-not $py) { throw 'Python is missing: winget install --id Python.Python.3.12 -e' }
    Write-Host 'Serving the web build on http://localhost:8090 (Ctrl+C to stop)'
    Start-Process 'http://localhost:8090'
    & $py.Source -m http.server 8090 --directory $web
    exit 0
}
if ($Step -eq 'test') {
    # Unity's test runner from the command line: it quits by itself (never with -quit, which skips the tests).
    New-Item -ItemType Directory -Force (Join-Path $Project 'Logs') | Out-Null
    $failed = 0
    foreach ($platform in 'EditMode', 'PlayMode') {
        $log = Join-Path $Project "Logs\test-$($platform.ToLower()).log"
        $xml = Join-Path $Project "Logs\tests-$($platform.ToLower()).xml"
        Remove-Item $log, $xml -ErrorAction SilentlyContinue
        Write-Host "$platform tests..."
        $testArgs = @('-batchmode', '-projectPath', "`"$Project`"", '-runTests', '-testPlatform', $platform, '-testResults', "`"$xml`"", '-logFile', "`"$log`"")
        $p = Start-Process -FilePath $Unity -ArgumentList $testArgs -PassThru -NoNewWindow -Wait
        if (-not (Test-Path $xml)) {
            Write-Host "  no results: see $log" -ForegroundColor Red
            $failed++
            continue
        }
        [xml]$r = Get-Content $xml
        $run = $r.'test-run'
        $color = if ([int]$run.failed -gt 0) { 'Red' } else { 'Green' }
        Write-Host "  $($run.passed) passed, $($run.failed) failed, $($run.skipped) skipped" -ForegroundColor $color
        foreach ($case in $r.SelectNodes('//test-case[@result="Failed"]')) {
            Write-Host "  FAILED $($case.fullname): $($case.failure.message.'#cdata-section')" -ForegroundColor Red
        }
        if ([int]$run.failed -gt 0 -or $p.ExitCode -ne 0) { $failed++ }
    }
    if ($failed) { Write-Host 'Tests failed.' -ForegroundColor Red; exit 1 }
    Write-Host 'All tests green.' -ForegroundColor Green
    exit 0
}
if ($Step -eq 'open') {
    # The editor with its window, on Scenes/Match.unity; it keeps running after this script ends.
    Start-Process -FilePath $Unity -ArgumentList @('-projectPath', "`"$Project`"", '-executeMethod', 'Legends.EditorTools.OpenMatch.Run')
    Write-Host 'Unity is opening the project (the first time takes a few minutes). Then press Play.'
    exit 0
}
New-Item -ItemType Directory -Force (Join-Path $Project 'Logs') | Out-Null
$log = Join-Path $Project "Logs\$Step.log"

$method = @{
    setup   = 'Legends.EditorTools.Setup.Run'
    demo    = 'Legends.EditorTools.DemoScene.Build'
    players = 'Legends.EditorTools.Players.Run'
    splash  = 'Legends.EditorTools.SplashCapture.Run'
    moves   = 'Legends.EditorTools.MovesCapture.Run'
    capture = 'Legends.EditorTools.Capture.Run'
    kits    = 'Legends.EditorTools.Capture.RunKits'
    plays   = 'Legends.EditorTools.Capture.RunPlays'
    webgl   = 'Legends.EditorTools.Builds.WebGL'
    android = 'Legends.EditorTools.Builds.Android'
}[$Step]
$unityArgs = @('-batchmode', '-projectPath', "`"$Project`"", '-executeMethod', $method, '-logFile', "`"$log`"")
if ($Step -notin @('setup', 'capture', 'kits', 'plays', 'players', 'splash')) { $unityArgs += '-quit' }   # these quit by themselves when done
if ($Step -eq 'webgl') { $unityArgs += @('-buildTarget', 'WebGL') }
if ($Step -eq 'android') { $unityArgs += @('-buildTarget', 'Android') }

Remove-Item $log -ErrorAction SilentlyContinue
$p = Start-Process -FilePath $Unity -ArgumentList $unityArgs -PassThru -NoNewWindow
$null = $p.Handle   # keeps the exit code readable after Unity quits
# show our own lines and the errors from the log while Unity works
$seen = 0
while ($true) {
    $done = $p.HasExited
    if (Test-Path $log) {
        $lines = @(Get-Content $log)
        for ($i = $seen; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match 'Legends:|error|Exception') { Write-Host $lines[$i] }
        }
        $seen = $lines.Count
    }
    if ($done) { break }
    Start-Sleep -Seconds 1
}
Write-Host "Unity exited with $($p.ExitCode). Full log: $log"
exit $p.ExitCode
