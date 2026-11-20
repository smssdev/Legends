<?php

declare(strict_types=1);

$discount = 10;
// fn تلتقط بالقيمة تلقائياً
$apply = fn (int $price): int => $price - intdiv($price * $discount, 100);
$discount = 50; // متأخر جداً: نسخت fn القيمة 10 من قبل
echo $apply(45000), "\n";

$count = 0;
// function () تحتاج use لتلتقط، وبالقيمة أيضاً
$increment = function () use ($count): int {
    return ++$count;
};
$increment();
$increment();
echo $count, "\n"; // ما زال 0: غيّرت الدالة المغلقة نسختها هي

// &$count: بالمرجع، على طريقة JavaScript
$counter = function () use (&$count): void {
    $count++;
};
$counter();
$counter();
echo $count, "\n";

// المعاملات المسماة: انتقل إلى ما تحتاجه، بأي ترتيب
echo str_pad(string: '7', length: 3, pad_string: '0', pad_type: STR_PAD_LEFT), "\n";
echo json_encode(['name' => 'عدة الروبوت'], flags: JSON_UNESCAPED_UNICODE), "\n";
