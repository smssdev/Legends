import { NextResponse, type NextRequest } from "next/server";

// راحة لا قفل: أرسل الزوار الذين بلا كوكي إلى صفحة الدخول
export function proxy(request: NextRequest) {
  if (!request.cookies.has("session")) {
    return NextResponse.redirect(new URL("/login", request.url));
  }
}

export const config = { matcher: ["/owner/:path*"] };
