<?php

namespace App\Notifications;

use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/** The password reset, in Arabic [PLAN 2.17]. The link opens the web app's reset screen. */
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

        return (new MailMessage)
            ->subject('استعادة كلمة المرور في الأساطير')
            ->greeting('أهلاً '.$notifiable->name)
            ->line('وصلنا طلب لتغيير كلمة المرور لحسابك.')
            ->action('اختر كلمة مرور جديدة', $this->url($notifiable))
            ->line("الرابط صالح $minutes دقيقة. إن لم تطلب هذا فتجاهل الرسالة، وكلمة مرورك كما هي.")
            ->salutation('فريق الأساطير');
    }
}
