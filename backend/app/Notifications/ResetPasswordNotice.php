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
        $url = $this->url($notifiable);
        if (($notifiable->locale ?? app()->getLocale()) === 'en') {
            return ActionMail::make(true, 'Reset your Game Legend Manager password', 'Account security', 'Choose a new password',
                'Hello '.$notifiable->name.',', ['We received a request to change your account\'s password. Tap the button to choose a new one.'],
                'Choose a new password', $url, "The link is valid for {$minutes} minutes and works once. Did not ask for this? Ignore this email: your password stays as it is.");
        }

        return ActionMail::make(false, 'استعادة كلمة المرور في Game Legend Manager', 'أمان الحساب', 'اختر كلمة مرور جديدة',
            'أهلاً '.$notifiable->name.'،', ['وصلنا طلب لتغيير كلمة مرور حسابك. اضغط الزر لتختار كلمة جديدة.'],
            'اختر كلمة مرور جديدة', $url, "الرابط صالح {$minutes} دقيقة ولمرة واحدة. لم تطلب هذا؟ تجاهل الرسالة، وكلمة مرورك كما هي.");
    }
}
