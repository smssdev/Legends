// testing/ar/vue/login.ts
import { createApp } from "vue";

// testing/ar/vue/LoginPage.vue
import { defineComponent as _defineComponent2 } from "vue";
import { createElementVNode as _createElementVNode2, createVNode as _createVNode, openBlock as _openBlock2, createElementBlock as _createElementBlock2 } from "vue";

// testing/ar/vue/LoginForm.vue
import { defineComponent as _defineComponent } from "vue";
import { toDisplayString as _toDisplayString, openBlock as _openBlock, createElementBlock as _createElementBlock, createCommentVNode as _createCommentVNode, createElementVNode as _createElementVNode, withModifiers as _withModifiers } from "vue";
import { ref } from "vue";

// testing/ar/vue/api.ts
async function signIn(email, password) {
  await new Promise((resolve) => setTimeout(resolve, 50));
  if (email === "sara@example.com" && password === "bit2026code") return { name: "\u0633\u0627\u0631\u0629" };
  throw new Error("\u0627\u0644\u0628\u0631\u064A\u062F \u0623\u0648 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u063A\u064A\u0631 \u0635\u062D\u064A\u062D\u0629.");
}

// testing/ar/vue/LoginForm.vue
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
      if (!email) return error.value = "\u0627\u0643\u062A\u0628 \u0628\u0631\u064A\u062F\u0643 \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A.";
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
        "\u0623\u0647\u0644\u0627\u064B \u0628\u0639\u0648\u062F\u062A\u0643 \u064A\u0627 " + _toDisplayString(user.value) + "!",
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
          "\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A",
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
          "\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631",
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
        }, _toDisplayString(busy.value ? "\u062C\u0627\u0631\u064D \u0627\u0644\u062F\u062E\u0648\u0644\u2026" : "\u0633\u062C\u0651\u0644 \u0627\u0644\u062F\u062E\u0648\u0644"), 9, _hoisted_4)
      ], 40, _hoisted_2));
    };
  }
});
var LoginForm_default = _sfc;

// testing/ar/vue/LoginPage.vue
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "LoginPage",
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock2(), _createElementBlock2("main", null, [
        _cache[0] || (_cache[0] = _createElementVNode2(
          "h1",
          null,
          "\u0645\u062A\u062C\u0631 \u0628\u0650\u062A",
          -1
          /* CACHED */
        )),
        _createVNode(LoginForm_default)
      ]);
    };
  }
});
var LoginPage_default = _sfc2;

// testing/ar/vue/login.ts
createApp(LoginPage_default).mount("#app");
