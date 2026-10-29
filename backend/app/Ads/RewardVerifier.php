<?php

namespace App\Ads;

/**
 * The ad provider's check of a rewarded video [Sprint 21 E9]. The provider is the owner's choice (README section 11);
 * until then the driver is DisabledVerifier and no video cuts anything. A real driver asks the provider (its server
 * side verification) whether this token is a video this account watched to the end, and returns the provider's own
 * id for that reward, or null.
 */
interface RewardVerifier
{
    public function name(): string;

    public function verify(string $token, int $userId): ?string;
}
