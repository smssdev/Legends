<?php

namespace App\Auth;

/** Who Google says signed in: from Socialite on the web or from an id_token from the app. */
final class GoogleIdentity
{
    public function __construct(
        public readonly string $sub,
        public readonly string $email,
        public readonly bool $emailVerified,
        public readonly string $name,
        // [UP5] Google's picture, the coach's own until they upload one.
        public readonly ?string $picture = null,
    ) {}
}
