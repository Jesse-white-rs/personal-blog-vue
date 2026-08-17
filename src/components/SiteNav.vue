<template>
  <nav class="nav" :class="{ scrolled }">
    <div class="container nav-inner">
      <a class="brand" href="#top">
        <span class="brand-mark">{{ initials }}</span>
        {{ profile?.name || 'RWG' }}
      </a>

      <ul class="nav-links" ref="linksEl" :class="{ open: menuOpen }" @click="onLinkClick">
        <li><a href="#articles">文章</a></li>
        <li><a href="#about">关于</a></li>
        <li><a href="#projects">项目</a></li>
        <li><a href="#now">现在</a></li>
      </ul>

      <div class="nav-actions">
        <template v-if="isAdmin">
          <button class="nav-link-btn" @click="$emit(view === 'admin' ? 'go-site' : 'go-admin')">
            {{ view === 'admin' ? '查看站点' : '写博客' }}
          </button>
          <button class="nav-link-btn" @click="logout">退出</button>
        </template>
        <template v-else-if="user">
          <span class="nav-user">{{ user.email }}</span>
          <button class="nav-link-btn" @click="logout">退出</button>
        </template>
        <button v-else class="nav-link-btn" @click="$emit('open-login')">登录</button>

        <button class="icon-btn" @click="toggleTheme" :aria-label="theme === 'dark' ? '切换为亮色' : '切换为暗色'">
          <span v-if="theme === 'dark'">☀</span>
          <span v-else>☾</span>
        </button>
        <button class="nav-burger" :class="{ open: menuOpen }" @click="toggleMenu"
                aria-label="菜单" :aria-expanded="menuOpen">
          <span></span><span></span>
        </button>
      </div>
    </div>
  </nav>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { useAuth } from '../composables/useAuth'

const props = defineProps({ profile: Object, view: { type: String, default: 'site' } })
defineEmits(['open-login', 'go-admin', 'go-site'])

const { user, isAdmin, logout } = useAuth()

const scrolled = ref(false)
const menuOpen = ref(false)
const theme = ref('light')
const linksEl = ref(null)

const initials = (props.profile?.name || 'RW').slice(0, 2).toUpperCase()

function onScroll() { scrolled.value = window.scrollY > 16 }

function syncPadding() {
  if (menuOpen.value && window.innerWidth <= 640) {
    document.body.style.paddingTop = (linksEl.value?.offsetHeight || 0) + 'px'
  } else {
    document.body.style.paddingTop = ''
  }
}

function toggleMenu() {
  menuOpen.value = !menuOpen.value
  syncPadding()
}

function closeMenu() {
  menuOpen.value = false
  document.body.style.paddingTop = ''
}

function onLinkClick(e) {
  if (e.target.closest('a')) closeMenu()
}

function toggleTheme() {
  theme.value = theme.value === 'dark' ? 'light' : 'dark'
  document.documentElement.setAttribute('data-theme', theme.value)
  localStorage.setItem('theme', theme.value)
}

function onResize() {
  if (window.innerWidth > 640) closeMenu()
  else syncPadding()
}

onMounted(() => {
  theme.value = localStorage.getItem('theme') ||
    (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
  document.documentElement.setAttribute('data-theme', theme.value)
  window.addEventListener('scroll', onScroll, { passive: true })
  window.addEventListener('resize', onResize)
  onScroll()
})

onUnmounted(() => {
  window.removeEventListener('scroll', onScroll)
  window.removeEventListener('resize', onResize)
})
</script>
