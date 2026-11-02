<?php

namespace App\Messages;

/**
 * A message's words in English [UP2], case for case with MessageText (the Arabic), from the same type and payload.
 * The payload's own words (names, a reason, an announcement) stay as they were written.
 */
class MessageTextEn
{
    private const STRICTNESS = ['very_lenient' => 'very lenient', 'lenient' => 'lenient', 'medium' => 'medium', 'strict' => 'strict', 'very_strict' => 'very strict'];

    private const SECTION = ['seats' => 'Tickets and seats', 'pitch' => 'The pitch', 'training' => 'Training facility'];

    private const RESULT = ['win' => 'You won', 'draw' => 'You drew', 'loss' => 'You lost'];

    public const STAFF = ['att_coach' => 'attack coach', 'mid_coach' => 'midfield coach', 'def_coach' => 'defence coach', 'keeper_coach' => 'goalkeeping coach',
        'physio' => 'physio', 'doctor' => 'club doctor', 'lawyer' => 'club lawyer', 'mental_coach' => 'sports psychologist'];

    private static function offer(string $type, array $p): string
    {
        $wants = implode(' and ', $p['in'] ?? []);
        $gives = array_filter([($p['money'] ?? 0) > 0 ? number_format($p['money']) : null, ($p['out'] ?? []) ? implode(' and ', $p['out']) : null]);
        $deal = sprintf('%s for %s in exchange for %s', $p['from'] ?? '', $wants, $gives ? implode(' and ', $gives) : 'nothing');

        return match ($type) {
            'offer_received' => "An offer from {$deal}.",
            'offer_countered' => "{$p['from']} countered: {$deal}.",
            'offer_accepted' => "{$p['to']} accepted your offer for {$wants}, and the deal is done.",
            'offer_rejected' => "{$p['to']} declined your offer for {$wants}.",
            'offer_cancelled' => "The offer {$deal} was cancelled: one of its players moved or the offer was withdrawn.",
            default => "The offer {$deal} expired without a reply.",
        };
    }

    /** @return array{title: string, body: string, link: ?string} */
    public static function render(string $type, array $p): array
    {
        $league = $p['league'] ?? '';
        $leagueLink = isset($p['league_id']) ? "/leagues/{$p['league_id']}" : '/leagues';

        return match ($type) {
            'referee' => [
                'title' => 'Your next match\'s referee',
                'body' => sprintf('Your match against %s in %s has a %s referee. %s', $p['opponent'] ?? '', $league, self::STRICTNESS[$p['strictness'] ?? 'medium'] ?? '',
                    in_array($p['strictness'] ?? '', ['strict', 'very_strict'], true) ? 'A strict referee shows more cards, so review your tackling before the lock.' : 'Review your lineup and tactics before the lock.'),
                'link' => '/match',
            ],
            'absence_warning' => [
                'title' => 'We have not seen you for a while',
                'body' => sprintf('You have not visited %s for %d hours. If you stay away for %d days your team goes back to the computer. Visit the league or take a holiday.',
                    $league, (int) config('game.league.absence_warning_hours'), (int) config('game.league.absence_days')),
                'link' => $leagueLink,
            ],
            'left_absent' => [
                'title' => 'You left the league for absence',
                'body' => sprintf('You were away from %s for %d days, so your team %s went back to the computer. You can return to this league next season.',
                    $league, (int) config('game.league.absence_days'), $p['club'] ?? ''),
                'link' => '/leagues',
            ],
            'kicked' => [
                'title' => 'You were removed from the league',
                'body' => sprintf('The creator of %s removed you, for this reason: «%s». Your team %s went back to the computer.', $league, $p['reason'] ?? '', $p['club'] ?? ''),
                'link' => '/leagues',
            ],
            'join_request' => [
                'title' => 'A new join request',
                'body' => sprintf('%s asks to join %s.', $p['user'] ?? '', $league),
                'link' => $leagueLink,
            ],
            'join_approved' => [
                'title' => 'Your request was approved',
                'body' => sprintf('The creator of %s approved your request. Pick your team now.', $league),
                'link' => isset($p['league_id']) ? "/leagues/{$p['league_id']}/pick" : '/leagues',
            ],
            'join_rejected' => [
                'title' => 'Your request was not approved',
                'body' => sprintf('The creator of %s declined your join request.', $league),
                'link' => '/leagues',
            ],
            'match_report' => [
                'title' => 'Your match report is ready',
                'body' => sprintf('%s against %s %s. Read why in the report.', self::RESULT[$p['result'] ?? 'draw'] ?? '', $p['opponent'] ?? '', $p['score'] ?? ''),
                'link' => isset($p['match_id']) ? "/live/{$p['match_id']}/report" : null,
            ],
            'in_debt' => [
                'title' => 'Your club\'s balance is below zero',
                'body' => sprintf('%s\'s balance is %s after wages, and you cannot spend until it is positive again. If it stays negative for %d rounds in a row, the most expensive player is sold automatically.',
                    $p['club'] ?? '', number_format((int) ($p['balance'] ?? 0)), (int) ($p['rounds'] ?? 3)),
                'link' => '/finance',
            ],
            'forced_sale' => [
                'title' => 'A forced sale for debt',
                'body' => sprintf('%s\'s balance stayed negative for %d rounds, so this was sold to the pool: %s.', $p['club'] ?? '', (int) ($p['rounds'] ?? 3), implode(', ', $p['players'] ?? [])),
                'link' => '/finance',
            ],
            'offer_received', 'offer_countered', 'offer_accepted', 'offer_rejected', 'offer_cancelled', 'offer_expired' => [
                'title' => ['offer_received' => 'A new offer', 'offer_countered' => 'A counter-offer', 'offer_accepted' => 'Your offer was accepted',
                    'offer_rejected' => 'Your offer was declined', 'offer_cancelled' => 'An offer was cancelled', 'offer_expired' => 'An offer expired'][$type],
                'body' => self::offer($type, $p),
                'link' => '/market?tab=offers',
            ],
            'scout_report' => [
                'title' => 'The scout\'s report is ready',
                'body' => ($p['players'] ?? []) ? 'The scout found you: '.implode(', ', $p['players']).'. Buy them before the pool renews.'
                    : 'The scout found no player with these criteria, so the full amount was refunded.',
                'link' => '/scout',
            ],
            'training_done' => [
                'title' => 'Training complete: '.($p['player'] ?? ''),
                'body' => sprintf('%s improved to %d, and their slot is free now: pick another player to train.', $p['player'] ?? '', (int) ($p['overall'] ?? 0)),
                'link' => '/training',
            ],
            'camp_back' => [
                'title' => 'The players are back from camp',
                'body' => implode(', ', array_map(fn ($x) => $x['gain'] ? "{$x['name']} +{$x['gain']}" : "{$x['name']} no gain", $p['players'] ?? [])).'. Those whose jump was not complete keep their progress.',
                'link' => '/training',
            ],
            'stadium_part' => [
                'title' => ($p['stage_done'] ?? false) ? 'A stadium stage is complete' : 'A stadium part is complete',
                'body' => sprintf('%s: %s. Start the next part from the stadium page.', self::SECTION[$p['section'] ?? ''] ?? '',
                    ($p['stage_done'] ?? false) ? "stage {$p['stage']} is complete and its effect works now" : "part {$p['part']} of 5 in stage {$p['stage']}"),
                'link' => '/stadium',
            ],
            'season_end' => [
                'title' => ($p['champion'] ?? false) ? "Champion of {$league}!" : "Season {$p['season']} of {$league} is over",
                'body' => sprintf('You finished in place %d. League objective: %s; cup objective: %s. %s', (int) ($p['place'] ?? 0),
                    ($p['league_goal'] ?? false) ? 'met' : 'not met', ($p['cup_goal'] ?? false) ? 'met' : 'not met',
                    ($p['renew'] ?? false) ? 'The new season has started from scratch, and your team awaits you in the preparation period.' : 'And the league is over.'),
                'link' => '/league',
            ],
            'vacation_request' => [
                'title' => 'A holiday request in '.$league,
                'body' => sprintf('%s asks for a %d-day holiday in %s. Reason: %s. Approve or decline from the league page.', $p['coach'] ?? '', (int) ($p['days'] ?? 0), $league, $p['reason'] ?? ''),
                'link' => $leagueLink,
            ],
            'vacation_approved' => [
                'title' => 'The league\'s manager approved your holiday',
                'body' => sprintf('Your %2$d-day holiday in %1$s has started. Your absence does not count, and the assistant runs your team.', $league, (int) ($p['days'] ?? 0)),
                'link' => $leagueLink,
            ],
            'vacation_rejected' => [
                'title' => 'Your holiday request was declined',
                'body' => sprintf('The manager of %s declined your holiday request. You can ask again with a clearer reason, or take a holiday for your whole account from your account page.', $league),
                'link' => $leagueLink,
            ],
            'listing_sold' => [
                'title' => 'Sold: '.($p['player'] ?? 'your player'),
                'body' => sprintf('A club from outside the league bought %s at the price you asked: %s. The money is in your club\'s balance.', $p['player'] ?? '', number_format((int) ($p['price'] ?? 0))),
                'link' => '/finance',
            ],
            'match_of_day' => [
                'title' => 'The match of the round is tonight',
                'body' => sprintf('Tonight in %s\'s evening slot: the match of the round between %s and %s. Book your ticket and watch it live!', $league, $p['home'] ?? '', $p['away'] ?? ''),
                'link' => '/match',
            ],
            'staff_left' => [
                'title' => 'Your '.(self::STAFF[$p['type'] ?? ''] ?? 'staff member').' resigned',
                'body' => sprintf('The %s\'s contract (%d stars) ended without a renewal, so they left the club. You can sign another from the staff page.', self::STAFF[$p['type'] ?? ''] ?? 'specialist', (int) ($p['stars'] ?? 0)),
                'link' => '/specialists',
            ],
            'inactive_warning' => [
                'title' => 'Last warning: your account will be deleted in two days',
                'body' => 'You have not signed in for '.(int) ($p['days'] ?? 12).' days. If you do not sign in or start a holiday within '.(int) ($p['left'] ?? 2).' days, your account and teams are deleted permanently.',
                'link' => '/profile',
            ],
            'account_vacation' => [
                'title' => ($p['status'] ?? '') === 'rejected' ? 'Your holiday request was declined' : 'Your holiday has started',
                'body' => ($p['status'] ?? '') === 'rejected'
                    ? 'The development team declined your long holiday request. Your account works as usual.'
                    : sprintf('Your %d-day holiday has started. Your account is protected from deletion, and the assistant coach leads your teams.', (int) ($p['days'] ?? 0)),
                'link' => '/profile',
            ],
            'account_vacation_request' => [
                'title' => 'A long holiday request',
                'body' => sprintf('%s asks for a %d-day holiday: %s', (string) ($p['name'] ?? ''), (int) ($p['days'] ?? 0), (string) ($p['reason'] ?? '')),
                'link' => '/admin',
            ],
            'article_pending' => [
                'title' => 'An article awaits your approval',
                'body' => sprintf('«%s» by %s for the %s newspaper.', (string) ($p['title'] ?? ''), (string) ($p['author'] ?? ''), (string) ($p['league'] ?? '')),
                'link' => isset($p['league_id']) ? "/leagues/{$p['league_id']}/newspaper" : '/leagues',
            ],
            'assistant_led' => [
                'title' => 'The assistant coach led your team',
                'body' => sprintf('You did not set your team before the match against %s, so the assistant picked the lineup: rested the tired, left out the injured and suspended, and played a balanced plan.', (string) ($p['opponent'] ?? '')),
                'link' => $leagueLink,
            ],
            // [Sprint 24 B3] A slot opened with the account's age.
            'loan' => [
                'title' => ['asked' => 'Loan request', 'accepted' => 'Loan accepted', 'rejected' => 'Loan turned down'][$p['what'] ?? 'asked'] ?? 'Loan',
                'body' => sprintf('%s asks for %s for %d rounds for %s.', $p['from'] ?? '', $p['player'] ?? '', (int) ($p['rounds'] ?? 1), number_format((int) ($p['money'] ?? 0))),
                'link' => '/market?tab=offers',
            ],
            // [Sprint 27 B2]
            'match_move' => [
                'title' => ['asked' => 'A request to move a match', 'accepted' => 'Your match has a new time', 'declined' => 'The new time was turned down'][$p['what'] ?? 'asked'] ?? 'Match time',
                'body' => match ($p['what'] ?? 'asked') {
                    'accepted' => sprintf('Your match against %s in %s now kicks off at %s Cairo time.', $p['opponent'] ?? '', $league, $p['at'] ?? ''),
                    'declined' => sprintf('%s turned down moving your match in %s to %s, so it stays at its time.', $p['opponent'] ?? '', $league, $p['at'] ?? ''),
                    default => sprintf('%s asks to move your match in %s to %s Cairo time, the same day. Accept or decline it from Next match.', $p['opponent'] ?? '', $league, $p['at'] ?? ''),
                },
                'link' => '/match',
            ],
            'suggestion_answer' => [
                'title' => ['accepted' => 'The team liked your suggestion', 'built' => 'Your suggestion is in the game', 'rejected' => 'The team answered your suggestion'][$p['status'] ?? ''] ?? 'An answer to your suggestion',
                'body' => trim(sprintf('«%s»', $p['title'] ?? '').(($p['coins'] ?? 0) > 0 ? sprintf(' Your reward is %s coins, and your name is on the honour roll.', $p['coins']) : (($p['status'] ?? '') === 'rejected' ? '' : ' Your name is on the honour roll.')).(($p['reply'] ?? '') !== '' ? ' '.$p['reply'] : '')),
                'link' => '/ideas',
            ],
            // [Sprint 29] The end of a tournament's groups, and an invitation to a chat group.
            'tournament_groups' => [
                'title' => ($p['through'] ?? false) ? sprintf('Through to the knockout of %s', $p['tournament'] ?? '') : sprintf('Out of %s in the group stage', $p['tournament'] ?? ''),
                'body' => ($p['through'] ?? false) ? 'The group stage is over and your team is through. See your opponent in the bracket.' : 'The group stage is over and your team is out. Follow the tournament to its final.',
                'link' => '/leagues/'.($p['league_id'] ?? ''),
            ],
            // [X68] A tournament's places are all taken (its draw is coming), and a team the organizer gave.
            'tournament_full' => [
                'title' => sprintf('%s is full', $p['tournament'] ?? ''),
                'body' => 'The draw is about to share the teams among the players. Come and watch it live and react with everyone.',
                'link' => '/tournaments/'.($p['league_id'] ?? '').'/draw',
            ],
            'tournament_team' => [
                'title' => sprintf('You coach %s in %s', $p['team'] ?? '', $p['tournament'] ?? ''),
                'body' => sprintf('%s chose you to coach this team. Get your lineup ready before the start.', $p['by'] ?? ''),
                'link' => '/tournaments/'.($p['league_id'] ?? ''),
            ],
            'chat_invite' => [
                'title' => sprintf('%s added you to the group %s', $p['by'] ?? '', $p['group'] ?? ''),
                'body' => 'Open the group to read its messages and join in.',
                'link' => '/groups/'.($p['group_id'] ?? ''),
            ],
            'slot_opened' => [
                'title' => sprintf('Congratulations! Coach slot %s is open', $p['slot'] ?? ''),
                'body' => sprintf('You now have %s of %s slots open: join a new league or create your own.', $p['open'] ?? '', $p['max'] ?? '').(! empty($p['next_at']) ? sprintf(' The next one opens in %d days.', (int) config('game.league.slots.every_days')) : ' That is the last of your slots.'),
                'link' => '/',
            ],
            // [X54] The developers gave the account coins.
            'coins_gift' => [
                'title' => sprintf('A gift from the team: %s coins', $p['coins'] ?? 0),
                'body' => (string) ($p['reason'] ?? ''),
                'link' => '/wallet',
            ],
            // [Sprint 21 E2.3] A friend signed up from the invite link and verified.
            'referral_reward' => [
                'title' => sprintf('Invite gift: %s coins', $p['coins'] ?? 0),
                'body' => sprintf('%s signed up from your invite link and verified their account, so you got %s coins. %s more invites with a gift left.', (string) ($p['name'] ?? ''), $p['coins'] ?? 0, $p['left'] ?? 0),
                'link' => '/wallet',
            ],
            // [Sprint 21 E7.7] A developer wrote to the coach.
            'official_message' => [
                'title' => sprintf('A message from %s', (string) ($p['username'] ?? 'the team')),
                'body' => (string) ($p['body'] ?? ''),
                'link' => '/support',
                'sender' => ['name' => (string) ($p['from'] ?? ''), 'username' => (string) ($p['username'] ?? ''), 'official' => true],
            ],
            'announcement' => [
                'title' => (string) ($p['title'] ?? 'An announcement from the Game Legend Manager team'),
                'body' => (string) ($p['body'] ?? ''),
                'link' => '/announcements',
                'sender' => ['name' => (string) ($p['from'] ?? ''), 'username' => (string) ($p['username'] ?? ''), 'official' => true],
            ],
            default => ['title' => 'Message', 'body' => '', 'link' => null],
        };
    }
}
