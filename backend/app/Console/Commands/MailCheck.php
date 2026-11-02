<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Notifications\AccountCodeNotice;
use App\Notifications\GameUpdateNotice;
use App\Notifications\StoreDealNotice;
use App\Support\Mailer;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Notification;

/**
 * Sends one test email and says what happened: which way the emails go, and the exact error if they cannot [X8].
 * php artisan mail:check you@example.com
 */
class MailCheck extends Command
{
    protected $signature = 'mail:check {to : The address that should receive the test email} {--sample= : Send a designed email instead: code, match, alert or deal [Sprint 39]} {--en : The sample in English}';

    protected $description = 'Send a test email and print the result';

    public function handle(): int
    {
        $to = (string) $this->argument('to');
        $this->line('الطريقة: '.Mailer::name().'، والمرسل: '.config('mail.from.address'));
        if (! Mailer::live()) {
            $this->warn('البريد يُكتب في السجل ولا يُرسل. ضع BREVO_API_KEY (أو RESEND_API_KEY، أو GMAIL_ADDRESS وGMAIL_APP_PASSWORD خارج Render) في المتغيرات.');
        }
        if ($sample = $this->option('sample')) {
            return $this->sample((string) $sample, $to);
        }
        try {
            // [X80] The test in the game's own design, so what arrives is what the coaches get.
            Notification::route('mail', $to)->notifyNow(GameUpdateNotice::alert(false, 'البريد يعمل ✓',
                'هذه رسالة تجربة من Game Legend Manager: البريد يخرج من السيرفر ويصل بتصميم اللعبة.', '/', [['المرسل', (string) config('mail.from.address')], ['الطريقة', Mailer::name()]]));
        } catch (\Throwable $e) {
            $this->error('لم تُرسل: '.$e->getMessage());
            $this->line('الحل: '.Mailer::explain($e->getMessage()));

            return self::FAILURE;
        }
        $this->info(Mailer::live() ? "أُرسلت إلى {$to}. افحص البريد الوارد والرسائل غير المرغوبة." : 'كُتبت في storage/logs/laravel.log.');

        return self::SUCCESS;
    }

    /** [Sprint 39 M1] One of the game's designed emails with sample values, to see it in a real inbox. */
    private function sample(string $kind, string $to): int
    {
        $en = (bool) $this->option('en');
        $notice = match ($kind) {
            'match' => GameUpdateNotice::matchSummary($en, 'Al Ahly', 2, 1, 'Zamalek', $en ? 'the league' : 'الدوري', ["Salah 23'", "Marmoush 67'"], 1),
            'alert' => GameUpdateNotice::alert($en, $en ? 'Your player was sold' : 'بِيع لاعبك', $en ? 'A club outside the league bought him at his price.' : 'اشتراه نادٍ من خارج الدوري بسعره.', '/market', [[$en ? 'Price' : 'السعر', '2,400,000']]),
            'deal' => new StoreDealNotice($en ? 'Coins offer: 30% more' : 'عرض الكوينز: 30% زيادة', $en ? 'Top up with a bonus' : 'اشحن بزيادة', $en ? 'This weekend only.' : 'نهاية هذا الأسبوع فقط.',
                [['name' => '500', 'gives' => $en ? '500 coins' : '500 كوينز', 'price' => '$4.99', 'was' => '$6.99', 'badge' => '-30%'], ['name' => '1200', 'gives' => $en ? '1200 coins' : '1200 كوينز', 'price' => '$9.99']], $en ? 'Sunday' : 'الأحد', en: $en),
            'code' => null,
            default => false,
        };
        if ($notice === false) {
            $this->error('النماذج: code أو match أو alert أو deal.');

            return self::FAILURE;
        }
        if ($notice === null) {
            $user = new User(['name' => 'Coach', 'username' => 'coach', 'locale' => $en ? 'en' : 'ar']);
            $notice = new AccountCodeNotice($user, '123456', 15);
        }
        $sent = Mailer::attempt(fn () => Notification::route('mail', $to)->notifyNow($notice), "sample {$kind}");
        $sent ? $this->info("أُرسل النموذج {$kind} إلى {$to}.") : $this->error('لم يُرسل: '.Mailer::$lastError);

        return $sent ? self::SUCCESS : self::FAILURE;
    }
}
