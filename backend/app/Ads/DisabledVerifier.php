<?php

namespace App\Ads;

/** No provider chosen yet (game.ads.driver = none): every token is refused. */
class DisabledVerifier implements RewardVerifier
{
    public function name(): string
    {
        return 'none';
    }

    public function verify(string $token, int $userId): ?string
    {
        return null;
    }
}
