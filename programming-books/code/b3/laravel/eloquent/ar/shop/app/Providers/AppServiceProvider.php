<?php

namespace App\Providers;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        // أثناء التطوير: لا تحميل كسول، ولا خصائص تُتجاهل بصمت
        Model::preventLazyLoading(config('shop.strict'));
        Model::preventSilentlyDiscardingAttributes(config('shop.strict'));
    }
}
