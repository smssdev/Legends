<?php

namespace App\Http\Controllers\Api;

use App\Assistant\Assistant;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** [Sprint 22 B5] The Assistant Coach (Manager Bot): the conversation's opening on a page, and one answer. */
class AssistantController extends Controller
{
    public function __construct(private Assistant $assistant) {}

    public function start(Request $request): JsonResponse
    {
        $page = $request->validate(['page' => ['sometimes', 'nullable', 'string', 'max:40']])['page'] ?? null;

        return response()->json($this->assistant->start($request->user(), (string) $page, app()->getLocale()));
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
