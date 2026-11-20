// vue/global/ar/projects/theme-page.ts
import { createApp } from "vue";

// vue/global/ar/projects/ThemeApp.vue
import { defineComponent as _defineComponent3 } from "vue";
import { createElementVNode as _createElementVNode2, createVNode as _createVNode, Fragment as _Fragment, openBlock as _openBlock3, createElementBlock as _createElementBlock3 } from "vue";

// vue/global/ar/Profile.vue
import { defineComponent as _defineComponent } from "vue";
import { createElementVNode as _createElementVNode, unref as _unref, toDisplayString as _toDisplayString, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";

// vue/global/ar/auth.ts
import { inject, provide, readonly, ref } from "vue";
var AuthKey = /* @__PURE__ */ Symbol("auth");
function provideAuth() {
  const user = ref(null);
  provide(AuthKey, {
    user: readonly(user),
    signIn: (name) => user.value = { name },
    signOut: () => user.value = null
  });
}
function useAuth() {
  const auth = inject(AuthKey);
  if (!auth) throw new Error("useAuth() must be used inside a component that called provideAuth()");
  return auth;
}

// vue/global/ar/Profile.vue
var _hoisted_1 = { class: "card" };
var _hoisted_2 = { class: "muted" };
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Profile",
  setup(__props) {
    const { user } = useAuth();
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("section", _hoisted_1, [
        _cache[0] || (_cache[0] = _createElementVNode(
          "h2",
          null,
          "\u0645\u0644\u0641\u0643 \u0627\u0644\u0634\u062E\u0635\u064A",
          -1
          /* CACHED */
        )),
        _createElementVNode(
          "p",
          _hoisted_2,
          _toDisplayString(_unref(user) ? `${_unref(user).name} \xB7 \u0639\u0636\u0648 \u0645\u0646\u0630 2025` : "\u0632\u0627\u0626\u0631"),
          1
          /* TEXT */
        )
      ]);
    };
  }
});
var Profile_default = _sfc;

// vue/global/ar/projects/ThemeButton.vue
import { defineComponent as _defineComponent2 } from "vue";
import { unref as _unref2, openBlock as _openBlock2, createElementBlock as _createElementBlock2 } from "vue";

// vue/global/ar/projects/theme.ts
import { computed, inject as inject2, provide as provide2, watchEffect } from "vue";
import { useLocalStorage, usePreferredDark } from "@vueuse/core";
var ThemeKey = /* @__PURE__ */ Symbol("theme");
function provideTheme() {
  const system = usePreferredDark();
  const saved = useLocalStorage("dark", null);
  const dark = computed(() => saved.value ?? system.value);
  watchEffect(() => document.documentElement.classList.toggle("dark", dark.value));
  provide2(ThemeKey, { dark, toggle: () => saved.value = !dark.value });
}
function useTheme() {
  const theme = inject2(ThemeKey);
  if (!theme) throw new Error("useTheme() must be used inside a component that called provideTheme()");
  return theme;
}

// vue/global/ar/projects/ThemeButton.vue
var _hoisted_12 = ["aria-pressed"];
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "ThemeButton",
  setup(__props) {
    const { dark, toggle } = useTheme();
    return (_ctx, _cache) => {
      return _openBlock2(), _createElementBlock2("button", {
        type: "button",
        "aria-pressed": _unref2(dark),
        onClick: _cache[0] || (_cache[0] = //@ts-ignore
        (...args) => _unref2(toggle) && _unref2(toggle)(...args))
      }, "\u0627\u0644\u0645\u0638\u0647\u0631 \u0627\u0644\u062F\u0627\u0643\u0646", 8, _hoisted_12);
    };
  }
});
var ThemeButton_default = _sfc2;

// vue/global/ar/projects/ThemeApp.vue
var _sfc3 = /* @__PURE__ */ _defineComponent3({
  __name: "ThemeApp",
  setup(__props) {
    provideAuth();
    provideTheme();
    return (_ctx, _cache) => {
      return _openBlock3(), _createElementBlock3(
        _Fragment,
        null,
        [
          _createElementVNode2("header", null, [
            _cache[0] || (_cache[0] = _createElementVNode2(
              "span",
              { class: "brand" },
              "\u0645\u062A\u062C\u0631 \u0628\u0650\u062A",
              -1
              /* CACHED */
            )),
            _createVNode(ThemeButton_default)
          ]),
          _createVNode(Profile_default)
        ],
        64
        /* STABLE_FRAGMENT */
      );
    };
  }
});
var ThemeApp_default = _sfc3;

// vue/global/ar/projects/theme-page.ts
localStorage.clear();
createApp(ThemeApp_default).mount("#app");
