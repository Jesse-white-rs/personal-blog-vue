<template>
  <header class="hero" id="top">
    <div class="container hero-grid">
      <div class="hero-left" v-reveal>
        <h1 class="hero-title">你好，我是 <span class="accent">{{ profile.name }}</span>。</h1>
        <p class="hero-tagline">{{ profile.tagline }}</p>
        <p class="hero-bio">{{ profile.bio }}</p>
        <div class="hero-actions">
          <a class="btn btn-dark" href="#articles">读读文章</a>
          <a class="btn btn-ghost" href="#projects">看看项目</a>
        </div>
        <div class="hero-stats">
          <div class="stat">
            <div class="stat-num">{{ articles.length }}</div>
            <div class="stat-label">篇文章</div>
          </div>
          <div class="stat">
            <div class="stat-num">{{ projects.length }}</div>
            <div class="stat-label">个项目</div>
          </div>
          <div class="stat">
            <div class="stat-num">{{ skillsCount }}</div>
            <div class="stat-label">项技能</div>
          </div>
        </div>
      </div>

      <div class="hero-right" v-reveal>
        <div class="terminal">
          <div class="terminal-bar">
            <span class="dot red"></span>
            <span class="dot yellow"></span>
            <span class="dot green"></span>
            <span class="terminal-title">rwg@blog ~ </span>
          </div>
          <div class="terminal-body">
            <p v-for="(l, i) in typedLines" :key="'l' + i" class="term-line">
              <span class="prompt">$</span>{{ l }}
            </p>
            <p class="term-line">
              <span class="prompt">$</span>{{ current }}<span class="caret"></span>
            </p>
          </div>
        </div>
      </div>
    </div>
  </header>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  profile: Object,
  articles: Array,
  projects: Array,
  skills: Array
})

const skillsCount = computed(() => props.skills?.length || 0)

const lines = [
  '> git commit -m "第 24 篇文章"',
  '> cd ~/ideas && vim new-post.md',
  '> npm run build && ship it'
]

const typedLines = ref([])
const current = ref('')
let timer = null

onMounted(() => {
  let line = 0
  let char = 0
  function tick() {
    const c = lines[line]
    if (char <= c.length) {
      current.value = c.slice(0, char)
      char++
      timer = setTimeout(tick, 46)
    } else {
      timer = setTimeout(() => {
        typedLines.value = [...typedLines.value, c]
        current.value = ''
        char = 0
        line = (line + 1) % lines.length
        timer = setTimeout(tick, 300)
      }, 2000)
    }
  }
  timer = setTimeout(tick, 800)
})

onUnmounted(() => clearTimeout(timer))
</script>
