<?php

namespace App\League;

/**
 * The 24 formations a coach picks from [PLAN 2.15]: 12 shapes, each in an A and a B version, plus up to 3 of
 * the club's own (custom). Same frame as App\Engine\Formations: x is the depth in decimetres towards the
 * opponent's goal (1050), y across the pitch (0 is the far touchline, so right-sided roles sit near 680),
 * and each slot's role gives its line. The engine reads a lineup's slots from here from Sprint 18 on; its
 * own six templates (the simulator's) stay as they are, so no recorded match changes.
 */
class FormationBook
{
    /** Columns across the pitch, right to left, and the depth of each row of a custom formation. */
    public const COLUMNS = [1 => 610, 2 => 470, 3 => 340, 4 => 210, 5 => 70];

    public const ROWS = ['def' => 260, 'dm' => 400, 'am' => 530, 'att' => 650];

    /**
     * The depth band of each line [X5]: a coach drags a player anywhere across the pitch, but only as deep or as high
     * as his line goes (a striker never drops into midfield). Across: from touchline to touchline.
     */
    public const BANDS = ['def' => [180, 350], 'mid' => [360, 580], 'att' => [590, 720]];

    public const ACROSS = [30, 650];

    /** Nearer a touchline than this is a wide role (RB, RM, RW and their left side). */
    public const WIDE = 140;

    /** Players in each line of a custom formation (the goalkeeper apart) [PLAN 2.15]. */
    public const LIMITS = ['def' => [3, 6], 'mid' => [2, 6], 'att' => [1, 5]];

    private const LINE = [
        'GK' => 'gk', 'RB' => 'def', 'LB' => 'def', 'CB' => 'def', 'RWB' => 'def', 'LWB' => 'def',
        'CDM' => 'mid', 'CM' => 'mid', 'CAM' => 'mid', 'RM' => 'mid', 'LM' => 'mid',
        'RW' => 'att', 'LW' => 'att', 'ST' => 'att',
    ];

    /** [role, x, y], goalkeeper first, then right to left from the back. */
    private const BOOK = [
        '4-4-2A' => [['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100], ['RM', 470, 590], ['CM', 440, 420], ['CM', 440, 260], ['LM', 470, 90], ['ST', 640, 420], ['ST', 640, 260]],
        '4-4-2B' => [['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100], ['CDM', 390, 340], ['CM', 470, 490], ['CM', 470, 190], ['CAM', 550, 340], ['ST', 650, 430], ['ST', 650, 250]],
        '4-3-3A' => [['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100], ['CDM', 400, 340], ['CM', 470, 470], ['CM', 470, 210], ['RW', 620, 590], ['ST', 660, 340], ['LW', 620, 90]],
        '4-3-3B' => [['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100], ['CM', 450, 500], ['CM', 430, 340], ['CM', 450, 180], ['RW', 630, 580], ['ST', 670, 340], ['LW', 630, 100]],
        '4-5-1A' => [['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100], ['RM', 480, 600], ['CM', 450, 460], ['CM', 430, 340], ['CM', 450, 220], ['LM', 480, 80], ['ST', 650, 340]],
        '4-5-1B' => [['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100], ['CDM', 380, 340], ['RM', 520, 590], ['CM', 500, 430], ['CM', 500, 250], ['LM', 520, 90], ['ST', 660, 340]],
        '4-2-3-1A' => [['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100], ['CDM', 400, 420], ['CDM', 420, 260], ['RM', 560, 590], ['CAM', 560, 340], ['LM', 560, 90], ['ST', 660, 340]],
        '4-2-3-1B' => [['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100], ['CDM', 400, 420], ['CDM', 400, 260], ['CAM', 550, 480], ['CAM', 570, 340], ['CAM', 550, 200], ['ST', 670, 340]],
        '3-5-2A' => [['CB', 260, 480], ['CB', 250, 340], ['CB', 260, 200], ['RWB', 430, 610], ['CDM', 400, 340], ['CM', 480, 450], ['CM', 480, 230], ['LWB', 430, 70], ['ST', 640, 420], ['ST', 640, 260]],
        '3-5-2B' => [['CB', 260, 480], ['CB', 250, 340], ['CB', 260, 200], ['RM', 480, 610], ['CM', 450, 460], ['CDM', 410, 340], ['CM', 450, 220], ['LM', 480, 70], ['ST', 640, 420], ['ST', 640, 260]],
        '5-3-2A' => [['RWB', 320, 610], ['CB', 250, 470], ['CB', 240, 340], ['CB', 250, 210], ['LWB', 320, 70], ['CM', 450, 470], ['CDM', 420, 340], ['CM', 450, 210], ['ST', 630, 420], ['ST', 630, 260]],
        '5-3-2B' => [['RB', 290, 610], ['CB', 250, 470], ['CB', 240, 340], ['CB', 250, 210], ['LB', 290, 70], ['CM', 460, 450], ['CAM', 520, 340], ['CM', 460, 230], ['ST', 640, 420], ['ST', 640, 260]],
        '3-4-3A' => [['CB', 260, 480], ['CB', 250, 340], ['CB', 260, 200], ['RM', 460, 600], ['CM', 430, 420], ['CM', 430, 260], ['LM', 460, 80], ['RW', 630, 560], ['ST', 660, 340], ['LW', 630, 120]],
        '3-4-3B' => [['CB', 260, 480], ['CB', 250, 340], ['CB', 260, 200], ['CDM', 390, 340], ['RM', 470, 600], ['LM', 470, 80], ['CAM', 540, 340], ['RW', 640, 540], ['ST', 670, 340], ['LW', 640, 140]],
        '4-2-4A' => [['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100], ['CM', 440, 420], ['CM', 440, 260], ['RW', 620, 600], ['ST', 650, 420], ['ST', 650, 260], ['LW', 620, 80]],
        '4-2-4B' => [['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100], ['CDM', 400, 420], ['CDM', 400, 260], ['RW', 610, 590], ['ST', 650, 420], ['ST', 650, 260], ['LW', 610, 90]],
        '5-4-1A' => [['RWB', 320, 610], ['CB', 250, 470], ['CB', 240, 340], ['CB', 250, 210], ['LWB', 320, 70], ['RM', 470, 590], ['CM', 440, 420], ['CM', 440, 260], ['LM', 470, 90], ['ST', 640, 340]],
        '5-4-1B' => [['RB', 290, 610], ['CB', 250, 470], ['CB', 240, 340], ['CB', 250, 210], ['LB', 290, 70], ['CDM', 400, 340], ['CM', 460, 480], ['CM', 460, 200], ['CAM', 540, 340], ['ST', 650, 340]],
        '4-3-2-1A' => [['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100], ['CM', 440, 480], ['CDM', 410, 340], ['CM', 440, 200], ['CAM', 560, 440], ['CAM', 560, 240], ['ST', 660, 340]],
        '4-3-2-1B' => [['RB', 300, 580], ['CB', 260, 430], ['CB', 260, 250], ['LB', 300, 100], ['CM', 450, 470], ['CM', 430, 340], ['CM', 450, 210], ['RW', 590, 470], ['LW', 590, 210], ['ST', 670, 340]],
        '3-3-4A' => [['CB', 260, 480], ['CB', 250, 340], ['CB', 260, 200], ['CM', 440, 470], ['CDM', 410, 340], ['CM', 440, 210], ['RW', 620, 590], ['ST', 650, 420], ['ST', 650, 260], ['LW', 620, 90]],
        '3-3-4B' => [['CB', 260, 480], ['CB', 250, 340], ['CB', 260, 200], ['RM', 460, 590], ['CM', 430, 340], ['LM', 460, 90], ['RW', 630, 560], ['ST', 660, 420], ['ST', 660, 260], ['LW', 630, 120]],
        '6-3-1A' => [['RWB', 320, 630], ['CB', 250, 500], ['CB', 240, 400], ['CB', 240, 280], ['CB', 250, 180], ['LWB', 320, 50], ['CM', 450, 470], ['CDM', 420, 340], ['CM', 450, 210], ['ST', 630, 340]],
        '6-3-1B' => [['RB', 290, 630], ['CB', 250, 500], ['CB', 240, 400], ['CB', 240, 280], ['CB', 250, 180], ['LB', 290, 50], ['RM', 460, 560], ['CM', 440, 340], ['LM', 460, 120], ['ST', 640, 340]],
    ];

    public static function names(): array
    {
        return array_keys(self::BOOK);
    }

    public static function has(string $name): bool
    {
        return isset(self::BOOK[$name]);
    }

    /** "4-3-3A" shows as "4-3-3 A". */
    public static function label(string $name): string
    {
        return preg_replace('/([AB])$/', ' $1', $name);
    }

    /** @return list<array{role: string, line: string, x: int, y: int}> eleven slots, the goalkeeper first */
    public static function slots(string $name): array
    {
        return array_map(fn ($s) => ['role' => $s[0], 'line' => self::LINE[$s[0]], 'x' => $s[1], 'y' => $s[2]],
            array_merge([['GK', 50, 340]], self::BOOK[$name]));
    }

    /** Players per line: ['def' => 4, 'mid' => 3, 'att' => 3]. */
    public static function lines(array $slots): array
    {
        $count = ['def' => 0, 'mid' => 0, 'att' => 0];
        foreach ($slots as $s) {
            if ($s['line'] !== 'gk') {
                $count[$s['line']]++;
            }
        }

        return $count;
    }

    /**
     * A custom formation's slots from its ten outfield cells ([row, column]): the row gives the line (the
     * midfield has two rows, defensive and attacking) and the column the side, so the role follows.
     */
    public static function custom(array $cells): array
    {
        $slots = [['role' => 'GK', 'line' => 'gk', 'x' => 50, 'y' => 340]];
        foreach ($cells as [$row, $col]) {
            $edge = $col === 1 ? 'R' : ($col === 5 ? 'L' : null);
            $role = match ($row) {
                'def' => $edge ? $edge.'B' : 'CB',
                'dm' => $edge ? $edge.'M' : 'CDM',
                'am' => $edge ? $edge.'M' : 'CAM',
                'att' => $edge ? $edge.'W' : 'ST',
            };
            $slots[] = ['role' => $role, 'line' => self::LINE[$role], 'x' => self::ROWS[$row], 'y' => self::COLUMNS[$col]];
        }

        return $slots;
    }

    /** The role a place gives within its line: wide or central, and in midfield how deep [X5]. */
    public static function roleAt(string $line, int $x, int $y): string
    {
        $edge = $y >= self::ACROSS[1] + self::ACROSS[0] - self::WIDE ? 'R' : ($y <= self::WIDE ? 'L' : null);

        return match ($line) {
            'def' => $edge ? $edge.($x >= 300 ? 'WB' : 'B') : 'CB',
            'mid' => $edge ? $edge.'M' : ($x < 430 ? 'CDM' : ($x >= 520 ? 'CAM' : 'CM')),
            default => $edge ? $edge.'W' : 'ST',
        };
    }

    /**
     * The slots with the coach's own places [X5]: ten [x, y] for the outfield (the keeper stays in goal), each inside
     * its line's band. A moved slot takes the role its new place gives; one left where it was keeps its own.
     *
     * @throws \InvalidArgumentException with the Arabic reason
     */
    public static function moved(array $slots, array $positions): array
    {
        if (count($positions) !== count($slots) - 1) {
            throw new \InvalidArgumentException('أماكن اللاعبين عشرة، والحارس ثابت في مرماه.');
        }
        $names = ['def' => 'الدفاع', 'mid' => 'الوسط', 'att' => 'الهجوم'];
        foreach (array_values($positions) as $i => $at) {
            $slot = &$slots[$i + 1];
            [$x, $y] = [(int) ($at[0] ?? -1), (int) ($at[1] ?? -1)];
            [$from, $to] = self::BANDS[$slot['line']];
            if ($x < $from || $x > $to || $y < self::ACROSS[0] || $y > self::ACROSS[1]) {
                throw new \InvalidArgumentException("لاعب {$names[$slot['line']]} يتحرك داخل منطقة خطه فقط.");
            }
            if ($x !== $slot['x'] || $y !== $slot['y']) {
                $slot = ['role' => self::roleAt($slot['line'], $x, $y), 'line' => $slot['line'], 'x' => $x, 'y' => $y];
            }
            unset($slot);
        }

        return $slots;
    }

    /** The first rule a custom formation breaks, in Arabic, or null when it is fine. */
    public static function invalid(array $slots): ?string
    {
        $names = ['def' => 'الدفاع', 'mid' => 'الوسط', 'att' => 'الهجوم'];
        foreach (self::lines($slots) as $line => $n) {
            [$min, $max] = self::LIMITS[$line];
            if ($n < $min || $n > $max) {
                return "{$names[$line]} من {$min} إلى {$max} لاعبين، وفي تشكيلتك {$n}.";
            }
        }

        return null;
    }
}
