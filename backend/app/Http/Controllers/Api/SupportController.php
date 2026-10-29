<?php

namespace App\Http\Controllers\Api;

use App\Admin\Conversations;
use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** The coach's side of the conversation with the game's developers [Sprint 21 E7.7]: read it, and write to them. */
class SupportController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        Conversations::markRead($request->user()->id, false);

        return response()->json(['messages' => Conversations::thread($request->user()->id)]);
    }

    public function write(Request $request): JsonResponse
    {
        $body = trim((string) $request->validate(['body' => ['required', 'string', 'min:1', 'max:'.Conversations::MAX]])['body']);
        Conversations::fromCoach($request->user(), $body);

        return $this->show($request);
    }
}
