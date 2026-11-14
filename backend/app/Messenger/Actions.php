<?php

namespace App\Messenger;

use App\League\MatchPrep;
use App\Market\Transfers;
use App\Models\Club;
use App\Support\GameClock;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

/**
 * [Sprint 68] What a coach may do from the bot, each asked twice (a tap shows «are you sure?», a second tap does it),
 * through the same game code as the site, so its rules and checks are the site's: accept or reject an offer made to
 * his club, and «تحسين» (his lineup back to the automatic best, as on the lineup screen) before the lock. The buttons
 * carry the command: ask:<what>:<id> asks, do:<what>:<id> does; the account is the chat's, never the button's.
 */
class Actions
{
    public const WHATS = ['accept', 'reject', 'fix'];

    /** The offers waiting for his answer, one message each, with its buttons. */
    public static function offers(int $userId, bool $en): array
    {
        $clubs = Reads::clubs($userId)->pluck('name', 'id');
        $offers = DB::table('transfer_offers')->whereIn('to_club_id', $clubs->keys())->where('status', 'pending')
            ->where('expires_at', '>', GameClock::now())->orderBy('expires_at')->limit(5)->get();
        if ($offers->isEmpty()) {
            return [['text' => $en ? 'No offer waits for your answer.' : 'لا عروض تنتظر ردك.', 'buttons' => []]];
        }

        return $offers->map(fn ($o) => ['text' => self::describe($o, $en), 'buttons' => [
            [$en ? 'Accept' : 'قبول', "ask:accept:{$o->id}"], [$en ? 'Reject' : 'رفض', "ask:reject:{$o->id}"],
        ]])->all();
    }

    private static function describe(object $o, bool $en): string
    {
        $from = DB::table('clubs')->where('id', $o->from_club_id)->value('name');
        $items = DB::table('offer_items')->join('players', 'players.id', '=', 'offer_items.player_id')
            ->join('master_players', 'master_players.id', '=', 'players.master_player_id')->where('offer_items.offer_id', $o->id)
            ->get(['offer_items.direction', 'master_players.name']);
        $wants = $items->where('direction', 'in')->pluck('name')->implode('، ');
        $gives = $items->where('direction', 'out')->pluck('name')->implode('، ');
        $lines = [$en ? "Offer from {$from}:" : "عرض من {$from}:"];
        if ($wants !== '') {
            $lines[] = ($en ? 'They want: ' : 'يطلب: ').$wants;
        }
        if ($gives !== '') {
            $lines[] = ($en ? 'They give: ' : 'يعطيك: ').$gives;
        }
        if ((int) $o->money > 0) {
            $lines[] = ($en ? 'Money: ' : 'المبلغ: ').number_format((int) $o->money);
        }

        return implode("\n", $lines);
    }

    /** «تحسين»: one button per club whose lineup is still open. */
    public static function fixChoices(int $userId, bool $en): array
    {
        $clubs = Reads::clubs($userId);
        if ($clubs->isEmpty()) {
            return ['text' => Reads::noClub($en), 'buttons' => []];
        }

        return ['text' => $en ? 'Set the automatic best lineup («Improve») for which club?' : 'أضبط التشكيلة التلقائية الأفضل («تحسين») لأي نادٍ؟',
            'buttons' => $clubs->map(fn ($c) => [$c->name, "ask:fix:{$c->id}"])->values()->all()];
    }

    /** A tapped ask:… or do:… from this account. */
    public static function run(int $userId, string $data, bool $en): array
    {
        [$step, $what, $id] = array_pad(explode(':', $data, 3), 3, '');
        $id = (int) $id;
        if (! in_array($what, self::WHATS, true) || $id < 1) {
            return ['text' => $en ? 'This button is no longer valid.' : 'هذا الزر لم يعد صالحاً.', 'buttons' => []];
        }
        $club = self::clubFor($userId, $what, $id);
        if (! $club) {
            return ['text' => $en ? 'This is not yours to decide, or it is already decided.' : 'هذا ليس لك أن تقرره، أو قُرّر من قبل.', 'buttons' => []];
        }
        if ($step === 'ask') {
            $q = match ($what) {
                'accept' => $en ? 'Accept this offer? The players and the money move at once.' : 'تقبل هذا العرض؟ ينتقل اللاعبون والمال فوراً.',
                'reject' => $en ? 'Reject this offer?' : 'ترفض هذا العرض؟',
                'fix' => $en ? "Set {$club->name}'s lineup back to the automatic best?" : "تعيد تشكيلة {$club->name} إلى التلقائية الأفضل؟",
            };

            return ['text' => $q, 'buttons' => [[$en ? 'Yes' : 'نعم', "do:{$what}:{$id}"], [$en ? 'No' : 'لا', 'cancel']]];
        }
        if ($step !== 'do') {
            return ['text' => '', 'buttons' => []];
        }
        try {
            match ($what) {
                'accept' => Transfers::accept($id, $club->id),
                'reject' => Transfers::reject($id, $club->id),
                'fix' => self::fix($club),
            };
        } catch (HttpExceptionInterface $e) {
            return ['text' => $e->getMessage() ?: ($en ? 'This cannot be done now.' : 'لا يمكن هذا الآن.'), 'buttons' => []];
        } catch (ValidationException $e) {
            return ['text' => collect($e->errors())->flatten()->first() ?? $e->getMessage(), 'buttons' => []];
        }

        return ['text' => match ($what) {
            'accept' => $en ? 'Offer accepted.' : 'قُبل العرض.',
            'reject' => $en ? 'Offer rejected.' : 'رُفض العرض.',
            'fix' => $en ? "{$club->name} plays the automatic best lineup now." : "تشكيلة {$club->name} الآن التلقائية الأفضل.",
        }, 'buttons' => []];
    }

    /** The club of this account the action is about: the offer's receiver, or the club itself for «تحسين». */
    private static function clubFor(int $userId, string $what, int $id): ?Club
    {
        $clubId = $what === 'fix' ? $id
            : DB::table('transfer_offers')->where('id', $id)->where('status', 'pending')->value('to_club_id');

        return $clubId ? Club::where('id', $clubId)->where('user_id', $userId)->first() : null;
    }

    /** As DELETE /leagues/{league}/team/lineup: the saved sheet goes, and the automatic best plays. */
    private static function fix(Club $club): void
    {
        MatchPrep::assertOpen($club);
        DB::table('lineups')->where('club_id', $club->id)->delete();
    }
}
