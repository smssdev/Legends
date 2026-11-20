import { CatalogPage } from "../features/catalog";
import { AccountPage } from "../features/account";

export const routes = [
  { path: "/", element: <CatalogPage /> },
  { path: "/account", element: <AccountPage /> },
];
