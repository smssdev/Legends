<?php

declare(strict_types=1);

namespace Shop;

enum Currency: string
{
    case EGP = 'EGP';
    case SAR = 'SAR';
    case USD = 'USD';
    case KWD = 'KWD';

    public function symbol(): string
    {
        return match ($this) {
            self::EGP => 'E£',
            self::SAR => 'SR',
            self::USD => '$',
            self::KWD => 'KD',
        };
    }

    // Minor units in one major unit: 100 piastres in a pound, 1000 fils in a Kuwaiti dinar.
    public function decimals(): int
    {
        return match ($this) {
            self::KWD => 3,
            default => 2,
        };
    }
}
