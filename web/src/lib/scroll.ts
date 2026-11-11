// [Sprint 55 W1] The screen scrolls inside the frame (AppShell's .shell-main), not the window: back to its top.
export function scrollToTop(smooth = false) {
  const box = document.querySelector<HTMLElement>('.shell-main')
  ;(box ?? window).scrollTo({ top: 0, behavior: smooth ? 'smooth' : 'auto' })
}
