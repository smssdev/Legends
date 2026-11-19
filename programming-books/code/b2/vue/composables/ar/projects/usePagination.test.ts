import { ref } from "vue";
import { expect, it } from "vitest";
import { usePagination } from "./usePagination";

it("يقسم القائمة إلى صفحات", () => {
  const p = usePagination([1, 2, 3, 4, 5, 6, 7], 3);
  expect(p.pages.value).toBe(3);
  p.next();
  expect(p.rows.value).toEqual([4, 5, 6]);
});

it("لا يتجاوز الصفحة الأخيرة أبداً", () => {
  const list = ref([1, 2, 3, 4, 5, 6, 7]);
  const p = usePagination(list, 3);
  p.next();
  p.next();
  p.next();
  expect(p.page.value).toBe(3);
  list.value = [1, 2];
  expect(p.page.value).toBe(1);
  expect(p.rows.value).toEqual([1, 2]);
});
