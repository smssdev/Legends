import type { RouteRecordRaw } from "vue-router";
import BlogLayout from "./BlogLayout.vue";
import PostList from "./PostList.vue";
import PostPage from "./PostPage.vue";

export const routes: RouteRecordRaw[] = [
  {
    path: "/",
    component: BlogLayout,
    children: [
      { path: "", name: "posts", component: PostList },
      { path: "posts/:slug", name: "post", component: PostPage, props: true },
    ],
  },
];
