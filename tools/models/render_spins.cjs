// [Sprint 61 F2] The app's models as pictures, not a web view: each .glb of tools/models/glb (make_models.py) turned once around
// (24 frames, 15° apart) from the angle its screen showed it, lit as model-viewer lit it, on a clear ground. Then
// spins.py joins the frames into one strip a model (WebP, 512 and 256 high) for GlmModelSpin.
//
//   npm i --no-save --no-package-lock --prefix tools/models three@0.170.0
//   NODE_PATH=$(npm root -g) node tools/models/render_spins.cjs     # tools/models/frames/<model>/NN.png
//   python3 tools/models/spins.py                                   # mobile/assets/models/<model>_spin_{512,256}.webp
const fs = require('fs')
const path = require('path')
const { chromium } = require('playwright')

const MODELS = path.join(__dirname, 'glb')
const THREE = path.join(__dirname, 'node_modules', 'three')
const OUT = path.join(__dirname, 'frames')

// Each model's camera as its screen had it (model-viewer's camera-orbit): its height (degrees from the top) and its
// first turn; the distance frames the model whole.
const VIEW = {
  trophy: { polar: 78, theta: 0 },
  player_card: { polar: 80, theta: 0 },
  stadium: { polar: 62, theta: 30 },
  chest_bronze: { polar: 75, theta: 0 },
  chest_silver: { polar: 75, theta: 0 },
  chest_legend: { polar: 75, theta: 0 },
}
const FRAMES = 24
const SIZE = 512

const page = `<!doctype html><html><body style="margin:0;background:transparent">
<script type="importmap">{"imports":{"three":"/three/build/three.module.js","three/addons/":"/three/examples/jsm/"}}</script>
<script type="module">
import * as THREE from 'three'
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js'
import { RoomEnvironment } from 'three/addons/environments/RoomEnvironment.js'
const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, preserveDrawingBuffer: true })
renderer.setPixelRatio(1)
renderer.setSize(${SIZE}, ${SIZE})
renderer.setClearColor(0x000000, 0)
renderer.outputColorSpace = THREE.SRGBColorSpace
renderer.toneMapping = THREE.NeutralToneMapping
renderer.toneMappingExposure = 0.75
document.body.appendChild(renderer.domElement)
const scene = new THREE.Scene()
scene.environment = new THREE.PMREMGenerator(renderer).fromScene(new RoomEnvironment(), 0.04).texture
const camera = new THREE.PerspectiveCamera(30, 1, 0.01, 100)
let model
window.load = async (name, polar, theta) => {
  if (model) scene.remove(model)
  model = (await new GLTFLoader().loadAsync('/models/' + name + '.glb')).scene
  const box = new THREE.Box3().setFromObject(model)
  const centre = box.getCenter(new THREE.Vector3())
  model.position.sub(centre)
  const pivot = new THREE.Group()
  pivot.add(model)
  scene.add(pivot)
  model = pivot
  const radius = box.getBoundingSphere(new THREE.Sphere()).radius
  const d = radius / Math.sin(THREE.MathUtils.degToRad(15)) * 1.05
  const p = THREE.MathUtils.degToRad(polar), t = THREE.MathUtils.degToRad(theta)
  camera.position.set(d * Math.sin(p) * Math.sin(t), d * Math.cos(p), d * Math.sin(p) * Math.cos(t))
  camera.lookAt(0, 0, 0)
}
window.frame = (i) => {
  model.rotation.y = (i / ${FRAMES}) * Math.PI * 2
  renderer.render(scene, camera)
  return renderer.domElement.toDataURL('image/png')
}
window.ready = true
</script></body></html>`

;(async () => {
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] })
  const tab = await browser.newPage({ viewport: { width: SIZE, height: SIZE } })
  await tab.route('http://spin.local/**', (route) => {
    const url = new URL(route.request().url())
    if (url.pathname === '/') return route.fulfill({ contentType: 'text/html', body: page })
    const [, kind, ...rest] = url.pathname.split('/')
    const file = kind === 'three' ? path.join(THREE, ...rest) : path.join(MODELS, ...rest)
    const type = file.endsWith('.js') ? 'text/javascript' : 'model/gltf-binary'
    return route.fulfill({ contentType: type, body: fs.readFileSync(file) })
  })
  tab.on('pageerror', (e) => console.error(e))
  await tab.goto('http://spin.local/')
  await tab.waitForFunction(() => window.ready)
  for (const [name, v] of Object.entries(VIEW)) {
    await tab.evaluate(([n, p, t]) => window.load(n, p, t), [name, v.polar, v.theta])
    const dir = path.join(OUT, name)
    fs.mkdirSync(dir, { recursive: true })
    for (let i = 0; i < FRAMES; i++) {
      const data = await tab.evaluate((k) => window.frame(k), i)
      fs.writeFileSync(path.join(dir, String(i).padStart(2, '0') + '.png'), Buffer.from(data.split(',')[1], 'base64'))
    }
    console.log(`${name}: ${FRAMES} frames`)
  }
  await browser.close()
})()
