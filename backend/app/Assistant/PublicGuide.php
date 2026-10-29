<?php

namespace App\Assistant;

/**
 * [X59] The game's guide as a public page (the owner's request 2026-10-29): the Assistant Coach's own explanations,
 * open to visitors and search engines, so the site shows what the game is before signing in (as Google AdSense asks
 * of a site). Grouped in sections by each topic's first page; the assistant's own topic stays in the assistant.
 */
class PublicGuide
{
    /** The sections in order, each with the guide's pages it gathers. */
    private const SECTIONS = [
        'start' => ['home', 'leagues', 'profile', 'wallet', 'support', 'inbox'],
        'club' => ['club', 'quests', 'friendlies'],
        'squad' => ['team', 'lineup'],
        'tactics' => ['tactics'],
        'training' => ['training', 'specialists'],
        'market' => ['market', 'scout'],
        'stadium' => ['stadium', 'finance'],
        'match' => ['match', 'fixtures', 'stats'],
        'league' => ['league', 'newspaper', 'predictions'],
    ];

    private const TITLES = [
        'start' => ['البداية والحساب', 'Getting started'],
        'club' => ['ناديك', 'Your club'],
        'squad' => ['اللاعبون والتشكيلة', 'Players and lineup'],
        'tactics' => ['التكتيك', 'Tactics'],
        'training' => ['التدريب والجهاز الفني', 'Training and staff'],
        'market' => ['السوق والكشاف', 'Market and scout'],
        'stadium' => ['الملعب والمالية', 'Stadium and money'],
        'match' => ['المباراة', 'The match'],
        'league' => ['الدوري والكأس', 'League and cup'],
    ];

    /** @return list<array{id: string, title: string, topics: list<array{id: string, q: string, a: string}>}> */
    public static function sections(string $l): array
    {
        $of = [];
        foreach (self::SECTIONS as $section => $pages) {
            foreach ($pages as $page) {
                $of[$page] ??= $section;
            }
        }
        $grouped = array_fill_keys(array_keys(self::SECTIONS), []);
        foreach (Guide::topics($l) as $t) {
            if ($t['id'] === 'about' || trim($t['a']) === '') {
                continue;
            }
            $grouped[$of[$t['pages'][0] ?? 'home'] ?? 'start'][] = ['id' => $t['id'], 'q' => $t['q'], 'a' => $t['a']];
        }

        return array_values(array_filter(array_map(fn ($id) => ['id' => $id, 'title' => self::TITLES[$id][$l === 'en' ? 1 : 0], 'topics' => $grouped[$id]],
            array_keys(self::SECTIONS)), fn ($s) => $s['topics'] !== []));
    }
}
