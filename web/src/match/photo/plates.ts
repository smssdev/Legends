// Each stadium photo's camera, for the depth of everything standing on its grass (MATCH_VIEW 4.7).
// All plates are shot from about a metre up with a 35mm lens, so a person whose feet are at row y
// (0 top, 1 bottom) is (y - horizon) * PERSON / camH of the picture's height tall.
// Calibrated by eye on the arena at night; the same angles in the other stadiums share these numbers.

export interface PlateCamera {
  horizon: number // the horizon's row, 0..1 from the top: things on it have no height
  camH: number // the camera's height above the grass in metres
  /** Where the goal mouth's middle meets the grass, 0..1, when the goal is in the picture. */
  goal?: { x: number; y: number; width: number }
}

export const PERSON = 1.8 // metres

const DEFAULT: PlateCamera = { horizon: 0.5, camH: 1.5 }

const ANGLES: Record<string, Partial<PlateCamera>> = {
  shot: { horizon: 0.5, camH: 1.55, goal: { x: 0.81, y: 0.8, width: 0.22 } },
  'shot-far': { horizon: 0.51, camH: 1.4, goal: { x: 0.885, y: 0.535, width: 0.08 } },
  'goal-front': { horizon: 0.5, camH: 1.4, goal: { x: 0.5, y: 0.71, width: 0.25 } },
  'behind-goal': { horizon: 0.5, camH: 1.2, goal: { x: 0.5, y: 0.6, width: 0.15 } },
  'box-high': { horizon: 0.46, camH: 6, goal: { x: 0.5, y: 0.98, width: 0.2 } },
  run: { horizon: 0.5, camH: 1.4 },
  wing: { horizon: 0.5, camH: 1.4 },
  centre: { horizon: 0.5, camH: 1.5 },
  corner: { horizon: 0.55, camH: 1.3 },
  touchline: { horizon: 0.5, camH: 1.4 },
  bench: { horizon: 0.5, camH: 1.3 },
  monitor: { horizon: 0.5, camH: 1.3 },
  'tunnel-out': { horizon: 0.55, camH: 1.6 },
}

/** The camera for a plate such as 'arena/night/shot': by its angle, the last part of the name. */
export function plateCamera(name: string): PlateCamera {
  return { ...DEFAULT, ...ANGLES[name.slice(name.lastIndexOf('/') + 1)] }
}

/** How tall, as a fraction of the picture's height, a person whose feet are at row y appears. */
export function personHeight(cam: PlateCamera, y: number): number {
  return Math.max(0, ((y - cam.horizon) * PERSON) / cam.camH)
}
