"""The working pace both plans use (docs/SLIEMAN.md, docs/HAMZA.md, docs/SCHEDULE.md, sprint-02-days.md).

Owner's decision (2026-10-22): Sliman makes the images the game needs first (waves 1 to 4) in parallel
with the code sprints; Hamza records the voice, then makes every stadium image whatever its wave, and the
images built last (waves 5 to 16, in sprints 49 to 52). Hamza only makes new images: every image a review
sends back is Sliman's to make again (tools/team.py, who_makes). Change a number here and re-run tools/plan/schedule.py, tools/art-prompts/days.py
and tools/team.py.
"""
import datetime as dt

PLAN_START = dt.date(2026, 10, 21)   # first day of the plan with images and code side by side
DAY_HOURS = 5                        # working hours a day, every day
IMG_HOURS = 2                        # of them on images while there are images left
IMG_PER_DAY = 12                     # approved images in those hours
CODE_HOURS = DAY_HOURS - IMG_HOURS   # the rest on the current code sprint
VOICE_PER_DAY = 30                   # Hamza's approved clips a day
HAMZA_FROM_WAVE = 5                  # image waves from this one on are Hamza's, the ones before it Sliman's
HAMZA_IMG_PER_DAY = 12               # Hamza's approved images a day, once his voice is done
HAMZA_FOLDERS = ('stadiums/',)       # folders under art/raw/ that are Hamza's in every wave


def image_owner(wave, path=''):
    """Who makes an image: 'hamza' or 'slieman', by its wave and its path under art/raw/."""
    folder = path.removeprefix('art/raw/')
    return 'hamza' if wave >= HAMZA_FROM_WAVE or folder.startswith(HAMZA_FOLDERS) else 'slieman'


def days_word(k):
    """The Arabic counted noun for days: 1 يوم، 3 أيام، 20 يوماً، 100 يوم."""
    r = k % 100
    return 'يوم' if r in (0, 1, 2) else ('أيام' if r <= 10 else 'يوماً')
