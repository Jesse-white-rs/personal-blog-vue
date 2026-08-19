<template>
  <section class="section" id="projects">
    <div class="container">
      <div class="section-head" v-reveal>
        <div>
          <p class="eyebrow">WORKS</p>
          <h2 class="section-title">项目</h2>
        </div>
      </div>

      <div class="project-grid">
        <a v-for="(p, i) in projects" :key="p.name"
           :href="p.link"
           class="project-card" v-reveal="{ dir: 'up', delay: (i % 2) * 90 }"
           :target="p.link && p.link.startsWith('http') ? '_blank' : '_self'">
          <h3>{{ p.name }}</h3>
          <p>{{ p.description }}</p>
          <div class="project-meta">
            <div class="project-langs">
              <span v-for="(l, i) in (p.langs || [])" :key="i">{{ l }}</span>
            </div>
            <span class="project-link">查看 <span aria-hidden="true">→</span></span>
          </div>
        </a>
      </div>
    </div>
  </section>
</template>

<script setup>
defineProps({ projects: Array })
</script>
