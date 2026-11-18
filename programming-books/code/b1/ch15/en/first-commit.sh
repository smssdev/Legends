# Start tracking this folder
$ git init
Initialized empty Git repository in /Users/sara/code-from-zero/profile/.git/
$ git status --short
?? index.html
?? style.css
# Choose what goes into the next snapshot
$ git add index.html style.css
$ git status --short
A  index.html
A  style.css
# Save the snapshot with a message
$ git commit -m "Add profile page"
[main (root-commit) 96c0a17] Add profile page
 2 files changed, 2 insertions(+)
 create mode 100644 index.html
 create mode 100644 style.css
