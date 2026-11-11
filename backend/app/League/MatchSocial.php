<?php

namespace App\League;

use App\Events\MatchSocialPosted;
use App\Support\GameClock;
use App\Support\LiveEvents;
use Illuminate\Support\Facades\Cache;
use Illuminate\Validation\ValidationException;

/**
 * The live broadcast's own life [X24]: the reactions that float on every viewer's screen, the boos and cheers
 * aimed at one side (with a long cool-down, so they mean something), and the side chat between the league's
 * coaches who watch. All of it lives as long as the match is watched (the cache), goes out with the live poll,
 * and changes nothing in the match.
 */
class MatchSocial
{
    public const CHEERS = ['boo', 'cheer'];

    /** A reaction: an emoji of the list, or a boo or a cheer for one side. */
    public static function react(int $matchId, int $userId, string $who, ?string $side, string $key, ?string $target): array
    {
        $cheer = in_array($key, self::CHEERS, true);
        $gap = $cheer ? (int) config('game.match.cheer_gap_ms') : (int) config('game.match.reaction_gap_ms');
        self::wait("match-react:{$matchId}:{$userId}:".($cheer ? 'cheer' : 'emoji'), $gap, 'key', $cheer ? 'التشجيع والاستهجان مرة كل نصف دقيقة.' : 'تمهّل قليلاً.');

        return self::push($matchId, 'reactions', ['side' => $side, 'key' => $key, 'target' => $cheer ? $target : null, 'who' => $who],
            (int) config('game.match.reactions_kept'));
    }

    public static function say(int $matchId, int $userId, string $who, ?string $side, string $body): array
    {
        self::wait("match-chat:{$matchId}:{$userId}", (int) config('game.match.chat_gap_ms'), 'body', 'تمهّل قليلاً قبل الرسالة التالية.');

        return self::push($matchId, 'chat', ['side' => $side, 'who' => $who, 'body' => $body, 'user_id' => $userId], (int) config('game.match.chat_kept'));
    }

    /** What the live poll gives: the latest reactions and the chat. */
    public static function recent(int $matchId): array
    {
        return ['reactions' => Cache::get("match-social:{$matchId}:reactions", []), 'chat' => Cache::get("match-social:{$matchId}:chat", [])];
    }

    private static function wait(string $key, int $ms, string $field, string $message): void
    {
        $now = GameClock::nowMs();
        if ($now - (int) Cache::get($key, 0) < $ms) {
            throw ValidationException::withMessages([$field => $message]);
        }
        Cache::put($key, $now, 600);
    }

    private static function push(int $matchId, string $list, array $item, int $keep): array
    {
        $item = Cache::lock("match-social:{$matchId}", 5)->block(3, function () use ($matchId, $list, $item, $keep) {
            $key = "match-social:{$matchId}:{$list}";
            $items = Cache::get($key, []);
            $item = ['id' => ($items ? end($items)['id'] : 0) + 1] + $item + ['at' => GameClock::nowMs()];
            Cache::put($key, array_slice([...$items, $item], -$keep), 10800);

            return $item;
        });
        // [Sprint 53 B3] On every watching screen at once (the poll keeps it too, for one that missed it).
        LiveEvents::send(new MatchSocialPosted($matchId, $list, $item));

        return $item;
    }
}
