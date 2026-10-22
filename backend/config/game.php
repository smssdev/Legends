<?php

// Calibratable game values (docs/PLAN.md section 3). Anything the engine reads
// is an integer (basis points for ratios) and is copied into each match's
// config_snapshot, so editing this file never changes a running match.

return [
    'match' => [
        'half_length' => 45, 'extra_half_length' => 15,
        'tick_ms' => 3000, 'halftime_seconds' => 30,
        // A match between friends kicks off this long after it is made or started: both coaches see the
        // preview and can change their plan before the whistle (the half-time break is as long).
        'kickoff_ms' => 30000,
        // A live minute is made this long before it starts, so both screens have it in time and play it together.
        'live_lead_ms' => 1200,
        // A coach's reactions in a match between friends: at most one this often.
        'reaction_gap_ms' => 1200,
        'reactions' => ['fire', 'clap', 'wow', 'laugh', 'angry', 'pray', 'unlucky', 'coming', 'easy', 'focus'],
        // A breath after each scene before the next minute: the timeline and the clock on screen (not after quiet minutes).
        'scene_gap_ms' => 1800,
        'extra_time_tick_ms' => 2000, 'extra_time_break_seconds' => 10,
        'stoppage_first_half' => [1, 3], 'stoppage_second_half' => [2, 6], 'stoppage_extra_time' => [0, 2],
        'lock_minutes_before' => 5, 'referee_minutes_before' => 30,
        'subs' => 3, 'extra_time_subs' => 1,
        // كل النسب بنقاط الأساس (10000 = 100%) لأن المحرك يعمل بأرقام صحيحة فقط
        'favourite_win_rate_bp' => 6700,       // الهدف للمعايرة
        'captain_bonus_bp' => 100, 'captain_min_fitness' => 50,
        'home_base_bp' => 500,                     // ميزة أساسية لكل فريق على أرضه
        'home_pitch_bp' => [0, 100, 200, 300],    // فوقها حسب مرحلة أرضية الملعب
        // مدة عرض كل دقيقة حسب لقطتها [MATCH_VIEW 4.5، MOMENTS.md]: الهادئة سريعة، واللقطة تأخذ وقتها
        'moment_ms' => [
            // A whole match plays in about three minutes (PLAN 2.24): quiet minutes fly by, each scene has its length.
            'quiet' => 450, 'attack' => 1100, 'stoppage' => 2200, 'shootout' => 2600, 'whistle' => 3200, 'coach' => 4200,
            'offside' => 4000, 'miss' => 7000, 'save' => 7600, 'corner' => 4200, 'goal' => 8400,
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
        // What the owner may choose [PLAN 2.3]
        'prep_days' => [1, 3], 'rounds_per_day' => [1, 2], 'starts_within_days' => 7,
        // Tries at a league code per account each minute [PLAN 2.1]
        'join_attempts_per_minute' => 10,
    ],
    'economy' => [
        'starting_budget' => 3_000_000,
        'starting_budget_min' => 1_000_000, 'starting_budget_max' => 10_000_000,   // what the owner may choose
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
    // A player's value in club money [PLAN 2.6]: from his rating, then his age, line and room to grow.
    // Integers only; each multiplier in basis points. Calibrated in Sprint 11 (docs/sprints/sprint-11.md).
    'valuation' => [
        // rating => value; between two points the value runs in a straight line
        'by_overall' => [40 => 10_000, 50 => 30_000, 55 => 60_000, 60 => 120_000, 65 => 250_000, 70 => 500_000,
            75 => 1_100_000, 80 => 2_500_000, 85 => 6_000_000, 88 => 11_000_000, 91 => 20_000_000, 99 => 45_000_000],
        // age => multiplier from that age up
        'age_bp' => [0 => 13000, 20 => 12500, 22 => 11500, 24 => 10000, 28 => 9000, 30 => 8000, 31 => 7000, 32 => 6000, 33 => 5000, 34 => 4000],
        'line_bp' => ['gk' => 8000, 'def' => 9000, 'mid' => 10000, 'att' => 11000],
        'potential_bp_per_point' => 150,      // each point of room to grow
        'round_to' => [100_000 => 1_000, 1_000_000 => 10_000, PHP_INT_MAX => 100_000],
    ],
    'training' => ['slots' => 4, 'tick_hours' => 8, 'progress_scale' => 10000,
        'season_gain_target' => [3, 5]],
    // Calibration targets for sim:balance (docs/ENGINE.md 9.1). Read by the tools only, never by the engine,
    // so they are not in a match's config_snapshot. Each is [min, max] per match (percentages as 0..100).
    'balance' => [
        'league' => 'Premier League',
        'nightly' => (bool) env('GAME_NIGHTLY_BALANCE', false),   // the home server turns it on (docs/HOME_SERVER.md)
        'favourite_gap_points' => 18,          // the strongest club against one this many points weaker
        'targets' => [
            'goals/match' => [2.6, 2.9],
            '0-0_%' => [6, 9],
            'home_win_%' => [42, 48], 'draw_%' => [22, 28], 'away_win_%' => [27, 33],
            'shots/team' => [10.5, 13.5], 'on_target/team' => [4, 5],
            'yellow/match' => [3.5, 4.5], 'red/match' => [0.07, 0.15],
            'penalties/match' => [0.2, 0.3], 'injuries/match' => [0.2, 0.3], 'offsides/match' => [2, 4],
            'late_goals_%' => [22, 27],
            'favourite_win_%' => [65, 70],
        ],
        // Knob isolation (ENGINE 9.2): moving one knob from low to high on equal teams must move these the
        // given way (+1 up, -1 down) and leave the win rate within max_win_shift points.
        'knobs' => [
            'pressing' => ['from' => 0, 'to' => 100, 'expect' => ['presses_won_home' => 1, 'yellow_home' => 1, 'fitness_65_home_%' => -1]],
            'tempo' => ['from' => 0, 'to' => 100, 'expect' => ['attacks_home' => 1, 'fitness_65_home_%' => -1]],
            'tackling' => ['from' => 0, 'to' => 3, 'expect' => ['yellow_home' => 1, 'red_home_%' => 1]],
            'style' => ['from' => 0, 'to' => 100, 'expect' => ['goals_home' => 1, 'counters_away' => 1]],
            'trap' => ['from' => 0, 'to' => 1, 'against' => ['plan' => 'long'], 'expect' => ['offsides_away' => 1]],
        ],
        'max_win_shift' => 3,
    ],
    'engine' => [
        'version' => 2,
        // القيم مبدئية وتُضبط بأدوات المحاكاة (docs/ENGINE.md 9)
        'overall_weight' => 60, 'attributes_weight' => 40,
        'attack_rate_bp' => 4500,                 // هجمات في الدقيقة للفريقين معاً
        'phase_floor_bp' => 800, 'phase_ceiling_bp' => 9200,
        'funnel_target_bp' => ['build' => 8000, 'progress' => 7500, 'create' => 7500],
        'matchup_cp' => [                         // خطة الهجوم × شكل دفاع الخصم (عالٍ، متوسط، منخفض)، بمئات النقطة
            'counter' => [300, 0, -300], 'long_balls' => [200, -100, -100],
            'passing' => [-100, 200, -100], 'wings' => [-200, 0, 200],
            'long_shots' => [-200, -100, 300],
        ],
        'tackling_bonus_cp' => [0, 20, 30, 40],   // قانوني، عادي، حماس، خشونة
        'fitness_drain_base' => 28, 'fitness_drain_pressing_max' => 17, 'fitness_drain_tempo_max' => 8,
        'red_card_drain_bp' => 11500,
        'trailing_push_from_minute' => 60,
        'tactics_max_win_bp' => 5800,             // شرط sim:matrix
        'live_reading_every_minutes' => 15,
        // Phase duels: success = base + slope × (attack − defence in rating points), clamped to floor..ceiling
        'phase_base_bp' => ['build' => 8000, 'progress' => 7500, 'create' => 8200, 'header' => 3500],
        'phase_slope_bp' => 17,              // per rating point of difference
        'share_slope_bp' => 30,              // initiative share per point of midfield difference
        'home_share_bp' => 450,              // the home side has the ball more (of 10000, on its own ground)
        'style_share_bp' => 5,               // initiative share per point of attacking style over the opponent's
        'goal_base_bp' => ['big' => 2000, 'normal' => 600, 'half' => 285, 'long' => 1000, 'header' => 450],
        'goal_slope_bp' => 12,               // per point of shooter − keeper
        'penalty_goal_bp' => 7600, 'free_kick_goal_bp' => 700,
        'on_target_bp' => 3700, 'corner_after_save_bp' => 3000,
        'press_bonus_cp' => 4,               // defence bonus in build-up per pressing point above 50
        'tempo_precision_cp' => 3,           // own precision loss per tempo point above 50
        'counter_base_bp' => 3200, 'counter_plan_bp' => 1600, 'counter_bonus_cp' => 150,
        'trap_base_bp' => 3500, 'trap_fail_bonus_cp' => 600,
        'foul_bp' => [800, 1300, 1900, 2700], // per lost duel, by tackling level
        'card_bp' => [1300, 1950, 2850, 3900], // per foul, by tackling level
        'referee_bp' => [7000, 10000, 13500], // soft, medium, strict
        'dogso_red_bp' => 120,
        'second_yellow_spare_bp' => 8000,    // a booked player's next yellow is let go this often
        'midfield_foul_bp' => 2300,          // per quiet minute: ordinary fouls away from danger
        'midfield_card_pct' => 110,           // of the card chance for a foul near goal (card_bp)
        'penalty_share_bp' => 700,           // fouls at the box that are inside it
        'progress_free_kick_bp' => 5000,     // fouls in midfield that still leave a free kick in range
        'offside_bp' => ['long' => 1900, 'counter' => 1500, 'passing' => 560, 'wings' => 440, 'shots' => 250],
        'injury_bp' => [170, 250, 380, 600],
        'man_down_cp' => 350,
        'captain_cp' => 80,
        'trailing_push_bp_per_minute' => 50,
        'late_open_bp_per_minute' => 30,     // the game opens up after minute 75
        'late_lapse_cp_per_minute' => 14,    // tired defences lose concentration after minute 70
        'stoppage' => [1 => [1, 3], 2 => [2, 6], 3 => [0, 2], 4 => [0, 2]],
        'bot_personalities' => ['giants', 'defenders', 'pressers', 'hard', 'wingers', 'adaptive'],
    ],
    'clock' => ['dev_round_minutes' => 1, 'file' => storage_path('app/game-clock.json')],
    'simulator' => ['enabled' => (bool) env('SIMULATOR_ENABLED', env('APP_ENV', 'production') !== 'production')],
    // The game's names (owner's decision, 2026-10-20): الأساطير, and its premium currency الكوينز.
    'brand' => ['name' => 'الأساطير', 'name_latin' => 'Legends', 'premium_currency' => 'الكوينز'],
    'app' => ['min_version' => '1.0.0', 'token_ttl_days' => 30],
    'monitoring' => ['ntfy_topic' => env('NTFY_TOPIC')],
    'stadium' => ['stages' => 3, 'parts_per_stage' => 5, 'part_hours' => 18],
];
