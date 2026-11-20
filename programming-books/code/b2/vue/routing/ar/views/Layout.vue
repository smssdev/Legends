<template>
  <div class="layout">
    <nav>
      <span class="brand">متجر بِت</span>
      <RouterLink to="/" exact-active-class="router-link-active" active-class="">الرئيسية</RouterLink>
      <RouterLink to="/products">المنتجات</RouterLink>
    </nav>
    <RouterView />
  </div>
</template>
