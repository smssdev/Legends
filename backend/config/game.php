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
        // The league broadcast [X24]: a boo or a cheer for one side at most this often per viewer, the side chat's
        // pace and length, and how many of each the live poll carries.
        'cheer_gap_ms' => 30000, 'chat_gap_ms' => 2000, 'chat_max' => 140, 'chat_kept' => 50, 'reactions_kept' => 20,
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
        'home_pitch_bp' => [0, 100, 200, 300],    // فوقها حسب مرحلة أرضية الملعب [PLAN 2.9، السبرنت 29]
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
        'absence_warning_hours' => 48, 'max_active_teams' => 10,   // the coach's slots: a team in each of up to 10 leagues [X18, 2026-10-25]
        'vacation_max_days' => 7, 'vacation_per_season' => 1,
        'min_teams' => 4, 'max_teams' => 20, 'code_length' => 8,
        'reference_season_days' => 37, 'strength_top_players' => 18,
        // What the owner may choose [PLAN 2.3]
        'prep_days' => [1, 3], 'rounds_per_day' => [1, 2], 'starts_within_days' => 7,
        // Tries at a league code per account each minute [PLAN 2.1]
        'join_attempts_per_minute' => 10,
    ],
    // League matches [PLAN 2.8, 2.12] (read by App\League, not by the engine).
    'matches' => [
        'missed_live_minutes' => 10,      // up to this late a match still starts live; later it is simulated at once
        'rest_recovery' => 30,            // fitness back for a player who rests in his club's match
        'played_recovery' => 8,           // and for one who played, between that match and the next [X21]
        'injury_matches' => [1, 3],       // an injury keeps a player out this many of his club's matches
        'red_card_matches' => 1,
        'runner_sleep_ms' => 200,         // how often matches:run looks at the clock
        // A live match more than this behind (the runner was stopped) goes on from now.
        'stalled_ms' => 5000,
        // A coach whose screen has not asked for his match in this long is away: his assistant manages [ENGINE 7].
        'assistant_after_ms' => 30000,
        // One runner at a time: another one waits this long after the first one stops before it takes over.
        'claim_seconds' => 10,
        // The assistant's live reading to his coach [ENGINE 8.2]: about this often in minutes of play, and at once
        // after a goal, a red card or a line under 60% fitness.
        'reading_minutes' => 15,
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
        'offer_hours' => 48,                // an offer between coaches waits this long for an answer
        'debt_rounds_before_forced_sale' => 3,
        'min_squad' => 16,                  // a forced sale never leaves fewer players than this
        'bot_min_squad' => 18, 'min_keepers' => 2,   // a bot club sells no lower than this [PLAN 2.7]
        'pool_size' => 300,
        // The pool renews every pool_hours from the players of every league in the data [X6], as strong as this
        // league: from its pool_level_from_pct percentile of strength to its best, in pool_lines shares per line.
        'pool_hours' => 4, 'pool_level_from_pct' => 40,
        'pool_lines' => ['gk' => 10, 'def' => 30, 'mid' => 35, 'att' => 25],
        // Selling [X6]: the instant sale pays the full value for coins (in a fair league, this share of the value);
        // a listing asks up to the sale cap (130% of the value, the value alone for a player the club bought), and a
        // buyer from outside takes it after a wait from this table (price in bp of value => hours, before the
        // season's scale), give or take jitter_bp.
        'quick_sale_fee_bp' => 1000,
        'sale_cap_bp' => 13000,
        'virtual_buyer' => ['hours_at_bp' => [5000 => 1, 10000 => 6, 13000 => 36], 'jitter_bp' => 2000],
        // Sprint 23 (first numbers, checked by sim:economy; docs/sprints/sprint-23.md). "Scale" is the league's
        // average squad value when it starts, so a small league's money is small like its prices.
        // Wages: this share of the squad's value over a season, paid each league round.
        'wages_bp_per_season' => 300,
        // A home match brings this share of the scale over a season (split over the home matches): sponsors
        // take sponsor_share of it, the tickets the rest at full attendance.
        'home_income_bp_per_season' => 450,
        'sponsor_share_bp' => 5500,
        // The four sectors of the stadium, each with its sponsor, and its share of the sponsors' money.
        'sectors' => ['main' => 3500, 'opposite' => 2500, 'north' => 2000, 'south' => 2000],
        // The sponsor offers per sector: a fixed part of the sector's money each home match, plus a part on a home win.
        'sponsor_offers' => [
            'steady' => ['fixed_bp' => 10000, 'win_bp' => 0],
            'bonus' => ['fixed_bp' => 7000, 'win_bp' => 7000],
            'ambitious' => ['fixed_bp' => 4000, 'win_bp' => 13000],
        ],
        // The stadium at stage 0 (Sprint 29 builds on it): seats, and attendance from the club's strength in its league.
        'stadium' => ['capacity' => 20000, 'attendance_min_bp' => 6000, 'attendance_max_bp' => 10000],
        // A league match's result, as a share of the scale: a bonus for a win, a smaller one for a draw, and a
        // deduction for a loss [X14].
        'win_bonus_bp' => 8, 'draw_bonus_bp' => 3, 'loss_penalty_bp' => 2,
        // Season prizes as a share of the scale: the league by place (from the champion down), and the cup.
        'league_prize_bp' => [100, 70, 50, 35, 25, 15, 10, 5],
        'cup_prize_bp' => ['winner' => 50, 'final' => 25, 'sf' => 10],
        // sim:economy's targets for a season: no mass bankruptcy, and no clear inflation.
        'sim_targets' => ['broke_%_max' => 10, 'median_end_ratio' => [0.7, 2.5], 'money_growth_max' => 2.0],
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
    // Training [PLAN 2.8, Sprint 27]: a session every tick_hours (scaled by the season's length), about
    // season_sessions of them in a season. Calibrated by sim:training (docs/sprints/sprint-27.md).
    'training' => ['slots' => 4, 'tick_hours' => 8, 'progress_scale' => 10000, 'season_sessions' => 111,
        // rating => about how many sessions a +1 takes; between two points in a straight line
        'sessions_by_overall' => [55 => 4, 65 => 6, 75 => 14, 80 => 19, 85 => 23, 89 => 25, 92 => 30, 99 => 40],
        'step_bp' => [5000, 15000],      // each session moves the bar by half to one and a half of the average
        'cost_bp_per_season' => 40,      // one slot busy all season costs this share of the league's money scale
        'season_gain_target' => [3, 5],
        // Open training [X16]: no stop at the potential. Above it each +1 takes this many times the sessions, one more
        // time for every point beyond (at the potential ×3, one above ×5...), up to the ceiling.
        'over_potential_factor' => 2, 'ceiling' => 99],
    // The training camp [docs/features/camp.md, Sprint 28]: players away from matches, training at the camp's pace.
    'camp' => ['max_players' => 5, 'days' => [1, 3], 'min_left' => 16,
        // each level: the session's step and its price, against an ordinary training session (basis points)
        'levels' => ['basic' => ['gain_bp' => 10000, 'cost_bp' => 10000], 'good' => ['gain_bp' => 15000, 'cost_bp' => 20000],
            'elite' => ['gain_bp' => 20000, 'cost_bp' => 35000]]],
    // Secret training [docs/features/secret-training.md, Sprint 28]: one line, the next match only.
    'secret_training' => ['boost' => 3, 'cost_bp' => 20, 'per_season' => 5],
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
            // Chemistry [X22] is not a tactic: from 40 to 100 it must win more, by a few points, not by a class.
            'chem' => ['field' => 'chem', 'from' => 40, 'to' => 100, 'min_shift' => 2, 'max_shift' => 10, 'expect' => ['goals_home' => 1, 'goals_away' => -1]],
        ],
        'max_win_shift' => 3,
    ],
    // Chemistry [X22]: each player is linked to his `neighbours` nearest team-mates; a link is worth its colour,
    // and green also comes from `together_matches` played together for the club. The engine's effect is in engine.chemistry_*.
    'chemistry' => [
        'neighbours' => 2,
        'link_value' => ['green' => 100, 'yellow' => 65, 'red' => 25],
        'together_matches' => 15,
    ],
    'engine' => [
        'version' => 7,
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
        // Fatigue [X21]: per minute, in hundredths of a per cent, for a player of stamina 70. About 18% in a normal
        // match (pressing and tempo at 50), about 24% with the press and the tempo high. Under tired_fit the
        // injuries come tired_injury_bp as often.
        'fitness_drain_base' => 12, 'fitness_drain_pressing_max' => 20, 'fitness_drain_tempo_max' => 8,
        'tired_fit' => 5500, 'tired_injury_bp' => 30000,
        'red_card_drain_bp' => 11500,
        // Chemistry [X22]: from chemistry_high the phases (passing, counters, cover) gain chemistry_high_bp, from
        // the first value at the line up to the second at 100; under chemistry_low they lose up to chemistry_low_bp at 0.
        'chemistry_high' => 85, 'chemistry_high_bp' => [300, 700], 'chemistry_low' => 50, 'chemistry_low_bp' => 600,
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
    'clock' => ['dev_round_minutes' => 1, 'file' => env('GAME_CLOCK_FILE', storage_path('app/game-clock.json'))],
    'simulator' => ['enabled' => (bool) env('SIMULATOR_ENABLED', env('APP_ENV', 'production') !== 'production')],
    // The game's names (owner's decision, 2026-10-20): الأساطير, and its premium currency الكوينز.
    'brand' => ['name' => 'الأساطير', 'name_latin' => 'Legends', 'premium_currency' => 'الكوينز'],
    'app' => ['min_version' => '1.0.0', 'token_ttl_days' => 30],
    // The coach's level on the home screen [X18]: points per win, draw and trophy; each level asks level_step more.
    'career' => ['xp_win' => 3, 'xp_draw' => 1, 'xp_trophy' => 30, 'level_step' => 20],
    // Support [X13]: WhatsApp (the number in international form, digits only) and Telegram (the username, without @),
    // for account and sign-up problems and ideas. A channel left empty has no button.
    'support' => ['whatsapp' => env('SUPPORT_WHATSAPP'), 'telegram' => env('SUPPORT_TELEGRAM'),
        'message' => 'مرحباً، أحتاج مساعدة في لعبة الأساطير: '],
    // The account [X4, 2026-10-24]: a holiday for every league at once, of up to vacation_max_days, and the next one
    // after vacation_rest_days from its end; the picture's largest upload (kilobytes) and its side (pixels).
    // How the coach watches [X9, X10]: the Arabic voices (web/public/commentary/ar/<id>/; base is the first recording)
    // shown as «المعلق 1..6», and the two simulators. Unity opens only once its web build is deployed (Sprint 8).
    'viewing' => ['commentators' => ['base', 'voice-1', 'voice-2', 'voice-3', 'voice-4', 'voice-5', 'voice-6'], 'default_commentator' => 'voice-6',
        'match_views' => ['cartoon', 'unity'], 'unity_ready' => (bool) env('UNITY_BUILD', false)],
    'account' => ['vacation_max_days' => 14, 'vacation_rest_days' => 14, 'avatar_max_kb' => 4096, 'avatar_size' => 256,
        // Usernames [X11]: words that pass for the game's staff, anywhere in the name; the short ones only alone (or with
        // digits), so "modric" stays free. The developers' names are given by the admin only, with the official badge.
        'blocked_words' => ['owner', 'admin', 'support', 'moderator', 'official', 'legends', 'system', 'staff', 'developer'],
        'blocked_names' => ['mod', 'dev', 'gm', 'root', 'help', 'team'],
        'official_usernames' => ['Owner-Hamza', 'Owner-Soliman'],
        // Each developer's Gmail, on the server only: the confirmed address takes its name and the admin panel.
        'official_emails' => ['Owner-Hamza' => env('OWNER_HAMZA_EMAIL'), 'Owner-Soliman' => env('OWNER_SOLIMAN_EMAIL')]],
    // The home server's health check every minute, with an alert on the phones by ntfy [PLAN 2.19, Sprint 21 B2].
    // Each phone subscribes to the topic in the ntfy app; no topic, no alert (the check still runs).
    'monitoring' => [
        'ntfy_topic' => env('NTFY_TOPIC'),
        'ntfy_server' => env('NTFY_SERVER', 'https://ntfy.sh'),
        'web_url' => env('HEALTH_WEB_URL', 'http://127.0.0.1:8000'),
        // A service is down when its last sign of life is older than this (seconds).
        'stale' => ['queue' => 120, 'scheduler' => 150],
        // While a service stays down, the alert comes again this often (minutes).
        'remind_minutes' => 30,
        // Disk space under this many MB on the data disk is a warning.
        'min_free_mb' => 1024,
    ],
    // The stadium [PLAN 2.9, Sprint 29]: three sections of three stages of five parts, one part at a time, each
    // started by the coach and done in part_hours (scaled by the season's length). The pitch's effect is in
    // match.home_pitch_bp (the engine reads it from the match's snapshot).
    'stadium' => ['stages' => 3, 'parts_per_stage' => 5, 'part_hours' => 18,
        'sections' => ['seats', 'pitch', 'training'],
        'part_cost_bp' => [1 => 5, 2 => 8, 3 => 12],          // one part of a stage, as a share of the league's money scale
        'capacity_by_stage' => [20000, 25000, 31000, 38000],   // seats: the same ticket price, more seats
        // training: each session's step goes up by a random share in this range (basis points)
        'training_speed_bp' => [[0, 0], [0, 1000], [500, 2000], [1000, 3000]]],
    // Backups off this machine [PLAN 2.19, Sprint 37]: an rclone remote to Google Drive (rclone config, once).
    'backup' => ['rclone_remote' => env('BACKUP_RCLONE_REMOTE')],
    // The admin panel [PLAN 2.17, Sprint 37]: a code from the authenticator is asked again after these hours.
    'admin' => ['two_factor_hours' => 12],
    // Notifications [PLAN 2.13, Sprint 36]: one channel (Web Push now, FCM in Sprint 45). Each kind can be turned off,
    // and the inbox messages that push under each kind. The VAPID keys come from .env (php artisan push:keys).
    'notifications' => [
        'kinds' => [
            'referee' => ['referee'],
            'match_soon' => ['match_soon'],
            'offers' => ['offer_received', 'offer_countered', 'offer_accepted', 'offer_rejected', 'listing_sold'],
            'done' => ['training_done', 'camp_back', 'stadium_part', 'scout_report', 'staff_left'],
            'absence' => ['absence_warning', 'left_absent', 'kicked', 'vacation_request', 'vacation_approved', 'vacation_rejected'],
        ],
        'match_soon_minutes' => 10,
        'vapid' => ['public' => env('WEBPUSH_VAPID_PUBLIC'), 'private' => env('WEBPUSH_VAPID_PRIVATE'), 'subject' => env('WEBPUSH_SUBJECT', 'mailto:admin@legends.local')],
    ],
    // The premium coins [docs/features/premium.md, Sprint 34]: earned in the game only, spent like OSM, never into club money.
    'premium' => [
        'season_cap' => 400,           // the most a coach spends in one league in one season
        'earn' => ['daily' => 10, 'win' => 5, 'draw' => 2, 'objective_league' => 50, 'objective_cup' => 30,
            // The big season prizes go to the champions alone: the league's and the cup's [X14].
            'league_1' => 300, 'cup_1' => 200],
        'price' => ['spy' => 20, 'secret_training' => 30, 'specialist' => 25, 'finish_training' => 5, 'finish_scout' => 15, 'finish_stadium_per_stage' => 10, 'quick_sale' => 5],
        'shop' => [['coins' => 100, 'label' => 'حزمة صغيرة'], ['coins' => 300, 'label' => 'حزمة متوسطة'], ['coins' => 1000, 'label' => 'حزمة كبيرة']],
    ],
    // Club objectives [PLAN 2.20, Sprint 33]: from the club's rank by strength in its league (1 = strongest).
    // League: the strongest goes for the title; the top quarter for a place this far below its rank; the rest
    // further; and nobody is asked for less than to stay out of the bottom fifth. Cup: a stage by quarter of rank.
    'objectives' => ['top_quarter_slack' => 1, 'rest_slack' => 2, 'bottom_bp' => 2000,
        'cup_by_quarter' => ['final', 'sf', 'qf', 'qf']],
    // The bots between matches [ENGINE 7, Sprint 32]: each personality's own tactics, then the match's adjustments
    // from what any coach can see of the opponent (strength, the four public tactics of his last match, his form).
    'bots' => [
        'personalities' => [
            'giants' => ['plan' => 'passing', 'tackling' => 1, 'pressing' => 55, 'style' => 62, 'tempo' => 50, 'att' => 'support', 'mid' => 'push', 'def' => 'stay', 'trap' => 0, 'marking' => 'zone'],
            'defenders' => ['plan' => 'counter', 'tackling' => 1, 'pressing' => 30, 'style' => 25, 'tempo' => 45, 'att' => 'only', 'mid' => 'def', 'def' => 'stay', 'trap' => 0, 'marking' => 'man'],
            'pressers' => ['plan' => 'passing', 'tackling' => 2, 'pressing' => 85, 'style' => 62, 'tempo' => 78, 'att' => 'back', 'mid' => 'push', 'def' => 'stay', 'trap' => 1, 'marking' => 'zone'],
            'hard' => ['plan' => 'long', 'tackling' => 3, 'pressing' => 55, 'style' => 48, 'tempo' => 55, 'att' => 'support', 'mid' => 'stay', 'def' => 'stay', 'trap' => 0, 'marking' => 'man'],
            'wingers' => ['plan' => 'wings', 'tackling' => 1, 'pressing' => 50, 'style' => 58, 'tempo' => 60, 'att' => 'support', 'mid' => 'stay', 'def' => 'fullbacks', 'trap' => 0, 'marking' => 'zone'],
            'adaptive' => ['plan' => 'passing', 'tackling' => 1, 'pressing' => 50, 'style' => 50, 'tempo' => 50, 'att' => 'support', 'mid' => 'stay', 'def' => 'stay', 'trap' => 0, 'marking' => 'zone'],
        ],
        'style_per_100cp' => 4,        // a stronger side attacks more: style moves this much per 100 strength points of gap
        'style_swing' => 12,           // at most this far from the personality's own style
        'rest_below_fitness' => ['pressers' => 75, 'default' => 65],   // rotation: who rests while the squad allows
    ],
    // Specialists [docs/features/specialists.md, Sprint 31]: a contract of contract_days (scaled by the season's
    // length), paid when signed as a share of the league's money scale (club money until the premium coins).
    'specialists' => ['contract_days' => 7,
        // [X20] The staff by stars, 1 to 5: a coach for each line (the keeper coach for the keepers), the doctor, the
        // physio and the lawyer. The price is cost_bp (of the league's money scale) times stars_cost_bp; each effect
        // grows with the stars. A contract can be renewed in its last renew_hours (the new one starts when it ends);
        // one that ends unrenewed is a resignation, and the coach is told.
        'cost_bp' => ['doctor' => 20, 'lawyer' => 15, 'physio' => 20, 'keeper_coach' => 20, 'def_coach' => 15, 'mid_coach' => 15, 'att_coach' => 15],
        'stars_cost_bp' => [1 => 5000, 2 => 7500, 3 => 10000, 4 => 14000, 5 => 20000],
        'renew_hours' => 24,
        'doctor_countdown' => [1 => 1, 2 => 1, 3 => 2, 4 => 2, 5 => 3],         // each match counts injuries down by this many
        'lawyer_cancel_bp' => [1 => 2000, 2 => 3500, 3 => 5000, 4 => 6500, 5 => 8000],   // the share of new red-card bans cancelled
        'keeper_coach_boost' => [1 => 1, 2 => 1, 3 => 2, 4 => 2, 5 => 3],       // on the keeper's rating and attributes in a match
        'physio_rest_bonus' => [1 => 5, 2 => 10, 3 => 15, 4 => 20, 5 => 25],     // fitness on top of rest_recovery for a player who rests
        'coach_training_bp' => [1 => 1000, 2 => 2000, 3 => 3000, 4 => 4500, 5 => 6000]],  // faster training for the coach's line
    // Spying on the next opponent [docs/features/spy.md, Sprint 30]: a share of the league's money scale (club
    // money until the premium coins come, Sprint 34).
    'spy' => ['cost_bp' => 15],
    // The scout [docs/features/scout.md, X15]: a share of the league's money scale, a 15-hour trip scaled by the
    // season's length, and five players that match every criterion (the position, the age, the rating, the price).
    'scout' => ['cost_bp' => 30, 'hours' => 15, 'results' => 5],
];
