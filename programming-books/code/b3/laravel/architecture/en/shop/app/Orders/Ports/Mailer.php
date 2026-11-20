<?php

namespace App\Orders\Ports;

interface Mailer
{
    public function send(string $to, string $subject): void;
}
