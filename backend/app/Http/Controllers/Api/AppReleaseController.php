<?php

namespace App\Http\Controllers\Api;

use App\Apps\AppReleases;
use App\Http\Controllers\Controller;
use App\Notify\Fcm;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\HttpFoundation\BinaryFileResponse;

/** [Sprint 15 D1] The app on the site: what to download (public), and its upload by the admin, piece by piece. */
class AppReleaseController extends Controller
{
    public function show(): JsonResponse
    {
        $android = AppReleases::latest();

        // The iPhone has no file to download: it installs the web app from Safari until the App Store (README section 11).
        // [Sprint 19 B1] The app's Firebase settings (not secret), so pushes start without a new build; null until set.
        return response()->json(['android' => $android ? AppReleases::card($android) : null, 'ios' => null, 'firebase' => Fcm::client()]);
    }

    public function download(): BinaryFileResponse
    {
        $r = AppReleases::latest();
        abort_unless($r && is_file(AppReleases::path((int) $r->id)), 404, 'لا نسخة للتنزيل الآن.');
        DB::table('app_releases')->where('id', $r->id)->increment('downloads');
        $name = 'GameLegendManager-'.preg_replace('/[^0-9A-Za-z.\-]/', '', $r->version).'.apk';

        return response()->download(AppReleases::path((int) $r->id), $name, [
            'Content-Type' => 'application/vnd.android.package-archive',
            'Cache-Control' => 'no-store',
        ]);
    }

    public function index(): JsonResponse
    {
        return response()->json(['releases' => DB::table('app_releases')->where('status', '!=', 'removed')->orderByDesc('id')->limit(20)->get()
            ->map(fn ($r) => AppReleases::card($r))->all(), 'chunk_kb' => (int) config('game.app.chunk_kb'), 'max_mb' => (int) config('game.app.max_mb')]);
    }

    public function start(Request $request): JsonResponse
    {
        $data = $request->validate(['version' => ['required', 'string', 'max:20', 'regex:/^\d+\.\d+\.\d+([+.\-][0-9A-Za-z.]+)?$/'],
            'bytes' => ['required', 'integer', 'min:1'], 'notes' => ['nullable', 'string', 'max:1000']],
            ['version.regex' => 'النسخة بأرقام مثل 1.0.0.']);
        $id = AppReleases::start($data['version'], (int) $data['bytes'], $data['notes'] ?? null, $request->user()->id);

        return response()->json(['id' => $id, 'chunk_kb' => (int) config('game.app.chunk_kb')], 201);
    }

    /** A piece of the file as the request's raw body, at ?offset=. */
    public function chunk(Request $request, int $id): JsonResponse
    {
        $offset = (int) $request->query('offset', -1);
        $bytes = $request->getContent();
        abort_if($offset < 0 || $bytes === '' || strlen($bytes) > (int) config('game.app.chunk_kb') * 1024, 422, 'قطعة غير صالحة.');

        return response()->json(['received' => AppReleases::chunk($id, $offset, $bytes)]);
    }

    public function finish(int $id): JsonResponse
    {
        return response()->json(['release' => AppReleases::finish($id)]);
    }

    public function destroy(int $id): JsonResponse
    {
        AppReleases::delete($id);

        return response()->json(['ok' => true]);
    }
}
