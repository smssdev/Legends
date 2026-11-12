// [Sprint 57 W1] The server's clock on this screen: server time = Date.now() + offset, taken from the reply that came
// back fastest (a live match plays every minute at its instant on that clock, on every screen), and a ticker that runs
// once a second on the second's turn, so a countdown never shows a second late (W-P14).
export function useMatchClock() {
  let offset = 0
  let bestRtt = Infinity
  let timer = 0
  let interval = 0

  const serverNow = () => Date.now() + offset

  /** A reply's server time: sentAt is when the request left (Date.now()). */
  function sample(sentAt: number, serverMs: number) {
    const back = Date.now(), rtt = back - sentAt
    bestRtt += 2 // older samples count a little less, so a drifting clock is followed
    if (rtt <= bestRtt) { bestRtt = rtt; offset = serverMs - (sentAt + back) / 2 }
  }

  /** Calls tick now, then on every turn of the server's second. */
  function start(tick: () => void) {
    stop()
    tick()
    timer = window.setTimeout(() => {
      tick()
      interval = window.setInterval(tick, 1000)
    }, 1000 - (((serverNow() % 1000) + 1000) % 1000))
  }

  function stop() {
    window.clearTimeout(timer)
    window.clearInterval(interval)
  }

  return { serverNow, sample, start, stop }
}
