# Add a title line at the top, then:
$ git commit -q -am "Add a title"
# Two branches change the same line
$ git switch -q -c personal
# Change the title on this branch, then:
$ git commit -q -am "Personal title"
$ git switch -q main
$ git switch -q -c ambitious
# Change the same line differently here, then:
$ git commit -q -am "Ambitious title"
$ git switch -q main
$ git merge personal
Updating 5ffca6e..d5dc855
Fast-forward
 journal.md | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
# Merging the second one causes a conflict
$ git merge ambitious
Auto-merging journal.md
CONFLICT (content): Merge conflict in journal.md
Automatic merge failed; fix conflicts and then commit the result.
# Git marks both versions inside the file
$ head -5 journal.md
<<<<<<< HEAD
Title: Sara’s learning journal
=======
Title: My road to senior
>>>>>>> ambitious
# Keep the line you want, delete the markers, then:
$ git add journal.md
$ git commit -q -m "Choose the final title"
$ git log --oneline --graph -4
*   9900c88 Choose the final title
|\  
| * fc23fdc Ambitious title
* | d5dc855 Personal title
|/  
* 5ffca6e Add a title
