// Components registered for every template (main.ts).
import BrandMark from './components/BrandMark.vue'
import AppImage from './components/ui/AppImage.vue'

declare module 'vue' {
  export interface GlobalComponents {
    BrandMark: typeof BrandMark
    AppImage: typeof AppImage
  }
}
