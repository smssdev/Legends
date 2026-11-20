// vue/global/ar/context.ts
import { createApp } from "vue";

// vue/global/ar/AuthApp.vue
import { defineComponent as _defineComponent3 } from "vue";
import { createElementVNode as _createElementVNode3, createVNode as _createVNode, Fragment as _Fragment, openBlock as _openBlock3, createElementBlock as _createElementBlock3 } from "vue";

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
import { defineComponent as _defineComponent } from "vue";
import { createElementVNode as _createElementVNode, unref as _unref, toDisplayString as _toDisplayString, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
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

// vue/global/ar/UserMenu.vue
import { defineComponent as _defineComponent2 } from "vue";
import { unref as _unref2, openBlock as _openBlock2, createElementBlock as _createElementBlock2, toDisplayString as _toDisplayString2, createElementVNode as _createElementVNode2, createTextVNode as _createTextVNode } from "vue";
var _hoisted_12 = {
  key: 1,
  class: "row"
};
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "UserMenu",
  setup(__props) {
    const { user, signIn, signOut } = useAuth();
    return (_ctx, _cache) => {
      return !_unref2(user) ? (_openBlock2(), _createElementBlock2("button", {
        key: 0,
        type: "button",
        onClick: _cache[0] || (_cache[0] = ($event) => _unref2(signIn)("\u0633\u0627\u0631\u0629"))
      }, "\u0633\u062C\u0651\u0644 \u0627\u0644\u062F\u062E\u0648\u0644")) : (_openBlock2(), _createElementBlock2("span", _hoisted_12, [
        _createTextVNode(
          " \u0623\u0647\u0644\u0627\u064B\u060C " + _toDisplayString2(_unref2(user).name) + " ",
          1
          /* TEXT */
        ),
        _createElementVNode2("button", {
          type: "button",
          class: "secondary",
          onClick: _cache[1] || (_cache[1] = //@ts-ignore
          (...args) => _unref2(signOut) && _unref2(signOut)(...args))
        }, "\u0633\u062C\u0651\u0644 \u0627\u0644\u062E\u0631\u0648\u062C")
      ]));
    };
  }
});
var UserMenu_default = _sfc2;

// vue/global/ar/AuthApp.vue
var _sfc3 = /* @__PURE__ */ _defineComponent3({
  __name: "AuthApp",
  setup(__props) {
    provideAuth();
    return (_ctx, _cache) => {
      return _openBlock3(), _createElementBlock3(
        _Fragment,
        null,
        [
          _createElementVNode3("header", null, [
            _cache[0] || (_cache[0] = _createElementVNode3(
              "span",
              { class: "brand" },
              "\u0645\u062A\u062C\u0631 \u0628\u0650\u062A",
              -1
              /* CACHED */
            )),
            _createVNode(UserMenu_default)
          ]),
          _createElementVNode3("main", null, [
            _createVNode(Profile_default)
          ])
        ],
        64
        /* STABLE_FRAGMENT */
      );
    };
  }
});
var AuthApp_default = _sfc3;

// vue/global/ar/context.ts
createApp(AuthApp_default).mount("#app");
