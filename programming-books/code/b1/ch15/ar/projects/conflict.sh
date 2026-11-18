# أضف سطر عنوان في الأعلى، ثم:
$ git commit -q -am "إضافة عنوان"
# فرعان يغيّران السطر نفسه
$ git switch -q -c personal
# غيّر العنوان في هذا الفرع، ثم:
$ git commit -q -am "عنوان شخصي"
$ git switch -q main
$ git switch -q -c ambitious
# غيّر السطر نفسه بشكل آخر هنا، ثم:
$ git commit -q -am "عنوان طموح"
$ git switch -q main
$ git merge personal
Updating f59166c..4390b4a
Fast-forward
 journal.md | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
# دمج الثاني يسبب تعارضاً
$ git merge ambitious
Auto-merging journal.md
CONFLICT (content): Merge conflict in journal.md
Automatic merge failed; fix conflicts and then commit the result.
# Git يضع النسختين داخل الملف
$ head -5 journal.md
<<<<<<< HEAD
العنوان: دفتر تعلّم سارة
=======
العنوان: طريقي إلى الاحتراف
>>>>>>> ambitious
# أبقِ السطر الذي تريده، واحذف العلامات، ثم:
$ git add journal.md
$ git commit -q -m "اختيار العنوان النهائي"
$ git log --oneline --graph -4
*   c00d6d1 اختيار العنوان النهائي
|\  
| * be5d73e عنوان طموح
* | 4390b4a عنوان شخصي
|/  
* f59166c إضافة عنوان
