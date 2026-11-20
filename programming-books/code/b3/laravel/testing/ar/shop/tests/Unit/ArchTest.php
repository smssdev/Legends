<?php

// قواعد عن الكود نفسه، تُفحص كأي اختبار
arch('leaves no debugging calls in the code')
    ->expect(['dd', 'dump', 'ray', 'var_dump'])
    ->not->toBeUsed();

arch()->preset()->laravel();
