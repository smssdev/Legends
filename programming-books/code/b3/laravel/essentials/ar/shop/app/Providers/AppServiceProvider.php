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
        // اطلب ProductCatalog تحصل على هذا: يُبنى مرة واحدة لكل دورة طلب.
        $this->app->singleton(
            ProductCatalog::class,
            fn () => new JsonProductCatalog(config('shop.catalog_file')),
        );
    }

    public function boot(): void
    {
        // عدد N من الطلبات في الدقيقة لكل عنوان على الأكثر، وN من config/shop.php.
        RateLimiter::for('api', function (Request $request) {
            $perMinute = config('shop.requests_per_minute');

            return Limit::perMinute($perMinute)->by($request->ip());
        });
    }
}
