<?php

namespace App\Console\Commands;

use App\Data\PlayerValuation;
use App\Data\Potential;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/**
 * Works out every master player's potential and value again from config/game.php, after the
 * numbers change, without importing the files again. Then prints how the values spread [Sprint 11].
 */
class DataValue extends Command
{
    protected $signature = 'data:value {--data-version= : Only this data version}';

    protected $description = 'Recalculate player potential and value, and report how they spread';

    public function handle(): int
    {
        $valuation = PlayerValuation::fromConfig();
        $query = DB::table('master_players')->select('id', 'overall', 'age', 'line');
        if ($v = $this->option('data-version')) {
            $query->where('data_version', $v);
        }
        $n = 0;
        DB::transaction(function () use ($query, $valuation, &$n) {
            foreach ($query->lazyById(1000) as $p) {
                $potential = Potential::for($p->overall, $p->age);
                DB::table('master_players')->where('id', $p->id)->update(['potential' => $potential, 'value' => $valuation->value($p->overall, $p->age, $p->line, $potential)]);
                $n++;
            }
        });
        $this->info("$n players valued.");
        $this->report();

        return self::SUCCESS;
    }

    /** Values by rating band and by age: the report Sprint 11 asks for. */
    private function report(): void
    {
        $money = fn ($v) => number_format((int) $v);
        $bands = DB::table('master_players')
            ->selectRaw('(overall / 5) * 5 as band, count(*) as n, min(value) as lo, avg(value) as mid, max(value) as hi, avg(potential - overall) as room')
            ->groupBy('band')->orderBy('band')->get();
        $this->table(['التقييم', 'اللاعبون', 'أقل قيمة', 'المتوسط', 'أعلى قيمة', 'متوسط مساحة التطور'],
            $bands->map(fn ($b) => [$b->band.'-'.($b->band + 4), $b->n, $money($b->lo), $money($b->mid), $money($b->hi), round($b->room, 1)])->all());
        $ages = DB::table('master_players')
            ->selectRaw("case when age <= 19 then '17-19' when age <= 23 then '20-23' when age <= 27 then '24-27' when age <= 30 then '28-30' else '31+' end as ages, count(*) as n, avg(overall) as ovr, avg(potential) as pot, avg(value) as val")
            ->groupBy('ages')->orderBy('ages')->get();
        $this->table(['العمر', 'اللاعبون', 'متوسط التقييم', 'متوسط الإمكانية', 'متوسط القيمة'],
            $ages->map(fn ($a) => [$a->ages, $a->n, round($a->ovr, 1), round($a->pot, 1), $money($a->val)])->all());
    }
}
