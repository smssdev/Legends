"""The working pace the plans use (docs/SLIEMAN.md, docs/HAMZA.md, docs/SCHEDULE.md).

Owner's decision (2026-10-23): the match images and the Flow videos are cancelled, and the realistic match is
built in Unity after the sprints (phase Z). So Sliman's whole day is code with Claude, and the voice stays
all Hamza's. Change a number here and re-run tools/plan/schedule.py and tools/team.py.
"""
import datetime as dt

PLAN_START = dt.date(2026, 10, 21)   # first day of the plan
DAY_HOURS = 5                        # working hours a day, every day, all on the code
VOICE_PER_DAY = 30                   # Hamza's approved clips a day


def days_word(k):
    """The Arabic counted noun for days: 1 يوم، 3 أيام، 20 يوماً، 100 يوم."""
    r = k % 100
    return 'يوم' if r in (0, 1, 2) else ('أيام' if r <= 10 else 'يوماً')
