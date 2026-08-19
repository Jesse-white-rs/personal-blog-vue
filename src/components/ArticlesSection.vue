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
                  @click="setCategory(c)">
            {{ c === 'all' ? '全部' : c }}
          </button>
        </div>
      </div>

      <div class="article-list">
        <article v-for="(a, i) in paged" :key="a.id || a.title" class="article-item"
                 :class="{ 'no-cover': !a.cover_url }"
                 v-reveal="{ dir: 'up', delay: (i % 3) * 60 }" role="button" tabindex="0" @click="$emit('open', a)"
                 @keydown.enter="$emit('open', a)">
          <div v-if="a.cover_url" class="article-cover">
            <img :src="a.cover_url" :alt="a.title" loading="lazy" referrerpolicy="no-referrer" />
          </div>
          <div class="article-main">
            <div class="article-top">
              <time class="article-date">{{ a.date }}</time>
              <span class="article-tag">{{ a.category }}</span>
            </div>
            <h3>{{ a.title }}</h3>
            <p class="article-excerpt">{{ a.excerpt }}</p>
            <div class="article-stats">
              <span class="stat" title="阅读数">
                <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/></svg>
                {{ fmt(a.views || 0) }}
              </span>
              <span class="stat" title="评论数">
                <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
                {{ fmt(commentCounts[a.id] ?? 0) }}
              </span>
              <span class="stat" title="点赞数">
                <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8z"/></svg>
                {{ fmt(a.likes || 0) }}
              </span>
            </div>
          </div>
        </article>
        <p v-if="!allFiltered.length" class="empty-tip">还没有文章，去 Supabase 的 posts 表写点东西吧。</p>
      </div>

      <Pagination :page="page" :total="total" :per-page="perPage" @change="page = $event" />
    </div>
  </section>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import Pagination from './Pagination.vue'
import { useContent } from '../composables/useContent'

const props = defineProps({ articles: Array })
defineEmits(['open'])

const { getCommentCounts } = useContent()

const active = ref('all')
const page = ref(1)
const perPage = 5
const commentCounts = ref({})

const categories = computed(() => ['all', ...new Set((props.articles || []).map((a) => a.category))])
const allFiltered = computed(() => {
  const list = props.articles || []
  return active.value === 'all' ? list : list.filter((a) => a.category === active.value)
})
const total = computed(() => allFiltered.value.length)
const paged = computed(() => {
  const start = (page.value - 1) * perPage
  return allFiltered.value.slice(start, start + perPage)
})

// 文章列表变化时批量拉取各文章的评论数
watch(() => props.articles, async (list) => {
  const ids = (list || []).map((a) => a.id).filter(Boolean)
  if (!ids.length) {
    commentCounts.value = {}
    return
  }
  commentCounts.value = await getCommentCounts(ids)
}, { immediate: true })

function setCategory(c) {
  active.value = c
  page.value = 1
}

// 数字美化：1200 -> 1.2k，23000 -> 2.3w
function fmt(n) {
  n = Number(n) || 0
  if (n >= 10000) return (n / 10000).toFixed(1).replace(/\.0$/, '') + 'w'
  if (n >= 1000) return (n / 1000).toFixed(1).replace(/\.0$/, '') + 'k'
  return String(n)
}
</script>
