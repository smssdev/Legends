import { expect, it } from "vitest";
import { render, screen } from "@testing-library/vue";
import userEvent from "@testing-library/user-event";
import Tasks from "./Tasks.vue";

it("adds a task from the form", async () => {
  const user = userEvent.setup();
  render(Tasks);
  await user.type(screen.getByRole("textbox", { name: "New task" }), "Read chapter 11{Enter}");
  expect(screen.getByRole("checkbox", { name: "Read chapter 11" })).not.toBeChecked();
  expect(screen.getByRole("status")).toHaveTextContent("1 left");
  expect(screen.getByRole("textbox", { name: "New task" })).toHaveValue("");
});

it("ticks a task off and updates the count", async () => {
  const user = userEvent.setup();
  const initial = [
    { id: 1, text: "Read chapter 11", done: false },
    { id: 2, text: "Write a test", done: false },
  ];
  render(Tasks, { props: { initial } });
  await user.click(screen.getByRole("checkbox", { name: "Read chapter 11" }));
  expect(screen.getByRole("checkbox", { name: "Read chapter 11" })).toBeChecked();
  expect(screen.getByRole("status")).toHaveTextContent("1 left");
});

it("does not add an empty task", async () => {
  const user = userEvent.setup();
  render(Tasks);
  await user.type(screen.getByRole("textbox", { name: "New task" }), "   {Enter}");
  expect(screen.queryAllByRole("checkbox")).toHaveLength(0);
});
