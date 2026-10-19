<?php

// Calibratable game values (docs/PLAN.md section 3). Anything the engine reads
// is an integer (basis points for ratios) and is copied into each match's
// config_snapshot, so editing this file never changes a running match.

return [
    'match' => [
        'half_length' => 45, 'extra_half_length' => 15,
        'tick_ms' => 3000, 'halftime_seconds' => 15,
        'extra_time_tick_ms' => 2000, 'extra_time_break_seconds' => 10,
        'stoppage_first_half' => [1, 3], 'stoppage_second_half' => [2, 6], 'stoppage_extra_time' => [0, 2],
        'lock_minutes_before' => 5, 'referee_minutes_before' => 30,
        'subs' => 3, 'extra_time_subs' => 1,
        // كل النسب بنقاط الأساس (10000 = 100%) لأن المحرك يعمل بأرقام صحيحة فقط
        'favourite_win_rate_bp' => 6700,       // الهدف للمعايرة
        'captain_bonus_bp' => 100, 'captain_min_fitness' => 50,
        'home_base_bp' => 250,                     // ميزة أساسية لكل فريق على أرضه
        'home_pitch_bp' => [0, 100, 200, 300],    // فوقها حسب مرحلة أرضية الملعب
        // مدة عرض كل دقيقة حسب لقطتها [MATCH_VIEW 4.5، MOMENTS.md]: الهادئة سريعة، واللقطة تأخذ وقتها
        'moment_ms' => [
            // A whole match plays in about three minutes (PLAN 2.24): quiet minutes fly by, each scene has its length.
            'quiet' => 450, 'attack' => 1100, 'stoppage' => 2200, 'shootout' => 2600, 'whistle' => 3200, 'coach' => 4200,
            'offside' => 4000, 'miss' => 3800, 'save' => 4600, 'corner' => 4200, 'goal' => 7400,
            'yellow' => 4400, 'red' => 5600, 'free_kick' => 5800, 'free_kick_goal' => 7000,
            'penalty' => 6600, 'penalty_goal' => 7400, 'sub' => 3800, 'injury' => 3800,
        ],
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
        'attack_rate_bp' => 5300,                 // هجمات في الدقيقة للفريقين معاً
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
        // Phase duels: success = base + slope × (attack − defence in rating points), clamped to floor..ceiling
        'phase_base_bp' => ['build' => 8000, 'progress' => 7500, 'create' => 8200, 'header' => 3500],
        'phase_slope_bp' => 22,              // per rating point of difference
        'share_slope_bp' => 40,              // initiative share per point of midfield difference
        'goal_base_bp' => ['big' => 2000, 'normal' => 600, 'half' => 285, 'long' => 360, 'header' => 450],
        'goal_slope_bp' => 18,               // per point of shooter − keeper
        'penalty_goal_bp' => 7600, 'free_kick_goal_bp' => 700,
        'on_target_bp' => 4600, 'corner_after_save_bp' => 3000,
        'press_bonus_cp' => 4,               // defence bonus in build-up per pressing point above 50
        'tempo_precision_cp' => 3,           // own precision loss per tempo point above 50
        'counter_base_bp' => 3200, 'counter_plan_bp' => 1600, 'counter_bonus_cp' => 150,
        'trap_base_bp' => 3500, 'trap_fail_bonus_cp' => 600,
        'foul_bp' => [800, 1300, 1900, 2700], // per lost duel, by tackling level
        'card_bp' => [1300, 1950, 2850, 3900], // per foul, by tackling level
        'referee_bp' => [7000, 10000, 13500], // soft, medium, strict
        'dogso_red_bp' => 300,
        'midfield_foul_bp' => 2300,          // per quiet minute: ordinary fouls away from danger
        'penalty_share_bp' => 700,          // fouls at the box that are inside it
        'offside_bp' => ['long' => 1500, 'counter' => 1200, 'passing' => 450, 'wings' => 350, 'shots' => 200],
        'injury_bp' => [200, 300, 450, 700],
        'man_down_cp' => 350,
        'captain_cp' => 80,
        'trailing_push_bp_per_minute' => 50,
        'late_open_bp_per_minute' => 30,     // the game opens up after minute 75
        'late_lapse_cp_per_minute' => 14,    // tired defences lose concentration after minute 70
        'stoppage' => [1 => [1, 3], 2 => [2, 6], 3 => [0, 2], 4 => [0, 2]],
        'bot_personalities' => ['giants', 'defenders', 'pressers', 'hard', 'wingers', 'adaptive'],
    ],
    'clock' => ['dev_round_minutes' => 1],
    'simulator' => ['enabled' => (bool) env('SIMULATOR_ENABLED', env('APP_ENV', 'production') !== 'production')],
    'app' => ['min_version' => '1.0.0', 'token_ttl_days' => 30],
    'monitoring' => ['ntfy_topic' => env('NTFY_TOPIC')],
    'stadium' => ['stages' => 3, 'parts_per_stage' => 5, 'part_hours' => 18],
];
