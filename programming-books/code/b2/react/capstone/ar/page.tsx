// للصور واختبارات الطرف إلى الطرف فقط
import { createRoot } from "react-dom/client";
import { createMemoryRouter, RouterProvider } from "react-router";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { fakeFetch, server } from "./src/api/fake-server";
import { routes } from "./src/app/routes";

window.fetch = fakeFetch;
Object.assign(window, { server }); // so a test can say: server.failNextChange = true

const router = createMemoryRouter(routes);
const queryClient = new QueryClient({ defaultOptions: { queries: { staleTime: 30_000, retry: false } } });

createRoot(document.getElementById("root")!).render(
  <QueryClientProvider client={queryClient}>
    <RouterProvider router={router} />
  </QueryClientProvider>,
);
