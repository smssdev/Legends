<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\ClientFrames;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Validation\Rule;

/**
 * [Sprint 74 P2] POST /client-frames: a session's frame counts from the app, per screen. Open to anyone (as the errors:
 * no account is read), 4 KB at most, limited per address; counts only.
 */
class ClientFramesController extends Controller
{
    public const MAX_BYTES = 4096;

    public function store(Request $request): Response
    {
        abort_if(strlen((string) $request->getContent()) > self::MAX_BYTES, 413, 'التقرير أكبر من المسموح.');
        $r = $request->validate([
            'platform' => ['required', Rule::in(ClientFrames::PLATFORMS)],
            'version' => 'required|string|max:20',
            'tier' => ['required', Rule::in(ClientFrames::TIERS)],
            'screens' => 'required|array|min:1|max:20',
            'screens.*.path' => 'required|string|max:500',
            'screens.*.frames' => 'required|integer|min:0',
            'screens.*.late16' => 'required|integer|min:0',
            'screens.*.late33' => 'required|integer|min:0',
        ]);
        ClientFrames::record($r);

        return response()->noContent();
    }
}
