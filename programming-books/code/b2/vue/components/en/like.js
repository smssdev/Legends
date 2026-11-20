// vue/components/en/like.ts
import { createApp } from "vue";

// vue/components/en/Likes.vue
import { defineComponent as _defineComponent2 } from "vue";
import { createVNode as _createVNode, openBlock as _openBlock2, createElementBlock as _createElementBlock2 } from "vue";

// vue/components/en/LikeButton.vue
import { defineComponent as _defineComponent } from "vue";
import { toDisplayString as _toDisplayString, normalizeClass as _normalizeClass, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
import { ref } from "vue";
var _hoisted_1 = ["aria-pressed"];
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "LikeButton",
  props: {
    initial: {}
  },
  setup(__props) {
    const props = __props;
    const likes = ref(props.initial);
    const liked = ref(false);
    function toggle() {
      liked.value = !liked.value;
      likes.value += liked.value ? 1 : -1;
    }
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("button", {
        type: "button",
        class: _normalizeClass({ secondary: !liked.value }),
        "aria-pressed": liked.value,
        onClick: toggle
      }, _toDisplayString(liked.value ? "\u2665 Liked" : "\u2661 Like") + " \xB7 " + _toDisplayString(likes.value) + " likes ", 11, _hoisted_1);
    };
  }
});
var LikeButton_default = _sfc;

// vue/components/en/Likes.vue
var _hoisted_12 = { style: { "display": "flex", "gap": "8px" } };
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "Likes",
  setup(__props) {
    return (_ctx, _cache) => {
      return _openBlock2(), _createElementBlock2("p", _hoisted_12, [
        _createVNode(LikeButton_default, { initial: 41 }),
        _createVNode(LikeButton_default, { initial: 7 })
      ]);
    };
  }
});
var Likes_default = _sfc2;

// vue/components/en/like.ts
createApp(Likes_default).mount("#app");
