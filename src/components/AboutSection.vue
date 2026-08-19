<template>
  <section class="section section-dark" id="about">
    <div class="container about-wrap">
      <div class="about-sticky" v-reveal="'left'">
        <p class="eyebrow eyebrow-light">ABOUT</p>
        <h2 class="section-title section-title-light">关于</h2>
        <p class="about-quote">"first, solve the problem. then, write the code."</p>
      </div>

      <div class="about-body" v-reveal="'right'">
        <p class="lead">{{ profile.lead }}</p>
        <p v-for="(p, i) in profile.paragraphs" :key="i">{{ p }}</p>

        <p class="block-label">技能</p>
        <div class="skill-tags">
          <span v-for="(s, i) in skills" :key="i">{{ typeof s === 'string' ? s : s.name }}</span>
        </div>

        <p class="block-label">工具</p>
        <ul class="tool-list">
          <li v-for="(t, i) in tools" :key="i">{{ typeof t === 'string' ? t : t.name }}</li>
        </ul>
      </div>
    </div>
  </section>
</template>

<script setup>
defineProps({ profile: Object, skills: Array, tools: Array })
</script>
