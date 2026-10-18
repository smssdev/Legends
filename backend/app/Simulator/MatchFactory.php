<?php

namespace App\Simulator;

use App\Engine\MatchSetup;
use App\Models\MasterClub;

/**
 * Builds engine states from real clubs. This is the only place that reads the
 * database and config(); the engine itself gets plain arrays and a snapshot.
 */
class MatchFactory
{
    public static function snapshot(): array
    {
        return ['match' => config('game.match'), 'engine' => config('game.engine')];
    }

    public static function club(MasterClub $club): array
    {
        return [
            'id' => $club->id, 'name' => $club->name, 'code' => $club->code, 'league' => $club->league_name,
            'primary' => $club->color_primary, 'secondary' => $club->color_secondary, 'strength' => $club->strength_cp,
        ];
    }

    public static function squad(MasterClub $club): array
    {
        return $club->players()->orderByDesc('overall')->orderBy('id')->get()->map(fn ($p) => $p->toArray())->all();
    }

    /**
     * @param  array  $options  seed, competition, referee, venue
     * @param  array  $overrides  per side: formation, starters, bench, tactics
     */
    public static function make(MasterClub $home, MasterClub $away, array $options, array $overrides = []): array
    {
        $side = fn (MasterClub $club, string $key) => [
            'club' => self::club($club),
            'squad' => self::squad($club),
        ] + array_filter($overrides[$key] ?? [], fn ($v) => $v !== null);

        return MatchSetup::build($side($home, 'home'), $side($away, 'away'), $options, self::snapshot());
    }
}
