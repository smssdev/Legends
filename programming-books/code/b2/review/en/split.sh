# Move the formatting into its own pull request
$ git switch -c chore/format-styles main
Switched to a new branch 'chore/format-styles'
$ git checkout feature/discount-codes -- src/ui/styles.css
$ git commit -qm "Format the styles"
$ git switch feature/discount-codes
Switched to branch 'feature/discount-codes'
$ git checkout main -- src/ui/styles.css
$ git commit -qm "Keep only the discount codes"
# The feature’s pull request, after the split
$ git diff --stat main
 src/cart/discount.ts | 11 +++++++++++
 1 file changed, 11 insertions(+)
