<template>
  <section class="admin">
    <div class="container">
      <div class="admin-head">
        <h2>写博客 · 后台</h2>
        <button class="btn" v-if="tab === 'posts'" @click="resetForm">+ 新建文章</button>
      </div>

      <p class="admin-hint" v-if="!supabase">未配置 Supabase，后台不可用（请检查 .env 中的 VITE_SUPABASE_*）。</p>

      <div class="tabs">
        <button class="tab" :class="{ active: tab === 'posts' }" @click="tab = 'posts'">文章管理</button>
        <button class="tab" :class="{ active: tab === 'site' }" @click="tab = 'site'; loadSite()">站点设置</button>
      </div>

      <!-- 文章管理 -->
      <div v-if="tab === 'posts'">
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
            <label>封面图
              <ImageUploader v-model="form.cover_url" folder="covers" label="上传封面图" />
            </label>
            <label class="full">标签（逗号分隔）
              <input v-model.trim="form.tags" placeholder="Vue, 前端" />
            </label>
          </div>

          <label>摘要
            <textarea v-model.trim="form.excerpt" rows="2" placeholder="列表页显示的摘要"></textarea>
          </label>
          <label>正文（支持 Markdown，可插入图片）
            <MarkdownEditor v-model="form.content" />
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

      <!-- 站点设置 -->
      <form class="site-form" @submit.prevent="saveSite" v-if="tab === 'site' && supabase">
        <h3>站点资料</h3>
        <p class="site-desc">这些信息会显示在前台首页（如“你好，我是 <b>{{ site.name || 'RWG' }}</b>”）与“关于”板块，可随时修改。</p>

        <div class="grid-2">
          <label>名称（如 RWG）
            <input v-model.trim="site.name" placeholder="RWG" />
          </label>
          <label>标语
            <input v-model.trim="site.tagline" placeholder="写代码，也写生活。" />
          </label>
        </div>
        <label>简介（一句话）
          <textarea v-model.trim="site.bio" rows="2" placeholder="一个写代码的人，也记录生活里的琐碎与思考。"></textarea>
        </label>
        <label>引导语（Hero 下方段落）
          <textarea v-model.trim="site.lead" rows="3" placeholder="我是一名后端工程师，平时主要和 Java、Spring Boot、数据库打交道……"></textarea>
        </label>
        <label>关于我（每段一行）
          <textarea v-model.trim="site.paragraphsText" rows="4"
                    placeholder="第一段内容&#10;第二段内容"></textarea>
        </label>

        <p class="form-error" v-if="siteError">{{ siteError }}</p>

        <div class="form-foot">
          <button class="btn btn-primary" type="submit" :disabled="siteSaving">
            {{ siteSaving ? '保存中…' : '保存站点资料' }}
          </button>
        </div>
        <p class="site-note">提示：保存后刷新前台首页即可看到更新。</p>
      </form>
    </div>
  </section>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import { useAuth } from '../composables/useAuth'
import MarkdownEditor from './MarkdownEditor.vue'
import ImageUploader from './ImageUploader.vue'

const { isAdmin } = useAuth()
const posts = ref([])
const loading = ref(false)
const saving = ref(false)
const error = ref('')
const editingId = ref(null)

const tab = ref('posts')
const site = ref({ name: '', tagline: '', bio: '', lead: '', paragraphsText: '' })
const siteError = ref('')
const siteSaving = ref(false)

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

async function loadSite() {
  if (!supabase) return
  const { data, error: e } = await supabase.from('profile').select('*').eq('id', 1).single()
  if (e) { siteError.value = e.message; return }
  site.value = {
    name: data.name || '', tagline: data.tagline || '', bio: data.bio || '',
    lead: data.lead || '', paragraphsText: (data.paragraphs || []).join('\n')
  }
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

async function saveSite() {
  if (!supabase) return
  siteError.value = ''
  siteSaving.value = true
  const payload = {
    name: site.value.name,
    tagline: site.value.tagline || null,
    bio: site.value.bio || null,
    lead: site.value.lead || null,
    paragraphs: (site.value.paragraphsText || '').split('\n').map((s) => s.trim()).filter(Boolean),
    updated_at: new Date().toISOString()
  }
  const { error: e } = await supabase.from('profile').update(payload).eq('id', 1)
  siteSaving.value = false
  if (e) { siteError.value = e.message; return }
}

onMounted(load)
</script>
