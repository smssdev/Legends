<?php

namespace Tests\Feature;

use App\Assistant\ClubReader;
use App\League\ClubAgenda;
use App\League\Tactics;
use App\Models\Club;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request as HttpRequest;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Http;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 22] The Assistant Coach (Manager Bot): the guide's answers, the AI with the coach's own club, and the fallbacks. */
class ManagerBotTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    private User $owner;

    private array $league;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-22 10:00:00');
        $this->template(full: true);
        $this->owner = User::factory()->create();
        $this->league = $this->makeLeague($this->owner, ['team_count' => 4, 'is_dev' => true, 'prep_days' => 1, 'starts_at' => '2026-10-22T10:00:00Z']);
        $this->actingAs($this->owner)->postJson("/api/v1/leagues/{$this->league['id']}/start")->assertOk();
        config(['services.gemini.key' => null, 'services.gemini.models' => ['model-a', 'model-b']]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    private function ask(string $question, array $more = []): array
    {
        return $this->postJson('/api/v1/assistant/ask', ['question' => $question, 'league_id' => $this->league['id'], 'page' => 'tactics'] + $more)
            ->assertOk()->json();
    }

    private function gemini(array ...$responses): void
    {
        config(['services.gemini.key' => 'test-key']);
        Http::fake(['generativelanguage.googleapis.com/*' => Http::sequence(array_map(fn ($r) => is_int($r[0] ?? null)
            ? Http::response(['error' => ['code' => $r[0]]], $r[0])
            : Http::response(['candidates' => [['content' => ['role' => 'model', 'parts' => $r]]]]), $responses))]);
    }

    public function test_the_start_introduces_him_with_the_pages_questions_in_both_languages(): void
    {
        $this->app['auth']->forgetGuards();
        $this->getJson('/api/v1/assistant/start')->assertUnauthorized();
        $this->postJson('/api/v1/assistant/ask', ['question' => 'مرحبا'])->assertUnauthorized();
        $start = $this->actingAs($this->owner)->getJson('/api/v1/assistant/start?page=tactics')->assertOk()->json();
        $this->assertSame('المدرب المساعد', $start['name']);
        $this->assertStringContainsString('أنا المدرب المساعد', $start['intro']);
        $this->assertContains('pressing', array_column($start['questions'], 'topic'));
        $this->assertFalse($start['ai']);
        $this->assertNull($start['remaining']);

        $en = $this->getJson('/api/v1/assistant/start?page=league-newspaper', ['Accept-Language' => 'en'])->assertOk()->json();
        $this->assertSame('Manager Bot', $en['name']);
        $this->assertSame('newspaper', $en['questions'][0]['topic']);
        $this->assertStringContainsString('Manager Bot', $en['intro']);
    }

    public function test_a_quick_question_is_answered_from_the_guide_at_once_without_the_ai(): void
    {
        $this->gemini();
        $a = $this->actingAs($this->owner)->ask('ماذا يفعل الضغط؟', ['topic' => 'pressing']);
        $this->assertSame('guide', $a['source']);
        $this->assertSame(Tactics::HELP['pressing'], $a['answer']);
        $this->assertSame('tactics', $a['go']);
        $this->assertNotEmpty($a['related']);
        Http::assertNothingSent();
    }

    public function test_without_a_key_the_smart_search_answers_the_coachs_own_words(): void
    {
        $a = $this->actingAs($this->owner)->ask('يعني ايه المصيده');
        $this->assertSame('guide', $a['source']);
        $this->assertSame('off', $a['notice']);
        $this->assertSame(Tactics::HELP['trap'], $a['answer']);

        $none = $this->ask('xyzzy qwerty');
        $this->assertSame('guide', $none['source']);
        $this->assertNotEmpty($none['related']);
    }

    public function test_the_ai_reads_the_coachs_own_club_and_answers_with_a_page(): void
    {
        $this->gemini(
            [['functionCall' => ['name' => 'read_club', 'args' => ['part' => 'summary']]]],
            [['text' => 'فريقك جاهز، ودرّب اللياقة قبل المباراة. [go:training]']],
        );
        $a = $this->actingAs($this->owner)->ask('كيف حال فريقي؟', ['history' => [['from' => 'me', 'text' => 'مرحبا'], ['from' => 'bot', 'text' => 'أهلاً كوتش']]]);
        $this->assertSame('ai', $a['source']);
        $this->assertSame('فريقك جاهز، ودرّب اللياقة قبل المباراة.', $a['answer']);
        $this->assertSame('training', $a['go']);
        $this->assertSame(29, $a['remaining']);

        $club = Club::find($this->league['my_club_id']);
        $sent = Http::recorded();
        $this->assertCount(2, $sent);
        [$first] = $sent[0];
        $this->assertSame('test-key', $first->header('x-goog-api-key')[0]);
        $this->assertStringContainsString('model-a:generateContent', $first->url());
        $this->assertSame('read_club', $first['tools'][0]['functionDeclarations'][0]['name']);
        $this->assertStringContainsString($club->name, $first['systemInstruction']['parts'][0]['text']);
        $this->assertSame(['user', 'model', 'user'], array_column($first['contents'], 'role'));
        // The second carries what was read: the coach's own club, and never his email.
        [$second] = $sent[1];
        $read = json_encode($second['contents'][count($second['contents']) - 1], JSON_UNESCAPED_UNICODE);
        $this->assertStringContainsString($club->name, $read);
        $this->assertStringNotContainsString($this->owner->email, json_encode($second->data(), JSON_UNESCAPED_UNICODE));
    }

    public function test_the_day_used_up_or_google_unable_falls_back_to_the_guide(): void
    {
        config(['game.manager_bot.daily_ai' => 1]);
        $this->gemini([['text' => 'جواب ذكي']], [429], [429]);
        $this->assertSame('ai', $this->actingAs($this->owner)->ask('ما هي المصيدة؟')['source']);
        $limit = $this->ask('ما هي المصيدة؟');
        $this->assertSame('guide', $limit['source']);
        $this->assertSame('limit', $limit['notice']);
        $this->assertSame(0, $limit['remaining']);

        // Google's free day used up on both models: the guide answers, and the question is given back.
        $this->travel(1)->days();
        $error = $this->ask('ما هي المصيدة؟');
        $this->assertSame('guide', $error['source']);
        $this->assertSame('error', $error['notice']);
        Http::assertSentCount(3);
        $this->assertSame(1, $this->getJson('/api/v1/assistant/start')->json('remaining'));
    }

    public function test_without_a_club_in_that_league_nothing_of_any_club_can_be_read(): void
    {
        $other = User::factory()->create();
        $this->gemini([['text' => 'افتح أحد أنديتك أولاً.']]);
        $this->actingAs($other)->postJson('/api/v1/assistant/ask', ['question' => 'كيف حال فريقي؟', 'league_id' => $this->league['id']])->assertOk();
        Http::assertSent(fn (HttpRequest $r) => ! isset($r['tools']) && str_contains($r['systemInstruction']['parts'][0]['text'], 'no club'));
    }

    public function test_what_he_reads_never_holds_the_opponents_private_tactics(): void
    {
        $mine = Club::find($this->league['my_club_id']);
        $f = ClubAgenda::nextFixture($mine);
        $opponent = Club::find($f->home_id === $mine->id ? $f->away_id : $f->home_id);
        Tactics::save($opponent, ['pressing' => 13, 'style' => 17, 'tempo' => 19]);
        $reader = ClubReader::for($this->owner, $this->league['id']);
        foreach (ClubReader::PARTS as $part) {
            $json = json_encode($reader->read($part));
            $this->assertArrayNotHasKey('error', $reader->read($part), $part);
            foreach (['"pressing":13', '"style":17', '"tempo":19'] as $secret) {
                $this->assertStringNotContainsString($secret, $json, $part);
            }
            $this->assertStringNotContainsString('@', $json, $part);
        }
    }
}
