import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";
import { ProductForm } from "./ProductForm";

const mug = { id: 2, name: "Bit mug", price: 8500, stock: 40 };

describe("ProductForm", () => {
  it("shows an error under each wrong field, and does not save", async () => {
    const onSave = vi.fn();
    render(<ProductForm product={mug} onSave={onSave} />);
    await userEvent.clear(screen.getByLabelText("Name"));
    await userEvent.clear(screen.getByLabelText("Price in piastres"));
    await userEvent.type(screen.getByLabelText("Price in piastres"), "85.5");
    await userEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(await screen.findByText("Write a name of 2 to 40 characters.")).toBeInTheDocument();
    expect(screen.getByText("The price must be a whole number above zero.")).toBeInTheDocument();
    expect(onSave).not.toHaveBeenCalled();
  });

  it("saves whole numbers, not the text typed", async () => {
    const onSave = vi.fn().mockResolvedValue(undefined);
    render(<ProductForm product={mug} onSave={onSave} />);
    await userEvent.clear(screen.getByLabelText("Stock"));
    await userEvent.type(screen.getByLabelText("Stock"), "39");
    await userEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(await screen.findByRole("status")).toHaveTextContent("Saved.");
    expect(onSave).toHaveBeenCalledWith({ id: 2, name: "Bit mug", price: 8500, stock: 39 });
  });

  it("shows the server's errors under the right field", async () => {
    render(<ProductForm product={mug} onSave={async () => ({ name: "Another product already has this name." })} />);
    await userEvent.click(screen.getByRole("button", { name: "Save" }));
    expect(await screen.findByText("Another product already has this name.")).toBeInTheDocument();
    expect(screen.getByLabelText("Name")).toHaveAttribute("aria-invalid", "true");
  });
});
