<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;

/** Copies the built Vue app (web/dist) into public/ so `php artisan serve` serves it. */
class WebPublish extends Command
{
    protected $signature = 'web:publish {--from=../web/dist}';

    protected $description = 'Copy the built web app into public/';

    public function handle(): int
    {
        $from = base_path($this->option('from'));
        if (! is_file("$from/index.html")) {
            $this->error("لا يوجد بناء في $from. شغّل npm run build في web أولاً.");

            return self::FAILURE;
        }
        File::deleteDirectory(public_path('assets'));
        File::copyDirectory($from, public_path());
        $this->info('نُسخ تطبيق الويب إلى public/.');

        return self::SUCCESS;
    }
}
