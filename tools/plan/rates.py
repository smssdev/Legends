"""The working pace both plans use (docs/SLIEMAN.md, docs/SCHEDULE.md, sprint-02-days.md).

Owner's decision (2026-10-20): Sliman makes all the images himself, in parallel with the
code sprints; Hamza records the voice only. Change a number here and re-run
tools/plan/schedule.py, tools/art-prompts/days.py and tools/team.py.
"""
import datetime as dt

PLAN_START = dt.date(2026, 10, 21)   # first day of the plan with images and code side by side
DAY_HOURS = 5                        # working hours a day, every day
IMG_HOURS = 2                        # of them on images while there are images left
IMG_PER_DAY = 12                     # approved images in those hours
CODE_HOURS = DAY_HOURS - IMG_HOURS   # the rest on the current code sprint
VOICE_PER_DAY = 30                   # Hamza's approved clips a day


def days_word(k):
    """The Arabic counted noun for days: 1 يوم، 3 أيام، 20 يوماً، 100 يوم."""
    r = k % 100
    return 'يوم' if r in (0, 1, 2) else ('أيام' if r <= 10 else 'يوماً')
