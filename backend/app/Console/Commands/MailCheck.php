<?php

namespace App\Console\Commands;

use App\Support\Mailer;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Mail;

/**
 * Sends one test email and says what happened: which way the emails go, and the exact error if they cannot [X8].
 * php artisan mail:check you@example.com
 */
class MailCheck extends Command
{
    protected $signature = 'mail:check {to : The address that should receive the test email}';

    protected $description = 'Send a test email and print the result';

    public function handle(): int
    {
        $to = (string) $this->argument('to');
        $this->line('الطريقة: '.Mailer::name().'، والمرسل: '.config('mail.from.address'));
        if (! Mailer::live()) {
            $this->warn('البريد يُكتب في السجل ولا يُرسل. ضع BREVO_API_KEY (أو RESEND_API_KEY، أو GMAIL_ADDRESS وGMAIL_APP_PASSWORD خارج Render) في المتغيرات.');
        }
        try {
            Mail::raw('رسالة تجربة من الأساطير: البريد يعمل.', fn ($m) => $m->to($to)->subject('تجربة البريد في الأساطير'));
        } catch (\Throwable $e) {
            $this->error('لم تُرسل: '.$e->getMessage());
            $this->line('الحل: '.Mailer::explain($e->getMessage()));

            return self::FAILURE;
        }
        $this->info(Mailer::live() ? "أُرسلت إلى {$to}. افحص البريد الوارد والرسائل غير المرغوبة." : 'كُتبت في storage/logs/laravel.log.');

        return self::SUCCESS;
    }
}
