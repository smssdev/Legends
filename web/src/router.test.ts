// [Sprint 75 W8, WEB-08] The server answers 404 for an address that is no page of the app (deploy/docker/router.php,
// App\Support\AppPages), from public/app-routes.json: the list must be the router's own, or a real page would go out
// as «not found» to Google (and a page gone from the app would still answer 200). A new route is written there too.
import { describe, expect, it } from 'vitest'
import known from '../public/app-routes.json'
import { router } from './router'

describe('public/app-routes.json', () => {
  it('is every page of the router, the «not found» catch-all aside', () => {
    const routes = [...new Set(router.getRoutes().map((r) => r.path))].filter((p) => !p.includes(':pathMatch')).sort()
    expect([...known.paths].sort()).toEqual(routes)
  })

  it('writes each route in the shapes the server reads (":name", ":name(re)", ":name?")', () => {
    for (const path of known.paths) {
      for (const segment of path.split('/').filter(Boolean)) {
        if (segment.startsWith(':')) expect(segment, path).toMatch(/^:\w+(\(.+\))?\??$/)
        else expect(segment, path).toMatch(/^[\w-]+$/)
      }
    }
  })
})
