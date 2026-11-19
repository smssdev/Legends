<?php

namespace App\Providers;

use App\Catalog\JsonProductCatalog;
use App\Catalog\ProductCatalog;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Ask for a ProductCatalog, get this one: built once per request cycle.
        $this->app->singleton(
            ProductCatalog::class,
            fn () => new JsonProductCatalog(config('shop.catalog_file')),
        );
    }

    public function boot(): void
    {
        // At most N requests a minute per address; N comes from config/shop.php.
        RateLimiter::for('api', function (Request $request) {
            $perMinute = config('shop.requests_per_minute');

            return Limit::perMinute($perMinute)->by($request->ip());
        });
    }
}
