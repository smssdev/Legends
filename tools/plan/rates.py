"""The working pace both plans use (docs/SLIEMAN.md, docs/HAMZA.md, docs/SCHEDULE.md, sprint-02-days.md).

Owner's decision (2026-10-22, final): the voice is all Hamza's. Of the images, Sliman makes the large
part (everything but the stadiums) in parallel with the code sprints, and Hamza a small part: the
stadium plates of every wave, after his voice. Every image a review sends back is Sliman's to make
again (tools/team.py, who_makes). Change a number here and re-run tools/plan/schedule.py, tools/art-prompts/days.py
and tools/team.py.
"""
import datetime as dt

PLAN_START = dt.date(2026, 10, 21)   # first day of the plan with images and code side by side
DAY_HOURS = 5                        # working hours a day, every day
IMG_HOURS = 2                        # of them on images while there are images left
IMG_PER_DAY = 12                     # approved images in those hours
CODE_HOURS = DAY_HOURS - IMG_HOURS   # the rest on the current code sprint
VOICE_PER_DAY = 30                   # Hamza's approved clips a day
HAMZA_IMG_PER_DAY = 12               # Hamza's approved images a day, once his voice is done
HAMZA_FOLDERS = ('stadiums/',)       # folders under art/raw/ that are Hamza's in every wave


def image_owner(wave, path='', book=''):
    """Who makes an image: 'hamza' for the stadium plates (HAMZA_FOLDERS), 'slieman' for everything else."""
    return 'hamza' if path.removeprefix('art/raw/').startswith(HAMZA_FOLDERS) else 'slieman'


def days_word(k):
    """The Arabic counted noun for days: 1 يوم، 3 أيام، 20 يوماً، 100 يوم."""
    r = k % 100
    return 'يوم' if r in (0, 1, 2) else ('أيام' if r <= 10 else 'يوماً')
