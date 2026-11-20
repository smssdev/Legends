<?php

// rules about the code itself, checked like any test
arch('leaves no debugging calls in the code')
    ->expect(['dd', 'dump', 'ray', 'var_dump'])
    ->not->toBeUsed();

arch()->preset()->laravel();
