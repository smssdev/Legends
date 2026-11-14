<?php

namespace App\Messenger;

use App\League\DailyTasks;
use App\League\Predictions;
use App\Models\Club;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

/**
 * [Sprint 69] The daily tasks and the round's predictions on the bot, by the game's own code: the tasks' progress with
 * a button to take each finished one's coins (DailyTasks::claim, once a day by its key), and a button per result to
 * predict each open match of the round (Predictions::pick, until its lineup locks).
 */
class Plays
{
    private const TASKS = [
        'lineup' => ['ضبط الفريق (التشكيلة أو التكتيك)', 'Set the team (lineup or tactics)'],
        'friendly' => ['مباراة ودية', 'A friendly'],
        'training' => ['تدريب لاعب', 'A training session'],
        'chat' => ['كلمة في جروب', 'A word in a group'],
    ];

    public static function tasks(int $userId, bool $en): array
    {
        $clubs = Reads::clubs($userId);
        if ($clubs->isEmpty()) {
            return ['text' => Reads::noClub($en), 'buttons' => []];
        }
        $lines = [];
        $buttons = [];
        foreach ($clubs as $c) {
            $view = DailyTasks::view(Club::find($c->id), $userId);
            $lines[] = ($en ? "Today's tasks, {$c->name}: " : "مهام اليوم، {$c->name}: ")."{$view['done']}/{$view['total']}";
            foreach ($view['tasks'] as $t) {
                $state = $t['claimed'] ? ($en ? 'taken' : 'أُخذت') : ($t['complete'] ? ($en ? 'done' : 'تمت') : ($en ? 'not yet' : 'لم تتم'));
                $lines[] = '- '.self::TASKS[$t['task']][$en ? 1 : 0].": {$state} ({$t['coins']} ".($en ? 'coins' : 'كوينز').')';
                if ($t['complete'] && ! $t['claimed']) {
                    $buttons[] = [($en ? 'Take ' : 'خذ ').$t['coins'].($en ? ' coins: ' : ' كوينز: ').self::TASKS[$t['task']][$en ? 1 : 0], "claim:{$c->id}:{$t['task']}"];
                }
            }
        }

        return ['text' => implode("\n", $lines), 'buttons' => $buttons];
    }

    /** claim:<club>:<task>. */
    public static function claim(int $userId, string $data, bool $en): array
    {
        [, $clubId, $task] = array_pad(explode(':', $data, 3), 3, '');
        $club = Club::where('id', (int) $clubId)->where('user_id', $userId)->first();
        if (! $club || ! in_array($task, DailyTasks::TASKS, true)) {
            return ['text' => $en ? 'This button is no longer valid.' : 'هذا الزر لم يعد صالحاً.', 'buttons' => []];
        }
        try {
            DailyTasks::claim($club, $userId, $task);
        } catch (HttpExceptionInterface $e) {
            return ['text' => $e->getMessage(), 'buttons' => []];
        }

        return self::tasks($userId, $en);
    }

    /** The open matches of the round in each of his leagues, a message each with three buttons. */
    public static function predictions(int $userId, bool $en): array
    {
        $out = [];
        foreach (Reads::clubs($userId)->unique('league_id') as $c) {
            $round = Predictions::round((int) $c->league_id, $userId);
            foreach ($round['matches'] as $m) {
                if (! $m['open'] || count($out) >= 6) {
                    continue;
                }
                $mine = $m['mine'] ? ($en ? ' (your pick: ' : ' (توقعك: ').self::pickLabel($m['mine'], $m, $en).')' : '';
                $out[] = ['text' => ($en ? "Round {$round['round']}, {$c->league_name}: " : "الجولة {$round['round']}، {$c->league_name}: ")."{$m['home']['name']} - {$m['away']['name']}{$mine}",
                    'buttons' => array_map(fn ($p) => [self::pickLabel($p, $m, $en), "pr:{$m['fixture_id']}:{$p}"], Predictions::PICKS)];
            }
        }

        return $out ?: [['text' => $en ? 'No match to predict now.' : 'لا مباراة تتوقعها الآن.', 'buttons' => []]];
    }

    private static function pickLabel(string $pick, array $m, bool $en): string
    {
        return match ($pick) {
            'home' => $m['home']['name'],
            'away' => $m['away']['name'],
            default => $en ? 'Draw' : 'تعادل',
        };
    }

    /** pr:<fixture>:<pick>, in a league where he coaches. */
    public static function predict(int $userId, string $data, bool $en): array
    {
        [, $fixtureId, $pick] = array_pad(explode(':', $data, 3), 3, '');
        $league = (int) DB::table('fixtures')->join('seasons', 'seasons.id', '=', 'fixtures.season_id')->where('fixtures.id', (int) $fixtureId)->value('seasons.league_id');
        if (! $league || ! Reads::clubs($userId)->pluck('league_id')->map(fn ($v) => (int) $v)->contains($league)) {
            return ['text' => $en ? 'This button is no longer valid.' : 'هذا الزر لم يعد صالحاً.', 'buttons' => []];
        }
        try {
            Predictions::pick($league, $userId, (int) $fixtureId, $pick);
        } catch (HttpExceptionInterface $e) {
            return ['text' => $e->getMessage(), 'buttons' => []];
        }

        return ['text' => $en ? 'Prediction saved. You can change it until the lineups lock.' : 'حُفظ توقعك، وتغيّره حتى قفل التشكيلة.', 'buttons' => []];
    }
}
