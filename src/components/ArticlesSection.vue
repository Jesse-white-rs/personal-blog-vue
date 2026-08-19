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
                 v-reveal="{ dir: 'up', delay: (i % 3) * 60 }" role="button" tabindex="0" @click="$emit('open', a)"
                 @keydown.enter="$emit('open', a)">
          <time class="article-date">{{ a.date }}</time>
          <div class="article-main">
            <h3>{{ a.title }}</h3>
            <p class="article-excerpt">{{ a.excerpt }}</p>
          </div>
          <span class="article-tag">{{ a.category }}</span>
        </article>
        <p v-if="!allFiltered.length" class="empty-tip">还没有文章，去 Supabase 的 posts 表写点东西吧。</p>
      </div>

      <Pagination :page="page" :total="total" :per-page="perPage" @change="page = $event" />
    </div>
  </section>
</template>

<script setup>
import { ref, computed } from 'vue'
import Pagination from './Pagination.vue'

const props = defineProps({ articles: Array })
defineEmits(['open'])

const active = ref('all')
const page = ref(1)
const perPage = 5

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

function setCategory(c) {
  active.value = c
  page.value = 1
}
</script>
