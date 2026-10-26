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
                ->greeting('Hello '.$notifiable->name)
                ->line('Press the button to confirm your email and activate your account.')
                ->action('Confirm email', self::url($notifiable))
                ->line('The link is valid for 24 hours. If you did not create a Game Legend Manager account, ignore this message.')
                ->salutation('The Game Legend Manager team');
        }

        return (new MailMessage)
            ->subject('أكّد بريدك في لعبة المدرب الأسطورة')
            ->greeting('أهلاً '.$notifiable->name)
            ->line('اضغط الزر لتأكيد بريدك وتفعيل حسابك.')
            ->action('تأكيد البريد', self::url($notifiable))
            ->line('الرابط صالح 24 ساعة. إن لم تنشئ حساباً في لعبة المدرب الأسطورة فتجاهل هذه الرسالة.')
            ->salutation('فريق لعبة المدرب الأسطورة');
    }
}
