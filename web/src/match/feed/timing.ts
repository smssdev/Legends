// [Sprint 37 R1] The scenes' timing, apart from story.ts so the pure modules (director.ts) and their node checks
// load it without the i18n and the commentary lines.
// The scene's own length in seconds, and when its key moment happens (see art.ts).
export const SCENE_TIME = {
  // [Sprint 42] The cartoon clips: the card is up at 3.4 s after the foul and its drama; the penalty opens with the
  // referee pointing to the spot (1.2 s); a foul's contact at 1.5 s; the injury and the sub longer and funnier.
  goal: [6.0, 3.0], save: [5.4, 2.9], penalty: [6.8, 4.05], freekick: [5.2, 2.65], card: [6.6, 3.4], coach: [4.6, 1.0], sub: [5.0, 0.8],
  offside: [4.2, 1.5], corner: [4.6, 1.75], injury: [5.6, 0.4], foul: [5.2, 1.5], whistle: [3.6, 0.6], miss: [5.0, 2.9], blocked: [4.8, 2.6], board: [3.0, 0.5],
  // [Sprint 35 C1] The director's cutaways after a scene.
  crowd: [2.6, 0.3], coachReact: [2.4, 0.2], brawl: [2.8, 0.2], tunnel: [2.8, 0.2], handshake: [3.0, 0.2],
  // [Sprint 35 C3] A goal ruled out by VAR: the ball in at 3.0 s, the check, no goal at 6.4 s.
  var: [8.2, 6.4],
  // [Sprint 42 F] The second set, 3 to 5 s each: a clearance off the line (kicked off at 2.4 s), the offside trap (the
  // flag at 1.5 s), the coach's megaphone, a slip in the rain, and the coach's meltdown after a chance blasted over.
  clearance: [4.2, 2.4], trap: [3.6, 1.5], rant: [3.6, 0.6], slip: [3.6, 1.0], meltdown: [2.8, 0.3],
}
