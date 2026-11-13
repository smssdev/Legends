<?php

namespace Tests\Feature;

use App\Models\User;
use App\Wallet\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Tests\Feature\Concerns\MakesLeagues;
use Tests\TestCase;

/** [Sprint 50 M10] Daily tasks: done from what the coach did today (Cairo), each reward once a day, a new day anew. */
class DailyTasksTest extends TestCase
{
    use MakesLeagues, RefreshDatabase;

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_a_task_pays_once_a_day_when_done(): void
    {
        Carbon::setTestNow('2026-11-10 10:00:00');
        $this->template(full: true);
        $owner = User::factory()->create();
        $league = $this->makeLeague($owner, ['team_count' => 4, 'starts_at' => '2026-11-14T10:00:00Z']);
        $url = "/api/v1/leagues/{$league['id']}/daily-tasks";

        $view = $this->actingAs($owner)->getJson($url)->assertOk()->assertJsonCount(4, 'tasks')
            // [Sprint 59 F1] The fields the app reads through DailyTasks (openapi.yaml).
            ->assertJsonStructure(['day', 'renews_at', 'done', 'total', 'tasks' => ['*' => ['task', 'complete', 'claimed', 'coins']]])->json();
        $this->assertSame('2026-11-10', $view['day']);
        $chat = collect($view['tasks'])->firstWhere('task', 'chat');
        $this->assertFalse($chat['complete']);
        $this->postJson("{$url}/claim", ['task' => 'chat'])->assertConflict();

        // A word in the league's group.
        $group = DB::table('chat_groups')->where('league_id', $league['id'])->value('id');
        $this->postJson("/api/v1/groups/{$group}/messages", ['body' => 'صباح الخير'])->assertCreated();
        $coins = Wallet::balance($owner->id);
        $this->postJson("{$url}/claim", ['task' => 'chat'])->assertOk();
        $this->assertSame($coins + (int) config('game.daily_tasks.chat'), Wallet::balance($owner->id));
        $this->postJson("{$url}/claim", ['task' => 'chat'])->assertConflict();
        $this->postJson("{$url}/claim", ['task' => 'stadium'])->assertUnprocessable();

        // Midnight in Cairo: a new day, the task to do again.
        Carbon::setTestNow('2026-11-10 22:30:00');
        $this->getJson($url)->assertJsonPath('day', '2026-11-11')->assertJsonPath('tasks.3.complete', false)->assertJsonPath('tasks.3.claimed', false);
    }
}
