<?php

namespace Tests\Feature;

use Tests\TestCase;

/** [Sprint 62 B1] Android's App Links file: the release key's fingerprint from the server's setting, or nothing. */
class AssetLinksTest extends TestCase
{
    public function test_no_fingerprint_set_no_file(): void
    {
        config(['game.app.android_cert_sha256' => '']);
        $this->get('/.well-known/assetlinks.json')->assertNotFound();
    }

    public function test_the_app_may_open_the_sites_links_with_its_keys(): void
    {
        config(['game.app.android_cert_sha256' => 'AA:BB:CC, DD:EE:FF']);
        $this->get('/.well-known/assetlinks.json')
            ->assertOk()
            ->assertHeader('Content-Type', 'application/json')
            ->assertExactJson([[
                'relation' => ['delegate_permission/common.handle_all_urls'],
                'target' => ['namespace' => 'android_app', 'package_name' => 'online.gamelegendmanager.glm', 'sha256_cert_fingerprints' => ['AA:BB:CC', 'DD:EE:FF']],
            ]]);
    }
}
