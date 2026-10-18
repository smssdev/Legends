<?php

// Calibratable game values (docs/PLAN.md section 3). Anything the engine reads
// is an integer (basis points for ratios) and is copied into each match's
// config_snapshot, so editing this file never changes a running match.

return [
    'match' => [
        'half_length' => 45, 'extra_half_length' => 15,
        'tick_ms' => 3000, 'halftime_seconds' => 30,
        'extra_time_tick_ms' => 2000, 'extra_time_break_seconds' => 10,
        'stoppage_first_half' => [1, 3], 'stoppage_second_half' => [2, 6], 'stoppage_extra_time' => [0, 2],
        'lock_minutes_before' => 5, 'referee_minutes_before' => 30,
        'subs' => 3, 'extra_time_subs' => 1,
        // كل النسب بنقاط الأساس (10000 = 100%) لأن المحرك يعمل بأرقام صحيحة فقط
        'favourite_win_rate_bp' => 6700,       // الهدف للمعايرة
        'captain_bonus_bp' => 100, 'captain_min_fitness' => 50,
        'home_base_bp' => 250,                     // ميزة أساسية لكل فريق على أرضه
        'home_pitch_bp' => [0, 100, 200, 300],    // فوقها حسب مرحلة أرضية الملعب
    ],
    'league' => [
        'lock_last_bp' => 2500, 'absence_days' => 3,
        'absence_warning_hours' => 48, 'max_active_teams' => 4,
        'vacation_max_days' => 7, 'vacation_per_season' => 1,
        'min_teams' => 4, 'max_teams' => 20, 'code_length' => 8,
        'reference_season_days' => 37, 'strength_top_players' => 18,
    ],
    'economy' => [
        'starting_budget' => 3_000_000,
        'handover_min' => 500_000,               // والحد الأعلى = starting_budget
        // من جهة المدرب
        'buy_from_pool_bp' => 10000, 'sell_to_pool_bp' => 7000,
        'buy_from_bot_bp' => 12500,
        'human_trade_min_bp' => 5000, 'human_trade_max_bp' => 20000,
        'pair_net_transfer_cap_bp' => 2500,   // من ميزانية البداية، لكل ناديين في الموسم
        'same_pair_player_moves_per_season' => 1,
        'debt_rounds_before_forced_sale' => 3,
        'pool_size' => 300,
        'round_base_income' => null, 'win_bonus' => null, 'draw_bonus' => null,
        'salary_ratio_per_round' => null,   // تُحدد بعد الاستيراد
    ],
    'training' => ['slots' => 4, 'tick_hours' => 8, 'progress_scale' => 10000,
        'season_gain_target' => [3, 5]],
    'engine' => [
        'version' => 1,
        // القيم مبدئية وتُضبط بأدوات المحاكاة (docs/ENGINE.md 9)
        'overall_weight' => 60, 'attributes_weight' => 40,
        'attack_rate_bp' => 5800,                 // هجمات في الدقيقة للفريقين معاً
        'phase_floor_bp' => 800, 'phase_ceiling_bp' => 9200,
        'funnel_target_bp' => ['build' => 8000, 'progress' => 7500, 'create' => 7500],
        'matchup_cp' => [                         // خطة الهجوم × شكل دفاع الخصم (عالٍ، متوسط، منخفض)، بمئات النقطة
            'counter' => [300, 0, -300], 'long_balls' => [200, -100, -100],
            'passing' => [-100, 200, -100], 'wings' => [-200, 0, 200],
            'long_shots' => [-200, -100, 300],
        ],
        'tackling_bonus_cp' => [0, 50, 100, 200], // قانوني، عادي، حماس، خشونة
        'fitness_drain_base' => 28, 'fitness_drain_pressing_max' => 17, 'fitness_drain_tempo_max' => 8,
        'red_card_drain_bp' => 11500,
        'trailing_push_from_minute' => 60,
        'tactics_max_win_bp' => 5800,             // شرط sim:matrix
        'live_reading_every_minutes' => 15,
        'bot_personalities' => ['giants', 'defenders', 'pressers', 'hard', 'wingers', 'adaptive'],
    ],
    'clock' => ['dev_round_minutes' => 1],
    'app' => ['min_version' => '1.0.0', 'token_ttl_days' => 30],
    'monitoring' => ['ntfy_topic' => env('NTFY_TOPIC')],
    'stadium' => ['stages' => 3, 'parts_per_stage' => 5, 'part_hours' => 18],
];
