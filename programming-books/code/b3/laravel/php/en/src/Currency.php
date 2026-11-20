<?php

declare(strict_types=1);

namespace Shop;

enum Currency: string
{
    case EGP = 'EGP';
    case SAR = 'SAR';
    case USD = 'USD';

    public function symbol(): string
    {
        return match ($this) {
            self::EGP => 'E£',
            self::SAR => 'SR',
            self::USD => '$',
        };
    }
}
