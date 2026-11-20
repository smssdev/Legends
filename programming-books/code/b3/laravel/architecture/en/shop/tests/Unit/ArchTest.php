<?php

// the layers, checked on every run
arch('keeps the domain free of Laravel and of the adapters')
    ->expect('App\Orders\Domain')
    ->not->toUse(['Illuminate', 'App\Orders\Infrastructure', 'App\Orders\Http']);

arch('lets the action use only the domain and the ports')
    ->expect('App\Orders\Actions')
    ->toOnlyUse(['App\Orders\Domain', 'App\Orders\Ports']);
