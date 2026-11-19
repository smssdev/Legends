import { render, screen } from "@testing-library/vue";
import userEvent from "@testing-library/user-event";
import { createPinia } from "pinia";
import { describe, expect, it, vi } from "vitest";
import ProductForm from "./ProductForm.vue";

const mug = { id: 2, name: "Bit mug", price: 8500, stock: 40 };
const show = (onSave: (p: typeof mug) => Promise<Record<string, string> | void>) =>
  render(ProductForm, { props: { product: mug, onSave }, global: { plugins: [createPinia()] } });

describe("ProductForm", () => {
  it("يعرض خطأ تحت كل حقل خاطئ، ولا يحفظ", async () => {
    const onSave = vi.fn();
    show(onSave);
    await userEvent.clear(screen.getByLabelText("Name"));
    await userEvent.clear(screen.getByLabelText("Price in piastres"));
    await userEvent.type(screen.getByLabelText("Price in piastres"), "85.5");
    await userEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(await screen.findByText("Write a name of 2 to 40 characters.")).toBeInTheDocument();
    expect(screen.getByText("The price must be a whole number above zero.")).toBeInTheDocument();
    expect(onSave).not.toHaveBeenCalled();
  });

  it("يحفظ أعداداً صحيحة، لا النص المكتوب", async () => {
    const onSave = vi.fn().mockResolvedValue(undefined);
    show(onSave);
    await userEvent.clear(screen.getByLabelText("Stock"));
    await userEvent.type(screen.getByLabelText("Stock"), "39");
    await userEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(await screen.findByRole("status")).toHaveTextContent("Saved.");
    expect(onSave).toHaveBeenCalledWith({ id: 2, name: "Bit mug", price: 8500, stock: 39 });
  });

  it("يعرض أخطاء الخادم تحت الحقل الصحيح", async () => {
    show(async () => ({ name: "Another product already has this name." }));
    await userEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(await screen.findByText("Another product already has this name.")).toBeInTheDocument();
    expect(screen.getByLabelText("Name")).toHaveAttribute("aria-invalid", "true");
  });
});
