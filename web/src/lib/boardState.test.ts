import { describe, expect, it } from 'vitest'
import { boardState, type BoardFacts } from './boardState'

const base: BoardFacts = {
  board: false,
  loading: false,
  error: false,
  slotsReady: true,
  slotsError: false,
  slotLeague: null,
  boardLeague: null,
}

describe('boardState [Sprint 75 W1, WEB-01]', () => {
  it('a new coach with no club gets «none» at once, not a skeleton for ever', () => {
    expect(boardState(base)).toBe('none')
  })

  it('waits while the slots have not answered yet, even with no league', () => {
    expect(boardState({ ...base, slotsReady: false })).toBe('wait')
  })

  it('waits while the board is on its way', () => {
    expect(boardState({ ...base, slotLeague: 7, boardLeague: 7, loading: true })).toBe('wait')
  })

  it('waits for the slot league the shell has not asked for yet', () => {
    expect(boardState({ ...base, slotLeague: 7, boardLeague: null })).toBe('wait')
    expect(boardState({ ...base, slotLeague: 7, boardLeague: 3 })).toBe('wait')
  })

  it('no club in the slot league (left, or not yet taken) is «none»', () => {
    expect(boardState({ ...base, slotLeague: 7, boardLeague: 7 })).toBe('none')
  })

  it('a failure of the server or the network is an error, never «none»', () => {
    expect(boardState({ ...base, slotLeague: 7, boardLeague: 7, error: true })).toBe('error')
    expect(boardState({ ...base, slotsError: true })).toBe('error')
  })

  it("an earlier league's failure does not hide «none» from a coach with no club", () => {
    expect(boardState({ ...base, error: true, boardLeague: 3 })).toBe('none')
  })

  it('the board shows once it is here, whatever else', () => {
    expect(boardState({ ...base, board: true, loading: true, slotsReady: false })).toBe('board')
  })
})
