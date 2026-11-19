// vue/global/en/context.ts
import { createApp } from "vue";

// vue/global/en/AuthApp.vue
import { defineComponent as _defineComponent3 } from "vue";
import { createElementVNode as _createElementVNode3, createVNode as _createVNode, Fragment as _Fragment, openBlock as _openBlock3, createElementBlock as _createElementBlock3 } from "vue";

// vue/global/en/auth.ts
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

// vue/global/en/Profile.vue
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
          "Your profile",
          -1
          /* CACHED */
        )),
        _createElementVNode(
          "p",
          _hoisted_2,
          _toDisplayString(_unref(user) ? `${_unref(user).name} \xB7 Member since 2025` : "Guest"),
          1
          /* TEXT */
        )
      ]);
    };
  }
});
var Profile_default = _sfc;

// vue/global/en/UserMenu.vue
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
        onClick: _cache[0] || (_cache[0] = ($event) => _unref2(signIn)("Sara"))
      }, "Sign in")) : (_openBlock2(), _createElementBlock2("span", _hoisted_12, [
        _createTextVNode(
          " Hello, " + _toDisplayString2(_unref2(user).name) + " ",
          1
          /* TEXT */
        ),
        _createElementVNode2("button", {
          type: "button",
          class: "secondary",
          onClick: _cache[1] || (_cache[1] = //@ts-ignore
          (...args) => _unref2(signOut) && _unref2(signOut)(...args))
        }, "Sign out")
      ]));
    };
  }
});
var UserMenu_default = _sfc2;

// vue/global/en/AuthApp.vue
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
              "Bit's shop",
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

// vue/global/en/context.ts
createApp(AuthApp_default).mount("#app");
