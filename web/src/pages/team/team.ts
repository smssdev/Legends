// My club in the current league (Sprint 16): loads the team sheet once for the squad and lineup screens.
import { ref } from 'vue'
import { api, asApiError } from '../../api/client'
import type { components } from '../../api/schema'
import { currentLeague } from '../../lib/currentLeague'

export type Team = components['responses']['Team']['content']['application/json']
export type SquadPlayer = components['schemas']['SquadPlayer']
export type Lineup = components['schemas']['Lineup']
export type Formation = components['schemas']['Formation']

export function useTeam() {
  const leagueId = ref<number | null>(null)
  const team = ref<Team | null>(null)
  const error = ref('')
  const loaded = ref(false)

  async function load() {
    error.value = ''
    try {
      leagueId.value = await currentLeague()
      if (leagueId.value) {
        const { data } = await api.GET('/leagues/{league}/team', { params: { path: { league: leagueId.value } } })
        team.value = data as Team
      }
    } catch (e) {
      error.value = asApiError(e).message
    }
    loaded.value = true
  }

  return { leagueId, team, error, loaded, load }
}

/** Arabic names of the six attributes and the keeper's five. */
export const ATTRIBUTES: Record<string, string> = {
  pac: 'السرعة', sho: 'التسديد', pas: 'التمرير', dri: 'المراوغة', def: 'الدفاع', phy: 'البدنية',
  diving: 'الارتماء', handling: 'الإمساك', kicking: 'الركل', positioning: 'التمركز', reflexes: 'رد الفعل',
}

/** Green when good, gold in between, orange when low (the design's bars). */
export const barColor = (v: number) => (v >= 80 ? 'bg-success' : v >= 60 ? 'bg-gold' : 'bg-warning')
