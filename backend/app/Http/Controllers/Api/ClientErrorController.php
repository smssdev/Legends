<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\ClientErrors;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Validation\Rule;

/**
 * [Sprint 66 B1] POST /client-errors: an error the web or the app met on a player's device. Open to anyone (an error can
 * come before signing in), 4 KB at most, limited per address; nothing that names the player is read or kept.
 */
class ClientErrorController extends Controller
{
    public const MAX_BYTES = 4096;

    public function store(Request $request): Response
    {
        abort_if(strlen((string) $request->getContent()) > self::MAX_BYTES, 413, 'التقرير أكبر من المسموح.');
        $e = $request->validate([
            'platform' => ['required', Rule::in(ClientErrors::PLATFORMS)],
            'version' => 'required|string|max:20',
            'path' => 'nullable|string|max:500',
            'message' => 'required|string|max:1000',
            'stack' => 'nullable|string|max:3000',
        ]);
        ClientErrors::record($e);

        return response()->noContent();
    }
}
