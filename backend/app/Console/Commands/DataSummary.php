<?php

namespace App\Console\Commands;

use App\Http\Controllers\Api\DataController;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;

/** What the imported data holds: the leagues, and the strongest clubs of one [Sprint 11 B3]. */
class DataSummary extends Command
{
    protected $signature = 'data:summary {--league=Premier League : The league to list} {--top=20 : How many clubs}';

    protected $description = 'Summarise the imported clubs and players';

    public function handle(): int
    {
        $version = DataController::version();
        if ($version === '') {
            $this->error('لا توجد بيانات. شغّل data:import أولاً.');

            return self::FAILURE;
        }
        $clubs = DB::table('master_clubs')->where('data_version', $version);
        $players = DB::table('master_players')->where('data_version', $version);
        $this->line("نسخة البيانات $version: ".$clubs->count().' نادياً في '.$clubs->distinct()->count('league_name').' دورياً، و'.$players->count().' لاعباً.');

        $league = (string) $this->option('league');
        $rows = DB::table('master_clubs as c')->where('c.data_version', $version)->where('c.league_name', $league)
            ->leftJoin('master_players as p', 'p.master_club_id', '=', 'c.id')
            ->groupBy('c.id', 'c.name', 'c.code', 'c.strength_cp')
            ->select('c.name', 'c.code', 'c.strength_cp', DB::raw('count(p.id) as players'), DB::raw('max(p.overall) as best'), DB::raw('sum(p.value) as value'))
            ->orderByDesc('c.strength_cp')->limit((int) $this->option('top'))->get();
        if ($rows->isEmpty()) {
            $this->error("لا يوجد دوري باسم $league.");

            return self::FAILURE;
        }
        $this->line('');
        $this->line("أقوى {$rows->count()} في $league:");
        $this->table(['#', 'النادي', 'الرمز', 'القوة', 'اللاعبون', 'الأفضل', 'قيمة التشكيلة'], $rows->values()->map(fn ($r, $i) => [
            $i + 1, $r->name, $r->code, number_format($r->strength_cp / 100, 1), $r->players, $r->best, number_format((int) $r->value),
        ])->all());

        return self::SUCCESS;
    }
}
