# مجلد جديد لدفترك
$ git init
Initialized empty Git repository in /Users/sara/code/journal/.git/
# أنشئ journal.md بعنوان، ثم:
$ git add journal.md
$ git commit -q -m "بداية الدفتر"
# أضف سطر اليوم 1، ثم:
$ git commit -q -am "اليوم 1"
# أضف سطر اليوم 2، ثم:
$ git commit -q -am "اليوم 2"
# ثلاث لقطات، الأحدث أولاً
$ git log --oneline
b9d7cf2 اليوم 2
bf34050 اليوم 1
eb4e70b بداية الدفتر
# ما الذي تغيّر بالضبط في آخر commit؟
$ git show --stat --format=%s HEAD
اليوم 2

 journal.md | 1 +
 1 file changed, 1 insertion(+)
