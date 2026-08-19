<template>
  <nav class="nav" :class="{ scrolled }">
    <div class="scroll-progress" :style="{ '--progress': progress }"></div>
    <div class="container nav-inner">
      <a class="brand" href="#top">
        <span class="brand-mark">{{ initials }}</span>
        <span class="brand-name">{{ profile?.name || 'RWG' }}</span>
      </a>

      <ul class="nav-links" ref="linksEl" :class="{ open: menuOpen }" @click="onLinkClick">
        <li><a href="#articles">文章</a></li>
        <li><a href="#about">关于</a></li>
        <li><a href="#projects">项目</a></li>
        <li><a href="#now">现在</a></li>
        <!-- 移动端：登录后的操作按钮收进折叠菜单，避免顶栏挤不下换行 -->
        <li v-if="user || isAdmin" class="nav-menu-actions">
          <template v-if="isAdmin">
            <button class="nav-menu-btn" @click="goAdmin">
              {{ view === 'admin' ? '查看站点' : '写博客' }}
            </button>
            <button class="nav-menu-btn" @click="openProfile">个人资料</button>
            <button class="nav-menu-btn nav-menu-logout" @click="handleLogout">退出登录</button>
          </template>
          <template v-else>
            <button class="nav-menu-btn nav-menu-user" @click="openProfile">
              <span class="avatar avatar-xs">
                <img v-if="myAvatar" :src="myAvatar" :alt="myName" referrerpolicy="no-referrer" />
                <span v-else>{{ myInitial }}</span>
              </span>
              <span>{{ myName }}</span>
            </button>
            <button class="nav-menu-btn nav-menu-logout" @click="handleLogout">退出登录</button>
          </template>
        </li>
      </ul>

      <div class="nav-actions">
        <!-- 桌面端操作按钮；移动端由 CSS 隐藏，收进折叠菜单 -->
        <template v-if="isAdmin">
          <button class="nav-link-btn nav-desktop-only" @click="$emit(view === 'admin' ? 'go-site' : 'go-admin')">
            {{ view === 'admin' ? '查看站点' : '写博客' }}
          </button>
          <button class="nav-link-btn nav-desktop-only" @click="openProfile">个人资料</button>
          <button class="nav-link-btn nav-logout nav-desktop-only" @click="handleLogout">退出登录</button>
        </template>
        <template v-else-if="user">
          <button class="nav-user-btn nav-desktop-only" @click="openProfile">
            <span class="avatar avatar-xs">
              <img v-if="myAvatar" :src="myAvatar" :alt="myName" referrerpolicy="no-referrer" />
              <span v-else>{{ myInitial }}</span>
            </span>
            <span class="nav-user-name">{{ myName }}</span>
          </button>
          <button class="nav-link-btn nav-logout nav-desktop-only" @click="handleLogout">退出</button>
        </template>
        <button v-else class="nav-link-btn nav-login" @click="$emit('open-login')">登录</button>

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
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useAuth } from '../composables/useAuth'

const props = defineProps({ profile: Object, view: { type: String, default: 'site' } })
const emit = defineEmits(['open-login', 'open-profile', 'go-admin', 'go-site', 'logout'])

const { user, profile: myProfile, isAdmin, logout } = useAuth()

const scrolled = ref(false)
const menuOpen = ref(false)
const theme = ref('light')
const linksEl = ref(null)

const initials = (props.profile?.name || 'RW').slice(0, 2).toUpperCase()

const myName = computed(() => myProfile.value?.nickname || myProfile.value?.email || '我')
const myInitial = computed(() => (myName.value || '我').charAt(0).toUpperCase())
const myAvatar = computed(() => myProfile.value?.avatar_url)

function goAdmin() {
  emit(props.view === 'admin' ? 'go-site' : 'go-admin')
  closeMenu()
}

function openProfile() {
  emit('open-profile')
  closeMenu()
}

async function handleLogout() {
  closeMenu()
  await logout()
  emit('logout')
}

function onScroll() {
  scrolled.value = window.scrollY > 16
  const h = document.documentElement
  const max = h.scrollHeight - h.clientHeight
  progress.value = max > 0 ? Math.min(window.scrollY / max, 1) : 0
}

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
