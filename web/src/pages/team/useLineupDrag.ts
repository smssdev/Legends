// [Sprint 56 W3] The lineup's drag, moved out of Lineup.vue as it was (pointer events: the same code for a finger and a
// mouse). A ghost follows the finger; on release, the spot under it ([data-spot="zone:index"]) receives, and a
// starter let go on open grass stays where he is dropped (the screen's `dropOnGrass`). Near the list column's top or
// bottom edge that list scrolls. The click that follows a drag does not also select (`justDragged`).
import { ref, type Ref } from 'vue'

export type Spot = { zone: 'slot' | 'bench' | 'reserve'; index: number }

export interface DragHooks {
  editing: Ref<boolean>
  listBox: Ref<HTMLElement | null>
  playerAt: (s: Spot) => number | null
  move: (from: Spot, to: Spot) => void
  remember: () => void
  later: () => void
  dropOnGrass: (slot: number, e: PointerEvent) => void
}

export function useLineupDrag(h: DragHooks) {
  const drag = ref<{ from: Spot; id: number; x: number; y: number; moved: boolean } | null>(null)
  let edge = 0
  let scrolling = false
  let suppress = false

  function down(e: PointerEvent, s: Spot) {
    const id = h.playerAt(s)
    if (id === null || !h.editing.value) return
    drag.value = { from: s, id, x: e.clientX, y: e.clientY, moved: false }
    window.addEventListener('pointermove', follow)
    window.addEventListener('pointerup', up, { once: true })
    // [Sprint 30 Q7] A touch the phone takes back (a call, a system gesture) drops nothing anywhere: the drag ends.
    window.addEventListener('pointercancel', cancel, { once: true })
  }
  function cancel() {
    window.removeEventListener('pointermove', follow)
    window.removeEventListener('pointerup', up)
    window.removeEventListener('pointercancel', cancel)
    edge = 0
    drag.value = null
  }
  function follow(e: PointerEvent) {
    if (!drag.value) return
    if (Math.hypot(e.clientX - drag.value.x, e.clientY - drag.value.y) > 8) drag.value.moved = true
    drag.value.x = e.clientX
    drag.value.y = e.clientY
    const box = h.listBox.value?.getBoundingClientRect()
    edge = !box || e.clientX < box.left || e.clientX > box.right ? 0 : e.clientY < box.top + 50 ? -14 : e.clientY > box.bottom - 50 ? 14 : 0
    if (edge && !scrolling) scroll()
  }
  function scroll() {
    if (!drag.value || !edge) {
      scrolling = false
      return
    }
    scrolling = true
    h.listBox.value?.scrollBy(0, edge)
    requestAnimationFrame(scroll)
  }
  function up(e: PointerEvent) {
    window.removeEventListener('pointermove', follow)
    window.removeEventListener('pointercancel', cancel)
    edge = 0
    const d = drag.value
    drag.value = null
    if (!d?.moved) return
    const el = document.elementFromPoint(e.clientX, e.clientY)?.closest<HTMLElement>('[data-spot]')
    if (el) {
      const [zone, index] = el.dataset.spot!.split(':')
      h.move(d.from, { zone: zone as Spot['zone'], index: Number(index) })
    } else if (d.from.zone === 'slot' && d.from.index > 0) {
      h.remember()
      h.dropOnGrass(d.from.index, e)
    }
    h.later()
    suppress = true
    window.setTimeout(() => (suppress = false), 0)
  }

  return { drag, down, cancel, justDragged: () => suppress }
}
