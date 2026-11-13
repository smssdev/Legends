import { describe, expect, it } from 'vitest'
import { DOCK, MORE_IN_SLOT, PAGE_LABELS, SECTIONS } from './nav'

// [Sprint 60 F1] Every page of the dock and «المزيد» has its one name (docs/design/nav.json, the app's too) here too.
describe('the frame from nav.json', () => {
  it('names each page as nav.json does, and every one exists', () => {
    for (const name of [...DOCK.flatMap((d) => d.items), ...MORE_IN_SLOT]) {
      const s = SECTIONS.find((x) => x.name === name)
      expect(s, name).toBeDefined()
      expect(s!.label, name).toBe(PAGE_LABELS[name])
    }
  })
  it('has the six sections of the approved draft', () => {
    expect(DOCK.map((d) => d.label)).toEqual(['المكتب', 'الفريق', 'التكتيك', 'المباراة', 'السوق', 'النادي'])
  })
})
