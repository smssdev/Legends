# What git never sees
$ cat .gitignore | grep -n env
3:.env
4:.env.backup
5:.env.production
# Known vulnerabilities in the dependencies
$ composer audit --no-ansi 2>&1
No security vulnerability advisories found.
