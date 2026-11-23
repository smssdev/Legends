$ node specific.mjs
> Write a function that checks a phone number.
Sure! Here's a simple Python function that checks if a given string resembles a valid phone number format. This function validates the phone number based on a common format (e.g., 123-456-7890 or (123) 456-7890), but **does not verify** if the number actually exists or is in use — it only checks the format.

```python
import re

def is_valid_phone_number(phone):
    """
    Checks if a string resembles a valid phone number format.
    
    Supported formats:
    - 123-456-7890
    - (123) 456-7890
    - 123.456.7890
    - 123 456 7890
    - 1234567890 (no separators)
    
    Returns:
        bool: True if the phone number matches a valid format, False otherwise.
    """
    # Regex pattern to match various common phone number formats
    pattern = r'''
        ^(?:\(\d{3}\)\s+|\d{3}[-.\s]|\d{3}[\s.-]|\d{3}[\s.-]|\d{3}[\s.-]|\d{3}[\s.-]|\d{

> Write a JavaScript function isEgyptianMobile(text) that returns true only for Egyptian mobile numbers: 11 digits starting with 010, 011, 012 or 015, or the same number with +20 instead of the first 0. Spaces and dashes between digits are allowed. Return only the code, in one code block.
```javascript
function isEgyptianMobile(text) {
    const cleaned = text.replace(/\s|-/g, '');
    if (cleaned.length !== 11) return false;
    
    // Check if it starts with 010, 011, 012, or 015
    const firstThree = cleaned.substring(0, 3);
    return (firstThree === '010' || firstThree === '011' || firstThree === '012' || firstThree === '015');
}
```

pass  "01012345678" -> true
FAIL  "+20 101 234 5678" -> false
pass  "015-1234-5678" -> true
pass  "01312345678" -> false
pass  "0101234567" -> false
pass  "phone: 01012345678" -> false
