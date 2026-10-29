<?php

namespace App\Console\Commands;

use App\League\LiveDegrade;
use Illuminate\Console\Command;

/** Shows or sets the live broadcast's degradation level [Sprint 21 E8.7] (App\League\LiveDegrade). */
class MatchesDegrade extends Command
{
    protected $signature = 'matches:degrade {level? : 0 everything, 1 no summary, 2 and no voice, 3 and less often} {--hours=6} {--reset : Back to the config\'s level}';

    protected $description = 'Show or set how much the live broadcast gives up under load';

    public function handle(): int
    {
        if ($this->option('reset')) {
            LiveDegrade::set(null);
        } elseif ($this->argument('level') !== null) {
            if (! ctype_digit((string) $this->argument('level')) || (int) $this->argument('level') > LiveDegrade::MAX) {
                $this->error('The level is 0 to '.LiveDegrade::MAX.'.');

                return self::FAILURE;
            }
            LiveDegrade::set((int) $this->argument('level'), max(1, (int) $this->option('hours')));
        }
        $this->info('Live degradation level: '.LiveDegrade::level());
        // [Sprint 20 S6] What the automatic level reads.
        $this->line('Automatic: level '.LiveDegrade::auto().', load '.LiveDegrade::load().' ms'.(config('game.live.degrade.auto.enabled') ? '' : ' (off)'));

        return self::SUCCESS;
    }
}
