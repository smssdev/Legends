// vue/components/en/projects/profile.ts
import { createApp } from "vue";

// vue/components/en/projects/Profile.vue
import { defineComponent as _defineComponent2 } from "vue";
import { createElementVNode as _createElementVNode2, withCtx as _withCtx, openBlock as _openBlock2, createBlock as _createBlock } from "vue";

// vue/components/en/projects/ProfileCard.vue
import { defineComponent as _defineComponent } from "vue";
import { createElementVNode as _createElementVNode, toDisplayString as _toDisplayString, renderSlot as _renderSlot, createTextVNode as _createTextVNode, normalizeClass as _normalizeClass, openBlock as _openBlock, createElementBlock as _createElementBlock } from "vue";
import { computed, ref } from "vue";
var _hoisted_1 = { class: "profile" };
var _hoisted_2 = { class: "body" };
var _hoisted_3 = {
  class: "avatar",
  "aria-hidden": "true"
};
var _hoisted_4 = { class: "meta" };
var _hoisted_5 = { class: "stats" };
var _hoisted_6 = ["aria-pressed"];
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "ProfileCard",
  props: {
    person: {}
  },
  setup(__props) {
    const props = __props;
    const following = ref(false);
    const followers = computed(() => props.person.followers + (following.value ? 1 : 0));
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("article", _hoisted_1, [
        _cache[3] || (_cache[3] = _createElementVNode(
          "div",
          { class: "cover" },
          null,
          -1
          /* CACHED */
        )),
        _createElementVNode("div", _hoisted_2, [
          _createElementVNode(
            "div",
            _hoisted_3,
            _toDisplayString(__props.person.name[0]),
            1
            /* TEXT */
          ),
          _createElementVNode(
            "h2",
            null,
            _toDisplayString(__props.person.name),
            1
            /* TEXT */
          ),
          _createElementVNode(
            "p",
            _hoisted_4,
            _toDisplayString(__props.person.role) + " \xB7 " + _toDisplayString(__props.person.city),
            1
            /* TEXT */
          ),
          _renderSlot(_ctx.$slots, "default"),
          _createElementVNode("div", _hoisted_5, [
            _createElementVNode("span", null, [
              _createElementVNode(
                "b",
                null,
                _toDisplayString(__props.person.projects),
                1
                /* TEXT */
              ),
              _cache[1] || (_cache[1] = _createTextVNode(
                "projects",
                -1
                /* CACHED */
              ))
            ]),
            _createElementVNode("span", null, [
              _createElementVNode(
                "b",
                null,
                _toDisplayString(followers.value),
                1
                /* TEXT */
              ),
              _cache[2] || (_cache[2] = _createTextVNode(
                "followers",
                -1
                /* CACHED */
              ))
            ])
          ]),
          _createElementVNode("button", {
            type: "button",
            class: _normalizeClass({ secondary: following.value }),
            "aria-pressed": following.value,
            onClick: _cache[0] || (_cache[0] = ($event) => following.value = !following.value)
          }, _toDisplayString(following.value ? "Following" : "Follow"), 11, _hoisted_6)
        ])
      ]);
    };
  }
});
var ProfileCard_default = _sfc;

// vue/components/en/projects/Profile.vue
var _sfc2 = /* @__PURE__ */ _defineComponent2({
  __name: "Profile",
  setup(__props) {
    const sara = { name: "Sara", role: "Frontend developer", city: "Alexandria", projects: 12, followers: 340 };
    return (_ctx, _cache) => {
      return _openBlock2(), _createBlock(ProfileCard_default, { person: sara }, {
        default: _withCtx(() => [..._cache[0] || (_cache[0] = [
          _createElementVNode2(
            "p",
            null,
            "I build fast, accessible web apps with Vue and TypeScript.",
            -1
            /* CACHED */
          )
        ])]),
        _: 1
        /* STABLE */
      });
    };
  }
});
var Profile_default = _sfc2;

// vue/components/en/projects/profile.ts
createApp(Profile_default).mount("#app");
