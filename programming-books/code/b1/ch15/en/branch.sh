# A new branch for a new feature
$ git switch -c contact
Switched to a new branch 'contact'
# Create contact.html, then:
$ git add contact.html
$ git commit -m "Add contact section"
[contact 857eb74] Add contact section
 1 file changed, 1 insertion(+)
 create mode 100644 contact.html
# Back to the main branch: contact.html disappears from the folder
$ git switch main
Switched to branch 'main'
# Bring the feature in
$ git merge contact
Updating 8be4da4..857eb74
Fast-forward
 contact.html | 1 +
 1 file changed, 1 insertion(+)
 create mode 100644 contact.html
$ git log --oneline --graph
* 857eb74 Add contact section
* 8be4da4 Add tagline
* 96c0a17 Add profile page
