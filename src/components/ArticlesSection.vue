<template>
  <section class="section" id="articles">
    <div class="container">
      <div class="section-head" v-reveal>
        <div>
          <p class="eyebrow">WORDS</p>
          <h2 class="section-title">文章</h2>
        </div>
        <div class="filter-bar">
          <button v-for="c in categories" :key="c"
                  class="chip" :class="{ active: active === c }"
                  @click="active = c">
            {{ c === 'all' ? '全部' : c }}
          </button>
        </div>
      </div>

      <div class="article-list">
        <article v-for="a in filtered" :key="a.title" class="article-item" v-reveal>
          <time class="article-date">{{ a.date }}</time>
          <div class="article-main">
            <h3>{{ a.title }}</h3>
            <p class="article-excerpt">{{ a.excerpt }}</p>
          </div>
          <span class="article-tag">{{ a.category }}</span>
        </article>
        <p v-if="!filtered.length" class="empty-tip">还没有文章，去 Supabase 的 posts 表写点东西吧。</p>
      </div>
    </div>
  </section>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({ articles: Array })

const active = ref('all')
const categories = computed(() => ['all', ...new Set(props.articles.map((a) => a.category))])
const filtered = computed(() =>
  active.value === 'all' ? props.articles : props.articles.filter((a) => a.category === active.value)
)
</script>
