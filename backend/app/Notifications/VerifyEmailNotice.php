<?php

namespace App\Notifications;

use App\Support\GameClock;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;
use Illuminate\Support\Facades\URL;

/** The email confirmation, in Arabic [PLAN 2.17]. The link is signed and lasts 24 hours. */
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
        return (new MailMessage)
            ->subject('أكّد بريدك في GLM')
            ->greeting('أهلاً '.$notifiable->name)
            ->line('اضغط الزر لتأكيد بريدك وتفعيل حسابك.')
            ->action('تأكيد البريد', self::url($notifiable))
            ->line('الرابط صالح 24 ساعة. إن لم تنشئ حساباً في GLM فتجاهل هذه الرسالة.')
            ->salutation('فريق GLM');
    }
}
