<template>
  <section class="admin">
    <div class="container">
      <div class="admin-head">
        <h2>写博客 · 后台</h2>
        <button class="btn" v-if="tab === 'posts'" @click="openCreate">+ 新建文章</button>
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

        <Pagination :page="page" :total="total" :per-page="perPage" @change="gotoPage" />
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
        <label>终端窗口内容（每行一条，前台会逐条打字播放）
          <textarea v-model.trim="site.terminalLinesText" rows="4"
                    placeholder="git commit -m &quot;第 24 篇文章&quot;&#10;cd ~/ideas &amp;&amp; vim new-post.md&#10;npm run build &amp;&amp; ship it"></textarea>
        </label>

        <p class="form-error" v-if="siteError">{{ siteError }}</p>
        <p class="form-ok" v-if="siteOk">{{ siteOk }}</p>

        <div class="form-foot">
          <button class="btn btn-primary" type="submit" :disabled="siteSaving">
            {{ siteSaving ? '保存中…' : '保存站点资料' }}
          </button>
        </div>
        <p class="site-note">提示：保存后前台首页会自动刷新。</p>
      </form>
    </div>

    <!-- 操作反馈 Toast -->
    <transition name="toast">
      <div class="toast" v-if="toast" :class="toast.type" role="status" aria-live="polite">
        <svg v-if="toast.type === 'success'" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5" /></svg>
        <svg v-else viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M12 8v5M12 16.5v.5" /></svg>
        <span>{{ toast.msg }}</span>
      </div>
    </transition>

    <!-- 新建 / 编辑文章弹窗 -->
    <transition name="modal">
      <div class="modal-mask" v-if="editorOpen && supabase" @click.self="closeEditor">
        <div class="modal modal-wide" role="dialog" aria-modal="true" aria-label="文章编辑">
          <button class="modal-close" @click="closeEditor" aria-label="关闭">
            <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M18 6L6 18M6 6l12 12" /></svg>
          </button>
          <div class="modal-head">
            <span class="modal-badge">{{ editingId ? 'EDIT POST' : 'NEW POST' }}</span>
            <h2 class="modal-title">{{ editingId ? '编辑文章' : '新建文章' }}</h2>
          </div>
          <form class="post-form" @submit.prevent="save">
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
              <button class="btn" type="button" @click="closeEditor">取消</button>
            </div>
          </form>
        </div>
      </div>
    </transition>
  </section>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import { useAuth } from '../composables/useAuth'
import MarkdownEditor from './MarkdownEditor.vue'
import ImageUploader from './ImageUploader.vue'
import Pagination from './Pagination.vue'

const { isAdmin } = useAuth()
const posts = ref([])
const loading = ref(false)
const saving = ref(false)
const error = ref('')
const editingId = ref(null)
const editorOpen = ref(false)

/* ---------- 文章列表分页 ---------- */
const page = ref(1)
const perPage = 8
const total = ref(0)
const totalPages = computed(() => Math.max(1, Math.ceil(total.value / perPage)))

function gotoPage(n) {
  if (n === page.value || n < 1 || n > totalPages.value) return
  page.value = n
  load()
}

const tab = ref('posts')
const site = ref({ name: '', tagline: '', bio: '', lead: '', paragraphsText: '', terminalLinesText: '' })
const siteError = ref('')
const siteOk = ref('')
const siteSaving = ref(false)

/* ---------- 全局反馈 Toast ---------- */
const toast = ref(null)
let toastTimer = null
function showToast(msg, type = 'success') {
  toast.value = { msg, type }
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => { toast.value = null }, 3000)
}

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
  const from = (page.value - 1) * perPage
  const to = from + perPage - 1
  const { data, count, error: e } = await supabase
    .from('posts')
    .select('*', { count: 'exact' })
    .order('date', { ascending: false })
    .range(from, to)
  loading.value = false
  if (e) { error.value = e.message; return }
  posts.value = data || []
  total.value = count ?? 0
}

async function loadSite() {
  if (!supabase) return
  siteError.value = ''
  siteOk.value = ''
  const { data, error: e } = await supabase.from('profile').select('*').eq('id', 1).maybeSingle()
  if (e) { siteError.value = e.message; return }
  if (data) {
    site.value = {
      name: data.name || '', tagline: data.tagline || '', bio: data.bio || '',
      lead: data.lead || '', paragraphsText: (data.paragraphs || []).join('\n'),
      terminalLinesText: (data.terminal_lines || []).join('\n')
    }
  }
}

function resetForm() {
  editingId.value = null
  form.value = empty()
  error.value = ''
}

function openCreate() {
  resetForm()
  editorOpen.value = true
}

function closeEditor() {
  editorOpen.value = false
  resetForm()
}

function edit(p) {
  editingId.value = p.id
  form.value = {
    title: p.title || '', category: p.category || '', date: p.date || '',
    status: p.status || 'published', slug: p.slug || '', cover_url: p.cover_url || '',
    tags: (p.tags || []).join(', '), excerpt: p.excerpt || '', content: p.content || ''
  }
  editorOpen.value = true
}

function remove(p) {
  if (!supabase) return
  if (!confirm(`确定删除《${p.title || '无标题'}》？`)) return
  supabase.from('posts').delete().eq('id', p.id).then(({ error: e }) => {
    if (e) { showToast(`删除失败：${e.message}`, 'error'); return }
    if (editingId.value === p.id) closeEditor()
    // 当前页删空时回退一页，避免停在空页
    if (posts.value.length === 1 && page.value > 1) page.value -= 1
    load()
    window.dispatchEvent(new Event('content:updated'))
    showToast(`已删除《${p.title || '无标题'}》`)
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
  const isEdit = Boolean(editingId.value)
  let res
  if (isEdit) {
    res = await supabase.from('posts').update(payload).eq('id', editingId.value)
  } else {
    res = await supabase.from('posts').insert(payload)
  }
  saving.value = false
  if (res.error) { showToast(`保存失败：${res.error.message}`, 'error'); return }
  closeEditor()
  // 新建的文章排在最前，回到第一页以便看到
  if (!isEdit) page.value = 1
  load()
  window.dispatchEvent(new Event('content:updated'))
  showToast(isEdit ? '文章已更新' : '文章已发布')
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
    terminal_lines: (site.value.terminalLinesText || '').split('\n').map((s) => s.trim()).filter(Boolean),
    updated_at: new Date().toISOString()
  }
  // 用 upsert 保证 id=1 行始终存在（update 在行不存在时影响 0 行且不报错）
  const { error: e } = await supabase
    .from('profile')
    .upsert({ id: 1, ...payload }, { onConflict: 'id' })
  siteSaving.value = false
  if (e) {
    siteError.value = e.message
    siteOk.value = ''
    showToast(`保存失败：${e.message}`, 'error')
    return
  }
  siteError.value = ''
  siteOk.value = '已保存，前台首页已同步更新。'
  // 通知前台重新拉取数据，立即生效
  window.dispatchEvent(new Event('content:updated'))
  showToast('站点资料已保存')
}

onMounted(load)
</script>
