// [X82] The site's own accounts and its credit line, in one place (the footer, PublicFooter.vue, reads them).
// A social account without its real address stays null, and the footer shows no button for it: never a made-up link.

/** The game's email, for the coaches' problems and ideas (the address the game's own emails come from). */
export const EMAIL = 'game.legend.manager@gmail.com'

export type Social = { key: 'facebook' | 'instagram' | 'tiktok' | 'youtube'; name: string; url: string | null }

export const SOCIALS: Social[] = [
  { key: 'facebook', name: 'Facebook', url: 'https://www.facebook.com/profile.php?id=61595892341604' },
  { key: 'instagram', name: 'Instagram', url: 'https://www.instagram.com/gamelegendmanager/' },
  { key: 'tiktok', name: 'TikTok', url: 'https://www.tiktok.com/@matchzone100' },
  { key: 'youtube', name: 'YouTube', url: 'https://www.youtube.com/@GameLegendManager' },
]

/**
 * «Made with ♥ by …»: the team's name and where it links. An address starting with / is a page of the game; a full
 * https:// address opens in a new tab [X98: the team's own site, the developers' page is gone]. Change these two lines to rename it.
 */
export const TEAM = { name: 'GLM Team', url: 'https://nesr.site' }
