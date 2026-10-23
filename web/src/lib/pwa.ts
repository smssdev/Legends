// The site as an app (Sprint 36): the browser's install offer, kept for our own button, and this browser's push
// subscription for the game's notifications. On iPhone there is no install offer: the site is added from Share,
// and pushes work only once it is on the home screen (iOS 16.4 and later).
import { ref } from 'vue'

type InstallEvent = Event & { prompt: () => Promise<void>; userChoice: Promise<{ outcome: string }> }

export const installable = ref(false)
let offer: InstallEvent | null = null
if (typeof window !== 'undefined') {
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault()
    offer = e as InstallEvent
    installable.value = true
  })
  window.addEventListener('appinstalled', () => (installable.value = false))
}

export async function install(): Promise<boolean> {
  if (!offer) return false
  await offer.prompt()
  const { outcome } = await offer.userChoice
  offer = null
  installable.value = false
  return outcome === 'accepted'
}

export const isIos = () => /iphone|ipad|ipod/i.test(navigator.userAgent)
export const standalone = () => window.matchMedia?.('(display-mode: standalone)').matches || (navigator as any).standalone === true
export const pushSupported = () => 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window

function key(base64: string): Uint8Array {
  const pad = '='.repeat((4 - (base64.length % 4)) % 4)
  const raw = atob((base64 + pad).replace(/-/g, '+').replace(/_/g, '/'))
  return Uint8Array.from(raw, (c) => c.charCodeAt(0))
}

/** This browser's subscription, if it has one. */
export async function currentSubscription(): Promise<PushSubscription | null> {
  if (!pushSupported()) return null
  const reg = await navigator.serviceWorker.getRegistration()
  return (await reg?.pushManager.getSubscription()) ?? null
}

/** Ask for permission and subscribe with the server's key. Null when refused or not possible here. */
export async function subscribe(publicKey: string): Promise<PushSubscription | null> {
  if (!pushSupported() || (await Notification.requestPermission()) !== 'granted') return null
  const reg = await navigator.serviceWorker.ready
  return (await reg.pushManager.getSubscription()) ?? reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: key(publicKey) })
}
