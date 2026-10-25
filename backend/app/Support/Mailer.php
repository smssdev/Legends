<?php

namespace App\Support;

use Illuminate\Support\Facades\Log;

/**
 * Whether the emails really leave the server, and sending one without breaking the request around it [X8].
 * Render's free plan blocks SMTP, so there the emails go through Brevo or Resend over HTTPS (App\Mail\ApiTransport).
 */
class Mailer
{
    /** log and array keep the emails on the server: nobody receives them. */
    public static function live(): bool
    {
        return ! in_array(config('mail.default'), ['log', 'array'], true);
    }

    public static function name(): string
    {
        return (string) config('mail.default');
    }

    /** Runs the send; a failure is logged with its reason and answered false, never thrown. */
    public static function attempt(callable $send, string $what): bool
    {
        try {
            $send();

            return true;
        } catch (\Throwable $e) {
            Log::error("Email not sent ({$what}) through ".self::name().': '.$e->getMessage());

            return false;
        }
    }
}
