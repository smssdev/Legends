"""Real club logos [UP3, owner's decision 2026-10-26]: python3 tools/data/club_logos.py

Links every club in the game's data (EA FC 26 and the Arab leagues) to its SVG in football-logos-main/logos/
<country>/<Club>.svg: the league names the country to look in first (a club of the Libertadores or of a
league whose clubs come from elsewhere is looked for everywhere), then the names are compared without
accents, case, punctuation and the words every club carries (FC, CF, SC, Club...).

Writes data/names/club_logos.csv (league, club, file, score, image) and draws each logo that is used, in
Chromium, as a 160-pixel WebP in web/public/logos/<country>/<slug>.webp: a few kilobytes each instead of the
pack's heavy SVGs, so the lists stay light on weak phones (the spec's section 9). The site serves those only. A club under the score has no logo
and keeps its drawn badge (App\\Data\\Crest). Run it again after a data import.
"""
import csv, difflib, os, re, shutil, sys, unicodedata

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..')
LOGOS = os.path.join(ROOT, 'football-logos-main', 'logos')
OUT_CSV = os.path.join(ROOT, 'data', 'names', 'club_logos.csv')
OUT_DIR = os.path.join(ROOT, 'web', 'public', 'logos')
SOURCES = ['data/ea-fc26/ea_fc26_outfield.csv', 'data/ea-fc26/ea_fc26_goalkeepers.csv', 'data/arab/arab_players.csv']
MIN_SCORE = 0.82

SOUTH = ['argentina', 'brazil', 'uruguay', 'paraguay', 'chile', 'peru', 'colombia', 'ecuador', 'bolivia', 'venezuela']
COUNTRY = {
    'Premier League': ['england', 'wales'], 'EFL Championship': ['england', 'wales'], 'EFL League One': ['england', 'wales'],
    'EFL League Two': ['england', 'wales'], 'LALIGA EA SPORTS': ['spain'], 'LALIGA HYPERMOTION': ['spain'],
    'Serie A Enilive': ['italy'], 'Serie BKT': ['italy'], 'Bundesliga': ['germany'], 'Bundesliga 2': ['germany'],
    '3. Liga': ['germany'], "Ligue 1 McDonald's": ['france'], 'Ligue 2 BKT': ['france'], 'Eredivisie': ['netherlands'],
    'Liga Portugal': ['portugal'], '1A Pro League': ['belgium'], 'Trendyol Süper Lig': ['turkey'], 'Scottish Prem': ['scotland'],
    'Ö. Bundesliga': ['austria'], 'Brack Super League': ['switzerland'], '3F Superliga': ['denmark'], 'Allsvenskan': ['sweden'],
    'Eliteserien': ['norway'], 'Finnliiga': ['finland'], 'PKO BP Ekstraklasa': ['poland'], 'SUPERLIGA': ['romania'],
    'Hellas Liga': ['greece'], 'Česká Liga': ['czech-republic'], 'Liga Hrvatska': ['croatia'], 'Ukrayina Liha': ['ukraine'],
    'Magyar Liga': ['hungary'], 'Liga Cyprus': ['cyprus'], 'Liga Azerbaijan': ['azerbaijan'],
    'SSE Airtricity PD': ['republic-of-ireland', 'northern-ireland'], 'MLS': ['usa', 'canada'], 'LPF': ['argentina'],
    'Liga Chile': ['chile'], 'CSL': ['china'], 'K League 1': ['south-korea'], 'A-League': ['australia', 'new-zealand'],
    'ISL': ['india'], 'ROSHN Saudi League': ['saudi-arabia'], 'United Emirates League': ['uae'], 'UAE Pro League': ['uae'],
    'Libertadores': SOUTH, 'Sudamericana': SOUTH, 'Qatar Stars League': ['qatar'], 'Egyptian Premier League': ['egypt'], 'Botola Pro': ['morocco'],
    'Algerian Ligue 1': ['algeria'], 'Tunisian Ligue 1': ['tunisia'], 'Iraq Stars League': ['iraq'],
}
# Words that tell nothing about which club it is.
NOISE = {'fc', 'cf', 'sc', 'ac', 'afc', 'ssc', 'club', 'de', 'cd', 'ud', 'sd', 'rcd', 'ca', 'cr', 'fk', 'sk', 'if', 'bk',
         'calcio', 'football', 'futbol', 'futebol', 'the', 'sv', 'vfl', 'vfb', 'tsg', 'fsv', 'ss', 'us', 'as', 'rc', 'og',
         'ks', 'kv', 'krc', 'kaa', 'rsc', 'sporting', 'clube', 'esporte', 'saudi', 'al', 'el', 'and', '1', '04', '05', '1899', '1846', '1907'}
# Clubs whose name in the data and in the logos differ beyond what the comparison sees.
MANUAL = {
    ('Premier League', 'Spurs'): 'england/Tottenham.svg', ('1A Pro League', 'STVV'): 'belgium/Sint-Truidense_VV.svg',
    ('1A Pro League', 'Sp. Charleroi'): 'belgium/Royal_Charleroi_S.C..svg', ('3F Superliga', 'F.C. København'): 'denmark/F.C._Copenhagen.svg',
    ('3F Superliga', 'Odense BK'): 'denmark/OB.svg', ('3F Superliga', 'Vejle Boldklub'): 'denmark/VB.svg', ('Botola Pro', 'DH El Jadida'): 'morocco/Difaâ_Hassani_El_Jadidi.svg',
    ('Botola Pro', 'HUS Agadir'): 'morocco/Hassania_Agadir.svg', ('Botola Pro', 'KAC Marrakech'): 'morocco/Kawkab_of_Marrakech.svg',
    ('Botola Pro', 'MA Tétouan'): 'morocco/Moghreb_Tetouan.svg', ('Botola Pro', 'MAS Fez'): 'morocco/Maghreb_of_Fez.svg',
    ('Bundesliga', "M'gladbach"): 'germany/Borussia_Mönchengladbach.svg', ('CSL', 'SZ Peng City'): 'china/Shenzhen_Xinpengcheng.svg',
    ('CSL', 'Tianjin JMT FC'): 'china/Tianjin_Jinmen_Tiger.svg', ('Eliteserien', 'HamKam Fotball'): 'norway/Hamarkameratene.svg',
    ('LALIGA EA SPORTS', 'D. Alavés'): 'spain/Deportivo_Alavés.svg', ('Libertadores', 'LDU Quito'): 'ecuador/Liga_de_Quito.svg',
    ('Libertadores', 'U. de Chile'): 'chile/Universidad_de_Chile.svg', ("Ligue 1 McDonald's", 'Stade Brestois 29'): 'france/Brest.svg',
    ('Ligue 2 BKT', 'En Avant Guingamp'): 'france/EA_Guingamp.svg', ('Ligue 2 BKT', 'Laval MFC'): 'france/Stade_Lavallois.svg',
    ('MLS', 'LAFC'): 'usa/Los_Angeles_Football_Club.svg', ('SSE Airtricity PD', 'St. Pats'): "republic-of-ireland/St_Patrick's_Athletic.svg",
    ('SUPERLIGA', 'FC Dinamo 1948'): 'romania/Dinamo_Bucureşti.svg', ('SUPERLIGA', 'FC Rapid 1923'): 'romania/Rapid_Bucureşti.svg',
    ('SUPERLIGA', 'FCSB'): 'romania/FC_Steaua_București.svg', ('Serie A Enilive', 'Bergamo Calcio'): 'italy/Atalanta.svg',
    ('Serie A Enilive', 'Latium'): 'italy/Lazio.svg', ('Serie A Enilive', 'Lombardia FC'): 'italy/Inter.svg',
    ('Sudamericana', 'U. Católica'): 'ecuador/Universidad_Católica.svg', ('1A Pro League', 'Cercle Brugge'): 'belgium/Cercle_Brugge_KSV.svg',
    ('1A Pro League', 'R. Union St.-G.'): 'belgium/Union_Saint-Gilloise.svg', ('Bundesliga', '1. FC Köln'): '',  # not in the pack: keeps its drawn badge
   
    ('Bundesliga 2', 'Düsseldorf'): 'germany/Fortuna_Düsseldorf.svg', ('EFL League One', 'Peterborough'): 'england/Peterborough_United.svg',
    ('Eredivisie', 'Excelsior'): 'netherlands/Excelsior_Rotterdam.svg', ('LALIGA EA SPORTS', 'Athletic Club'): 'spain/Athletic_Club_Bilbao.svg',
    ('LALIGA HYPERMOTION', 'R. Racing Club'): 'spain/Racing_Santander.svg', ('LALIGA HYPERMOTION', 'R. Sporting'): 'spain/Sporting_Gijón.svg',
    ('LALIGA HYPERMOTION', 'RC Deportivo'): 'spain/Deportivo_La_Coruña.svg', ('Libertadores', 'Atl. Nacional'): 'colombia/Atlético_Nacional.svg',
    ('Libertadores', 'San Antonio'): 'bolivia/CD_San_Antonio_Bulo_Bulo.svg', ('Libertadores', 'Universitario'): 'peru/Universitario_de_Deportes.svg',
    ('Liga Portugal', 'Nacional'): 'portugal/Nacional_da_Madeira.svg', ('Liga Portugal', 'Vitória SC'): 'portugal/Vitória_de_Guimarães.svg',
    ("Ligue 1 McDonald's", 'OL'): 'france/Olympique_Lyonnais.svg', ("Ligue 1 McDonald's", 'OM'): 'france/Marseille.svg',
    ("Ligue 1 McDonald's", 'Paris SG'): 'france/PSG.svg', ("Ligue 1 McDonald's", 'Stade Rennais FC'): 'france/Rennes.svg',
    ('Premier League', 'Wolves'): 'england/Wolverhampton_Wanderers.svg', ('Premier League', 'Man Utd'): 'england/Manchester_United.svg',
    ('Premier League', 'Man City'): 'england/Manchester_City.svg', ('Premier League', "Nott'm Forest"): 'england/Nottingham_Forest.svg',
    ('Sudamericana', 'Nacional Potosí'): 'bolivia/Atlético_Nacional_Potosí.svg', ('Sudamericana', 'Racing Club'): 'argentina/Racing_Club.svg',
}


def norm(s):
    s = unicodedata.normalize('NFKD', s.replace('_', ' ')).encode('ascii', 'ignore').decode().lower()
    s = re.sub(r'\(.*?\)', ' ', s)
    return ' '.join(w for w in re.findall(r'[a-z0-9]+', s) if w not in NOISE)


def abbreviated(a, b):
    """Every word of a is a word of b, the start of one (Dep. for Deportivo) or the initials of a run of them (QPR)."""
    words = b.split()
    for w in a.split():
        if any(x == w or (len(w) >= 2 and x.startswith(w)) for x in words):
            continue
        initials = ''.join(x[0] for x in words)
        if len(w) >= 2 and w in initials:
            continue
        return False
    return True


def score(a, b):
    if not a or not b:
        return 0
    if a == b:
        return 1.0
    if abbreviated(a, b):
        return 0.9 + 0.05 * min(len(a), len(b)) / max(len(a), len(b))
    ratio = difflib.SequenceMatcher(None, a, b).ratio()
    ta, tb = set(a.split()), set(b.split())
    overlap = len(ta & tb) / max(1, min(len(ta), len(tb)))
    return max(ratio, 0.6 + 0.35 * overlap if ta & tb and (ta <= tb or tb <= ta) else 0, ratio * 0.5 + overlap * 0.5)


def image(f):
    """The served picture's path under /logos: the country and an ASCII slug of the file's name."""
    country, name = f.split('/', 1)
    return f'{country}/' + re.sub(r'[^a-z0-9]+', '-', unicodedata.normalize('NFKD', name[:-4]).encode('ascii', 'ignore').decode().lower()).strip('-') + '.webp'


def draw(pairs, size=160):
    from io import BytesIO
    from PIL import Image
    from playwright.sync_api import sync_playwright
    if os.path.isdir(OUT_DIR):
        shutil.rmtree(OUT_DIR)
    with sync_playwright() as p:
        b = p.chromium.launch(executable_path=os.environ.get('CHROMIUM') or next((x for x in ['/opt/pw-browsers/chromium'] if os.path.exists(x)), None))
        page = b.new_page(viewport={'width': size, 'height': size})
        for src, out in pairs:
            svg = open(os.path.join(LOGOS, src), encoding='utf-8').read()
            head = svg[:svg.find('>') + 1]
            if 'viewBox' not in head:
                # Some files give only a width and a height: without a box the picture is cut, not scaled.
                w, h = (re.search(rf'\b{k}="([\d.]+)', head) for k in ('width', 'height'))
                if w and h:
                    svg = svg.replace('<svg', f'<svg viewBox="0 0 {w.group(1)} {h.group(1)}"', 1)
            page.set_content('<style>html,body{margin:0;background:transparent}svg{display:block;width:%dpx;height:%dpx}</style>%s'
                             % (size, size, re.sub(r'<svg', '<svg preserveAspectRatio="xMidYMid meet"', svg, count=1)))
            # Pictures inside the SVG (some logos are a photo in a frame) load before the shot.
            page.wait_for_function('[...document.images].every((i) => i.complete) && [...document.querySelectorAll("image")].length >= 0', timeout=5000)
            page.wait_for_timeout(60 if '<image' in svg else 0)
            png = page.screenshot(omit_background=True)
            os.makedirs(os.path.join(OUT_DIR, os.path.dirname(out)), exist_ok=True)
            Image.open(BytesIO(png)).save(os.path.join(OUT_DIR, out), 'WEBP', quality=88, method=6)
        b.close()


def main():
    files = {c: [f for f in os.listdir(os.path.join(LOGOS, c)) if f.endswith('.svg')] for c in os.listdir(LOGOS) if os.path.isdir(os.path.join(LOGOS, c))}
    index = {c: [(norm(f[:-4]), f) for f in fs] for c, fs in files.items()}
    clubs = set()
    for src in SOURCES:
        for r in csv.DictReader(open(os.path.join(ROOT, src), encoding='utf-8')):
            clubs.add((r['leagueName'], r['team']))
    rows, found = [], 0
    for league, club in sorted(clubs):
        if (league, club) in MANUAL:
            f = MANUAL[(league, club)]
            if f and not os.path.exists(os.path.join(LOGOS, f)):
                sys.exit(f'missing in the pack: {f}')
            rows.append((league, club, f, '1.00' if f else '0'))
            found += bool(f)
            continue
        n = norm(club)
        best = (0, None)
        for c in COUNTRY.get(league, []) + [None]:
            for cc in ([c] if c else [k for k in index if k not in COUNTRY.get(league, [])]):
                for key, f in index[cc]:
                    sc = score(n, key) - (0 if c else 0.06)
                    if sc > best[0]:
                        best = (sc, f'{cc}/{f}')
            if c and best[0] >= 0.97:
                break
        if best[0] >= MIN_SCORE:
            rows.append((league, club, best[1], f'{best[0]:.2f}'))
            found += 1
        else:
            rows.append((league, club, '', f'{best[0]:.2f}'))
            print(f'no logo: {league} / {club} (best {best[1]} {best[0]:.2f})', file=sys.stderr)
    rows = [r + (image(r[2]) if r[2] else '',) for r in rows]
    with open(OUT_CSV, 'w', newline='', encoding='utf-8') as fh:
        w = csv.writer(fh)
        w.writerow(['league', 'club', 'file', 'score', 'image'])
        w.writerows(rows)
    draw(sorted({(r[2], r[4]) for r in rows if r[2]}))
    print(f'{found} of {len(rows)} clubs have a logo')


if __name__ == '__main__':
    main()
