// The broadcast-angle 2.5D projection (docs/MATCH_VIEW.md 4). Pitch
// coordinates are decimetres: x 0..1050, y 0..680 (y = 0 far touchline).
export const VIEW_W = 1000
export const VIEW_H = 560

export function project(x: number, y: number): { sx: number; sy: number; s: number } {
  const t = y / 680
  const s = 0.64 + 0.36 * t
  return {
    sx: 500 + ((x - 525) / 1050) * 940 * s,
    sy: 92 + 430 * (0.62 * t + 0.38 * t * t),
    s,
  }
}
