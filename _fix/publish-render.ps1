# One-time helper: commits the Render fix on its own branch, pushes it and opens the pull request.
#   powershell -ExecutionPolicy Bypass -File D:\Legends\_fix\publish-render.ps1
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot)
$branch = 'fix/render-auth'


git checkout -B $branch
if ($LASTEXITCODE) { throw 'git checkout failed' }
git add Dockerfile render.yaml deploy/render/start.sh docs/DONE.md unity/Assets/Legends/Editor/Setup.cs unity/build.ps1
git commit -m 'Render: sign-in, workers, Gmail and Google sign-in; Unity setup survives the reload' `
    -m 'The container takes its public address from Render at start (session cookie, email links, Google), caches the config then, and runs the queue, scheduler and live matches. build.ps1 finds the editor where Unity Hub put it; Setup.cs finishes after the reload that adding packages causes.' `
    -m 'Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>' `
    -m 'Claude-Session: https://claude.ai/code/session_01SkCnVqx3aBAsVNvaUhBRja'
if ($LASTEXITCODE) { throw 'git commit failed' }
git push -u origin $branch
if ($LASTEXITCODE) { throw 'git push failed' }

if (Get-Command gh -ErrorAction SilentlyContinue) {
    $bodyFile = Join-Path $env:TEMP 'legends-pr-body.md'
    $body = "Render: sign-in works on the public address, the queue/scheduler/live matches run, Gmail and Google from Render's Environment (deploy/render/start.sh). Also unity/build.ps1 (finds the editor on D:) and Setup.cs (exits 0 after the reload).`n`n🤖 Generated with [Claude Code](https://claude.com/claude-code)`n`nhttps://claude.ai/code/session_01SkCnVqx3aBAsVNvaUhBRja"
    [IO.File]::WriteAllText($bodyFile, $body, (New-Object Text.UTF8Encoding $false))
    gh pr create --base main --head $branch --title 'Render: sign-in, workers, Gmail and Google sign-in' --body-file $bodyFile
    gh pr merge $branch --squash --auto --delete-branch
    gh pr view $branch --web
} else {
    Start-Process "https://github.com/smssdev/Legends/compare/main...$branch`?expand=1"
    Write-Host 'Pull request page opened: Create pull request, then "Squash and merge" when CI is green.' -ForegroundColor Yellow
}
Write-Host 'Done.' -ForegroundColor Green
