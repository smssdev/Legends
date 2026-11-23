**Summary:**  
A loyalty card system where every 10th paid hot drink purchased counts as a free drink, with specific eligibility and card rules.

**Rules:**  
- Only paid hot drinks count; any size is eligible.  
- Stamps never expire.  
- One card per account.  
- A refunded drink removes its stamp.  
- The free drink is any hot drink up to the price of a large latte.  
- Both branches share the card.

**Acceptance Criteria:**  
Given a user has an account in the café app,  
When they purchase a paid hot drink,  
Then the system stamps the loyalty card if it is the 10th such drink.  

Given a user purchases a hot drink that is refunded,  
Then the system removes the corresponding stamp from the loyalty card.  

Given a user purchases a hot drink priced above the price of a large latte,  
Then the drink does not count toward the free drink eligibility.  

Given a user purchases a non-hot drink,  
Then the drink does not count toward the free drink eligibility.  

Given a user has a loyalty card from one branch,  
Then the card is valid for purchases at both branches.  

Given a user has more than one loyalty card,  
Then only one card per account is active.