<?php

namespace App\Notifications;

use Illuminate\Notifications\Messages\MailMessage;

/**
 * [X80] An email with one thing to do (confirm the email, choose a new password), in the game's frame
 * (resources/views/mail/action.blade.php) with its plain text twin (mail/text.blade.php).
 */
final class ActionMail
{
    /** @param  list<string>  $lines */
    public static function make(bool $en, string $subject, string $eyebrow, string $title, string $greeting, array $lines, string $button, string $url, string $after): MailMessage
    {
        return (new MailMessage)
            ->subject($subject)
            ->action($button, $url)
            ->view(['html' => 'mail.action', 'text' => 'mail.text'], ['en' => $en, 'eyebrow' => $eyebrow, 'title' => $title, 'greeting' => $greeting,
                'lines' => $lines, 'button' => $button, 'url' => $url, 'after' => $after,
                'heading' => $title, 'textLines' => [$greeting, ...$lines, $after]]);
    }
}
