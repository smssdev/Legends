// vue/routing/en/projects/fav-page.ts
import { createApp, h } from "vue";
import { VueQueryPlugin } from "@tanstack/vue-query";

// vue/routing/en/projects/FavouriteButton.vue
import { defineComponent as _defineComponent } from "vue";
import { unref as _unref, openBlock as _openBlock, createElementBlock as _createElementBlock, createCommentVNode as _createCommentVNode, toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, normalizeClass as _normalizeClass } from "vue";
import { useMutation, useQuery, useQueryClient } from "@tanstack/vue-query";

// vue/routing/en/api.ts
var products = [
  { id: 1, name: "Code from Zero", description: "The friendly first book of the series.", price: 25, category: "books", favourite: false },
  { id: 2, name: "Bit mug", description: "A big mug for long coding nights.", price: 8, category: "gifts", favourite: false },
  { id: 3, name: "Bit cap", description: "Keeps the sun out of your eyes.", price: 12, category: "gifts", favourite: true },
  { id: 4, name: "Bit sticker", description: "For your laptop.", price: 3, category: "gifts", favourite: false }
];
var NotFoundError = class extends Error {
};
var wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
async function getProduct(id) {
  await wait(300);
  const product = products.find((p) => p.id === id);
  if (!product) throw new NotFoundError(`#${id}`);
  return structuredClone(product);
}
var server = { failNextSave: false };
async function setFavourite(id, favourite) {
  await wait(400);
  if (server.failNextSave) {
    server.failNextSave = false;
    throw new Error("The server is busy");
  }
  const product = products.find((p) => p.id === id);
  if (!product) throw new NotFoundError(`#${id}`);
  product.favourite = favourite;
  return structuredClone(product);
}

// vue/routing/en/projects/FavouriteButton.vue
var _hoisted_1 = {
  key: 0,
  class: "muted"
};
var _hoisted_2 = {
  key: 1,
  class: "card"
};
var _hoisted_3 = ["aria-pressed"];
var _hoisted_4 = {
  key: 0,
  class: "muted"
};
var _hoisted_5 = {
  key: 1,
  class: "error",
  role: "alert"
};
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "FavouriteButton",
  props: {
    id: {}
  },
  setup(__props) {
    const props = __props;
    const client = useQueryClient();
    const key = ["product", props.id];
    const product = useQuery({ queryKey: key, queryFn: () => getProduct(props.id) });
    const mutation = useMutation({
      mutationFn: (favourite) => setFavourite(props.id, favourite),
      // 1. Before the server answers: change the cache, and remember the old value
      onMutate: async (favourite) => {
        await client.cancelQueries({ queryKey: key });
        const previous = client.getQueryData(key);
        client.setQueryData(key, (old) => old ? { ...old, favourite } : old);
        return { previous };
      },
      // 2. If it fails: put the old value back
      onError: (_error, _favourite, context) => client.setQueryData(key, context?.previous),
      // 3. Either way: ask the server for the truth
      onSettled: () => client.invalidateQueries({ queryKey: key })
    });
    return (_ctx, _cache) => {
      return !_unref(product).data.value ? (_openBlock(), _createElementBlock("p", _hoisted_1, "Loading\u2026")) : (_openBlock(), _createElementBlock("div", _hoisted_2, [
        _createElementVNode(
          "h2",
          null,
          _toDisplayString(_unref(product).data.value.name),
          1
          /* TEXT */
        ),
        _createElementVNode("button", {
          type: "button",
          "aria-pressed": _unref(product).data.value.favourite,
          class: _normalizeClass({ secondary: !_unref(product).data.value.favourite }),
          onClick: _cache[0] || (_cache[0] = ($event) => _unref(mutation).mutate(!_unref(product).data.value.favourite))
        }, _toDisplayString(_unref(product).data.value.favourite ? "\u2665" : "\u2661") + " Favourite ", 11, _hoisted_3),
        _unref(mutation).isPending.value ? (_openBlock(), _createElementBlock("span", _hoisted_4, " Saving\u2026")) : _createCommentVNode("v-if", true),
        _unref(mutation).isError.value ? (_openBlock(), _createElementBlock("p", _hoisted_5, "Could not save. The change was undone.")) : _createCommentVNode("v-if", true)
      ]));
    };
  }
});
var FavouriteButton_default = _sfc;

// vue/routing/en/projects/fav-page.ts
server.failNextSave = false;
createApp({ render: () => h(FavouriteButton_default, { id: 2 }) }).use(VueQueryPlugin).mount("#app");
