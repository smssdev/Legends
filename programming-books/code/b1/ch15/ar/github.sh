# اربط المجلد بمستودع فارغ أنشأته على github.com
$ git remote add origin https://github.com/sara-khan/profile.git
$ git push -u origin main
Enumerating objects: 11, done.
Writing objects: 100% (11/11), 1.02 KiB | 1.02 MiB/s, done.
To https://github.com/sara-khan/profile.git
 * [new branch]      main -> main
branch 'main' set up to track 'origin/main'.
# لاحقاً، على أي حاسوب:
$ git clone https://github.com/sara-khan/profile.git
$ git pull
