<?php

namespace App\Http\Controllers\Api;

use App\Assistant\Assistant;
use App\Assistant\PublicGuide;
use App\Http\Controllers\Controller;
use App\Support\GameClock;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/** [Sprint 22 B5] The Assistant Coach (Manager Bot): the conversation's opening on a page, and one answer. */
class AssistantController extends Controller
{
    public function __construct(private Assistant $assistant) {}

    public function start(Request $request): JsonResponse
    {
        $page = $request->validate(['page' => ['sometimes', 'nullable', 'string', 'max:40']])['page'] ?? null;

        return response()->json($this->assistant->start($request->user(), (string) $page, app()->getLocale()));
    }

    /** [X59] The game's guide for everyone, signed in or not: the public "how to play" page. */
    public function guide(): JsonResponse
    {
        return response()->json(['sections' => PublicGuide::sections(app()->getLocale())])->header('Cache-Control', 'public, max-age=600');
    }

    /** [X61] The coach rates the conversation at its end: helpful or not, and a short note (the privacy policy says so). */
    public function feedback(Request $request): JsonResponse
    {
        $data = $request->validate(['helpful' => ['required', 'boolean'], 'page' => ['sometimes', 'nullable', 'string', 'max:40'],
            'note' => ['sometimes', 'nullable', 'string', 'max:300']]);
        DB::table('assistant_feedback')->insert(['user_id' => $request->user()->id, 'helpful' => (bool) $data['helpful'],
            'page' => $data['page'] ?? null, 'note' => trim((string) ($data['note'] ?? '')) ?: null, 'created_at' => GameClock::now()]);

        return response()->json(['message' => __('شكراً، سنحسّن الردود.')]);
    }

    public function ask(Request $request): JsonResponse
    {
        $cfg = config('game.manager_bot');
        $data = $request->validate([
            'question' => ['required', 'string', 'max:'.$cfg['question_max']],
            'topic' => ['sometimes', 'nullable', 'string', 'max:40'],
            'page' => ['sometimes', 'nullable', 'string', 'max:40'],
            'league_id' => ['sometimes', 'nullable', 'integer'],
            'history' => ['sometimes', 'array', 'max:'.$cfg['history']],
            'history.*.from' => ['required', 'in:me,bot'],
            'history.*.text' => ['required', 'string', 'max:2000'],
        ]);

        return response()->json($this->assistant->ask($request->user(), trim($data['question']), $data['history'] ?? [],
            $data['league_id'] ?? null, (string) ($data['page'] ?? ''), $data['topic'] ?? null, app()->getLocale()));
    }
}
