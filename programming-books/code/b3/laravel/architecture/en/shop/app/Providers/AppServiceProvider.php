<?php

namespace App\Providers;

use App\Orders\Infrastructure\LogMailer;
use App\Orders\Infrastructure\QueryBuilderOrderStore;
use App\Orders\Ports\Mailer;
use App\Orders\Ports\OrderStore;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    // the composition root: which concrete class answers each port
    public array $bindings = [
        OrderStore::class => QueryBuilderOrderStore::class,
        Mailer::class => LogMailer::class,
    ];
}
