<?php

namespace App\Orders\Infrastructure;

use App\Orders\Ports\Mailer;
use Illuminate\Support\Facades\Log;

final class LogMailer implements Mailer
{
    public function send(string $to, string $subject): void
    {
        Log::info("mail to $to: $subject");
    }
}
