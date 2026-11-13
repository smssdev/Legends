// [Sprint 24 W3] A short rising chime for a slot opened at once (the owner's "sound and visual effect"). [Sprint 63 G12]
// The app's own success chime now (web/public/sounds/ui/confirm), at the interface's level: one sound on both.
import { uiSound } from './soundLevels'

export function chime() {
  uiSound('confirm')
}
