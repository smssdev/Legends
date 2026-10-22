<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Messages\Inbox;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/** The inbox [Sprint 22]: the account's messages, newest first, and marking them read. */
class MessageController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $data = $request->validate(['before' => 'nullable|integer|min:1', 'limit' => 'nullable|integer|min:1|max:50']);
        $limit = $data['limit'] ?? 30;
        $rows = DB::table('messages')->where('user_id', $request->user()->id)
            ->when($data['before'] ?? null, fn ($q, $before) => $q->where('id', '<', $before))
            ->orderByDesc('id')->limit($limit + 1)->get();

        return response()->json([
            'messages' => $rows->take($limit)->map(fn ($m) => Inbox::view($m))->values(),
            'more' => $rows->count() > $limit,
            'unread' => Inbox::unread($request->user()->id),
        ]);
    }

    public function unread(Request $request): JsonResponse
    {
        return response()->json(['unread' => Inbox::unread($request->user()->id)]);
    }

    public function read(Request $request, int $message): JsonResponse
    {
        abort_unless(DB::table('messages')->where('id', $message)->where('user_id', $request->user()->id)->exists(), 404, 'الرسالة غير موجودة.');
        Inbox::read($request->user()->id, [$message]);

        return response()->json(['unread' => Inbox::unread($request->user()->id)]);
    }

    public function readAll(Request $request): JsonResponse
    {
        $ids = Inbox::read($request->user()->id);

        return response()->json(['read' => count($ids), 'unread' => 0]);
    }
}
