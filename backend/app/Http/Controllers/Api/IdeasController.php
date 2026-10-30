<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Ideas\Polls;
use App\Ideas\Suggestions;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * [Sprint 28] The development ideas: the coach's suggestions and the team's answers, the polls on what to build next,
 * and the honour roll; and the panel's side (answer a suggestion with its reward, open and close a poll).
 */
class IdeasController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $id = $request->user()->id;
        $max = (int) config('game.ideas.per_day');

        return response()->json(['suggestions' => Suggestions::mine($id), 'per_day' => $max, 'left_today' => max(0, $max - Suggestions::sentToday($id)),
            'polls' => Polls::forCoach($id), 'honours' => Suggestions::honours()]);
    }

    public function suggest(Request $request): JsonResponse
    {
        $data = $request->validate(['title' => ['required', 'string', 'min:4', 'max:120'], 'body' => ['required', 'string', 'min:10', 'max:2000']]);

        return response()->json(['suggestion' => Suggestions::send($request->user(), trim($data['title']), trim($data['body']))], 201);
    }

    public function vote(Request $request, int $poll): JsonResponse
    {
        $data = $request->validate(['option_id' => ['required', 'integer']]);

        return response()->json(['poll' => Polls::vote($request->user()->id, $poll, (int) $data['option_id'])]);
    }

    public function adminSuggestions(Request $request): JsonResponse
    {
        $status = $request->validate(['status' => ['nullable', Rule::in(Suggestions::STATUSES)]])['status'] ?? null;

        return response()->json(Suggestions::forPanel($status) + ['reward_default' => (int) config('game.ideas.reward_default'), 'reward_max' => (int) config('game.ideas.reward_max')]);
    }

    public function decide(Request $request, int $id): JsonResponse
    {
        $data = $request->validate(['status' => ['required', Rule::in(['accepted', 'built', 'rejected'])],
            'coins' => ['nullable', 'integer', 'min:0', 'max:'.config('game.ideas.reward_max')], 'reply' => ['nullable', 'string', 'max:500']]);
        $reply = isset($data['reply']) ? (trim($data['reply']) ?: null) : null;

        return response()->json(['suggestion' => Suggestions::decide($request->user(), $id, $data['status'], (int) ($data['coins'] ?? 0), $reply)]);
    }

    public function adminPolls(): JsonResponse
    {
        return response()->json(['polls' => Polls::forPanel(), 'max_days' => (int) config('game.ideas.poll_max_days'),
            'options_min' => (int) config('game.ideas.poll_options_min'), 'options_max' => (int) config('game.ideas.poll_options_max')]);
    }

    public function openPoll(Request $request): JsonResponse
    {
        $data = $request->validate([
            'question' => ['required', 'string', 'min:4', 'max:160'],
            'body' => ['nullable', 'string', 'max:1000'],
            'starts_at' => ['nullable', 'date'],
            'hours' => ['required', 'integer', 'min:1'],
            'options' => ['required', 'array', 'min:'.config('game.ideas.poll_options_min'), 'max:'.config('game.ideas.poll_options_max')],
            'options.*.label' => ['required', 'string', 'min:1', 'max:120'],
            'options.*.suggestion_id' => ['nullable', 'integer', 'exists:suggestions,id'],
        ]);

        return response()->json(['poll' => Polls::open($request->user()->id, $data)], 201);
    }

    public function closePoll(int $id): JsonResponse
    {
        return response()->json(['ok' => true, 'deleted' => Polls::close($id)]);
    }
}
