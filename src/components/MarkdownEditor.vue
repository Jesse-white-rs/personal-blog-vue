<template>
  <div class="md-editor">
    <div class="md-toolbar">
      <button v-for="b in tools" :key="b.label" type="button" class="md-btn"
              :title="b.label" @click="b.run">{{ b.text }}</button>
      <label class="md-btn md-img-btn" title="插入图片">
        <svg viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">
          <rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="M21 16l-5-5L5 20"/>
        </svg>
        <span>图片</span>
        <input ref="imgInput" type="file" accept="image/*" hidden @change="onImageFile" />
      </label>
      <span v-if="uploading" class="md-hint">上传中…</span>
      <span class="md-spacer"></span>
      <button type="button" class="md-btn" :class="{ active: preview }" @click="preview = !preview">
        {{ preview ? '编辑' : '预览' }}
      </button>
    </div>

    <div class="md-body" :class="{ 'show-preview': preview }">
      <textarea ref="ta" class="md-input" :value="model" @input="onInput"
                @paste="onPaste" :placeholder="placeholder" spellcheck="false"></textarea>
      <div class="md-preview" v-show="preview || isWide">
        <MarkdownView :source="model" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import MarkdownView from './MarkdownView.vue'
import { uploadImage } from '../lib/storage'

const model = defineModel({ type: String, default: '' })
const props = defineProps({ placeholder: { type: String, default: '用 Markdown 写点什么…' } })

const ta = ref(null)
const imgInput = ref(null)
const preview = ref(false)
const uploading = ref(false)
// 桌面端（≥900px）默认左右分栏预览
const isWide = ref(typeof window !== 'undefined' ? window.innerWidth >= 900 : true)
if (typeof window !== 'undefined') {
  window.addEventListener('resize', () => { isWide.value = window.innerWidth >= 900 })
}

function onInput(e) { model.value = e.target.value }

function wrap(before, after = '', placeholder = '') {
  const el = ta.value
  if (!el) return
  const start = el.selectionStart
  const end = el.selectionEnd
  const val = model.value
  const selected = val.slice(start, end) || placeholder
  const inserted = before + selected + after
  model.value = val.slice(0, start) + inserted + val.slice(end)
  requestAnimationFrame(() => {
    el.focus()
    const pos = start + before.length + selected.length
    el.setSelectionRange(pos, pos)
  })
}

function insertText(text) {
  const el = ta.value
  if (!el) { model.value += text; return }
  const start = el.selectionStart
  const end = el.selectionEnd
  const val = model.value
  model.value = val.slice(0, start) + text + val.slice(end)
  requestAnimationFrame(() => {
    el.focus()
    const pos = start + text.length
    el.setSelectionRange(pos, pos)
  })
}

const tools = [
  { label: '标题1', text: 'H1', run: () => wrap('\n# ', '', '标题') },
  { label: '标题2', text: 'H2', run: () => wrap('\n## ', '', '小标题') },
  { label: '标题3', text: 'H3', run: () => wrap('\n### ', '', '小节') },
  { label: '粗体', text: 'B', run: () => wrap('**', '**', '粗体') },
  { label: '斜体', text: 'I', run: () => wrap('_', '_', '斜体') },
  { label: '引用', text: '❝', run: () => wrap('\n> ', '', '引用内容') },
  { label: '行内代码', text: '</>', run: () => wrap('`', '`', 'code') },
  { label: '链接', text: '🔗', run: () => wrap('[', '](https://)', '链接文字') },
  { label: '列表', text: '≡', run: () => wrap('\n- ', '', '列表项') }
]

async function onImageFile(e) {
  const f = e.target.files?.[0]
  if (f) await doImageUpload(f)
  e.target.value = ''
}

async function doImageUpload(file) {
  uploading.value = true
  const { url, error } = await uploadImage(file, 'post-images')
  uploading.value = false
  if (error) { alert(error); return }
  const name = file.name.replace(/\.[^.]+$/, '')
  insertText(`\n![${name}](${url})\n`)
}

// 粘贴图片直接上传
function onPaste(e) {
  const items = e.clipboardData?.items
  if (!items) return
  for (const it of items) {
    if (it.type.startsWith('image/')) {
      e.preventDefault()
      const file = it.getAsFile()
      if (file) doImageUpload(file)
      return
    }
  }
}
</script>

<style scoped>
.md-editor {
  border: 1px solid var(--border);
  border-radius: 14px;
  overflow: hidden;
  background: var(--card);
}
.md-toolbar {
  display: flex; align-items: center; gap: 4px; flex-wrap: wrap;
  padding: 8px 10px; border-bottom: 1px solid var(--border); background: var(--card-2);
}
.md-btn {
  display: inline-flex; align-items: center; gap: 4px;
  min-width: 30px; height: 30px; padding: 0 8px;
  border: 1px solid transparent; border-radius: 8px;
  background: transparent; color: var(--text); cursor: pointer;
  font-size: 13px; font-weight: 600;
  transition: background 0.15s, border-color 0.15s;
}
.md-btn:hover { background: color-mix(in srgb, var(--brand-1) 10%, var(--card)); border-color: var(--border); }
.md-btn.active { background: color-mix(in srgb, var(--brand-1) 15%, var(--card)); border-color: var(--brand-1); }
.md-img-btn { cursor: pointer; }
.md-hint { font-size: 12.5px; color: var(--brand-1); }
.md-spacer { flex: 1; }
.md-body { display: grid; grid-template-columns: 1fr; }
.md-body.show-preview { grid-template-columns: 1fr 1fr; }
.md-input {
  width: 100%; min-height: 320px; resize: vertical;
  border: none; outline: none; padding: 16px;
  background: transparent; color: var(--text);
  font-family: var(--mono); font-size: 14px; line-height: 1.7;
}
.md-preview {
  border-left: 1px solid var(--border); padding: 16px; overflow-x: auto;
  background: var(--card);
}
@media (max-width: 899px) {
  .md-body.show-preview { grid-template-columns: 1fr; }
  .md-body.show-preview .md-preview { border-left: none; border-top: 1px solid var(--border); }
  /* 窄屏默认只显示编辑区，点"预览"才显示 */
  .md-preview { display: none !important; }
  .md-body.show-preview .md-preview { display: block !important; }
}
</style>
