// The names dictionary [X40]: the Arabic name of each league, club and player by the Latin name the game stores,
// from data/names (leagues by hand, clubs by hand and from Wikidata, players from Wikidata) and the Arab leagues'
// file (data/arab, X34). Runs before dev and build; the site loads it once (lib/names.ts), and the names switch in
// «حسابي» shows the Arabic names (the default) or the Latin ones. A name with no Arabic stays Latin.
import fs from 'node:fs';

const root = new URL('../../data/', import.meta.url);
const out = new URL('../public/names/ar.json', import.meta.url);

/** A small CSV reader: quoted fields with commas and doubled quotes, as Python's csv writes them. */
function rows(file) {
  let text;
  try { text = fs.readFileSync(new URL(file, root), 'utf8').replace(/^﻿/, ''); } catch { return []; }
  const out = [];
  let row = [], field = '', quoted = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (quoted) {
      if (c === '"' && text[i + 1] === '"') { field += '"'; i++; } else if (c === '"') quoted = false; else field += c;
    } else if (c === '"') quoted = true;
    else if (c === ',') { row.push(field); field = ''; }
    else if (c === '\n' || c === '\r') { if (c === '\r' && text[i + 1] === '\n') i++; row.push(field); out.push(row); row = []; field = ''; }
    else field += c;
  }
  if (field || row.length) { row.push(field); out.push(row); }
  const [head, ...body] = out.filter((r) => r.length > 1);
  return (body ?? []).map((r) => Object.fromEntries((head ?? []).map((h, i) => [h, r[i] ?? ''])));
}

const arabic = (s) => /[؀-ۿ]/.test(s ?? '');
const dict = { leagues: {}, clubs: {}, players: {}, nations: {} };
for (const r of rows('names/leagues.csv')) if (arabic(r.ar)) dict.leagues[r.name] = r.ar;
// Wikidata first, then the hand-written table over it.
for (const r of rows('names/clubs.csv')) if (arabic(r.ar)) dict.clubs[r.name] = r.ar;
for (const r of rows('names/clubs_manual.csv')) if (arabic(r.ar)) dict.clubs[r.name] = r.ar;
// [Sprint 29] The national teams (written from App\Data\Nations).
for (const r of rows('names/nations.csv')) if (arabic(r.ar)) dict.clubs[r.name] = r.ar;
dict.leagues['National Teams'] = 'المنتخبات';
// [Sprint 30, the owner's decision 2026-11-01] The players' names are English on every screen: none in Arabic here.
// [Sprint 30 Q10] The nationalities in Arabic (Belgium → بلجيكا), from the national teams' names (Sprint 29).
for (const r of rows('names/nations.csv')) if (r.name && arabic(r.ar)) dict.nations[r.name] = r.ar;

fs.mkdirSync(new URL('.', out), { recursive: true });
fs.writeFileSync(out, JSON.stringify(dict));
console.log(`names: ${Object.keys(dict.leagues).length} leagues, ${Object.keys(dict.clubs).length} clubs, ${Object.keys(dict.nations).length} nations in Arabic`);
