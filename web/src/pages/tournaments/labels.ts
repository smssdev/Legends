// [Sprint 29] The tournaments' words: the templates, the formats and the knockout's stages (in Arabic; the screens pass
// them through $t).
export const TEMPLATES: Record<string, string> = {
  world_cup: 'كأس العالم',
  club_world_cup: 'كأس العالم للأندية',
  afcon: 'كأس أمم أفريقيا',
  euro: 'كأس أمم أوروبا',
  asian_cup: 'كأس آسيا',
  custom: 'بطولة مخصصة',
}
export const TEMPLATE_NOTES: Record<string, string> = {
  world_cup: 'أقوى المنتخبات من كل القارات',
  club_world_cup: 'أقوى الأندية، ناديان على الأكثر من كل دوري',
  afcon: 'منتخبات أفريقيا',
  euro: 'منتخبات أوروبا',
  asian_cup: 'منتخبات آسيا',
  custom: 'منتخبات وأندية تختارها، من فريقين',
}
export const FORMATS: Record<string, string> = { league: 'دوري', groups: 'مجموعات ثم إقصاء', knockout: 'خروج المغلوب' }
export const STAGES: Record<string, string> = { preliminary: 'الدور التمهيدي', r16: 'دور الـ16', qf: 'ربع النهائي', sf: 'نصف النهائي', final: 'النهائي' }
export const CONFEDERATIONS: Record<string, string> = { UEFA: 'أوروبا', CAF: 'أفريقيا', AFC: 'آسيا', CONMEBOL: 'أمريكا الجنوبية', CONCACAF: 'أمريكا الشمالية', OFC: 'أوقيانوسيا' }
