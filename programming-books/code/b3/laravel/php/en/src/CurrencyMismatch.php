<?php

declare(strict_types=1);

namespace Shop;

use DomainException;

final class CurrencyMismatch extends DomainException
{
    public function __construct(
        public readonly Currency $left,
        public readonly Currency $right,
    ) {
        $message = strtr('Cannot add {a} to {b}', [
            '{a}' => $right->value,
            '{b}' => $left->value,
        ]);
        parent::__construct($message);
    }
}
