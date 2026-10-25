<?php

namespace App\Mail;

use Illuminate\Support\Facades\Http;
use Symfony\Component\Mailer\Exception\TransportException;
use Symfony\Component\Mailer\SentMessage;
use Symfony\Component\Mailer\Transport\AbstractTransport;
use Symfony\Component\Mime\Address;
use Symfony\Component\Mime\MessageConverter;

/**
 * Emails over HTTPS, for hosts that block the SMTP ports (Render's free plan blocks 25, 465 and 587) [X8].
 * Two free services: Brevo (300 emails a day; the sender is one verified address, a Gmail one works)
 * and Resend (3,000 a month; needs a domain of our own to write to anyone). No package: one POST each.
 */
class ApiTransport extends AbstractTransport
{
    public function __construct(private readonly string $service, private readonly string $key)
    {
        parent::__construct();
    }

    protected function doSend(SentMessage $message): void
    {
        $email = MessageConverter::toEmail($message->getOriginalMessage());
        $from = $email->getFrom()[0] ?? throw new TransportException('No sender address.');
        $to = $message->getEnvelope()->getRecipients();

        $response = $this->service === 'brevo'
            ? Http::timeout(15)->withHeaders(['api-key' => $this->key])->acceptJson()->post('https://api.brevo.com/v3/smtp/email', array_filter([
                'sender' => array_filter(['email' => $from->getAddress(), 'name' => $from->getName() ?: null]),
                'to' => array_map(fn (Address $a) => array_filter(['email' => $a->getAddress(), 'name' => $a->getName() ?: null]), $to),
                'subject' => (string) $email->getSubject(),
                'htmlContent' => $email->getHtmlBody() ? (string) $email->getHtmlBody() : null,
                'textContent' => $email->getTextBody() ? (string) $email->getTextBody() : null,
            ]))
            : Http::timeout(15)->withToken($this->key)->acceptJson()->post('https://api.resend.com/emails', array_filter([
                'from' => $from->toString(),
                'to' => array_map(fn (Address $a) => $a->getAddress(), $to),
                'subject' => (string) $email->getSubject(),
                'html' => $email->getHtmlBody() ? (string) $email->getHtmlBody() : null,
                'text' => $email->getTextBody() ? (string) $email->getTextBody() : null,
            ]));

        if ($response->failed()) {
            throw new TransportException("{$this->service} refused the email ({$response->status()}): ".substr($response->body(), 0, 500));
        }
    }

    public function __toString(): string
    {
        return $this->service.'+api';
    }
}
