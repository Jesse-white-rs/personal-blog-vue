<template>
  <SiteNav :profile="profile" />
  <main>
    <HeroSection :profile="profile" :articles="articles" :projects="projects" :skills="skills" />
    <ArticlesSection :articles="articles" />
    <AboutSection :profile="profile" :skills="skills" :tools="tools" />
    <ProjectsSection :projects="projects" />
    <NowSection :items="nowItems" />
  </main>
  <SiteFooter :profile="profile" />
</template>

<script setup>
import { onMounted } from 'vue'
import SiteNav from './components/SiteNav.vue'
import HeroSection from './components/HeroSection.vue'
import ArticlesSection from './components/ArticlesSection.vue'
import AboutSection from './components/AboutSection.vue'
import ProjectsSection from './components/ProjectsSection.vue'
import NowSection from './components/NowSection.vue'
import SiteFooter from './components/SiteFooter.vue'
import { useContent } from './composables/useContent'

const { articles, projects, skills, tools, nowItems, profile, load } = useContent()

onMounted(load)
</script>
