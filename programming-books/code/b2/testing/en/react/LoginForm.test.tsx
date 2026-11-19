import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { LoginForm } from "./LoginForm";

describe("LoginForm", () => {
  it("shows an error when the email is empty", async () => {
    const user = userEvent.setup();
    render(<LoginForm />);
    // Find things the way users do: by role and by name
    await user.click(screen.getByRole("button", { name: "Sign in" }));
    expect(screen.getByRole("alert")).toHaveTextContent("Please enter your email.");
  });

  it("signs in and greets the user", async () => {
    const user = userEvent.setup();
    const signIn = vi.fn().mockResolvedValue({ name: "Sara" });
    render(<LoginForm signIn={signIn} />);

    await user.type(screen.getByLabelText("Email"), "sara@example.com");
    await user.type(screen.getByLabelText("Password"), "bit2026code");
    await user.click(screen.getByRole("button", { name: "Sign in" }));

    expect(await screen.findByRole("heading", { name: "Welcome back, Sara!" })).toBeInTheDocument();
    expect(signIn).toHaveBeenCalledWith("sara@example.com", "bit2026code");
  });

  it("shows the server's error for a wrong password", async () => {
    const user = userEvent.setup();
    render(<LoginForm />);
    await user.type(screen.getByLabelText("Email"), "sara@example.com");
    await user.type(screen.getByLabelText("Password"), "wrong");
    await user.click(screen.getByRole("button", { name: "Sign in" }));
    expect(await screen.findByRole("alert")).toHaveTextContent("Wrong email or password.");
  });
});
