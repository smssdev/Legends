import { expect, it } from "vitest";
import { render, screen } from "@testing-library/vue";
import userEvent from "@testing-library/user-event";
import Tasks from "./Tasks.vue";

it("يضيف مهمة من النموذج", async () => {
  const user = userEvent.setup();
  render(Tasks);
  await user.type(screen.getByRole("textbox", { name: "مهمة جديدة" }), "اقرأ الفصل 11{Enter}");
  expect(screen.getByRole("checkbox", { name: "اقرأ الفصل 11" })).not.toBeChecked();
  expect(screen.getByRole("status")).toHaveTextContent("1 متبقية");
  expect(screen.getByRole("textbox", { name: "مهمة جديدة" })).toHaveValue("");
});

it("يعلّم المهمة منجزة ويحدّث العدد", async () => {
  const user = userEvent.setup();
  const initial = [
    { id: 1, text: "اقرأ الفصل 11", done: false },
    { id: 2, text: "اكتب اختباراً", done: false },
  ];
  render(Tasks, { props: { initial } });
  await user.click(screen.getByRole("checkbox", { name: "اقرأ الفصل 11" }));
  expect(screen.getByRole("checkbox", { name: "اقرأ الفصل 11" })).toBeChecked();
  expect(screen.getByRole("status")).toHaveTextContent("1 متبقية");
});

it("لا يضيف مهمة فارغة", async () => {
  const user = userEvent.setup();
  render(Tasks);
  await user.type(screen.getByRole("textbox", { name: "مهمة جديدة" }), "   {Enter}");
  expect(screen.queryAllByRole("checkbox")).toHaveLength(0);
});
