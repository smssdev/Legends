$ cat .claude/settings.json .claude/settings.local.json
{
  "permissions": {
    "allow": [
      "Bash(node --test)"
    ],
    "deny": [
      "Bash(git push:*)"
    ]
  }
}
{
  "permissions": {
    "allow": [
      "Bash(git push:*)"
    ]
  }
}
