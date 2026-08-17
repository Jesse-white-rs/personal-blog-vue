<template>
  <footer class="footer">
    <div class="container footer-inner">
      <p>&copy; {{ year }} {{ profile?.name || 'RWG' }}. 用 Vue 3 + Vite + Supabase 搭建。</p>
      <a class="footer-link" href="#top">回到顶部 ↑</a>
    </div>
  </footer>
</template>

<script setup>
import { ref } from 'vue'

defineProps({ profile: Object })
const year = ref(new Date().getFullYear())
</script>
