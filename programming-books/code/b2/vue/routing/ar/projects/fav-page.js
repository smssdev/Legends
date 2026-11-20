// vue/routing/ar/projects/fav-page.ts
import { createApp, h } from "vue";
import { VueQueryPlugin } from "@tanstack/vue-query";

// vue/routing/ar/projects/FavouriteButton.vue
import { defineComponent as _defineComponent } from "vue";
import { unref as _unref, openBlock as _openBlock, createElementBlock as _createElementBlock, createCommentVNode as _createCommentVNode, toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, normalizeClass as _normalizeClass } from "vue";
import { useMutation, useQuery, useQueryClient } from "@tanstack/vue-query";

// vue/routing/ar/api.ts
var products = [
  { id: 1, name: "\u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0645\u0646 \u0627\u0644\u0635\u0641\u0631", description: "\u0627\u0644\u0643\u062A\u0627\u0628 \u0627\u0644\u0623\u0648\u0644 \u0627\u0644\u0648\u062F\u0648\u062F \u0641\u064A \u0627\u0644\u0633\u0644\u0633\u0644\u0629.", price: 25, category: "books", favourite: false },
  { id: 2, name: "\u0643\u0648\u0628 \u0628\u0650\u062A", description: "\u0643\u0648\u0628 \u0643\u0628\u064A\u0631 \u0644\u0644\u064A\u0627\u0644\u064A \u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0627\u0644\u0637\u0648\u064A\u0644\u0629.", price: 8, category: "gifts", favourite: false },
  { id: 3, name: "\u0642\u0628\u0639\u0629 \u0628\u0650\u062A", description: "\u062A\u062D\u0645\u064A \u0639\u064A\u0646\u064A\u0643 \u0645\u0646 \u0627\u0644\u0634\u0645\u0633.", price: 12, category: "gifts", favourite: true },
  { id: 4, name: "\u0645\u0644\u0635\u0642 \u0628\u0650\u062A", description: "\u0644\u062D\u0627\u0633\u0648\u0628\u0643 \u0627\u0644\u0645\u062D\u0645\u0648\u0644.", price: 3, category: "gifts", favourite: false }
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
    throw new Error("\u0627\u0644\u062E\u0627\u062F\u0645 \u0645\u0634\u063A\u0648\u0644");
  }
  const product = products.find((p) => p.id === id);
  if (!product) throw new NotFoundError(`#${id}`);
  product.favourite = favourite;
  return structuredClone(product);
}

// vue/routing/ar/projects/FavouriteButton.vue
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
      // 1. قبل رد الخادم: غيّر الذاكرة، وتذكّر القيمة القديمة
      onMutate: async (favourite) => {
        await client.cancelQueries({ queryKey: key });
        const previous = client.getQueryData(key);
        client.setQueryData(key, (old) => old ? { ...old, favourite } : old);
        return { previous };
      },
      // 2. إن فشل: أعد القيمة القديمة
      onError: (_error, _favourite, context) => client.setQueryData(key, context?.previous),
      // 3. في الحالتين: اسأل الخادم عن الحقيقة
      onSettled: () => client.invalidateQueries({ queryKey: key })
    });
    return (_ctx, _cache) => {
      return !_unref(product).data.value ? (_openBlock(), _createElementBlock("p", _hoisted_1, "\u062C\u0627\u0631\u064D \u0627\u0644\u062A\u062D\u0645\u064A\u0644\u2026")) : (_openBlock(), _createElementBlock("div", _hoisted_2, [
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
        }, _toDisplayString(_unref(product).data.value.favourite ? "\u2665" : "\u2661") + " \u0645\u0641\u0636\u0651\u0644 ", 11, _hoisted_3),
        _unref(mutation).isPending.value ? (_openBlock(), _createElementBlock("span", _hoisted_4, " \u062C\u0627\u0631\u064D \u0627\u0644\u062D\u0641\u0638\u2026")) : _createCommentVNode("v-if", true),
        _unref(mutation).isError.value ? (_openBlock(), _createElementBlock("p", _hoisted_5, "\u062A\u0639\u0630\u0651\u0631 \u0627\u0644\u062D\u0641\u0638\u060C \u0648\u0623\u064F\u0644\u063A\u064A \u0627\u0644\u062A\u063A\u064A\u064A\u0631.")) : _createCommentVNode("v-if", true)
      ]));
    };
  }
});
var FavouriteButton_default = _sfc;

// vue/routing/ar/projects/fav-page.ts
server.failNextSave = false;
createApp({ render: () => h(FavouriteButton_default, { id: 2 }) }).use(VueQueryPlugin).mount("#app");
