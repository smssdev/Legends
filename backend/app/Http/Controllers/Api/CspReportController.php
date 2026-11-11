<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Log;

/**
 * [Sprint 51 B2] POST /csp-report: what the full Content-Security-Policy (sent in report-only mode,
 * App\Http\Security\SecurityPolicy) would have blocked, as the browser reports it. Written to the log in one short line
 * (the directive, the blocked address and the page, never the query strings), so a week of clean reports lets the policy
 * be enforced. Open to anyone (the browser sends no session), limited per address.
 */
class CspReportController extends Controller
{
    public function store(Request $request): Response
    {
        $body = json_decode(substr((string) $request->getContent(), 0, 8192), true);
        // The old format ({"csp-report": {...}}) and the Reporting API's ([{type, body: {...}}]).
        $report = $body['csp-report'] ?? ($body[0]['body'] ?? null);
        if (is_array($report)) {
            $clip = fn ($v) => mb_substr(strtok((string) ($v ?? ''), '?') ?: '', 0, 200);
            Log::warning('csp', [
                'directive' => $clip($report['effective-directive'] ?? $report['effectiveDirective'] ?? $report['violated-directive'] ?? ''),
                'blocked' => $clip($report['blocked-uri'] ?? $report['blockedURL'] ?? ''),
                'page' => $clip($report['document-uri'] ?? $report['documentURL'] ?? ''),
                'line' => (int) ($report['line-number'] ?? $report['lineNumber'] ?? 0),
            ]);
        }

        return response()->noContent();
    }
}
