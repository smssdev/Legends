<?php

namespace App\Messenger;

use App\Auth\Referral;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 69] «@GameLegendManagerBot» typed in any Telegram chat: the coach picks one of his own things to send there,
 * each with a button that brings the reader to the game by his invite link (Referral): his last results, each of his
 * leagues' tables, and an invitation. Not linked: the invitation alone. Only what the coach chooses to send, and only
 * results and tables (never a tactic).
 */
class Inline
{
    public static function results(string $from, string $query): array
    {
        $userId = Messenger::userFor('telegram', $from);
        $user = $userId ? User::find($userId) : null;
        $en = $user ? $user->locale === 'en' : ! preg_match('/\p{Arabic}/u', $query);
        $site = rtrim((string) config('app.frontend_url'), '/');
        $invite = $user ? Referral::summary($user)['link'] : $site;
        $play = ['inline_keyboard' => [[['text' => $en ? 'Play Game Legend Manager' : 'العب المدرب الأسطورة', 'url' => $invite]]]];
        $article = fn (string $id, string $title, string $description, string $text) => ['type' => 'article', 'id' => $id, 'title' => $title,
            'description' => mb_substr($description, 0, 120), 'input_message_content' => ['message_text' => Messenger::clip($text), 'disable_web_page_preview' => true],
            'reply_markup' => $play];
        $out = [];
        if ($user) {
            $last = self::last($user->id, $en);
            if ($last !== null) {
                $out[] = $article('last', $en ? 'My last results' : 'آخر نتائجي', $last, ($en ? 'My last results in Game Legend Manager:' : 'آخر نتائجي في المدرب الأسطورة:')."\n".$last);
            }
            foreach (Reads::clubs($user->id)->unique('league_id')->take(5) as $c) {
                $season = Reads::season((int) $c->league_id);
                if ($season) {
                    $table = LeagueGroups::tableText($season, $en, 10);
                    $out[] = $article("table:{$c->league_id}", ($en ? 'Table: ' : 'ترتيب ').$c->league_name, $c->name, "{$c->league_name}\n{$table}");
                }
            }
        }
        $out[] = $article('invite', $en ? 'Invite to the game' : 'ادعُ صديقاً إلى اللعبة', $en ? 'A football manager game with your friends' : 'لعبة مدرب كرة قدم مع أصحابك',
            $en ? "Coach your club against your friends in Game Legend Manager: live matches, a market and private leagues.\n{$invite}"
                : "درّب ناديك ضد أصحابك في لعبة المدرب الأسطورة: مباريات حية وسوق ودوريات خاصة.\n{$invite}");

        return $out;
    }

    /** Each club's last result, a line each. */
    private static function last(int $userId, bool $en): ?string
    {
        $lines = [];
        foreach (Reads::clubs($userId) as $c) {
            $f = DB::table('fixtures')->where('status', 'finished')->where('is_bye', false)
                ->where(fn ($q) => $q->where('home_id', $c->id)->orWhere('away_id', $c->id))->orderByDesc('scheduled_at')->first();
            if ($f) {
                $names = DB::table('clubs')->whereIn('id', [$f->home_id, $f->away_id])->pluck('name', 'id');
                $lines[] = "{$names[$f->home_id]} {$f->home_goals} - {$f->away_goals} {$names[$f->away_id]}";
            }
        }

        return $lines ? implode("\n", $lines) : null;
    }
}
