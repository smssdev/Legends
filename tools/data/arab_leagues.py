"""The Arab leagues that EA FC does not have [X34]: the current squads from Wikipedia, with estimated ratings.

    python3 tools/data/arab_leagues.py            # writes data/arab/arab_players.csv (and a review copy for Excel)

The owner's decision (2026-10-25): the ratings are estimated here, then the owner and Hamza review and correct them in
the CSV (the overallRating column) before it goes into the game. The squads (names, nationalities, positions) come from
each club's "current squad" on English Wikipedia (CC BY-SA, credited in the game's About), the birth dates and the
national team caps from Wikidata (CC0). Nothing is copied from EA, Transfermarkt or any game.

The estimate, per club: a level from the league and last season's table (LEAGUES: the champion's and the last club's
average of their best 18, on EA's scale where the Saudi champion is about 77), and per player an offset for age (the
peak at 24 to 31), a foreign player (+3: the Arab clubs' imports are usually among their best), a full international
(+3), and a stable spread from the name (+/-3). The squad is then shifted so its best 18 average the club's level.
Positions: Wikipedia says only GK, DF, MF or FW, so the squad is spread over the roles in order (CB, RB, LB, ...).
The CSV has EA's columns, so data:import reads it as it reads the EA files. The name shown (commonName) is the
player's Arabic name from Wikidata where it has one, else the Latin one (nameLatin keeps the Latin one always).
"""
import csv
import datetime
import hashlib
import json
import os
import re
import sys
import time
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'data', 'arab')
TODAY = datetime.date(2026, 10, 25)
UA = {'User-Agent': 'LegendsGameData/1.0 (Arabic football manager game; https://github.com/smssdev/Legends)'}

# League name in the game: (this season's article, last season's article, champion level, last club level, id prefix).
LEAGUES = {
    'Egyptian Premier League': ('2026–27 Egyptian Premier League', '2025–26 Egyptian Premier League', 72, 59, 1),
    'Botola Pro': ('2026–27 Botola Pro', '2025–26 Botola Pro', 70, 58, 2),
    'Algerian Ligue 1': ('2026–27 Algerian Ligue Professionnelle 1', '2025–26 Algerian Ligue Professionnelle 1', 67, 57, 3),
    'Tunisian Ligue 1': ('2026–27 Tunisian Ligue Professionnelle 1', '2025–26 Tunisian Ligue Professionnelle 1', 68, 57, 4),
    'Qatar Stars League': ('2025–26 Qatar Stars League', '2025–26 Qatar Stars League', 72, 59, 5),
    'UAE Pro League': ('2026–27 UAE Pro League', '2025–26 UAE Pro League', 72, 59, 6),
    'Iraq Stars League': ('2026–27 Iraq Stars League', '2025–26 Iraq Stars League', 64, 55, 7),
}
# Where this season's article lists its clubs in no table the parser reads, the clubs as the article names them.
CLUBS = {
    'Tunisian Ligue 1': ['US Ben Guerdane', 'ES Hammam Sousse', 'AS Marsa', 'US Monastir (football)', 'Espérance Sportive de Tunis',
                         'Étoile Sportive du Sahel', 'ES Métlaoui', 'Stade Tunisien', 'Olympique Béja', 'PS Sakiet Eddaïer', 'JS El Omrane',
                         'CA Bizertin', 'CS Sfaxien', 'ES Zarzis', 'Club Africain', 'CS Hammam-Lif'],
    'UAE Pro League': ['Al Ain FC', 'Shabab Al Ahli Club', 'Al Jazira Club', 'Al Wahda FC', 'Al Wasl F.C.', 'Sharjah FC', 'Al-Nasr SC (Dubai)',
                       'Baniyas Club', 'Ajman Club', 'Khor Fakkan Club', 'Kalba FC', 'Hatta Club', 'United FC (Dubai)', 'Al Dhafra FC'],
}
# Each league's great clubs, strongest first: they head the ranking before last season's table (a giant that finished
# fifth is still a giant), and the owner and Hamza correct the rest in the review.
GIANTS = {
    'Egyptian Premier League': ['Al Ahly SC', 'Pyramids FC', 'Zamalek SC', 'Ceramica Cleopatra FC', 'Al Masry SC'],
    'Botola Pro': ['RS Berkane', 'Wydad AC', 'Raja CA', 'AS FAR (football club)', 'FUS Rabat'],
    'Algerian Ligue 1': ['MC Alger', 'CR Belouizdad', 'USM Alger', 'JS Kabylie', 'ES Sétif', 'CS Constantine'],
    'Tunisian Ligue 1': ['Espérance Sportive de Tunis', 'Étoile Sportive du Sahel', 'Club Africain', 'CS Sfaxien', 'US Monastir (football)', 'Stade Tunisien'],
    'Qatar Stars League': ['Al Sadd SC', 'Al-Duhail SC', 'Al-Rayyan SC', 'Al-Gharafa SC', 'Al-Arabi SC (Qatar)', 'Qatar SC'],
    'UAE Pro League': ['Al Ain FC', 'Shabab Al Ahli Club', 'Al Wahda FC', 'Al Jazira Club', 'Sharjah FC', 'Al Wasl F.C.'],
    'Iraq Stars League': ['Al-Shorta SC', 'Al-Zawraa SC', 'Al-Quwa Al-Jawiya', 'Al-Talaba SC', 'Erbil SC', 'Al-Karma SC'],
}
# Wikipedia's FIFA codes as EA names the countries (the game's chemistry compares these names).
NATIONS = {
    'EGY': 'Egypt', 'MAR': 'Morocco', 'ALG': 'Algeria', 'TUN': 'Tunisia', 'LBY': 'Libya', 'SUD': 'Sudan', 'IRQ': 'Iraq', 'QAT': 'Qatar',
    'UAE': 'United Arab Emirates', 'KSA': 'Saudi Arabia', 'SYR': 'Syria', 'JOR': 'Jordan', 'LIB': 'Lebanon', 'PLE': 'Palestine',
    'KUW': 'Kuwait', 'BHR': 'Bahrain', 'OMA': 'Oman', 'YEM': 'Yemen', 'MTN': 'Mauritania', 'COM': 'Comoros', 'DJI': 'Djibouti',
    'IRN': 'Iran', 'GHA': 'Ghana', 'NGA': 'Nigeria', 'CMR': 'Cameroon', 'CIV': "Côte d'Ivoire", 'SEN': 'Senegal', 'MLI': 'Mali',
    'BFA': 'Burkina Faso', 'GUI': 'Guinea', 'GNB': 'Guinea-Bissau', 'COD': 'Congo DR', 'CGO': 'Congo', 'GAB': 'Gabon', 'TOG': 'Togo',
    'BEN': 'Benin', 'NIG': 'Niger', 'TAN': 'Tanzania', 'KEN': 'Kenya', 'UGA': 'Uganda', 'ZAM': 'Zambia', 'ZIM': 'Zimbabwe',
    'RSA': 'South Africa', 'ANG': 'Angola', 'MOZ': 'Mozambique', 'MAD': 'Madagascar', 'GAM': 'Gambia', 'SLE': 'Sierra Leone',
    'LBR': 'Liberia', 'ETH': 'Ethiopia', 'CPV': 'Cape Verde Islands', 'EQG': 'Equatorial Guinea', 'CTA': 'Central African Republic',
    'CHA': 'Chad', 'BDI': 'Burundi', 'RWA': 'Rwanda', 'MWI': 'Malawi', 'NAM': 'Namibia', 'BOT': 'Botswana',
    'BRA': 'Brazil', 'ARG': 'Argentina', 'URU': 'Uruguay', 'COL': 'Colombia', 'CHI': 'Chile', 'PER': 'Peru', 'VEN': 'Venezuela',
    'ECU': 'Ecuador', 'PAR': 'Paraguay', 'BOL': 'Bolivia', 'MEX': 'Mexico', 'USA': 'United States', 'CAN': 'Canada', 'CRC': 'Costa Rica',
    'HON': 'Honduras', 'PAN': 'Panama', 'JAM': 'Jamaica', 'HAI': 'Haiti', 'FRA': 'France', 'ESP': 'Spain', 'POR': 'Portugal',
    'ITA': 'Italy', 'GER': 'Germany', 'NED': 'Holland', 'BEL': 'Belgium', 'ENG': 'England', 'SCO': 'Scotland', 'WAL': 'Wales',
    'IRL': 'Republic of Ireland', 'NIR': 'Northern Ireland', 'SUI': 'Switzerland', 'AUT': 'Austria', 'CRO': 'Croatia', 'SRB': 'Serbia',
    'BIH': 'Bosnia and Herzegovina', 'MNE': 'Montenegro', 'MKD': 'North Macedonia', 'SVN': 'Slovenia', 'SVK': 'Slovakia',
    'CZE': 'Czech Republic', 'POL': 'Poland', 'HUN': 'Hungary', 'ROU': 'Romania', 'BUL': 'Bulgaria', 'GRE': 'Greece', 'TUR': 'Turkey',
    'UKR': 'Ukraine', 'RUS': 'Russia', 'BLR': 'Belarus', 'GEO': 'Georgia', 'ARM': 'Armenia', 'AZE': 'Azerbaijan', 'ALB': 'Albania',
    'KVX': 'Kosovo', 'DEN': 'Denmark', 'SWE': 'Sweden', 'NOR': 'Norway', 'FIN': 'Finland', 'ISL': 'Iceland', 'CYP': 'Cyprus',
    'LUX': 'Luxembourg', 'JPN': 'Japan', 'KOR': 'Korea Republic', 'CHN': 'China PR', 'AUS': 'Australia', 'UZB': 'Uzbekistan',
    'TJK': 'Tajikistan', 'KGZ': 'Kyrgyzstan', 'TKM': 'Turkmenistan', 'KAZ': 'Kazakhstan', 'AFG': 'Afghanistan', 'IND': 'India',
    'PAK': 'Pakistan', 'IDN': 'Indonesia', 'MAS': 'Malaysia', 'THA': 'Thailand', 'VIE': 'Vietnam', 'PHI': 'Philippines',
    'NGR': 'Nigeria', 'DRC': 'Congo DR', 'MRT': 'Mauritania', 'PSE': 'Palestine', 'LBN': 'Lebanon', 'GIN': 'Guinea',
    'SER': 'Serbia', 'SLO': 'Slovenia', 'JAP': 'Japan',
    'SOM': 'Somalia', 'ERI': 'Eritrea', 'SSD': 'South Sudan', 'LTU': 'Lithuania', 'LVA': 'Latvia', 'EST': 'Estonia', 'MDA': 'Moldova',
}
ROLES = {'GK': ['GK'], 'DF': ['CB', 'CB', 'RB', 'LB', 'CB', 'RB', 'LB', 'CB'], 'MF': ['CDM', 'CM', 'CAM', 'CM', 'RM', 'LM', 'CDM', 'CM', 'CAM'],
         'FW': ['ST', 'LW', 'RW', 'ST', 'ST', 'LW', 'RW']}
# Each role's six numbers around the overall (EA's shape: a centre back is slow and strong, a winger quick).
SHAPE = {
    'CB': (-8, -25, -12, -14, 4, 4), 'RB': (2, -18, -6, -4, 0, -2), 'LB': (2, -18, -6, -4, 0, -2),
    'CDM': (-6, -10, 0, -3, 1, 4), 'CM': (-3, -4, 2, 1, -6, 0), 'CAM': (0, 0, 2, 3, -25, -8), 'RM': (5, -2, 0, 2, -20, -6),
    'LM': (5, -2, 0, 2, -20, -6), 'ST': (3, 3, -8, 0, -35, 2), 'LW': (6, -1, -2, 3, -32, -8), 'RW': (6, -1, -2, 3, -32, -8),
}
HEADER = ['id', 'rank', 'overallRating', 'firstName', 'lastName', 'commonName', 'birthdate', 'height', 'weight', 'skillMoves',
          'weakFootAbility', 'preferredFoot', 'position', 'positionType', 'alternatePositions', 'nationality', 'team', 'leagueName',
          'playStyles', 'playStylesPlus', 'age', 'pac', 'sho', 'pas', 'dri', 'def', 'phy', 'gkDiving', 'gkHandling', 'gkKicking',
          'gkPositioning', 'gkReflexes', 'penalties', 'freeKickAccuracy', 'crossing', 'headingAccuracy', 'stamina', 'aggression',
          'clubPrimary', 'clubSecondary', 'nameLatin', 'source']


CACHE = os.environ.get('LEGENDS_WP_CACHE', os.path.join(os.path.expanduser('~'), '.cache', 'legends-wikipedia'))


def get(url):
    """A Wikipedia or Wikidata answer, kept on disk for a day so a second run (after a fix) asks nothing again."""
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, hashlib.sha256(url.encode()).hexdigest() + '.json')
    if os.path.exists(path) and time.time() - os.path.getmtime(path) < 86400:
        with open(path) as f:
            return json.load(f)
    for attempt in range(7):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=40) as r:
                data = json.load(r)
            with open(path, 'w') as f:
                json.dump(data, f)
            return data
        except Exception:
            # Wikipedia answers a burst with "too many requests": wait longer each time.
            time.sleep(5 * (attempt + 1))
    return {}


def wp(**p):
    p.update(format='json', formatversion='2')
    time.sleep(0.2)
    return get('https://en.wikipedia.org/w/api.php?' + urllib.parse.urlencode(p))


def wikitext(title):
    parse = wp(action='parse', page=title, prop='wikitext', redirects=1).get('parse') or {}
    return parse.get('wikitext', ''), parse.get('title', title)


def season_clubs(title):
    """[(article, shown name)] from a season article's standings (the name_XXX entries), in table order."""
    text, _ = wikitext(title)
    order = re.search(r'team_order\s*=\s*([A-Z0-9_ ,]+)', text)
    # Some seasons keep their table in a template of its own ({{2025–26 Botola table}}): read that.
    if not order:
        table = re.search(r'\{\{\s*(20\d\d–\d\d[^{}|]*?[Tt]able)\s*\}\}', text)
        if table:
            text = wikitext('Template:' + table.group(1).strip())[0] + text
            order = re.search(r'team_order\s*=\s*([A-Z0-9_ ,]+)', text)
    names = {code: (link, (label or link)) for code, link, label in
             re.findall(r'\|\s*name_([A-Z0-9_]+)\s*=\s*\[\[([^\]|]+)(?:\|([^\]]*))?\]\]', text)}
    codes = [c.strip() for c in order.group(1).split(',') if c.strip()] if order else list(names)
    seen, out = set(), []
    for c in codes:
        if c in names and names[c][0] not in seen:
            seen.add(names[c][0])
            out.append((names[c][0].strip(), names[c][1].strip()))
    return out


def squad(article):
    """The first team: [(number, nation code, player article or None, name, GK/DF/MF/FW, captain)], and the kit colours."""
    text, _ = wikitext(article)
    # The first {{Fs start}} ... {{Fs end}} block is the first team wherever the page puts it (the loans come after).
    block = re.search(r'\{\{\s*[Ff]s start(.*?)\{\{\s*[Ff]s end', text, re.S)
    if block:
        text = '\n== Current squad ==\n{{Fs start' + block.group(1) + '\n== End =='
    start = None
    for heading in ('Current squad', 'First-team squad', 'First team squad', 'Current Squad', 'Squad', 'Players'):
        m = re.search(r'\n(=+)\s*' + re.escape(heading) + r'[^=\n]*=+', text)
        if m:
            start = m
            break
    if not start:
        return [], None
    level = len(start.group(1))
    body = text[start.end():]
    end = re.search(r'\n={2,%d}[^=]' % level, body)
    body = body[:end.start()] if end else body
    # Players out on loan, reserves and youth teams are not the first team.
    cut = re.search(r"(Out on loan|On loan|Reserve|Youth|U-?2[0-3]|U-?19|Academy)", body)
    if cut:
        body = body[:cut.start()]
    colours = re.search(r'\{\{\s*[Ff]s start[^}]*?bg\s*=\s*#?([0-9A-Fa-f]{6})[^}]*?color\s*=\s*#?([0-9A-Fa-f]{6})', body)
    players = []
    for t in re.findall(r'\{\{\s*[Ff]s player\s*\|(.*?)\}\}(?=\s*(?:\{\{|\n|$))', body, re.S):
        f = {}
        for part in re.split(r'\|(?![^\[]*\]\])', t):
            if '=' in part:
                k, v = part.split('=', 1)
                f[k.strip()] = v.strip()
        link = re.match(r'\[\[([^\]|]+)(?:\|([^\]]*))?\]\]', f.get('name', ''))
        name = (link.group(2) or link.group(1)) if link else re.sub(r'<.*?>|\{\{.*?\}\}', '', f.get('name', '')).strip()
        name = re.sub(r'\s*\(.*?\)\s*$', '', name).strip()
        pos = f.get('pos', '').upper()[:2]
        if not name or pos not in ROLES:
            continue
        players.append((f.get('no', ''), f.get('nat', '').upper(), link.group(1) if link else None, name, pos,
                        'captain' in f.get('other', '').lower()))
    return players, ('#' + colours.group(1).upper(), '#' + colours.group(2).upper()) if colours else None


def wikidata(articles):
    """For each player article: (birth date, played for a senior national team, his name in Arabic or '')."""
    qid = {}
    arts = list(articles)
    for i in range(0, len(arts), 50):
        d = wp(action='query', prop='pageprops', ppprop='wikibase_item', redirects=1, titles='|'.join(arts[i:i + 50]))
        q = d.get('query', {})
        back = {n['to']: n['from'] for n in q.get('redirects', [])}
        back.update({n['to']: n['from'] for n in q.get('normalized', [])})
        for p in q.get('pages', []):
            item = (p.get('pageprops') or {}).get('wikibase_item')
            if item:
                title = p['title']
                qid[back.get(title, title)] = item
                qid[title] = item
    claims, teams = {}, set()
    items = sorted(set(qid.values()))
    for i in range(0, len(items), 50):
        d = get('https://www.wikidata.org/w/api.php?' + urllib.parse.urlencode(
            {'action': 'wbgetentities', 'ids': '|'.join(items[i:i + 50]), 'props': 'claims|labels', 'languages': 'ar', 'format': 'json'}))
        time.sleep(0.2)
        for k, e in (d.get('entities') or {}).items():
            c = e.get('claims', {})
            born = None
            for s in c.get('P569', []):
                v = ((s.get('mainsnak') or {}).get('datavalue') or {}).get('value', {}).get('time')
                if v:
                    born = v[1:11]
                    break
            clubs = [((s.get('mainsnak') or {}).get('datavalue') or {}).get('value', {}).get('id') for s in c.get('P54', [])]
            arabic = ((e.get('labels') or {}).get('ar') or {}).get('value', '')
            claims[k] = (born, [x for x in clubs if x], re.sub(r'\s*\(.*?\)\s*$', '', arabic).strip())
            teams.update(x for x in clubs if x)
    national = set()
    team_list = sorted(teams)
    for i in range(0, len(team_list), 50):
        d = get('https://www.wikidata.org/w/api.php?' + urllib.parse.urlencode(
            {'action': 'wbgetentities', 'ids': '|'.join(team_list[i:i + 50]), 'props': 'labels', 'languages': 'en', 'format': 'json'}))
        time.sleep(0.2)
        for k, e in (d.get('entities') or {}).items():
            label = ((e.get('labels') or {}).get('en') or {}).get('value', '').lower()
            if 'national' in label and not re.search(r'under-|u-?\d\d|olympic|youth|\bb\b|futsal|beach|amateur|women', label):
                national.add(k)
    out = {}
    for art, q in qid.items():
        born, clubs, arabic = claims.get(q, (None, [], ''))
        out[art] = (born, any(c in national for c in clubs), arabic)
    return out


def stable(*parts):
    return int(hashlib.sha256('|'.join(parts).encode()).hexdigest()[:8], 16)


def age_of(born):
    try:
        b = datetime.date.fromisoformat(born)
    except (TypeError, ValueError):
        return None
    return TODAY.year - b.year - ((TODAY.month, TODAY.day) < (b.month, b.day))


def age_offset(age):
    return {True: 0}.get(24 <= age <= 31, -6 if age <= 17 else -4 if age <= 19 else -2 if age <= 21 else -1 if age <= 23
                         else -1 if age <= 32 else -3 if age <= 34 else -5)


def clamp(v, lo=25, hi=95):
    return max(lo, min(hi, v))


def ea_clubs():
    """The club names in the EA files: an Arab club with the same name (Qatar's Al Ahli, Egypt's Al Ittihad) takes its
    article's fuller name, or data:import would merge the two squads into one club."""
    names = set()
    for f in ('ea_fc26_outfield.csv', 'ea_fc26_goalkeepers.csv'):
        with open(os.path.join(ROOT, 'data', 'ea-fc26', f), encoding='utf-8') as h:
            names.update(r['team'] for r in csv.DictReader(h))
    return names


def main():
    os.makedirs(OUT, exist_ok=True)
    rows, report = [], []
    taken = ea_clubs()
    ids = set()
    for league, (season, last, top, bottom, prefix) in LEAGUES.items():
        clubs = [(c, None) for c in CLUBS[league]] if league in CLUBS else season_clubs(season)
        giants = GIANTS.get(league, [])
        table = giants + [c for c, _ in season_clubs(last) if c not in giants]
        names = {c: n for c, n in season_clubs(season)} if league not in CLUBS else {}
        squads = {}
        for article, _ in clubs:
            squads[article] = squad(article)
        info = wikidata({p[2] for s, _ in squads.values() for p in s if p[2]})
        n = len(clubs)
        for article, _ in clubs:
            players, colours = squads[article]
            shown = names.get(article) or re.sub(r'\s*\((football|football club|Dubai)\)|\s+(SC|FC|F\.C\.|Club|SCC)$', '', article).strip()
            if shown in taken:
                shown = re.sub(r'\s*\(([^)]*)\)', r' \1', article).replace(' Club', '').strip()
            taken.add(shown)
            if len(players) < 18 or not any(p[4] == 'GK' for p in players):
                report.append(f'{league}: {shown} skipped ({len(players)} players on Wikipedia)')
                continue
            # The club's level from last season's place (a promoted club starts near the bottom).
            place = table.index(article) if article in table else n - 2
            level = top - (top - bottom) * min(place, n - 1) / max(1, n - 1)
            local = max((NATIONS.get(p[1], p[1]) for p in players), key=[NATIONS.get(q[1], q[1]) for q in players].count)
            made, used = [], {k: 0 for k in ROLES}
            for no, nat, art, name, pos, captain in players:
                born, international, arabic = info.get(art, (None, False, '')) if art else (None, False, '')
                age = age_of(born) or 18 + stable(name, 'age') % 15
                nation = NATIONS.get(nat, nat or local)
                role = ROLES[pos][used[pos] % len(ROLES[pos])]
                used[pos] += 1
                raw = (age_offset(age) + (3 if nation != local else 0) + (3 if international else 0) + (2 if captain else 0)
                       + stable(name, article) % 7 - 3)
                made.append([no, nation, name, pos, role, age, born, raw, arabic])
            best = sorted((m[7] for m in made), reverse=True)[:18]
            shift = level - sum(best) / len(best)
            for no, nation, name, pos, role, age, born, raw, arabic in made:
                ovr = int(round(clamp(raw + shift, 40, 90)))
                h = stable(name, 'attr')
                j = lambda k: (h >> (k * 3)) % 5 - 2
                if role == 'GK':
                    six = [''] * 6
                    gk = [clamp(ovr + j(i)) for i in range(5)]
                else:
                    six = [clamp(ovr + d + j(i)) for i, d in enumerate(SHAPE[role])]
                    gk = [''] * 5
                first, _, rest = name.partition(' ')
                pid = prefix * 10 ** 8 + stable(league, article, name) % 10 ** 8
                # Two players of one squad may share a name (two Mohamed Samirs): each keeps an id of his own.
                while pid in ids:
                    pid += 1
                ids.add(pid)
                rows.append({
                    'id': pid, 'rank': '', 'overallRating': ovr, 'firstName': first if rest else '', 'lastName': rest or name,
                    'commonName': arabic or name, 'birthdate': born or '', 'height': '', 'weight': '', 'skillMoves': '', 'weakFootAbility': '',
                    'preferredFoot': 'Left' if role in ('LB', 'LM', 'LW') else 'Right', 'position': role,
                    'positionType': {'GK': 'GK', 'DF': 'DEF', 'MF': 'MID', 'FW': 'ATT'}[pos], 'alternatePositions': '',
                    'nationality': nation, 'team': shown, 'leagueName': league, 'playStyles': '', 'playStylesPlus': '', 'age': age,
                    'pac': six[0], 'sho': six[1], 'pas': six[2], 'dri': six[3], 'def': six[4], 'phy': six[5],
                    'gkDiving': gk[0], 'gkHandling': gk[1], 'gkKicking': gk[2], 'gkPositioning': gk[3], 'gkReflexes': gk[4],
                    'penalties': clamp(ovr - 8 + j(5)), 'freeKickAccuracy': clamp(ovr - 12 + j(6)), 'crossing': clamp(ovr - 10 + j(7)),
                    'headingAccuracy': clamp(ovr - 6 + j(8)), 'stamina': clamp(ovr - 2 + j(9)), 'aggression': clamp(ovr - 5 + j(10)),
                    'nameLatin': name, 'clubPrimary': colours[0] if colours else '', 'clubSecondary': colours[1] if colours else '',
                    'source': 'https://en.wikipedia.org/wiki/' + urllib.parse.quote(article.replace(' ', '_')),
                })
            report.append(f'{league}: {shown} {len(made)} players, level {level:.1f}')
        print(league, 'done', file=sys.stderr)
    rows.sort(key=lambda r: (r['leagueName'], r['team'], -r['overallRating']))
    with open(os.path.join(OUT, 'arab_players.csv'), 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=HEADER)
        w.writeheader()
        w.writerows(rows)
    # The same with a byte-order mark, so Excel opens the Arabic and accented names right; reviewed, it replaces the CSV.
    with open(os.path.join(OUT, 'arab_players_review.csv'), 'w', newline='', encoding='utf-8-sig') as f:
        w = csv.DictWriter(f, fieldnames=HEADER)
        w.writeheader()
        w.writerows(rows)
    print('\n'.join(report))
    print(f'{len(rows)} players written to {OUT}')


if __name__ == '__main__':
    main()
