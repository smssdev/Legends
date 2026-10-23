<?php

namespace App\Simulator;

/**
 * What the commentator says over one minute [PLAN 2.21, MATCH_VIEW 5, Sprint 35 B1]: the line (from the shared table
 * resources/commentary/voice.json, the one the web and the app read too), who is in it, and which variant of each of
 * its slots (the build-up, the key moment, the reaction, and the Arabic bubble), drawn from the match's seed and the
 * minute. Sent with the minute, so every screen and every replay says the same words.
 *
 * @phpstan-type Pick array{0: ?int, 1: ?int}
 */
class Voice
{
    private static ?array $lines = null;

    public static function lines(): array
    {
        return self::$lines ??= json_decode(file_get_contents(resource_path('commentary/voice.json')), true);
    }

    /**
     * @param  array  $events  the minute's events
     * @param  string  $kind  its moment (MomentClock)
     * @return ?array{line: string, vars: array, pick: array, how?: string}
     */
    public static function for(array $events, string $kind, int $seed, int $tick): ?array
    {
        $first = function (string $type) use ($events) {
            foreach ($events as $e) {
                if ($e['type'] === $type) {
                    return $e;
                }
            }

            return null;
        };
        $attack = $first('attack');
        $goal = $first('goal');
        $card = $first('card');
        $pen = $first('penalty');
        $fk = $first('free_kick');
        $corner = $first('corner');
        $sub = $first('sub');
        $injury = $first('injury');
        $period = $first('period');
        $shootout = $first('shootout');
        $action = null;
        foreach ($events as $e) {
            if ($e['type'] === 'action' && in_array($e['action']['type'] ?? null, ['tactics', 'formation'], true)) {
                $action = $e;
                break;
            }
        }
        $draw = fn (string $what, int $n) => $n > 0 ? crc32("voice:{$seed}:{$tick}:{$what}") % $n : 0;
        $vars = ['p' => null, 'q' => null, 'A' => 'home'];
        $how = null;
        $line = null;

        if ($kind === 'goal' && $goal) {
            $vars = ['p' => $goal['scorer'] ?? null, 'q' => $goal['assist'] ?? null, 'A' => $goal['team']];
            $line = ($attack['quality'] ?? null) === 'header' ? 'header' : 'goal';
        } elseif (in_array($kind, ['penalty', 'free_kick'], true) && ($pen || $fk)) {
            $sp = $pen ?? $fk;
            $vars = ['p' => $sp['taker'] ?? null, 'q' => $sp['keeper'] ?? null, 'A' => $sp['team']];
            $result = $goal ? 'goal' : (($sp['keeper'] ?? null) ? 'save' : 'miss');
            $line = $kind === 'penalty' ? ($goal ? 'penalty_goal' : 'penalty_save') : "free_kick_{$result}";
        } elseif (in_array($kind, ['red', 'yellow'], true) && $card) {
            $vars['p'] = $card['player'] ?? null;
            $vars['A'] = $card['team'];
            $line = ($card['second_yellow'] ?? false) ? 'second_yellow' : $kind;
        } elseif ($kind === 'save' && $attack) {
            $vars = ['p' => $attack['shooter'] ?? null, 'q' => $attack['keeper'] ?? null, 'A' => $attack['team']];
            $line = 'save';
        } elseif ($kind === 'miss' && $attack) {
            $vars = ['p' => $attack['shooter'] ?? null, 'q' => $attack['defender'] ?? null, 'A' => $attack['team']];
            if (($attack['result'] ?? null) === 'blocked') {
                $line = 'blocked';
            } else {
                $how = ['wide', 'wide', 'over', 'post'][$draw('how', 4)];
                $line = $how === 'post' ? 'post' : 'miss';
            }
        } elseif ($kind === 'offside' && $attack) {
            $vars['p'] = $attack['receiver'] ?? $attack['shooter'] ?? null;
            $vars['A'] = $attack['team'];
            $line = 'offside';
        } elseif ($kind === 'corner' && $corner) {
            $won = ($corner['won'] ?? true) !== false;
            $vars = ['p' => $attack['shooter'] ?? null, 'q' => $corner['taker'] ?? null, 'A' => $corner['team']];
            $line = $won ? 'corner_header' : 'corner_claim';
        } elseif ($kind === 'sub' && $sub) {
            $vars = ['p' => $sub['in'] ?? null, 'q' => $sub['out'] ?? null, 'A' => $sub['team']];
            $line = 'sub';
        } elseif ($kind === 'injury' && $injury) {
            $vars['p'] = $injury['player'] ?? null;
            $vars['A'] = $injury['team'];
            $line = 'injury';
        } elseif ($kind === 'coach' && $action) {
            $vars['A'] = $action['team'];
            $line = 'coach';
        } elseif ($kind === 'whistle' && $period) {
            $line = ['halftime' => 'halftime', 'fulltime' => 'fulltime', 'extra_time' => 'extra_time', 'penalties' => 'penalties'][$period['name'] ?? ''] ?? 'halftime';
        } elseif ($kind === 'stoppage' && $first('stoppage')) {
            $line = 'stoppage';
        } elseif ($kind === 'shootout' && $shootout) {
            $kicks = $shootout['kicks'] ?? [];
            $vars['A'] = $kicks ? $kicks[count($kicks) - 1]['team'] : 'home';
            $line = 'shootout';
        } elseif ($attack && $draw('attack', 100) < 45) {
            $vars['A'] = $attack['team'];
            $line = 'attack';
        }
        if (! $line) {
            return null;
        }

        $table = self::lines()[$line];
        $fits = fn (string $text) => (! str_contains($text, '{p}') || $vars['p']) && (! str_contains($text, '{q}') || $vars['q']);
        // Among the variants whose names we have, one drawn by the seed (English); any (Arabic, which says no names).
        $choose = function (array $list, string $what) use ($fits, $draw) {
            $ok = array_keys(array_filter($list, $fits));

            return $ok ? $ok[$draw($what, count($ok))] : null;
        };
        $pick = [];
        foreach (['pre', 'key', 'post'] as $slot) {
            if (isset($table[$slot])) {
                $pick[$slot] = [$choose($table[$slot]['en'] ?? [], "{$slot}:en"), ($table[$slot]['ar'] ?? []) ? $draw("{$slot}:ar", count($table[$slot]['ar'])) : null];
            }
        }
        $pick['bubble'] = $choose($table['bubble'] ?? [], 'bubble');

        return ['line' => $line, 'vars' => $vars, 'pick' => $pick] + ($how ? ['how' => $how] : []);
    }
}
