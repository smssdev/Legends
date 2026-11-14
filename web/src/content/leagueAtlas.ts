// [Sprint 48 D1] Where each of the data's leagues plays, for the league picker's tiles: the country (its flag, drawn by
// LeagueFlag.vue), the region tab it sits under, and its tier at home. Presentation only: the server knows the leagues
// by their names (master_clubs.league_name), and a league missing here still shows, under «أخرى».

export type Region = 'arab' | 'europe' | 'americas' | 'asia' | 'other'

export interface LeaguePlace {
  country: string
  ar: string
  en: string
  region: Region
  tier: number
}

const P = (country: string, ar: string, en: string, region: Region, tier = 1): LeaguePlace => ({ country, ar, en, region, tier })

export const ATLAS: Record<string, LeaguePlace> = {
  'LALIGA EA SPORTS': P('es', 'إسبانيا', 'Spain', 'europe'),
  'LALIGA HYPERMOTION': P('es', 'إسبانيا', 'Spain', 'europe', 2),
  'Premier League': P('gb-eng', 'إنجلترا', 'England', 'europe'),
  'EFL Championship': P('gb-eng', 'إنجلترا', 'England', 'europe', 2),
  'EFL League One': P('gb-eng', 'إنجلترا', 'England', 'europe', 3),
  'EFL League Two': P('gb-eng', 'إنجلترا', 'England', 'europe', 4),
  "Ligue 1 McDonald's": P('fr', 'فرنسا', 'France', 'europe'),
  'Ligue 2 BKT': P('fr', 'فرنسا', 'France', 'europe', 2),
  Bundesliga: P('de', 'ألمانيا', 'Germany', 'europe'),
  'Bundesliga 2': P('de', 'ألمانيا', 'Germany', 'europe', 2),
  '3. Liga': P('de', 'ألمانيا', 'Germany', 'europe', 3),
  'Serie A Enilive': P('it', 'إيطاليا', 'Italy', 'europe'),
  'Serie BKT': P('it', 'إيطاليا', 'Italy', 'europe', 2),
  'Trendyol Süper Lig': P('tr', 'تركيا', 'Türkiye', 'europe'),
  'Liga Portugal': P('pt', 'البرتغال', 'Portugal', 'europe'),
  Eredivisie: P('nl', 'هولندا', 'Netherlands', 'europe'),
  'Scottish Prem': P('gb-sct', 'إسكتلندا', 'Scotland', 'europe'),
  '1A Pro League': P('be', 'بلجيكا', 'Belgium', 'europe'),
  '3F Superliga': P('dk', 'الدنمارك', 'Denmark', 'europe'),
  'Brack Super League': P('ch', 'سويسرا', 'Switzerland', 'europe'),
  Eliteserien: P('no', 'النرويج', 'Norway', 'europe'),
  'Ö. Bundesliga': P('at', 'النمسا', 'Austria', 'europe'),
  SUPERLIGA: P('ro', 'رومانيا', 'Romania', 'europe'),
  'PKO BP Ekstraklasa': P('pl', 'بولندا', 'Poland', 'europe'),
  Allsvenskan: P('se', 'السويد', 'Sweden', 'europe'),
  'SSE Airtricity PD': P('ie', 'أيرلندا', 'Ireland', 'europe'),
  'Hellas Liga': P('gr', 'اليونان', 'Greece', 'europe'),
  'Česká Liga': P('cz', 'التشيك', 'Czechia', 'europe'),
  'ROSHN Saudi League': P('sa', 'السعودية', 'Saudi Arabia', 'arab'),
  'Egyptian Premier League': P('eg', 'مصر', 'Egypt', 'arab'),
  'Qatar Stars League': P('qa', 'قطر', 'Qatar', 'arab'),
  'UAE Pro League': P('ae', 'الإمارات', 'UAE', 'arab'),
  'Botola Pro': P('ma', 'المغرب', 'Morocco', 'arab'),
  'Tunisian Ligue 1': P('tn', 'تونس', 'Tunisia', 'arab'),
  'Algerian Ligue 1': P('dz', 'الجزائر', 'Algeria', 'arab'),
  'Iraq Stars League': P('iq', 'العراق', 'Iraq', 'arab'),
  LPF: P('ar', 'الأرجنتين', 'Argentina', 'americas'),
  MLS: P('us', 'أمريكا', 'USA', 'americas'),
  'K League 1': P('kr', 'كوريا الجنوبية', 'South Korea', 'asia'),
  CSL: P('cn', 'الصين', 'China', 'asia'),
  'A-League': P('au', 'أستراليا', 'Australia', 'asia'),
  ISL: P('in', 'الهند', 'India', 'asia'),
}

export const REGIONS: { key: Region | 'top'; label: string }[] = [
  { key: 'top', label: 'الدوريات الكبرى' },
  { key: 'arab', label: 'الدوريات العربية' },
  { key: 'europe', label: 'أوروبا' },
  { key: 'americas', label: 'الأمريكتان' },
  { key: 'asia', label: 'آسيا وأستراليا' },
  { key: 'other', label: 'أخرى' },
]

export function placeOf(league: string): LeaguePlace {
  return ATLAS[league] ?? P('', league, league, 'other')
}
