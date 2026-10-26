"""The Arabic names of the EA players and clubs [X40], from Wikidata (CC0), for the names switch (Arabic by default).

    python3 tools/data/arabic_names.py      # writes data/names/players.csv and data/names/clubs.csv

Players: Wikidata's search for each EA player's name, then the candidates' birth dates: a footballer born on the EA
birth date is the same man, and his Arabic label is his name (no label: he stays in Latin letters). Clubs: each EA
club takes the Arabic name of the club most of its matched players play for now (P54 without an end), when most of
them agree. Through Wikidata's ordinary API (its query service is often rate-limited or down). Every answer is kept
on disk, so a second run asks nothing again. The Arab leagues carry their own Arabic names (data/arab, X34); the
leagues' names are written by hand in data/names/leagues.csv, and data/names/clubs_manual.csv overrides any club.
"""
import collections
import concurrent.futures
import csv
import hashlib
import json
import os
import re
import time
import unicodedata
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'data', 'names')
CACHE = os.path.join(os.path.expanduser('~'), '.cache', 'legends-wikidata-api')
UA = {'User-Agent': 'LegendsGameData/1.0 (Arabic football manager game; https://github.com/smssdev/Legends)'}
API = 'https://www.wikidata.org/w/api.php?'


def get(params):
    params = dict(params, format='json')
    url = API + urllib.parse.urlencode(params)
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, hashlib.sha256(url.encode()).hexdigest() + '.json')
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    for attempt in range(7):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=40) as r:
                data = json.load(r)
            if 'error' in data and data['error'].get('code') == 'maxlag':
                raise RuntimeError('maxlag')
            with open(path, 'w') as f:
                json.dump(data, f)
            return data
        except Exception:
            time.sleep(4 * (attempt + 1))
    return {}


def plain(s):
    s = unicodedata.normalize('NFKD', s or '')
    return re.sub(r'[^a-z ]', '', ''.join(c for c in s if not unicodedata.combining(c)).lower().replace('-', ' ')).strip()


def entities(ids, props):
    out = {}
    ids = sorted(set(ids))
    for i in range(0, len(ids), 50):
        d = get({'action': 'wbgetentities', 'ids': '|'.join(ids[i:i + 50]), 'props': props, 'languages': 'ar|en'})
        out.update(d.get('entities') or {})
    return out


def claim_ids(e, prop, current=False):
    out = []
    for s in (e.get('claims') or {}).get(prop, []):
        if current and 'P582' in (s.get('qualifiers') or {}):
            continue
        v = ((s.get('mainsnak') or {}).get('datavalue') or {}).get('value')
        if isinstance(v, dict) and v.get('id'):
            out.append(v['id'])
    return out


def born(e):
    for s in (e.get('claims') or {}).get('P569', []):
        v = ((s.get('mainsnak') or {}).get('datavalue') or {}).get('value', {}).get('time')
        if v:
            return v[1:11]
    return None


def label(e, lang):
    return ((e.get('labels') or {}).get(lang) or {}).get('value', '')


def main():
    os.makedirs(OUT, exist_ok=True)
    players = []
    for f in ('ea_fc26_outfield.csv', 'ea_fc26_goalkeepers.csv'):
        with open(os.path.join(ROOT, 'data', 'ea-fc26', f), encoding='utf-8') as h:
            players += [r for r in csv.DictReader(h) if r['birthdate']]
    shown = {r['id']: (r['commonName'].strip() or (r['firstName'] + ' ' + r['lastName']).strip()) for r in players}

    def candidates(r):
        full = (r['firstName'] + ' ' + r['lastName']).strip()
        names = [n for n in dict.fromkeys([shown[r['id']], full]) if n]
        ids = []
        for n in names:
            d = get({'action': 'wbsearchentities', 'search': n, 'language': 'en', 'type': 'item', 'limit': 7})
            ids += [x['id'] for x in d.get('search', [])]
        return r, ids

    found, qid_of = {}, {}
    done = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        batch = []
        for r, ids in pool.map(candidates, players):
            batch.append((r, ids))
            done += 1
            if len(batch) >= 300 or done == len(players):
                ents = entities([q for _, ids in batch for q in ids], 'claims|labels')
                for r, ids in batch:
                    hits = [q for q in dict.fromkeys(ids) if q in ents and born(ents[q]) == r['birthdate'][:10]]
                    if len(hits) == 1:
                        qid_of[r['id']] = hits[0]
                        ar = label(ents[hits[0]], 'ar')
                        if ar:
                            found[r['id']] = re.sub(r'\s*\(.*?\)\s*$', '', ar).strip()
                batch = []
                print(f'players: {done}/{len(players)}, {len(qid_of)} matched, {len(found)} in Arabic', flush=True)

    # The clubs: where most of each club's matched players play now.
    team = {r['id']: r['team'] for r in players}
    ents = entities(set(qid_of.values()), 'claims')
    votes = collections.defaultdict(collections.Counter)
    for pid, q in qid_of.items():
        for c in claim_ids(ents.get(q, {}), 'P54', current=True):
            votes[team[pid]][c] += 1
    names = entities({c for v in votes.values() for c in v}, 'labels')
    clubs = {}
    for name, v in votes.items():
        (c, n), total = v.most_common(1)[0], sum(v.values())
        ar = label(names.get(c, {}), 'ar')
        if n >= 3 and n * 2 > total and ar and 'national' not in label(names.get(c, {}), 'en').lower():
            clubs[name] = ar

    with open(os.path.join(OUT, 'players.csv'), 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['id', 'name', 'ar'])
        for pid in sorted(found, key=int):
            w.writerow([pid, shown[pid], found[pid]])
    with open(os.path.join(OUT, 'clubs.csv'), 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['name', 'ar'])
        for name in sorted(clubs):
            w.writerow([name, clubs[name]])
    print(f'{len(found)} players and {len(clubs)} clubs in Arabic, written to {OUT}')


if __name__ == '__main__':
    main()
