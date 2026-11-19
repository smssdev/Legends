<?php

namespace App\Enums;

enum OrderStatus: string
{
    case Pending = 'pending';
    case Paid = 'paid';
    case Shipped = 'shipped';
    case Cancelled = 'cancelled';

    public function label(): string
    {
        return match ($this) {
            self::Pending => 'بانتظار الدفع',
            self::Paid => 'مدفوع',
            self::Shipped => 'في الطريق',
            self::Cancelled => 'ملغى',
        };
    }
}
