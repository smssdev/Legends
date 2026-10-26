<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\League\Members;
use App\League\Newspaper;
use App\League\Predictions;
use App\League\PressRoom;
use App\Models\Club;
use App\Models\League;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/** [UP12] The league's media: the press conference, the predictions and the newspaper with the coaches' articles. */
class PressController extends Controller
{
    public function conference(Request $request, League $league, int $fixture): JsonResponse
    {
        $this->member($request, $league);
        $f = $this->fixture($league, $fixture);

        return response()->json(['press' => PressRoom::of($f, $this->myClub($request, $league)), 'enabled' => (bool) $league->press_conferences]);
    }

    public function say(Request $request, League $league, int $fixture): JsonResponse
    {
        abort_unless($league->press_conferences, 409, 'المؤتمرات الصحفية متوقفة في هذا الدوري.');
        $club = $this->myClub($request, $league);
        $f = $this->fixture($league, $fixture);
        abort_unless($club && in_array($club, [$f->home_id, $f->away_id], true), 403, 'التصريح لمدربي المباراة فقط.');
        $data = $request->validate(['kind' => ['required', Rule::in(array_keys(PressRoom::STATEMENTS))]]);
        PressRoom::say($f, $club, $data['kind']);

        return response()->json(['press' => PressRoom::of($f, $club)]);
    }

    public function predictions(Request $request, League $league): JsonResponse
    {
        $this->member($request, $league);

        return response()->json(Predictions::round($league->id, $request->user()->id));
    }

    public function predict(Request $request, League $league): JsonResponse
    {
        $this->member($request, $league);
        $data = $request->validate(['fixture_id' => 'required|integer', 'pick' => ['required', Rule::in(Predictions::PICKS)]]);
        Predictions::pick($league->id, $request->user()->id, $data['fixture_id'], $data['pick']);

        return response()->json(Predictions::round($league->id, $request->user()->id));
    }

    public function newspaper(Request $request, League $league): JsonResponse
    {
        $this->member($request, $league);
        $round = $request->validate(['round' => 'nullable|integer|min:1'])['round'] ?? null;
        $owner = $league->owner_id === $request->user()->id;

        return response()->json([
            'edition' => Newspaper::edition($league, $round),
            'articles' => Newspaper::articles($league->id),
            'pending' => $owner ? Newspaper::articles($league->id, 'pending') : array_values(array_filter(Newspaper::articles($league->id, 'pending'), fn ($a) => $a['author']['id'] === $request->user()->id)),
            'is_owner' => $owner,
            'max' => (int) config('game.press.article_max'),
        ]);
    }

    public function write(Request $request, League $league): JsonResponse
    {
        $this->member($request, $league);
        $data = $request->validate(['title' => 'required|string|min:3|max:120', 'body' => 'required|string|min:10|max:'.config('game.press.article_max')]);
        Newspaper::write($league, $request->user()->id, trim($data['title']), trim($data['body']));

        return $this->newspaper($request, $league);
    }

    public function decide(Request $request, League $league, int $article): JsonResponse
    {
        abort_unless($league->owner_id === $request->user()->id, 403, 'النشر لمشرف الدوري فقط.');
        $data = $request->validate(['publish' => 'required|boolean']);
        Newspaper::decide($league, $article, (bool) $data['publish']);

        return $this->newspaper($request, $league);
    }

    private function member(Request $request, League $league): void
    {
        abort_unless(Members::isMember($request->user()->id, $league->id), 404);
    }

    private function myClub(Request $request, League $league): ?int
    {
        $id = Club::where('league_id', $league->id)->where('user_id', $request->user()->id)->value('id');

        return $id ? (int) $id : null;
    }

    private function fixture(League $league, int $id): object
    {
        $f = DB::table('fixtures')->join('seasons', 'seasons.id', '=', 'fixtures.season_id')->where('fixtures.id', $id)->where('seasons.league_id', $league->id)
            ->select('fixtures.*')->first();
        abort_unless($f && ! $f->is_bye, 404, 'المباراة غير موجودة في هذا الدوري.');

        return $f;
    }
}
