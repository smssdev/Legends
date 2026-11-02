<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * [Sprint 39 M2] A game event by email in the game's frame (resources/views/mail/game-update.blade.php): a match's
 * summary with its score board, or any alert (a player sold, an offer, a match about to start). Built from plain
 * values, so any part of the game can send one; App\Messages\Inbox stays the place every event is written first.
 */
class GameUpdateNotice extends Notification implements ShouldQueue
{
    use Queueable;

    /**
     * @param  array{0: string, 1: int, 2: int, 3: string}|null  $score  home, its goals, away's goals, away
     * @param  list<array{0: string, 1: string}>  $facts  label and value rows
     */
    public function __construct(
        public string $subject,
        public string $kind,
        public string $title,
        public string $lead,
        public string $button,
        public string $path = '/',
        public ?array $score = null,
        public array $facts = [],
        public bool $en = false,
        public string $why = '',
    ) {}

    /** A finished match: the score, the scorers and the way to its report. */
    public static function matchSummary(bool $en, string $home, int $homeGoals, int $awayGoals, string $away, string $competition, array $scorers, int $matchId): self
    {
        $line = "{$home} {$homeGoals} – {$awayGoals} {$away}";

        return new self(
            subject: $en ? "Full time: {$line}" : "انتهت المباراة: {$line}",
            kind: $en ? 'Match summary' : 'ملخص المباراة',
            title: $en ? 'Full time' : 'انتهت المباراة',
            lead: $en ? "Your match in {$competition} is over. Here is how it went." : "انتهت مباراتك في {$competition}. هذا ما حدث فيها.",
            button: $en ? 'Open the match report' : 'افتح تقرير المباراة',
            path: "/live/{$matchId}/report",
            score: [$home, $homeGoals, $awayGoals, $away],
            facts: array_map(fn ($s) => [$en ? 'Goal' : 'هدف', $s], $scorers),
            en: $en,
            why: $en ? 'You get this because you turned on match summaries by email (My account, then Notifications).' : 'وصلتك لأنك فعّلت ملخص المباريات بالبريد. تُوقفه من «حسابي» ← الإشعارات.',
        );
    }

    /** Any event of the game (a sale, an offer, a match starting soon): its title, its line and where it leads. */
    public static function alert(bool $en, string $title, string $body, string $path, array $facts = []): self
    {
        return new self(
            subject: $title,
            kind: $en ? 'Game alert' : 'تنبيه من اللعبة',
            title: $title,
            lead: $body,
            button: $en ? 'Open the game' : 'افتح اللعبة',
            path: $path,
            facts: $facts,
            en: $en,
            why: $en ? 'You get this because of your account in the game.' : 'وصلتك هذه الرسالة بسبب حسابك في اللعبة.',
        );
    }

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $url = rtrim((string) config('app.url'), '/').$this->path;

        $site = rtrim((string) config('app.url'), '/');

        return (new MailMessage)
            ->subject($this->subject)
            // [X80] One tap to stop these in the mail app (Gmail shows it beside the sender).
            ->withSymfonyMessage(fn ($m) => $m->getHeaders()->addTextHeader('List-Unsubscribe', '<mailto:'.config('mail.from.address').'?subject=unsubscribe>, <'.$site.'/profile>'))
            ->action($this->button, $url)
            ->view(['html' => 'mail.game-update', 'text' => 'mail.text'], ['en' => $this->en, 'kind' => $this->kind, 'title' => $this->title, 'lead' => $this->lead,
                'score' => $this->score, 'facts' => $this->facts, 'button' => $this->button, 'url' => $url, 'why' => $this->why,
                'heading' => $this->score ? "{$this->score[0]} {$this->score[1]} - {$this->score[2]} {$this->score[3]}" : $this->title,
                'lines' => array_merge([$this->lead], array_map(fn ($f) => "{$f[0]}: {$f[1]}", $this->facts))]);
    }
}
