// Components registered for every template (main.ts).
import BrandMark from './components/BrandMark.vue'

declare module 'vue' {
  export interface GlobalComponents {
    BrandMark: typeof BrandMark
  }
}
