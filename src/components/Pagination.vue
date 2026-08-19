<template>
  <nav class="pagination" v-if="totalPages > 1" aria-label="分页导航">
    <button class="page-btn" :disabled="page <= 1" @click="go(page - 1)">‹ 上一页</button>
    <template v-for="it in pages" :key="it.ellipsis ? 'e' + it.key : it.n">
      <span v-if="it.ellipsis" class="page-ellipsis">…</span>
      <button v-else class="page-btn num" :class="{ active: it.n === page }" @click="go(it.n)">{{ it.n }}</button>
    </template>
    <button class="page-btn" :disabled="page >= totalPages" @click="go(page + 1)">下一页 ›</button>
    <span class="page-info">{{ page }} / {{ totalPages }} 页 · 共 {{ total }} 条</span>
  </nav>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  page: { type: Number, required: true },
  total: { type: Number, required: true },
  perPage: { type: Number, default: 5 }
})
const emit = defineEmits(['change'])

const totalPages = computed(() => Math.max(1, Math.ceil(props.total / props.perPage)))

// 页码列表：≤7 页全显示；否则显示首尾 + 当前页前后，中间用省略号
const pages = computed(() => {
  const n = totalPages.value
  const cur = props.page
  if (n <= 7) return Array.from({ length: n }, (_, i) => ({ n: i + 1 }))
  const out = []
  const push = (num) => {
    const last = out[out.length - 1]
    if (last && !last.ellipsis && last.n === num) return
    if (last && !last.ellipsis && num - last.n > 1) out.push({ ellipsis: true, key: last.n })
    if (last && last.ellipsis && last.key === num - 1) return
    out.push({ n: num })
  }
  push(1)
  for (let i = Math.max(2, cur - 1); i <= Math.min(n - 1, cur + 1); i++) push(i)
  push(n)
  return out
})

function go(n) {
  if (n === props.page || n < 1 || n > totalPages.value) return
  emit('change', n)
}
</script>
