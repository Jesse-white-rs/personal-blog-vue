<template>
  <section class="section section-alt" id="now">
    <div class="container now-wrap">
      <div class="about-sticky" v-reveal>
        <p class="eyebrow">NOW</p>
        <h2 class="section-title">现在</h2>
        <p class="about-quote">最近在做什么，读到什么，折腾什么。</p>
      </div>

      <div class="now-list">
        <div v-for="(n, i) in items" :key="i" class="now-item" v-reveal>
          <span class="now-date">{{ n.date }}</span>
          <p>{{ n.text }}</p>
        </div>
        <p v-if="!items.length" class="empty-tip">暂无内容。</p>
      </div>
    </div>
  </section>
</template>

<script setup>
defineProps({ items: Array })
</script>
