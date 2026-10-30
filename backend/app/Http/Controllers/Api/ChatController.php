<?php

namespace App\Http\Controllers\Api;

use App\Chat\ChatGroups;
use App\Http\Controllers\Controller;
use App\League\Members;
use App\Models\League;
use App\Rules\NotJunk;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/** [Sprint 27] Chat groups: the account's groups, one group with its members and messages, and what its admins do. */
class ChatController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(['groups' => ChatGroups::mine($request->user())]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate(['name' => ['required', 'string', 'max:60', new NotJunk], 'usernames' => ['sometimes', 'array', 'max:50'], 'usernames.*' => ['string', 'max:40']]);
        $id = ChatGroups::create($request->user(), trim($data['name']), $data['usernames'] ?? []);

        return response()->json(['group' => ChatGroups::show($id, $request->user())], 201);
    }

    /** A league's or tournament's own group, for its owner and coaches. */
    public function league(Request $request, League $league): JsonResponse
    {
        abort_unless(Members::isMember($request->user()->id, $league->id), 404);

        return response()->json(['group' => ChatGroups::show(ChatGroups::forLeague($league), $request->user())]);
    }

    public function show(Request $request, int $group): JsonResponse
    {
        return response()->json(['group' => ChatGroups::show($group, $request->user()), 'messages' => ChatGroups::messages($group, $request->user())]);
    }

    public function messages(Request $request, int $group): JsonResponse
    {
        $data = $request->validate(['before' => ['nullable', 'integer']]);

        return response()->json(['messages' => ChatGroups::messages($group, $request->user(), $data['before'] ?? null)]);
    }

    public function send(Request $request, int $group): JsonResponse
    {
        $data = $request->validate(['body' => ['required', 'string', 'max:'.config('game.chat.max_length')], 'reply_to' => ['nullable', 'integer']]);

        return response()->json(['message' => ChatGroups::send($group, $request->user(), $data['body'], $data['reply_to'] ?? null)], 201);
    }

    public function destroyMessage(Request $request, int $group, int $message): JsonResponse
    {
        ChatGroups::delete($group, $request->user(), $message);

        return response()->json(['ok' => true]);
    }

    public function read(Request $request, int $group): JsonResponse
    {
        $data = $request->validate(['last_id' => ['required', 'integer']]);
        ChatGroups::read($group, $request->user(), $data['last_id']);

        return response()->json(['ok' => true]);
    }

    public function update(Request $request, int $group): JsonResponse
    {
        $data = $request->validate(['name' => ['required', 'string', 'max:60', new NotJunk]]);
        ChatGroups::rename($group, $request->user(), trim($data['name']));

        return response()->json(['group' => ChatGroups::show($group, $request->user())]);
    }

    public function addMembers(Request $request, int $group): JsonResponse
    {
        $data = $request->validate(['usernames' => ['required', 'array', 'min:1', 'max:50'], 'usernames.*' => ['string', 'max:40']]);
        $added = ChatGroups::add($group, $request->user(), $data['usernames']);

        return response()->json(['added' => $added, 'group' => ChatGroups::show($group, $request->user())]);
    }

    public function removeMember(Request $request, int $group, int $user): JsonResponse
    {
        ChatGroups::remove($group, $request->user(), $user);

        return response()->json(['group' => ChatGroups::show($group, $request->user())]);
    }

    public function admin(Request $request, int $group, int $user): JsonResponse
    {
        $data = $request->validate(['admin' => ['required', 'boolean']]);
        ChatGroups::setAdmin($group, $request->user(), $user, $data['admin']);

        return response()->json(['group' => ChatGroups::show($group, $request->user())]);
    }

    public function leave(Request $request, int $group): JsonResponse
    {
        ChatGroups::leave($group, $request->user());

        return response()->json(['ok' => true]);
    }

    public function join(Request $request, string $code): JsonResponse
    {
        $id = ChatGroups::joinByCode($request->user(), $code);

        return response()->json(['group' => ChatGroups::show($id, $request->user())]);
    }
}
