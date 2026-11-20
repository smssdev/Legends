<?php

declare(strict_types=1);

use Shop\{Currency, Money, OrderStatus};

// خطأ يجده PHPStan دون تشغيل أي شيء
function refund(Money $paid, ?OrderStatus $status): Money
{
    if ($status->canCancel()) {
        return $paid;
    }
    return new Money('0', Currency::EGP);
}
