<template>
  <SiteNav :profile="profile" :view="view"
           @open-login="loginOpen = true"
           @open-profile="profileOpen = true"
           @go-admin="view = 'admin'"
           @go-site="view = 'site'" />
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

  <LoginModal :open="loginOpen" @close="loginOpen = false" />
  <ProfileModal :open="profileOpen" @close="profileOpen = false" />
  <ArticleModal :open="!!selectedArticle" :article="selectedArticle || {}"
                @close="selectedArticle = null" @login="openLoginFromArticle" />
</template>

<script setup>
import { ref, onMounted } from 'vue'
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
const loginOpen = ref(false)
const profileOpen = ref(false)
const selectedArticle = ref(null)

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

onMounted(() => {
  load()
  init()
  window.addEventListener('auth:logged-in', onLoggedIn)
})
</script>
