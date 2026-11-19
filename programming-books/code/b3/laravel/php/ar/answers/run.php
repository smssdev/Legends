<?php

declare(strict_types=1);

// The answers' versions of the classes are loaded first; everything else comes from src/.
spl_autoload_register(function (string $class): void {
    $name = substr($class, strlen('Shop\\')) . '.php';
    foreach ([__DIR__ . '/src/', __DIR__ . '/../src/'] as $dir) {
        if (is_file($dir . $name)) {
            require $dir . $name;
            return;
        }
    }
});

use Shop\{Cart, Currency, Money, Product};

echo new Money(123456, Currency::KWD)->format(), ' ', new Money(123456, Currency::EGP)->format(), "
";

$cart = new Cart(Currency::EGP)->add(new Product(1, 'Kit', new Money(45000, Currency::EGP)), 2);
$cart->discountPercent = 10;
echo $cart->total->format(), ' -> ', $cart->payable->format(), "
";
try {
    $cart->discountPercent = 150;
} catch (ValueError $e) {
    echo get_class($e), ': ', $e->getMessage(), "
";
}
echo $cart->discountPercent, "
";
