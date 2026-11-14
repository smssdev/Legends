// [Sprint 66 T2] The web's lint: Vue's recommended rules with TypeScript (eslint-plugin-vue, typescript-eslint), and
// Prettier's look left to Prettier (.prettierrc). `npm run lint` before every PR; CI runs it.
import pluginVue from 'eslint-plugin-vue'
import { defineConfigWithVueTs, vueTsConfigs } from '@vue/eslint-config-typescript'
import skipFormatting from '@vue/eslint-config-prettier/skip-formatting'

export default defineConfigWithVueTs(
  { ignores: ['dist/**', 'public/**', 'src/api/schema.d.ts', 'src/styles/tokens.css', 'e2e/**/*-snapshots/**', 'test-results/**'] },
  pluginVue.configs['flat/recommended'],
  vueTsConfigs.recommended,
  skipFormatting,
  {
    rules: {
      // The look is Prettier's.
      'vue/first-attribute-linebreak': 'off',
      'vue/attributes-order': 'off',
      // The pages are named by what they are (Home.vue, Market.vue), as the router lists them.
      'vue/multi-word-component-names': 'off',
      // Optional props are typed (defineProps<{ x?: T }>): undefined is their default.
      'vue/require-default-prop': 'off',
      // Every v-html goes through esc() and scripts/safe-html.mjs checks it before each build.
      'vue/no-v-html': 'off',
      // `ok && go()` and `a ? b() : c()` as statements are the house style.
      '@typescript-eslint/no-unused-expressions': ['error', { allowShortCircuit: true, allowTernary: true }],
      // The drawing code's few untyped corners are flagged, not failed (vue-tsc's strict mode is the gate).
      '@typescript-eslint/no-explicit-any': 'warn',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_', varsIgnorePattern: '^_', caughtErrors: 'none' }],
    },
  },
  // A declaration file's interfaces merge into the library's (ImportMetaEnv): they are used where they land.
  { files: ['**/*.d.ts'], rules: { '@typescript-eslint/no-unused-vars': 'off' } },
)
