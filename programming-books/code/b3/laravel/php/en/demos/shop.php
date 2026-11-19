<?php

declare(strict_types=1);

require __DIR__ . '/../vendor/autoload.php';

use Shop\{Cart, Currency, CurrencyMismatch, Money, OrderStatus, Product};

$kit = new Product(1, 'Robot kit', new Money(45000, Currency::EGP));
$wheels = new Product(2, 'Spare wheels', new Money(6000, Currency::EGP));

// PHP 8.4: no parentheses needed around new before calling a method
$cart = new Cart(Currency::EGP)->add($kit)->add($wheels, 2);
echo "{$cart->count} items, total: {$cart->total->format()}\n";

$status = OrderStatus::from('paid');
echo $status->name, ' / ', $status->label(), ' / ', json_encode($status->canCancel()), "\n";
var_dump(OrderStatus::tryFrom('lost'));
echo implode(', ', array_map(fn (OrderStatus $s) => $s->value, OrderStatus::cases())), "\n";

try {
    $kit->price->plus(new Money(100, Currency::USD));
} catch (CurrencyMismatch $e) {
    echo get_class($e), ': ', $e->getMessage(), "\n";
}

try {
    $cart->lines = [];
} catch (Error $e) {
    echo get_class($e), ': ', $e->getMessage(), "\n";
}

try {
    $kit->price->amount = 1;
} catch (Error $e) {
    echo get_class($e), ': ', $e->getMessage(), "\n";
}

try {
    // readonly properties can only be set from inside the class
    clone($kit, ['name' => 'X']);
} catch (Error $e) {
    echo get_class($e), ': ', $e->getMessage(), "\n";
}

$sale = $kit->onSale(10);
echo $sale->name, ' ', $sale->price->format(), ' / ', $kit->price->format(), "\n";
