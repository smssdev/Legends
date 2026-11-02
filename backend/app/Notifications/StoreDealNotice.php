<?php

namespace App\Notifications;

use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * [Sprint 39 M3] The store's deals and top-up offers by email (resources/views/mail/store-deal.blade.php), ready for
 * when the store opens: nothing sends it yet. Only to coaches who asked for offers (README section 11: the owner
 * decides the store and who receives its emails), and a new kind of email goes into the privacy policy first.
 */
class StoreDealNotice extends Notification
{
    /**
     * @param  list<array{name: string, gives: string, price: string, was?: string|null, badge?: string|null}>  $packs  at most four
     */
    public function __construct(
        public string $subject,
        public string $title,
        public string $lead,
        public array $packs,
        public ?string $until = null,
        public string $path = '/wallet',
        public bool $en = false,
    ) {
        abort_if($packs === [] || count($packs) > 4, 500, 'العرض من باقة إلى أربع.');
    }

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $url = rtrim((string) config('app.url'), '/').$this->path;
        $button = $this->en ? 'See the offers' : 'شاهد العروض';

        return (new MailMessage)
            ->subject($this->subject)
            ->action($button, $url)
            ->view('mail.store-deal', ['en' => $this->en, 'title' => $this->title, 'lead' => $this->lead, 'packs' => $this->packs,
                'until' => $this->until, 'button' => $button, 'url' => $url]);
    }
}
