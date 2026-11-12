<?php

namespace App\Http\Security;

/**
 * [Sprint 51 B1, B2] The security headers of every answer, in one place for both ways a page leaves the server: Laravel
 * (SecurityHeaders, the API and its pages) and the web server's router (deploy/docker/router.php), which sends the Vue
 * app's page and the built files before Laravel boots. Plain PHP with no framework call, so the router can require
 * this file on its own.
 *
 * Two policies: the enforced one closes only what the app never uses (plugins, framing, a foreign <base>, forms posting
 * elsewhere); the full one (scripts, connections, images, frames…) is sent in report-only mode first, its violations
 * logged by POST /api/v1/csp-report, and becomes the enforced one once a week of reports is clean.
 */
final class SecurityPolicy
{
    /** The browser features the game may use: the microphone for the groups' voice notes (2026-11-09), nothing else. */
    public const PERMISSIONS = 'camera=(), microphone=(self), geolocation=(), payment=(), usb=()';

    /** Where the report-only policy's violations go. */
    public const REPORT_PATH = '/api/v1/csp-report';

    /** The enforced policy: nothing the game, Unity's WebGL or Reverb need. */
    public const ENFORCED_CSP = "object-src 'none'; base-uri 'self'; frame-ancestors 'self'; form-action 'self' https://accounts.google.com";

    /** Google's ad and measurement hosts (AdSense, Analytics 4, its ad-quality checks) and the Meta Pixel. */
    private const GOOGLE = 'https://*.google.com https://*.googlesyndication.com https://*.doubleclick.net https://*.gstatic.com https://*.adtrafficquality.google';

    /**
     * The headers for one answer.
     *
     * @param  bool  $secure  The request came over HTTPS (HSTS only then).
     * @param  list<string>  $scriptHashes  The page's own inline scripts ('sha256-…'), so the full policy allows them by
     *                                      hash and not by 'unsafe-inline'.
     * @return array<string, string>
     */
    public static function headers(bool $secure, array $scriptHashes = []): array
    {
        $h = [
            'X-Content-Type-Options' => 'nosniff',
            'X-Frame-Options' => 'SAMEORIGIN',
            'Referrer-Policy' => 'strict-origin-when-cross-origin',
            'Permissions-Policy' => self::PERMISSIONS,
            'Cross-Origin-Opener-Policy' => 'same-origin-allow-popups',
            'Content-Security-Policy' => self::ENFORCED_CSP,
            'Content-Security-Policy-Report-Only' => self::fullPolicy($scriptHashes),
        ];
        if ($secure) {
            $h['Strict-Transport-Security'] = 'max-age=31536000; includeSubDomains';
        }

        return $h;
    }

    /** @param  list<string>  $scriptHashes */
    public static function fullPolicy(array $scriptHashes = []): string
    {
        $hashes = implode(' ', array_map(fn ($h) => "'{$h}'", $scriptHashes));
        $directives = [
            "default-src 'self'",
            // Unity's WebGL build compiles WebAssembly; the Vue templates are compiled at build time (no eval).
            trim("script-src 'self' 'wasm-unsafe-eval' {$hashes} https://www.googletagmanager.com https://connect.facebook.net ".self::GOOGLE),
            // Tailwind's build and the components' inline style attributes. [Sprint 58 W2] Every font is our own (no Google Fonts).
            "style-src 'self' 'unsafe-inline'",
            "font-src 'self'",
            "img-src 'self' data: blob: https:",
            "media-src 'self' blob:",
            // Reverb's WebSocket on the site's own host, and the measurement hosts.
            "connect-src 'self' wss: https://*.google-analytics.com https://*.analytics.google.com https://www.googletagmanager.com https://www.facebook.com ".self::GOOGLE,
            "frame-src 'self' https://www.facebook.com ".self::GOOGLE,
            "worker-src 'self' blob:",
            "object-src 'none'",
            "base-uri 'self'",
            "frame-ancestors 'self'",
            "form-action 'self' https://accounts.google.com",
            'report-uri '.self::REPORT_PATH,
        ];

        return implode('; ', $directives);
    }

    /**
     * The 'sha256-…' of each inline script that runs (no src, and not a data block such as JSON-LD), as CSP hashes them:
     * the exact text between the tags.
     *
     * @return list<string>
     */
    public static function inlineScriptHashes(string $html): array
    {
        preg_match_all('#<script\b([^>]*)>(.*?)</script>#is', $html, $m, PREG_SET_ORDER);
        $hashes = [];
        foreach ($m as [, $attrs, $body]) {
            if (preg_match('/\bsrc\s*=/i', $attrs)) {
                continue;
            }
            if (preg_match('/\btype\s*=\s*["\']?([^"\'\s>]+)/i', $attrs, $t) && ! in_array(strtolower($t[1]), ['text/javascript', 'module', 'application/javascript'], true)) {
                continue;
            }
            $hashes[] = 'sha256-'.base64_encode(hash('sha256', $body, true));
        }

        return array_values(array_unique($hashes));
    }
}
