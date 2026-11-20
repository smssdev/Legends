<?php

namespace App\Orders\Domain;

use DomainException;

// أخطاء تتكلم لغة العمل؛ وكل محوّل يقرر ماذا تصير
abstract class OrderError extends DomainException {}
