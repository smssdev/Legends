<template>
  <div class="layout">
    <nav>
      <span class="brand">Bit's shop</span>
      <RouterLink to="/" exact-active-class="router-link-active" active-class="">Home</RouterLink>
      <RouterLink to="/products">Products</RouterLink>
    </nav>
    <RouterView />
  </div>
</template>
