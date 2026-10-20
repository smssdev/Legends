<?php

namespace App\Auth;

use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * Checks a Google id_token from the app [PLAN 2.17]: Google's signature (its public keys, cached
 * for an hour), the issuer, the expiry, and that it was made for one of our client ids (aud).
 * Returns null for anything that does not pass.
 */
class GoogleTokenVerifier
{
    private const ISSUERS = ['accounts.google.com', 'https://accounts.google.com'];

    public function verify(string $idToken): ?GoogleIdentity
    {
        $audiences = config('services.google.audiences', []);
        if ($audiences === []) {
            return null;
        }
        try {
            JWT::$leeway = 30;
            $claims = (array) JWT::decode($idToken, JWK::parseKeySet($this->keys()));
        } catch (Throwable) {
            return null;
        }
        if (! in_array($claims['iss'] ?? '', self::ISSUERS, true) || ! in_array($claims['aud'] ?? '', $audiences, true)) {
            return null;
        }
        if (empty($claims['sub']) || empty($claims['email'])) {
            return null;
        }
        $verified = ($claims['email_verified'] ?? false) === true || ($claims['email_verified'] ?? '') === 'true';

        return new GoogleIdentity((string) $claims['sub'], strtolower((string) $claims['email']), $verified, (string) ($claims['name'] ?? ''));
    }

    /** Google's current signing keys (JWKS). */
    protected function keys(): array
    {
        return Cache::remember('google.certs', 3600, fn () => Http::timeout(5)->get(config('services.google.certs_url'))->throw()->json());
    }
}
