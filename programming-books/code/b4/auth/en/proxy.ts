import { NextResponse, type NextRequest } from "next/server";

// a convenience, not the lock: send visitors without a cookie to the login page
export function proxy(request: NextRequest) {
  if (!request.cookies.has("session")) {
    return NextResponse.redirect(new URL("/login", request.url));
  }
}

export const config = { matcher: ["/owner/:path*"] };
