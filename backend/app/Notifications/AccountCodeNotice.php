<?php

namespace App\Notifications;

use App\Models\User;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * The account's verification code by email [Sprint 21 E2.4]: a designed message in the game's colours, Arabic
 * (right to left) or the account's English, with the six digits large, how long they last, and a word on safety.
 */
class AccountCodeNotice extends Notification
{
    public function __construct(private User $user, private string $code, private int $minutes) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $en = ($this->user->locale ?? app()->getLocale()) === 'en';

        return (new MailMessage)
            ->subject($en ? "{$this->code} is your Game Legend Manager code" : "{$this->code} هو كود توثيق حسابك في Game Legend Manager")
            ->view(['html' => 'mail.account-code', 'text' => 'mail.text'], ['en' => $en, 'name' => $this->user->name, 'username' => $this->user->username,
                'accountNo' => $this->user->account_no, 'code' => $this->code, 'minutes' => $this->minutes,
                'url' => $url = rtrim((string) config('app.url'), '/').'/profile', 'button' => $en ? 'Open my account' : 'افتح حسابي',
                'heading' => $en ? "Your code: {$this->code}" : "كودك: {$this->code}",
                'lines' => [$en ? "Valid for {$this->minutes} minutes, and only once. Never share it: the game's team will never ask you for it." : "صالح {$this->minutes} دقيقة ولمرة واحدة. لا تشاركه مع أحد: فريق اللعبة لن يطلبه منك أبداً."]]);
    }
}
