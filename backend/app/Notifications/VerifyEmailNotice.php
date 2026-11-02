<?php

namespace App\Notifications;

use App\Support\GameClock;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\URL;

/** The email confirmation, in Arabic or the account's English [PLAN 2.17, UP2]. The link is signed and lasts 24 hours. */
class VerifyEmailNotice extends Notification
{
    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public static function url(object $notifiable): string
    {
        return URL::temporarySignedRoute('verification.verify', GameClock::now()->addDay(), [
            'id' => $notifiable->getKey(),
            'hash' => sha1($notifiable->getEmailForVerification()),
        ]);
    }

    public function toMail(object $notifiable): MailMessage
    {
        if (($notifiable->locale ?? app()->getLocale()) === 'en') {
            return (new MailMessage)
                ->subject('Confirm your email in Game Legend Manager')
                ->action('Confirm email', self::url($notifiable))
                ->view('mail.action', ['en' => true, 'title' => 'Confirm your email in Game Legend Manager', 'greeting' => 'Hello '.$notifiable->name,
                    'lines' => ['Press the button to confirm your email and activate your account.'], 'button' => 'Confirm email', 'url' => self::url($notifiable), 'after' => 'The link is valid for 24 hours. If you did not create a Game Legend Manager account, ignore this message.']);
        }

        return (new MailMessage)
            ->subject('أكّد بريدك في لعبة المدرب الأسطورة')
            ->action('تأكيد البريد', self::url($notifiable))
            ->view('mail.action', ['en' => false, 'title' => 'أكّد بريدك في لعبة المدرب الأسطورة', 'greeting' => 'أهلاً '.$notifiable->name,
                'lines' => ['اضغط الزر لتأكيد بريدك وتفعيل حسابك.'], 'button' => 'تأكيد البريد', 'url' => self::url($notifiable), 'after' => 'الرابط صالح 24 ساعة. إن لم تنشئ حساباً في لعبة المدرب الأسطورة فتجاهل هذه الرسالة.']);
    }
}
