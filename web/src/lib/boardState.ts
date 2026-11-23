// [Sprint 75 W1, WEB-01] What the club board shows: the board, a wait, «you have no team yet», or an error with a retry.
// A new coach with no club waited on a skeleton for ever, since «no club» and «not loaded yet» looked the same. Only a
// finished answer is «none»: the slots came with no club, or this league's board came back empty (4xx: left, or not
// yet taken). A failure of the server or the network is an error, never «none».

export type BoardState = 'board' | 'wait' | 'none' | 'error'

export interface BoardFacts {
  /** The board is here. */
  board: boolean
  /** A request for the board is on its way. */
  loading: boolean
  /** The board's last request failed for the server or the network. */
  error: boolean
  /** The slots' first answer came (or failed). */
  slotsReady: boolean
  /** The slots could not be loaded. */
  slotsError: boolean
  /** The league of the slot the coach is in, null for none. */
  slotLeague: number | null
  /** The league the board was last asked for. */
  boardLeague: number | null
}

export function boardState(f: BoardFacts): BoardState {
  if (f.board) return 'board'
  if (f.loading || !f.slotsReady) return 'wait'
  if (f.slotsError) return 'error'
  if (f.slotLeague === null) return 'none'
  // The slot's league, not yet asked for: the shell asks for it next. A failure counts for this league's request only.
  if (f.boardLeague !== f.slotLeague) return 'wait'
  return f.error ? 'error' : 'none'
}
