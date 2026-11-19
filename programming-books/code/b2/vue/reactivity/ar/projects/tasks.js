// vue/reactivity/ar/projects/tasks.ts
import { createApp } from "vue";

// vue/reactivity/ar/projects/Tasks.vue
import { defineComponent as _defineComponent } from "vue";
import { toDisplayString as _toDisplayString, createElementVNode as _createElementVNode, createTextVNode as _createTextVNode, vModelText as _vModelText, withDirectives as _withDirectives, withModifiers as _withModifiers, renderList as _renderList, Fragment as _Fragment, openBlock as _openBlock, createElementBlock as _createElementBlock, vModelCheckbox as _vModelCheckbox, normalizeClass as _normalizeClass } from "vue";
import { computed, ref, watch } from "vue";
var _hoisted_1 = { class: "card" };
var _hoisted_2 = ["onUpdate:modelValue"];
var _sfc = /* @__PURE__ */ _defineComponent({
  __name: "Tasks",
  setup(__props) {
    function load() {
      try {
        return JSON.parse(localStorage.getItem("tasks") ?? "null") ?? defaults;
      } catch {
        return defaults;
      }
    }
    const defaults = [{ id: 1, text: "\u0627\u0642\u0631\u0623 \u0627\u0644\u0641\u0635\u0644 5", done: true }];
    const tasks = ref(load());
    const text = ref("");
    const left = computed(() => tasks.value.filter((t) => !t.done).length);
    watch(tasks, (now) => localStorage.setItem("tasks", JSON.stringify(now)), { deep: true });
    function add() {
      if (!text.value.trim()) return;
      tasks.value.push({ id: Date.now(), text: text.value.trim(), done: false });
      text.value = "";
    }
    return (_ctx, _cache) => {
      return _openBlock(), _createElementBlock("section", _hoisted_1, [
        _createElementVNode("h2", null, [
          _cache[2] || (_cache[2] = _createTextVNode(
            "\u0627\u0644\u0645\u0647\u0627\u0645 ",
            -1
            /* CACHED */
          )),
          _createElementVNode(
            "small",
            null,
            "(" + _toDisplayString(left.value) + " \u0645\u062A\u0628\u0642\u064A\u0629)",
            1
            /* TEXT */
          )
        ]),
        _createElementVNode(
          "form",
          {
            onSubmit: _withModifiers(add, ["prevent"])
          },
          [
            _cache[3] || (_cache[3] = _createElementVNode(
              "label",
              {
                for: "task",
                class: "sr-only"
              },
              "\u0645\u0647\u0645\u0629 \u062C\u062F\u064A\u062F\u0629",
              -1
              /* CACHED */
            )),
            _withDirectives(_createElementVNode(
              "input",
              {
                id: "task",
                "onUpdate:modelValue": _cache[0] || (_cache[0] = ($event) => text.value = $event),
                placeholder: "\u0645\u0647\u0645\u0629 \u062C\u062F\u064A\u062F\u0629"
              },
              null,
              512
              /* NEED_PATCH */
            ), [
              [_vModelText, text.value]
            ])
          ],
          32
          /* NEED_HYDRATION */
        ),
        _createElementVNode("ul", null, [
          (_openBlock(true), _createElementBlock(
            _Fragment,
            null,
            _renderList(tasks.value, (task) => {
              return _openBlock(), _createElementBlock("li", {
                key: task.id
              }, [
                _createElementVNode(
                  "label",
                  {
                    class: _normalizeClass({ done: task.done })
                  },
                  [
                    _withDirectives(_createElementVNode("input", {
                      "onUpdate:modelValue": ($event) => task.done = $event,
                      type: "checkbox"
                    }, null, 8, _hoisted_2), [
                      [_vModelCheckbox, task.done]
                    ]),
                    _createTextVNode(
                      " " + _toDisplayString(task.text),
                      1
                      /* TEXT */
                    )
                  ],
                  2
                  /* CLASS */
                )
              ]);
            }),
            128
            /* KEYED_FRAGMENT */
          ))
        ]),
        _createElementVNode("button", {
          type: "button",
          class: "secondary",
          onClick: _cache[1] || (_cache[1] = ($event) => tasks.value = tasks.value.filter((t) => !t.done))
        }, "\u0627\u062D\u0630\u0641 \u0627\u0644\u0645\u0646\u062C\u0632\u0629")
      ]);
    };
  }
});
var Tasks_default = _sfc;

// vue/reactivity/ar/projects/tasks.ts
createApp(Tasks_default).mount("#app");
