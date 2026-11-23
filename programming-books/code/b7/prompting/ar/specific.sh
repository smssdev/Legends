$ node specific.mjs
> اكتب دالة تتحقق من رقم هاتف.
بالطبع! إليك دالة (في لغة **Python**) تتحقق من صحة رقم هاتف بناءً على معايير بسيطة:

### المعايير التي تُستخدم في التحقق:
- يجب أن يكون الرقم يحتوي على أرقام فقط.
- يجب أن يكون طوله مقبولًا (مثلاً 10 أو 11 رقمًا لرقم هاتف في الدول العربية).
- يمكن أن يحتوي على مسافات أو أرقام مسبقة (مثل +966 أو 050).

---

### ✅ دالة تحقق من رقم هاتف (باللغة Python):

```python
import re

def check_phone_number(phone):
    # إزالة المسافات والرموز غير المطلوبة
    phone = re.sub(r'[^0-9]', '', phone)
    
    # التحقق من أن الرقم يحتوي على أرقام فقط
    if not phone.isdigit():
        return False
    
    # التحقق من طول الرقم (مثلاً 10 أو 11 رقمًا)
    if len(phone) < 8 or len(phone) > 15:
        return False
    
    # مثال: يمكن أن يكون رقم هاتف 10 أرقام (مثلاً 0501234567)
    # أو 11 رقمًا مع + (مث

> اكتب دالة JavaScript باسم isEgyptianMobile(text) تعيد true فقط لأرقام الجوال المصرية: 11 رقماً تبدأ بـ 010 أو 011 أو 012 أو 015، أو الرقم نفسه مع +20 بدل الصفر الأول. والمسافات والشرطات بين الأرقام مسموحة. أعِد الكود فقط، في كتلة كود واحدة.
```javascript
function isEgyptianMobile(text) {
    const cleaned = text.replace(/\s+/g, '').replace(/[^0-9+]/g, '');
    
    // التحقق من أن الرقم يحتوي على 11 رقمًا
    if (cleaned.length !== 11 && cleaned.length !== 12) {
        return false;
    }
    
    // التحقق من أن الرقم يبدأ بـ 010 أو 011 أو 012 أو 015
    if (cleaned.startsWith('010') || cleaned.startsWith('011') || cleaned.startsWith('012') || cleaned.startsWith('015')) {
        return true;
    }
    
    // التحقق من أن الرقم يبدأ بـ +20 ثم 10 أو 11 أو 12 أو 15
    if (cleaned.startsWith('+20') && (cleaned.substring(3).startsWith('10') || cleaned.substring(3).startsWith('11') || cleaned.substring(3).startsWith('12') || cleaned.substring(3).startsWith('15'))) {
        return true;
    }
    
    return false;
}
```

pass  "01012345678" -> true
FAIL  "+20 101 234 5678" -> false
pass  "015-1234-5678" -> true
pass  "01312345678" -> false
pass  "0101234567" -> false
FAIL  "phone: 01012345678" -> true
