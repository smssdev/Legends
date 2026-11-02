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
        $url = self::url($notifiable);
        if (($notifiable->locale ?? app()->getLocale()) === 'en') {
            return ActionMail::make(true, 'Confirm your email for Game Legend Manager', 'Welcome aboard', 'Confirm your email',
                'Hello '.$notifiable->name.',', ['One tap and your account is active: your league, your club and your coins are waiting.'],
                'Confirm my email', $url, 'The link is valid for 24 hours. Did not create a Game Legend Manager account? Ignore this email.');
        }

        return ActionMail::make(false, 'أكّد بريدك في Game Legend Manager', 'أهلاً بك في اللعبة', 'أكّد بريدك',
            'أهلاً '.$notifiable->name.'،', ['ضغطة واحدة ويُفعَّل حسابك: دوريك وناديك وكوينزك بانتظارك.'],
            'تأكيد البريد', $url, 'الرابط صالح 24 ساعة. لم تنشئ حساباً في Game Legend Manager؟ تجاهل هذه الرسالة.');
    }
}
