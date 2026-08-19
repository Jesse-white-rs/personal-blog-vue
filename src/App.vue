<template>
  <SiteNav :profile="profile" :view="view"
           @open-login="loginOpen = true"
           @open-profile="profileOpen = true"
           @go-admin="view = 'admin'"
           @go-site="view = 'site'"
           @logout="onLogout" />
  <main v-if="view === 'site'">
    <HeroSection :profile="profile" :articles="articles" :projects="projects" :skills="skills" />
    <ArticlesSection :articles="articles" @open="openArticle" />
    <AboutSection :profile="profile" :skills="skills" :tools="tools" />
    <ProjectsSection :projects="projects" />
    <NowSection :items="nowItems" />
  </main>
  <AdminView v-else-if="isAdmin" />
  <main v-else>
    <div class="container locked">
      <p>需要管理员权限才能访问后台。请先在右上角“登录”。</p>
    </div>
  </main>
  <SiteFooter :profile="profile" />

  <button class="back-to-top" :class="{ show: showTop }" @click="scrollTop" aria-label="回到顶部">
    <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19V5M5 12l7-7 7 7" /></svg>
  </button>

  <LoginModal :open="loginOpen" @close="loginOpen = false" />
  <ProfileModal :open="profileOpen" @close="profileOpen = false" />
  <ArticleModal :open="!!selectedArticle" :article="selectedArticle || {}"
                @close="selectedArticle = null" @login="openLoginFromArticle" />
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import SiteNav from './components/SiteNav.vue'
import HeroSection from './components/HeroSection.vue'
import ArticlesSection from './components/ArticlesSection.vue'
import AboutSection from './components/AboutSection.vue'
import ProjectsSection from './components/ProjectsSection.vue'
import NowSection from './components/NowSection.vue'
import SiteFooter from './components/SiteFooter.vue'
import AdminView from './components/AdminView.vue'
import LoginModal from './components/LoginModal.vue'
import ProfileModal from './components/ProfileModal.vue'
import ArticleModal from './components/ArticleModal.vue'
import { useContent } from './composables/useContent'
import { useAuth } from './composables/useAuth'

const { articles, projects, skills, tools, nowItems, profile, load } = useContent()
const { isAdmin, init } = useAuth()

const view = ref('site')
const showTop = ref(false)
const loginOpen = ref(false)
const profileOpen = ref(false)
const selectedArticle = ref(null)

function onScroll() {
  showTop.value = window.scrollY > 480
}

function scrollTop() {
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

function openArticle(a) {
  selectedArticle.value = a
}

function openLoginFromArticle() {
  selectedArticle.value = null
  loginOpen.value = true
}

function onLoggedIn() {
  if (isAdmin.value) view.value = 'admin'
  loginOpen.value = false
}

// 退出登录后返回站点首页
function onLogout() {
  view.value = 'site'
}

// 后台保存内容（文章/站点资料）后，前台立即重新拉取
function onContentUpdated() {
  load()
}

onMounted(() => {
  load()
  init()
  window.addEventListener('auth:logged-in', onLoggedIn)
  window.addEventListener('content:updated', onContentUpdated)
  window.addEventListener('scroll', onScroll, { passive: true })
  onScroll()
})

onUnmounted(() => {
  window.removeEventListener('scroll', onScroll)
  window.removeEventListener('content:updated', onContentUpdated)
})
</script>
