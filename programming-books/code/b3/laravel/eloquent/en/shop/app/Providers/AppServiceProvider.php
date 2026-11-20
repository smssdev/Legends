<?php

namespace App\Providers;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        // in development: no lazy loading, no silently ignored attributes
        Model::preventLazyLoading(config('shop.strict'));
        Model::preventSilentlyDiscardingAttributes(config('shop.strict'));
    }
}
