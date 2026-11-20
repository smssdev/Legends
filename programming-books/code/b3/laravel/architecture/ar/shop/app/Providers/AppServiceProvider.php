<?php

namespace App\Providers;

use App\Orders\Infrastructure\LogMailer;
use App\Orders\Infrastructure\QueryBuilderOrderStore;
use App\Orders\Ports\Mailer;
use App\Orders\Ports\OrderStore;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    // جذر التركيب: أي صنف حقيقي يجيب كل منفذ
    public array $bindings = [
        OrderStore::class => QueryBuilderOrderStore::class,
        Mailer::class => LogMailer::class,
    ];
}
