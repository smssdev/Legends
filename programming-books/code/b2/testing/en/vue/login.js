// testing/en/vue/login.ts
import { createApp } from "vue";

// testing/en/vue/LoginPage.vue
import { defineComponent as _defineComponent2 } from "vue";
import { createElementVNode as _createElementVNode2, createVNode as _createVNode, openBlock as _openBlock2, createElementBlock as _createElementBlock2 } from "vue";

// testing/en/vue/LoginForm.vue
import { defineComponent as _defineComponent } from "vue";
import { toDisplayString as _toDisplayString, openBlock as _openBlock, createElementBlock as _createElementBlock, createCommentVNode as _createCommentVNode, createElementVNode as _createElementVNode, withModifiers as _withModifiers } from "vue";
import { ref } from "vue";

// testing/en/vue/api.ts
async function signIn(email, password) {
  await new Promise((resolve) => setTimeout(resolve, 50));
  if (email === "sara@example.com" && password === "bit2026code") return { name: "Sara" };
  throw new Error("Wrong email or password.");
}

// testing/en/vue/LoginForm.vue
var _hoisted_1 = { key: 0 };
var _hoisted_2 = ["aria-describedby"];
var _hoisted_3 = {
  key: 0,
  id: "login-error",
  role: "alert"
};
var _hoisted_4 = ["disabled"];
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "LoginForm",
  props: {
    signIn: { default: () => signIn }
  },
  setup(__props) {
    const error = ref("");
    const user = ref(null);
    const busy = ref(false);
    async function submit(event) {
      const data = new FormData(event.target);
      const email = String(data.get("email") ?? "").trim();
      if (!email) return error.value = "Please enter your email.";
      busy.value = true;
      try {
        user.value = (await __props.signIn(email, String(data.get("password") ?? ""))).name;
      } catch (e) {
        error.value = e.message;
      } finally {
        busy.value = false;
      }
    }
    return (_ctx, _cache) => {
      return user.value ? (_openBlock(), _createElementBlock(
        "h2",
        _hoisted_1,
        "Welcome back, " + _toDisplayString(user.value) + "!",
        1
        /* TEXT */
      )) : (_openBlock(), _createElementBlock("form", {
        key: 1,
        novalidate: "",
        "aria-describedby": error.value ? "login-error" : void 0,
        onSubmit: _withModifiers(submit, ["prevent"])
      }, [
        _cache[0] || (_cache[0] = _createElementVNode(
          "label",
          { for: "email" },
          "Email",
          -1
          /* CACHED */
        )),
        _cache[1] || (_cache[1] = _createElementVNode(
          "input",
          {
            id: "email",
            name: "email",
            type: "email",
            autocomplete: "email",
            dir: "ltr"
          },
          null,
          -1
          /* CACHED */
        )),
        _cache[2] || (_cache[2] = _createElementVNode(
          "label",
          { for: "password" },
          "Password",
          -1
          /* CACHED */
        )),
        _cache[3] || (_cache[3] = _createElementVNode(
          "input",
          {
            id: "password",
            name: "password",
            type: "password",
            autocomplete: "current-password",
            dir: "ltr"
          },
          null,
          -1
          /* CACHED */
        )),
        error.value ? (_openBlock(), _createElementBlock(
          "p",
          _hoisted_3,
          _toDisplayString(error.value),
          1
          /* TEXT */
        )) : _createCommentVNode("v-if", true),
        _createElementVNode("button", {
          type: "submit",
          disabled: busy.value
        }, _toDisplayString(busy.value ? "Signing in\u2026" : "Sign in"), 9, _hoisted_4)
      ], 40, _hoisted_2));
    };
  }
});
var LoginForm_default = _sfc;

// testing/en/vue/LoginPage.vue
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "LoginPage",
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock2(), _createElementBlock2("main", null, [
        _cache[0] || (_cache[0] = _createElementVNode2(
          "h1",
          null,
          "Bit's shop",
          -1
          /* CACHED */
        )),
        _createVNode(LoginForm_default)
      ]);
    };
  }
});
var LoginPage_default = _sfc2;

// testing/en/vue/login.ts
createApp(LoginPage_default).mount("#app");
