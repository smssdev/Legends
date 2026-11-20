// For the book's screenshots only.
import { createRoot } from "react-dom/client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { FavouriteButton } from "./favourite";
import { server } from "../api";

server.failNextSave = false;

createRoot(document.getElementById("root")!).render(
  <QueryClientProvider client={new QueryClient()}>
    <FavouriteButton id={2} />
  </QueryClientProvider>,
);
