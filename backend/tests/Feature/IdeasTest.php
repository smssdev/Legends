<?php

namespace Tests\Feature;

use App\Auth\AccountDeletion;
use App\Models\User;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

/**
 * [Sprint 28] The development ideas: a coach's suggestion, the team's answer with its reward once, the honour roll,
 * and the polls on what to build next (one vote an account, the counts after voting, the winner at the end).
 */
class IdeasTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private User $coach;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-30 10:00:00');
        $this->admin = User::factory()->create(['role' => 'admin']);
        $this->coach = User::factory()->create(['name' => 'حمزة']);
        // The panel is the site's: a request from it carries a session.
        $this->withHeader('Referer', config('app.url'));
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function suggest(string $title = 'وضع الليل في المباراة'): int
    {
        return $this->actingAs($this->coach)->postJson('/api/v1/ideas/suggestions', ['title' => $title, 'body' => 'شاشة المباراة بألوان أهدأ في الليل.'])
            ->assertCreated()->assertJsonPath('suggestion.status', 'pending')->json('suggestion.id');
    }

    public function test_a_coach_sends_suggestions_up_to_the_days_limit(): void
    {
        config(['game.ideas.per_day' => 2]);
        $this->suggest('الأولى');
        $this->suggest('الثانية');
        $this->postJson('/api/v1/ideas/suggestions', ['title' => 'الثالثة', 'body' => 'نص طويل بما يكفي للاقتراح.'])->assertStatus(429);
        $this->postJson('/api/v1/ideas/suggestions', ['title' => 'قصير', 'body' => 'قصير'])->assertStatus(422);
        $this->getJson('/api/v1/ideas')->assertOk()->assertJsonCount(2, 'suggestions')
            // [Sprint 59 F1] The fields the app reads through its generated model (openapi.yaml).
            ->assertJsonStructure(['per_day', 'left_today', 'polls', 'honours', 'suggestions' => ['*' => ['id', 'title', 'body', 'status', 'coins', 'reply', 'at']]])->assertJsonPath('left_today', 0)->assertJsonPath('suggestions.0.title', 'الثانية');
        // A day later the limit opens again.
        Carbon::setTestNow('2026-10-31 10:01:00');
        $this->getJson('/api/v1/ideas')->assertJsonPath('left_today', 2);
        // Another account does not see them; a visitor cannot send.
        $this->actingAs(User::factory()->create())->getJson('/api/v1/ideas')->assertJsonCount(0, 'suggestions');
        $this->app['auth']->forgetGuards();
        $this->postJson('/api/v1/ideas/suggestions', ['title' => 'زائر', 'body' => 'لا حساب لي في اللعبة.'])->assertUnauthorized();
    }

    public function test_the_team_rewards_a_suggestion_it_likes_once_and_the_coach_joins_the_honour_roll(): void
    {
        $id = $this->suggest();
        $other = $this->suggest('سوق أسرع');
        $before = Wallet::balance($this->coach->id);
        $this->actingAs($this->coach)->postJson("/api/v1/admin/ideas/{$id}/decide", ['status' => 'accepted', 'coins' => 50])->assertForbidden();

        $this->actingAs($this->admin)->getJson('/api/v1/admin/ideas?status=pending')->assertOk()->assertJsonCount(2, 'suggestions')
            ->assertJsonPath('counts.pending', 2)->assertJsonPath('suggestions.1.user.name', 'حمزة');
        $this->postJson("/api/v1/admin/ideas/{$id}/decide", ['status' => 'accepted', 'coins' => 80, 'reply' => 'فكرة جميلة، سننفذها.'])->assertOk()
            ->assertJsonPath('suggestion.status', 'accepted')->assertJsonPath('suggestion.coins', 80);
        $this->assertSame($before + 80, Wallet::balance($this->coach->id));
        $this->assertSame('suggestion', DB::table('wallet_transactions')->where('user_id', $this->coach->id)->orderByDesc('id')->value('type'));
        $this->assertSame('suggestion_answer', DB::table('messages')->where('user_id', $this->coach->id)->orderByDesc('id')->value('type'));
        $this->assertSame(1, DB::table('admin_log')->where('action', 'suggestion')->count());
        // The reward is once; built later keeps it; an accepted one is not turned down after.
        $this->postJson("/api/v1/admin/ideas/{$id}/decide", ['status' => 'built', 'coins' => 50])->assertStatus(409);
        $this->postJson("/api/v1/admin/ideas/{$id}/decide", ['status' => 'built'])->assertOk()->assertJsonPath('suggestion.coins', 80);
        $this->postJson("/api/v1/admin/ideas/{$id}/decide", ['status' => 'rejected'])->assertStatus(409);
        $this->assertSame($before + 80, Wallet::balance($this->coach->id));
        // Not taken: no reward, and no place on the roll.
        $this->postJson("/api/v1/admin/ideas/{$other}/decide", ['status' => 'rejected', 'coins' => 10])->assertStatus(422);
        $this->postJson("/api/v1/admin/ideas/{$other}/decide", ['status' => 'rejected', 'reply' => 'موجودة في الإعدادات.'])->assertOk();
        $this->postJson("/api/v1/admin/ideas/{$other}/decide", ['status' => 'accepted', 'coins' => 99999])->assertStatus(422);

        $this->actingAs(User::factory()->create())->getJson('/api/v1/ideas')->assertOk()->assertJsonCount(1, 'honours')
            ->assertJsonPath('honours.0.user.name', 'حمزة')->assertJsonPath('honours.0.count', 1)->assertJsonPath('honours.0.coins', 80)
            ->assertJsonPath('honours.0.latest.status', 'built');
        $this->actingAs($this->coach)->getJson('/api/v1/ideas')->assertJsonPath('suggestions.0.status', 'rejected')->assertJsonPath('suggestions.0.reply', 'موجودة في الإعدادات.');
    }

    public function test_a_poll_takes_one_vote_an_account_shows_counts_after_voting_and_names_the_winner(): void
    {
        $from = $this->suggest();
        $poll = $this->actingAs($this->admin)->postJson('/api/v1/admin/polls', ['question' => 'ما الميزة القادمة؟', 'hours' => 48,
            'options' => [['label' => 'وضع الليل', 'suggestion_id' => $from], ['label' => 'بطولة الأبطال'], ['label' => 'تطبيق الجوال']]])
            ->assertCreated()->json('poll');
        [$night, $cup, $app] = array_column($poll['options'], 'id');
        $this->postJson('/api/v1/admin/polls', ['question' => 'خيار واحد؟', 'hours' => 5, 'options' => [['label' => 'وحيد']]])->assertStatus(422);
        $this->postJson('/api/v1/admin/polls', ['question' => 'طويل جداً', 'hours' => 31 * 24, 'options' => [['label' => 'أ'], ['label' => 'ب']]])->assertStatus(422);
        $this->postJson('/api/v1/admin/polls', ['question' => 'مكرر؟', 'hours' => 5, 'options' => [['label' => 'أ'], ['label' => 'أ']]])->assertStatus(422);

        // Before voting, no counts; after, the counts; the vote can change, and stays one.
        $this->actingAs($this->coach)->getJson('/api/v1/ideas')->assertJsonPath('polls.0.state', 'open')->assertJsonPath('polls.0.total', null)->assertJsonPath('polls.0.options.0.votes', null);
        $this->getJson('/api/v1/home')->assertJsonPath('polls_waiting', 1);
        $this->postJson("/api/v1/ideas/polls/{$poll['id']}/vote", ['option_id' => $cup])->assertOk()->assertJsonPath('poll.my_vote', $cup)->assertJsonPath('poll.total', 1);
        $this->postJson("/api/v1/ideas/polls/{$poll['id']}/vote", ['option_id' => $night])->assertOk()->assertJsonPath('poll.total', 1)->assertJsonPath('poll.options.0.votes', 1);
        $this->getJson('/api/v1/home')->assertJsonPath('polls_waiting', 0);
        $this->postJson("/api/v1/ideas/polls/{$poll['id']}/vote", ['option_id' => 999999])->assertStatus(422);
        foreach (range(1, 2) as $i) {
            $this->actingAs(User::factory()->create())->postJson("/api/v1/ideas/polls/{$poll['id']}/vote", ['option_id' => $app])->assertOk();
        }
        $this->assertSame(3, DB::table('poll_votes')->where('poll_id', $poll['id'])->count());

        // When it ends: the counts for everyone, the winner, and no more votes.
        Carbon::setTestNow('2026-11-01 10:01:00');
        $this->actingAs(User::factory()->create())->getJson('/api/v1/ideas')->assertJsonPath('polls.0.state', 'ended')
            ->assertJsonPath('polls.0.total', 3)->assertJsonPath('polls.0.winners', [$app]);
        $this->postJson("/api/v1/ideas/polls/{$poll['id']}/vote", ['option_id' => $app])->assertStatus(409);
        $this->actingAs($this->admin)->deleteJson("/api/v1/admin/polls/{$poll['id']}")->assertStatus(409);
    }

    public function test_the_team_schedules_a_poll_and_closes_it(): void
    {
        $later = $this->actingAs($this->admin)->postJson('/api/v1/admin/polls', ['question' => 'تصويت الأسبوع القادم', 'starts_at' => '2026-11-02T10:00:00Z', 'hours' => 24,
            'options' => [['label' => 'أ'], ['label' => 'ب']]])->assertCreated()->assertJsonPath('poll.state', 'upcoming')->json('poll.id');
        // A coach does not see one not started yet.
        $this->actingAs($this->coach)->getJson('/api/v1/ideas')->assertJsonCount(0, 'polls');
        $this->actingAs($this->admin)->deleteJson("/api/v1/admin/polls/{$later}")->assertOk()->assertJsonPath('deleted', true);

        // One running with votes ends now and stays as the record.
        $now = $this->postJson('/api/v1/admin/polls', ['question' => 'تصويت الآن', 'hours' => 24, 'options' => [['label' => 'أ'], ['label' => 'ب']]])->json('poll');
        $this->actingAs($this->coach)->postJson("/api/v1/ideas/polls/{$now['id']}/vote", ['option_id' => $now['options'][1]['id']])->assertOk();
        $this->actingAs($this->admin)->deleteJson("/api/v1/admin/polls/{$now['id']}")->assertOk()->assertJsonPath('deleted', false);
        $this->getJson('/api/v1/admin/polls')->assertOk()->assertJsonCount(1, 'polls')->assertJsonPath('polls.0.state', 'ended')->assertJsonPath('polls.0.winners', [$now['options'][1]['id']]);
    }

    public function test_a_deleted_account_takes_its_suggestions_and_votes(): void
    {
        $this->suggest();
        $poll = $this->actingAs($this->admin)->postJson('/api/v1/admin/polls', ['question' => 'سؤال التصويت', 'hours' => 24, 'options' => [['label' => 'أ'], ['label' => 'ب']]])->json('poll');
        $this->actingAs($this->coach)->postJson("/api/v1/ideas/polls/{$poll['id']}/vote", ['option_id' => $poll['options'][0]['id']])->assertOk();
        AccountDeletion::delete($this->coach);
        $this->assertSame(0, DB::table('suggestions')->count());
        $this->assertSame(0, DB::table('poll_votes')->count());
    }
}
