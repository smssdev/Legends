<?php

declare(strict_types=1);

use Shop\{Currency, Money, OrderStatus};

// a bug PHPStan finds without running anything
function refund(Money $paid, ?OrderStatus $status): Money
{
    if ($status->canCancel()) {
        return $paid;
    }
    return new Money('0', Currency::EGP);
}
