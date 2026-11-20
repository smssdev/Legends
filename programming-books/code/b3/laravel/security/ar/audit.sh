# ما لا يراه git أبداً
$ cat .gitignore | grep -n env
3:.env
4:.env.backup
5:.env.production
# الثغرات المعروفة في الاعتماديات
$ composer audit --no-ansi 2>&1
No security vulnerability advisories found.
