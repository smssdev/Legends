<?php

namespace App\Console\Commands;

use App\Support\GameClock;
use Illuminate\Console\Command;

/**
 * Moves the game's time in development: clock:travel +8h, -30m, +2d, or reset.
 * Refused in production, where the game runs on real time only [PLAN 1].
 */
class ClockTravel extends Command
{
    protected $signature = 'clock:travel {by? : +8h, -30m, +2d, +90s, or reset} {--status : Show the game time only}';

    protected $description = 'Move the game clock (development only)';

    public function handle(): int
    {
        if ($this->laravel->isProduction()) {
            $this->error('clock:travel لا يعمل في الإنتاج.');

            return self::FAILURE;
        }
        $by = $this->argument('by');
        if ($by !== null && ! $this->option('status')) {
            if ($by === 'reset') {
                GameClock::setOffset(0);
            } elseif (preg_match('/^([+-])(\d+)([smhd])$/', $by, $m)) {
                $seconds = (int) $m[2] * ['s' => 1, 'm' => 60, 'h' => 3600, 'd' => 86400][$m[3]];
                GameClock::setOffset(GameClock::offset() + ($m[1] === '-' ? -$seconds : $seconds));
            } else {
                $this->error('اكتب المدة هكذا: +8h أو -30m أو +2d أو reset');

                return self::INVALID;
            }
        }
        $offset = GameClock::offset();
        $this->line('وقت اللعبة: '.GameClock::now()->toIso8601String().' (UTC)');
        $this->line('بتوقيت القاهرة: '.GameClock::now()->timezone('Africa/Cairo')->format('Y-m-d H:i'));
        $this->line('الفرق عن الوقت الحقيقي: '.($offset >= 0 ? '+' : '-').gmdate('H:i:s', abs($offset) % 86400).(abs($offset) >= 86400 ? ' و'.intdiv(abs($offset), 86400).' يوم' : ''));

        return self::SUCCESS;
    }
}
