import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { LoginForm } from "./LoginForm";

describe("LoginForm", () => {
  it("يعرض خطأً حين يكون البريد فارغاً", async () => {
    const user = userEvent.setup();
    render(<LoginForm />);
    // جِد الأشياء كما يجدها المستخدمون: بالدور وبالاسم
    await user.click(screen.getByRole("button", { name: "سجّل الدخول" }));
    expect(screen.getByRole("alert")).toHaveTextContent("اكتب بريدك الإلكتروني.");
  });

  it("يسجّل الدخول ويرحّب بالمستخدم", async () => {
    const user = userEvent.setup();
    const signIn = vi.fn().mockResolvedValue({ name: "سارة" });
    render(<LoginForm signIn={signIn} />);

    await user.type(screen.getByLabelText("البريد الإلكتروني"), "sara@example.com");
    await user.type(screen.getByLabelText("كلمة المرور"), "bit2026code");
    await user.click(screen.getByRole("button", { name: "سجّل الدخول" }));

    expect(await screen.findByRole("heading", { name: "أهلاً بعودتك يا سارة!" })).toBeInTheDocument();
    expect(signIn).toHaveBeenCalledWith("sara@example.com", "bit2026code");
  });

  it("يعرض خطأ الخادم لكلمة مرور خاطئة", async () => {
    const user = userEvent.setup();
    render(<LoginForm />);
    await user.type(screen.getByLabelText("البريد الإلكتروني"), "sara@example.com");
    await user.type(screen.getByLabelText("كلمة المرور"), "wrong");
    await user.click(screen.getByRole("button", { name: "سجّل الدخول" }));
    expect(await screen.findByRole("alert")).toHaveTextContent("البريد أو كلمة المرور غير صحيحة.");
  });
});
