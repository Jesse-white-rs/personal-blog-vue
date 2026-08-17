<template>
  <section class="admin">
    <div class="container">
      <div class="admin-head">
        <h2>写博客 · 后台</h2>
        <button class="btn" @click="resetForm">+ 新建文章</button>
      </div>

      <p class="admin-hint" v-if="!supabase">未配置 Supabase，后台不可用（请检查 .env 中的 VITE_SUPABASE_*）。</p>

      <!-- 文章列表 -->
      <div class="post-list" v-if="posts.length">
        <div class="post-row" v-for="p in posts" :key="p.id">
          <div class="post-meta">
            <span class="post-title">{{ p.title || '(无标题)' }}</span>
            <span class="badge" :class="p.status">{{ p.status === 'draft' ? '草稿' : '已发布' }}</span>
            <span class="post-date">{{ p.date }}</span>
          </div>
          <div class="post-actions">
            <button class="btn sm" @click="edit(p)">编辑</button>
            <button class="btn sm danger" @click="remove(p)">删除</button>
          </div>
        </div>
      </div>
      <p v-else-if="!loading" class="empty">还没有文章，点右上角“新建文章”。</p>

      <!-- 编辑表单 -->
      <form class="post-form" @submit.prevent="save" v-if="supabase">
        <h3>{{ editingId ? '编辑文章' : '新建文章' }}</h3>

        <div class="grid-2">
          <label>标题
            <input v-model.trim="form.title" required placeholder="文章标题" />
          </label>
          <label>分类
            <input v-model.trim="form.category" placeholder="前端 / 后端 / 随笔" />
          </label>
          <label>日期
            <input v-model.trim="form.date" placeholder="2026-08-17" />
          </label>
          <label>状态
            <select v-model="form.status">
              <option value="published">已发布</option>
              <option value="draft">草稿</option>
            </select>
          </label>
          <label>Slug
            <input v-model.trim="form.slug" placeholder="url-slug（留空自动生成）" />
          </label>
          <label>封面图 URL
            <input v-model.trim="form.cover_url" placeholder="https://…" />
          </label>
          <label class="full">标签（逗号分隔）
            <input v-model.trim="form.tags" placeholder="Vue, 前端" />
          </label>
        </div>

        <label>摘要
          <textarea v-model.trim="form.excerpt" rows="2" placeholder="列表页显示的摘要"></textarea>
        </label>
        <label>正文（支持纯文本 / Markdown 原文）
          <textarea v-model="form.content" rows="10" placeholder="在这里写正文…"></textarea>
        </label>

        <p class="form-error" v-if="error">{{ error }}</p>

        <div class="form-foot">
          <button class="btn btn-primary" type="submit" :disabled="saving">
            {{ saving ? '保存中…' : '保存' }}
          </button>
          <button class="btn" type="button" @click="resetForm" v-if="editingId">取消</button>
        </div>
      </form>
    </div>
  </section>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import { useAuth } from '../composables/useAuth'

const { isAdmin } = useAuth()
const posts = ref([])
const loading = ref(false)
const saving = ref(false)
const error = ref('')
const editingId = ref(null)

const empty = () => ({
  title: '', category: '', date: new Date().toISOString().slice(0, 10),
  status: 'published', slug: '', cover_url: '', tags: '', excerpt: '', content: ''
})
const form = ref(empty())

function slugify(s) {
  return (s || '').toString().toLowerCase().trim()
    .replace(/[^\w\u4e00-\u9fa5]+/g, '-').replace(/^-+|-+$/g, '').slice(0, 80) || 'post'
}

async function load() {
  if (!supabase) return
  loading.value = true
  const { data, error: e } = await supabase
    .from('posts').select('*').order('date', { ascending: false })
  loading.value = false
  if (e) { error.value = e.message; return }
  posts.value = data || []
}

function resetForm() {
  editingId.value = null
  form.value = empty()
  error.value = ''
}

function edit(p) {
  editingId.value = p.id
  form.value = {
    title: p.title || '', category: p.category || '', date: p.date || '',
    status: p.status || 'published', slug: p.slug || '', cover_url: p.cover_url || '',
    tags: (p.tags || []).join(', '), excerpt: p.excerpt || '', content: p.content || ''
  }
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

function remove(p) {
  if (!supabase) return
  if (!confirm(`确定删除《${p.title || '无标题'}》？`)) return
  supabase.from('posts').delete().eq('id', p.id).then(({ error: e }) => {
    if (e) { error.value = e.message; return }
    if (editingId.value === p.id) resetForm()
    load()
  })
}

async function save() {
  if (!supabase) return
  error.value = ''
  saving.value = true
  const payload = {
    title: form.value.title,
    category: form.value.category || null,
    date: form.value.date || null,
    status: form.value.status,
    slug: form.value.slug || slugify(form.value.title),
    cover_url: form.value.cover_url || null,
    tags: (form.value.tags || '').split(',').map((t) => t.trim()).filter(Boolean),
    excerpt: form.value.excerpt || null,
    content: form.value.content || '',
    updated_at: new Date().toISOString()
  }
  let res
  if (editingId.value) {
    res = await supabase.from('posts').update(payload).eq('id', editingId.value)
  } else {
    res = await supabase.from('posts').insert(payload)
  }
  saving.value = false
  if (res.error) { error.value = res.error.message; return }
  resetForm()
  load()
}

onMounted(load)
</script>
