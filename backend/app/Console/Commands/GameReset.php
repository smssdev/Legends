<?php

namespace App\Console\Commands;

use App\Database\GameReset as Reset;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Cache;

/**
 * [X95] The game from zero (App\Database\GameReset). Without --force it only says what would go and who stays.
 * On the server it runs through legends-reset, which backs the game up first and asks to type the words.
 */
class GameReset extends Command
{
    protected $signature = 'game:reset {--force : Empty the game now (no question; legends-reset asks it)}';

    protected $description = 'Start the game from zero, keeping the admins and the game data';

    public function handle(): int
    {
        if (($live = MatchesLive::busy()) > 0) {
            $this->error("{$live} مباراة تُلعب الآن: انتظر نهايتها ثم أعد المحاولة.");

            return self::FAILURE;
        }
        $admins = Reset::admins();
        $this->info('يبقى المديرون ('.count($admins).'):');
        foreach ($admins as $a) {
            $this->line("  #{$a['id']} {$a['name']} @{$a['username']} {$a['email']}");
        }
        if (! $admins) {
            $this->warn('لا مدير الآن: بعد التفريغ يأخذ الدور من يدخل بجيميل المطورين الرسمي (OWNER_*_EMAIL).');
        }
        $plan = array_filter(Reset::plan());
        $this->info('ويُحذف كل ما سواهم ('.array_sum($plan).' صفاً):');
        foreach ($plan as $table => $rows) {
            $this->line("  {$table}: {$rows}");
        }
        $this->line('وتبقى: '.implode('، ', Reset::KEEP).' (المديرون وحدهم من users).');
        if (! $this->option('force')) {
            $this->warn('لم يُحذف شيء. للتفريغ على السيرفر: legends-reset');

            return self::SUCCESS;
        }
        $removed = Reset::run();
        Cache::flush();
        $this->info("تم: اللعبة من الصفر. حُذف {$removed} حساباً، وبقي ".count($admins).' مديراً.');

        return self::SUCCESS;
    }
}
