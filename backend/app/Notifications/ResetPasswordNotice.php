<?php

namespace App\Notifications;

use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/** The password reset, in Arabic or the account's English [PLAN 2.17, UP2]. The link opens the web app's reset screen. */
class ResetPasswordNotice extends Notification
{
    public function __construct(#[\SensitiveParameter] public string $token) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function url(object $notifiable): string
    {
        return rtrim(config('app.frontend_url'), '/').'/reset-password?'.http_build_query([
            'token' => $this->token,
            'email' => $notifiable->getEmailForPasswordReset(),
        ]);
    }

    public function toMail(object $notifiable): MailMessage
    {
        $minutes = config('auth.passwords.users.expire');
        if (($notifiable->locale ?? app()->getLocale()) === 'en') {
            return (new MailMessage)
                ->subject('Recover your Game Legend Manager password')
                ->action('Choose a new password', $this->url($notifiable))
                ->view('mail.action', ['en' => true, 'title' => 'Recover your Game Legend Manager password', 'greeting' => 'Hello '.$notifiable->name,
                    'lines' => ['We received a request to change your account\'s password.'], 'button' => 'Choose a new password', 'url' => $this->url($notifiable), 'after' => "The link is valid for $minutes minutes. If you did not ask for this, ignore the message; your password stays as it is."]);
        }

        return (new MailMessage)
            ->subject('استعادة كلمة المرور في لعبة المدرب الأسطورة')
            ->action('اختر كلمة مرور جديدة', $this->url($notifiable))
            ->view('mail.action', ['en' => false, 'title' => 'استعادة كلمة المرور في لعبة المدرب الأسطورة', 'greeting' => 'أهلاً '.$notifiable->name,
                'lines' => ['وصلنا طلب لتغيير كلمة المرور لحسابك.'], 'button' => 'اختر كلمة مرور جديدة', 'url' => $this->url($notifiable), 'after' => "الرابط صالح $minutes دقيقة. إن لم تطلب هذا فتجاهل الرسالة، وكلمة مرورك كما هي."]);
    }
}
