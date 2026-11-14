<?php

namespace App\Messenger;

use App\Assistant\Assistant;
use App\Assistant\Guide;
use App\Assistant\Priorities;
use App\Assistant\Search;
use App\Auth\Username;
use App\League\NextFixture;
use App\League\Standings;
use App\Models\User;
use App\Wallet\Wallet;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * [Sprint 67] What the bot answers in a coach's private chat, the same on Telegram and WhatsApp: a few commands (by
 * word, in Arabic or English, or by number) read his clubs from the game; anything else is a question for the Assistant
 * Coach (the guide, and the AI within his day's smart answers). Not linked yet: the guide answers, and he is told how
 * to link. The bot reads; it changes nothing in the game but the link itself and its own silence.
 *
 * @phpstan-type Reply array{text: string, buttons: array<int, array{0: string, 1: string}>, keyboard?: array, more?: array}
 * [Sprint 68] keyboard: the buttons that stay under a Telegram chat; more: the messages sent after this one.
 */
class Replies
{
    public const COMMANDS = [
        'help' => ['help', 'menu', 'start', 'hi', 'hello', '0', 'مساعدة', 'القائمة', 'قائمة', 'مرحبا', 'مرحباً', 'السلام عليكم'],
        'next' => ['next', '1', 'مباراتي', 'مباراتي القادمة', 'المباراة القادمة'],
        'table' => ['table', '2', 'ترتيبي', 'الترتيب', 'الجدول'],
        'balance' => ['balance', '3', 'رصيدي', 'الرصيد'],
        'last' => ['last', '4', 'آخر نتيجة', 'اخر نتيجة', 'النتيجة'],
        'now' => ['now', '5', 'ماذا أفعل', 'ماذا افعل', 'ماذا أفعل الآن', 'ماذا افعل الان', 'ماذا أفعل الان'],
        'stop' => ['stop', 'mute', 'إيقاف', 'ايقاف', 'أوقف', 'اوقف'],
        'resume' => ['resume', 'unmute', 'تشغيل'],
        'unlink' => ['unlink', 'فك الربط', 'إلغاء الربط', 'الغاء الربط'],
        'channel' => ['channel', 'قناة', 'القناة'],
        // [Sprint 68] More readings, and «تحسين» (asked before it is done).
        'squad' => ['squad', '6', 'فريقي', 'my squad', 'الإصابات'],
        'training' => ['training', '7', 'التدريب', 'تدريبي'],
        'offers' => ['offers', '8', 'العروض', 'عروضي'],
        'fixtures' => ['fixtures', '9', 'مبارياتي', 'my matches', 'جدولي'],
        'scorers' => ['scorers', '10', 'الهدافون', 'الهدافين', 'top scorers'],
        'inbox' => ['inbox', '11', 'رسائلي', 'الرسائل', 'my messages'],
        'fix' => ['fix', 'improve', 'تحسين'],
        // [Sprint 69] The daily tasks and the round's predictions.
        'tasks' => ['tasks', '12', 'مهامي', 'المهام', 'my tasks'],
        'predict' => ['predict', '13', 'توقعاتي', 'توقع', 'التوقعات', 'predictions'],
        'cancel' => ['cancel', 'إلغاء', 'الغاء'],
    ];

    private const LABELS = [
        'next' => ['مباراتي القادمة', 'Next match'],
        'table' => ['ترتيبي', 'My table'],
        'balance' => ['رصيدي', 'Balance'],
        'last' => ['آخر نتيجة', 'Last result'],
        'now' => ['ماذا أفعل الآن؟', 'What now?'],
        'help' => ['القائمة', 'Menu'],
        'squad' => ['فريقي', 'My squad'],
        'training' => ['التدريب', 'Training'],
        'offers' => ['العروض', 'Offers'],
        'fixtures' => ['مبارياتي', 'My matches'],
        'scorers' => ['الهدافون', 'Top scorers'],
        'inbox' => ['رسائلي', 'My messages'],
        'fix' => ['تحسين', 'Improve'],
        'tasks' => ['مهامي', 'My tasks'],
        'predict' => ['توقعاتي', 'Predictions'],
    ];

    /** [Sprint 68] The buttons that stay under a Telegram chat (each sends its label). */
    private const KEYBOARD = [['next', 'table', 'now'], ['squad', 'offers', 'training'], ['fixtures', 'scorers', 'inbox'], ['tasks', 'predict', 'fix']];

    /** [Sprint 68] The menu Telegram shows by «/» (the commands' English words, which the bot reads too). */
    public const TELEGRAM_COMMANDS = [
        'next' => ['مباراتي القادمة', 'My next match'], 'table' => ['ترتيبي في الدوري', 'My place in the table'],
        'balance' => ['الكوينز وأموال النادي', 'Coins and club money'], 'last' => ['آخر نتيجة', 'My last result'],
        'now' => ['ماذا أفعل الآن؟', 'What should I do now?'], 'squad' => ['المصابون والموقوفون والمرهقون', 'Injured, suspended and tired'],
        'training' => ['التدريب الآن', 'Training now'], 'offers' => ['العروض التي تنتظر ردك', 'Offers waiting for you'],
        'fixtures' => ['مبارياتي القادمة', 'My coming matches'], 'scorers' => ['هدافو الدوري', 'The league\'s top scorers'],
        'inbox' => ['رسائلي غير المقروءة', 'My unread messages'], 'fix' => ['التشكيلة التلقائية الأفضل', 'The automatic best lineup'],
        'tasks' => ['مهام اليوم ومكافآتها', 'Today\'s tasks and their coins'], 'predict' => ['توقع مباريات الجولة', 'Predict the round\'s matches'],
        'daily' => ['الملخص اليومي: /daily 8 أو /daily off', 'Daily summary: /daily 8 or /daily off'],
        'live' => ['أحداث مبارياتي الحية: /live on أو off', 'My live matches: /live on or off'],
        'help' => ['القائمة', 'Menu'],
    ];

    /** The labels under the chat, in the coach's language. */
    public static function keyboard(string $l): array
    {
        return array_map(fn ($row) => array_map(fn ($k) => self::LABELS[$k][$l === 'en' ? 1 : 0], $row), self::KEYBOARD);
    }

    public function __construct(private Assistant $assistant) {}

    /** The command a message is, or null for a question. Arabic-Indic digits count, and "/next@bot" is "next". */
    public static function command(string $text): ?string
    {
        $t = self::normal($text);
        foreach (self::COMMANDS as $cmd => $words) {
            if (in_array($t, $words, true)) {
                return $cmd;
            }
        }

        return null;
    }

    /** "start CODE", "/start CODE", "ربط CODE", "link CODE", or the code alone: the code. */
    public static function linkCode(string $text): ?string
    {
        $parts = preg_split('/\s+/u', self::normal($text)) ?: [];
        $code = count($parts) === 2 && in_array($parts[0], ['start', 'link', 'ربط'], true) ? $parts[1] : (count($parts) === 1 ? $parts[0] : null);

        return $code !== null && Messenger::looksLikeCode($code) ? strtoupper($code) : null;
    }

    public static function normal(string $text): string
    {
        $t = trim(mb_strtolower(strtr($text, ['٠' => '0', '١' => '1', '٢' => '2', '٣' => '3', '٤' => '4', '٥' => '5', '٦' => '6', '٧' => '7', '٨' => '8', '٩' => '9'])));
        $t = preg_replace('/^\/([a-z_]+)@\w+/u', '$1', $t) ?? $t;
        $t = ltrim($t, '/');
        $t = rtrim($t, '?؟!. ');

        return preg_replace('/\s+/u', ' ', $t) ?? $t;
    }

    public static function language(?User $user, string $text): string
    {
        return $user ? ($user->locale === 'en' ? 'en' : 'ar') : (preg_match('/\p{Arabic}/u', $text) ? 'ar' : 'en');
    }

    /** The menu's buttons: all five on Telegram, the three WhatsApp can show. */
    public static function buttons(string $platform, string $l): array
    {
        $keys = $platform === 'whatsapp' ? ['next', 'table', 'now'] : ['next', 'table', 'balance', 'last', 'now'];

        return array_map(fn ($k) => [self::LABELS[$k][$l === 'en' ? 1 : 0], $k], $keys);
    }

    /** @return Reply */
    public function answer(string $platform, string $chatId, string $text): array
    {
        $userId = Messenger::userFor($platform, $chatId);
        $user = $userId ? User::find($userId) : null;
        $code = self::linkCode($text);
        if ($code !== null) {
            return $this->link($platform, $chatId, $code, $text);
        }
        $l = self::language($user, $text);
        $en = $l === 'en';
        // [Sprint 68] A tapped action (ask:… then do:…), and the two settings with their word.
        if ($user && preg_match('/^(ask|do):/', trim($text))) {
            return Actions::run($user->id, trim($text), $en);
        }
        // [Sprint 69] The match's quick orders and «جاهز», the training's choice, a task's coins, a prediction.
        if ($user && preg_match('/^(q|ready|pick|claim|pr):/', trim($text), $m)) {
            return match ($m[1]) {
                'q', 'ready' => ['text' => MatchControl::run($user->id, trim($text), $en), 'buttons' => []],
                'pick' => Actions::trainingChoices($user->id, trim($text), $en),
                'claim' => Plays::claim($user->id, trim($text), $en),
                'pr' => Plays::predict($user->id, trim($text), $en),
            };
        }
        if ($user && ($setting = $this->setting($user, $platform, $text, $en)) !== null) {
            return ['text' => $setting, 'buttons' => []];
        }
        $cmd = self::command($text);
        if ($cmd === 'cancel') {
            return ['text' => $en ? 'Nothing was done.' : 'لم يتغير شيء.', 'buttons' => []];
        }
        if ($user && $cmd === 'offers') {
            $all = Actions::offers($user->id, $en);

            return $all[0] + ['more' => array_slice($all, 1)];
        }
        if ($user && $cmd === 'fix') {
            return Actions::fixChoices($user->id, $en);
        }
        if ($user && $cmd === 'tasks') {
            return Plays::tasks($user->id, $en);
        }
        if ($user && $cmd === 'predict') {
            $all = Plays::predictions($user->id, $en);

            return $all[0] + ['more' => array_slice($all, 1)];
        }
        if ($user && $cmd === 'training') {
            return ['text' => Reads::training($user->id, $en), 'buttons' => Actions::trainingButtons($user->id, $en)];
        }
        if ($cmd === 'help' || ($cmd === null && trim($text) === '')) {
            return $this->menu($platform, $user, $l);
        }
        if ($cmd !== null && ! $user) {
            return ['text' => self::howToLink($l), 'buttons' => []];
        }
        if ($user) {
            $reply = match ($cmd) {
                'next' => $this->next($user, $en),
                'table' => $this->table($user, $en),
                'balance' => $this->balance($user, $en),
                'last' => $this->last($user, $en),
                'now' => $this->now($user, $l),
                'stop' => $this->silence($user, $platform, true, $en),
                'resume' => $this->silence($user, $platform, false, $en),
                'unlink' => Messenger::unlink($user->id, $platform) ? ($en ? 'Unlinked. Send a new code from your profile to link again.' : 'تم فك الربط. أرسل كوداً جديداً من ملفك لتربط مجدداً.') : '',
                'channel' => $this->channel($user, $en),
                'squad' => Reads::squad($user->id, $en),
                'training' => Reads::training($user->id, $en),
                'fixtures' => Reads::fixtures($user->id, $en),
                'scorers' => Reads::scorers($user->id, $en),
                'inbox' => Reads::inbox($user->id, $l, $en),
                default => null,
            };
            if ($reply !== null) {
                return ['text' => $reply, 'buttons' => $cmd === 'unlink' || $cmd === 'channel' ? [] : self::buttons($platform, $l)];
            }
        }

        return ['text' => $this->question($user, $text, $l), 'buttons' => self::buttons($platform, $l)];
    }

    private function link(string $platform, string $chatId, string $code, string $text): array
    {
        $userId = Messenger::claim($platform, $chatId, $code);
        $user = $userId ? User::find($userId) : null;
        $l = self::language($user, $text);
        if (! $user) {
            return ['text' => $l === 'en' ? 'This code is wrong or expired. Make a new one from your profile in the game.'
                : 'هذا الكود غير صحيح أو انتهت مدته. اطلب كوداً جديداً من ملفك في اللعبة.', 'buttons' => []];
        }
        $en = $l === 'en';
        $notice = $platform === 'whatsapp'
            ? ($en ? "\nOn WhatsApp your notifications reach you within 24 hours of your last message here: write to me once a day to keep them coming."
                : "\nفي واتساب تصلك إشعاراتك خلال 24 ساعة من آخر رسالة ترسلها هنا: راسلني مرة في اليوم لتبقى تصلك.")
            : '';

        return ['text' => ($en ? "Linked to {$user->name}. Your notifications reach you here now, and you can ask me about your clubs and the game." : "تم الربط بحساب {$user->name}. ستصلك إشعاراتك هنا، واسألني عن أنديتك وعن اللعبة.").$notice,
            'buttons' => self::buttons($platform, $l)];
    }

    private function menu(string $platform, ?User $user, string $l): array
    {
        $en = $l === 'en';
        if (! $user) {
            return ['text' => ($en ? "Hello! I am the bot of Game Legend Manager.\n" : "أهلاً! أنا بوت لعبة المدرب الأسطورة.\n").self::howToLink($l)
                .($en ? "\nUntil then, ask me anything about how the game is played." : "\nوحتى ذلك اسألني عن أي شيء في طريقة اللعب."), 'buttons' => []];
        }
        $lines = $en
            ? ['1 Next match', '2 My table', '3 Balance', '4 Last result', '5 What now?', '6 My squad', '7 Training', '8 Offers (accept or reject)',
                '9 My matches', '10 Top scorers', '11 My messages', '12 My tasks', '13 Predictions', 'improve: the automatic best lineup', 'Or ask me anything about the game.',
                'daily 8: a summary every morning at 8 (Cairo time); daily off', 'live on / live off: your live matches here', 'stop / resume: all notifications here.']
            : ['1 مباراتي القادمة', '2 ترتيبي', '3 رصيدي', '4 آخر نتيجة', '5 ماذا أفعل الآن؟', '6 فريقي', '7 التدريب', '8 العروض (قبول أو رفض)',
                '9 مبارياتي', '10 الهدافون', '11 رسائلي', '12 مهامي', '13 توقعاتي', '«تحسين»: التشكيلة التلقائية الأفضل', 'أو اسألني أي سؤال عن اللعبة.',
                '«ملخص 8»: ملخص كل صباح الساعة 8 بتوقيت القاهرة، و«ملخص إيقاف»', '«المباشر تشغيل» و«المباشر إيقاف»: أحداث مبارياتك الحية هنا', '«إيقاف» و«تشغيل»: كل الإشعارات هنا.'];
        $text = ($en ? "Hello {$user->name}! Send a number or a word:\n" : "أهلاً {$user->name}! أرسل رقماً أو كلمة:\n").implode("\n", $lines);

        // On Telegram the buttons stay under the chat; WhatsApp shows its three.
        return $platform === 'telegram' ? ['text' => $text, 'buttons' => [], 'keyboard' => self::keyboard($l)] : ['text' => $text, 'buttons' => self::buttons($platform, $l)];
    }

    public static function howToLink(string $l): string
    {
        $url = rtrim((string) config('app.frontend_url'), '/').'/profile';

        return $l === 'en'
            ? "To read your clubs, link your account: open your profile in the game ({$url}), tap «Link the bot», then send me the code."
            : "لأقرأ أنديتك اربط حسابك: افتح ملفك في اللعبة ({$url})، واضغط «اربط البوت»، ثم أرسل لي الكود.";
    }

    private static function clubs(int $userId)
    {
        return Reads::clubs($userId);
    }

    private static function noClub(bool $en): string
    {
        return Reads::noClub($en);
    }

    private function next(User $user, bool $en): string
    {
        $clubs = self::clubs($user->id);
        if ($clubs->isEmpty()) {
            return self::noClub($en);
        }
        $lines = [];
        foreach ($clubs as $c) {
            $f = NextFixture::of($c->id);
            if (! $f) {
                $lines[] = $en ? "{$c->name}: no match scheduled." : "{$c->name}: لا مباراة مجدولة.";

                continue;
            }
            $home = (int) $f->home_id === (int) $c->id;
            $other = DB::table('clubs')->where('id', $home ? $f->away_id : $f->home_id)->value('name');
            $when = $f->status === 'live' ? ($en ? 'being played now' : 'تُلعب الآن') : self::in(Carbon::parse($f->scheduled_at), $en);
            $lines[] = $en ? "{$c->name} vs {$other} (".($home ? 'home' : 'away')."): {$when}." : "{$c->name} ضد {$other} (".($home ? 'على أرضك' : 'خارج أرضك')."): {$when}.";
        }

        return implode("\n", $lines);
    }

    private static function in(Carbon $at, bool $en): string
    {
        return Reads::in($at, $en);
    }

    private static function season(int $leagueId): ?int
    {
        return Reads::season($leagueId);
    }

    private function table(User $user, bool $en): string
    {
        $clubs = self::clubs($user->id);
        if ($clubs->isEmpty()) {
            return self::noClub($en);
        }
        $lines = [];
        foreach ($clubs as $c) {
            $season = self::season((int) $c->league_id);
            $rows = $season ? Standings::table($season) : [];
            $i = array_search((int) $c->id, array_column($rows, 'id'), true);
            if ($i === false) {
                $lines[] = $en ? "{$c->league_name}: the season has not started." : "{$c->league_name}: لم يبدأ الموسم.";

                continue;
            }
            $r = $rows[$i];
            $lines[] = $en
                ? sprintf('%s, %s: %d of %d, %d points from %d matches (%d W, %d D, %d L).', $c->league_name, $c->name, $i + 1, count($rows), $r['pts'], $r['p'], $r['w'], $r['d'], $r['l'])
                : sprintf('%s، %s: المركز %d من %d، %d نقطة من %d مباراة (فوز %d، تعادل %d، خسارة %d).', $c->league_name, $c->name, $i + 1, count($rows), $r['pts'], $r['p'], $r['w'], $r['d'], $r['l']);
        }

        return implode("\n", $lines);
    }

    private function balance(User $user, bool $en): string
    {
        $lines = [($en ? 'Coins: ' : 'الكوينز: ').number_format(Wallet::balance($user->id))];
        foreach (self::clubs($user->id) as $c) {
            $lines[] = ($en ? "{$c->name} club money: " : "أموال {$c->name}: ").number_format((int) $c->balance);
        }

        return implode("\n", $lines);
    }

    private function last(User $user, bool $en): string
    {
        $clubs = self::clubs($user->id);
        if ($clubs->isEmpty()) {
            return self::noClub($en);
        }
        $lines = [];
        foreach ($clubs as $c) {
            $f = DB::table('fixtures')->where('status', 'finished')->where('is_bye', false)
                ->where(fn ($q) => $q->where('home_id', $c->id)->orWhere('away_id', $c->id))->orderByDesc('scheduled_at')->first();
            if (! $f) {
                $lines[] = $en ? "{$c->name}: no match played yet." : "{$c->name}: لم يلعب مباراة بعد.";

                continue;
            }
            $names = DB::table('clubs')->whereIn('id', [$f->home_id, $f->away_id])->pluck('name', 'id');
            $lines[] = "{$names[$f->home_id]} {$f->home_goals} - {$f->away_goals} {$names[$f->away_id]}";
        }

        return implode("\n", $lines);
    }

    private function now(User $user, string $l): string
    {
        $club = self::clubs($user->id)->first();
        $a = $club ? Priorities::answer('now', $user->id, (int) $club->league_id, $l) : null;

        return $a['answer'] ?? self::noClub($l === 'en');
    }

    private function silence(User $user, string $platform, bool $muted, bool $en): string
    {
        Messenger::mute($user->id, $platform, $muted);

        return $muted
            ? ($en ? 'Notifications stopped here. Send «resume» to have them again.' : 'أوقفت الإشعارات هنا. أرسل «تشغيل» لتعود.')
            : ($en ? 'Notifications are on here again.' : 'عادت الإشعارات هنا.');
    }

    /**
     * [Sprint 68] «daily 8» / «ملخص 8» (a summary every morning at that Cairo hour), «daily off» / «ملخص إيقاف»;
     * «live on|off» / «المباشر تشغيل|إيقاف» (his live matches here). Null when the text is neither.
     */
    private function setting(User $user, string $platform, string $text, bool $en): ?string
    {
        $parts = explode(' ', self::normal($text));
        $off = ['off', 'stop', 'إيقاف', 'ايقاف'];
        $on = ['on', 'تشغيل'];
        $link = DB::table('messenger_links')->where('user_id', $user->id)->where('platform', $platform);
        if (in_array($parts[0], ['daily', 'ملخص', 'الملخص'], true)) {
            $arg = $parts[1] ?? null;
            if ($arg !== null && in_array($arg, $off, true)) {
                $link->update(['daily_hour' => null]);

                return $en ? 'The daily summary is off.' : 'أوقفت الملخص اليومي.';
            }
            if ($arg !== null && preg_match('/^\d{1,2}$/', $arg) && (int) $arg <= 23) {
                $link->update(['daily_hour' => (int) $arg]);

                return $en ? "Your summary comes every day at {$arg}:00, Cairo time." : "يصلك ملخصك كل يوم الساعة {$arg}:00 بتوقيت القاهرة.";
            }
            $hour = $link->value('daily_hour');

            return ($hour === null ? ($en ? 'The daily summary is off.' : 'الملخص اليومي متوقف.') : ($en ? "Your summary comes at {$hour}:00, Cairo time." : "ملخصك الساعة {$hour}:00 بتوقيت القاهرة."))
                ."\n".($en ? 'Send «daily 8» for 8 in the morning (0 to 23), or «daily off».' : 'أرسل «ملخص 8» للساعة 8 صباحاً (من 0 إلى 23)، أو «ملخص إيقاف».');
        }
        if (in_array($parts[0], ['live', 'المباشر'], true) && ! (isset($parts[1]) && in_array($parts[1], [...$on, ...$off], true))) {
            return ($link->value('live') ? ($en ? 'Your live matches reach you here.' : 'أحداث مبارياتك الحية تصلك هنا.') : ($en ? 'Your live matches are off here.' : 'أحداث مبارياتك الحية متوقفة هنا.'))
                ."\n".($en ? 'Send «live on» or «live off».' : 'أرسل «المباشر تشغيل» أو «المباشر إيقاف».');
        }
        if (in_array($parts[0], ['live', 'المباشر'], true)) {
            $link->update(['live' => in_array($parts[1], $on, true)]);

            return in_array($parts[1], $on, true)
                ? ($en ? 'Your live matches reach you here: goals, red cards, half-time and the result.' : 'تصلك أحداث مبارياتك الحية هنا: الأهداف والطرد ونهاية الشوط والنتيجة.')
                : ($en ? 'Your live matches no longer reach you here.' : 'أوقفت أحداث مبارياتك الحية هنا.');
        }

        return null;
    }

    /** [Sprint 67] For the developers' official accounts: the last channel posts, to copy into the WhatsApp channel. */
    private function channel(User $user, bool $en): ?string
    {
        if (! Username::official($user->username)) {
            return null;
        }
        $posts = Messenger::posts();

        return $posts ? implode("\n\n———\n\n", $posts) : ($en ? 'Nothing posted to the channel yet.' : 'لم يُنشر في القناة شيء بعد.');
    }

    private function question(?User $user, string $text, string $l): string
    {
        $text = mb_substr(trim($text), 0, (int) config('game.manager_bot.question_max'));
        if ($user) {
            $league = self::clubs($user->id)->first()?->league_id;

            return $this->assistant->ask($user, $text, [], $league ? (int) $league : null, 'home', null, $l)['answer'];
        }
        $found = Search::find($text, Guide::topics($l));

        return $found['topic'] ? $found['topic']['a']."\n\n".self::howToLink($l)
            : ($l === 'en' ? 'I did not find that in the game\'s guide. Try other words.' : 'لم أجد هذا في دليل اللعبة. جرّب كلمات أخرى.')."\n\n".self::howToLink($l);
    }
}
