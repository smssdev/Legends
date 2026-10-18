<?php

namespace App\Engine;

/**
 * Formation templates. Positions are pitch coordinates in decimetres for a
 * team attacking towards x = 1050 (the away team is mirrored), y = 0 is the
 * far touchline. Each slot names its line and the positions that fit it.
 */
final class Formations
{
    public const DEFAULT = '4-2-3-1';

    private const SLOT = [
        'GK' => ['gk', ['GK']],
        'LB' => ['def', ['LB', 'LWB']], 'RB' => ['def', ['RB', 'RWB']], 'CB' => ['def', ['CB']],
        'LWB' => ['def', ['LB', 'LWB']], 'RWB' => ['def', ['RB', 'RWB']],
        'CDM' => ['mid', ['CDM', 'CM']], 'CM' => ['mid', ['CM', 'CDM', 'CAM']], 'CAM' => ['mid', ['CAM', 'CM']],
        'LM' => ['mid', ['LM', 'LW']], 'RM' => ['mid', ['RM', 'RW']],
        'LW' => ['att', ['LW', 'LM']], 'RW' => ['att', ['RW', 'RM']], 'ST' => ['att', ['ST', 'CF']],
    ];

    /** [role, x, y] per slot, GK first. */
    private const TEMPLATES = [
        '4-2-3-1' => [['GK', 50, 340], ['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100],
            ['CDM', 400, 420], ['CDM', 420, 260], ['RM', 560, 590], ['CAM', 560, 340], ['LM', 560, 90], ['ST', 660, 340]],
        '4-3-3' => [['GK', 50, 340], ['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100],
            ['CDM', 400, 340], ['CM', 470, 470], ['CM', 470, 210], ['RW', 620, 590], ['ST', 660, 340], ['LW', 620, 90]],
        '4-4-2' => [['GK', 50, 340], ['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100],
            ['RM', 470, 590], ['CM', 440, 420], ['CM', 440, 260], ['LM', 470, 90], ['ST', 640, 420], ['ST', 640, 260]],
        '4-1-4-1' => [['GK', 50, 340], ['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100],
            ['CDM', 380, 340], ['RM', 520, 590], ['CM', 500, 430], ['CM', 500, 250], ['LM', 520, 90], ['ST', 660, 340]],
        '3-5-2' => [['GK', 50, 340], ['CB', 260, 480], ['CB', 250, 340], ['CB', 260, 200], ['RWB', 430, 610],
            ['CDM', 400, 340], ['CM', 480, 450], ['CM', 480, 230], ['LWB', 430, 70], ['ST', 640, 420], ['ST', 640, 260]],
        '5-3-2' => [['GK', 50, 340], ['RWB', 320, 610], ['CB', 250, 470], ['CB', 240, 340], ['CB', 250, 210],
            ['LWB', 320, 70], ['CM', 450, 470], ['CDM', 420, 340], ['CM', 450, 210], ['ST', 630, 420], ['ST', 630, 260]],
    ];

    public static function names(): array
    {
        return array_keys(self::TEMPLATES);
    }

    public static function exists(string $name): bool
    {
        return isset(self::TEMPLATES[$name]);
    }

    /** @return list<array{role: string, line: string, fits: list<string>, x: int, y: int}> */
    public static function slots(string $name): array
    {
        return array_map(fn ($s) => [
            'role' => $s[0], 'line' => self::SLOT[$s[0]][0], 'fits' => self::SLOT[$s[0]][1], 'x' => $s[1], 'y' => $s[2],
        ], self::TEMPLATES[$name] ?? self::TEMPLATES[self::DEFAULT]);
    }
}
