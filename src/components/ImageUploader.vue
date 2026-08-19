<template>
  <div class="img-uploader" :class="{ round }">
    <div class="upload-drop" :class="{ 'has-img': model, round }"
         @click="pick" @dragover.prevent @drop.prevent="onDrop">
      <img v-if="model" :src="model" class="preview" :class="{ round }" alt="预览" />
      <div v-else class="upload-ph">
        <svg viewBox="0 0 24 24" width="22" height="22" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round">
          <path d="M12 16V4m0 0L8 8m4-4l4 4" />
          <path d="M4 16v2a2 2 0 002 2h12a2 2 0 002-2v-2" />
        </svg>
        <span>{{ uploading ? '上传中…' : (label || '点击或拖拽上传') }}</span>
      </div>
      <input ref="fileInput" type="file" accept="image/*" hidden @change="onFile" />
    </div>
    <p v-if="errorMsg" class="upload-err">{{ errorMsg }}</p>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { uploadImage } from '../lib/storage'

const model = defineModel({ type: String, default: '' })
const props = defineProps({
  folder: { type: String, default: 'avatars' },
  label: { type: String, default: '' },
  round: { type: Boolean, default: false },
  maxMB: { type: Number, default: 5 }
})

const fileInput = ref(null)
const uploading = ref(false)
const errorMsg = ref('')

function pick() { fileInput.value?.click() }

async function doUpload(file) {
  uploading.value = true
  errorMsg.value = ''
  const { url, error } = await uploadImage(file, props.folder, { maxMB: props.maxMB })
  uploading.value = false
  if (error) { errorMsg.value = error; return }
  model.value = url
}

async function onFile(e) {
  const f = e.target.files?.[0]
  if (f) await doUpload(f)
  e.target.value = ''
}

async function onDrop(e) {
  const f = e.dataTransfer.files?.[0]
  if (f) await doUpload(f)
}
</script>

<style scoped>
.img-uploader { width: 100%; }
.upload-drop {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 120px;
  border: 1.5px dashed var(--border);
  border-radius: 14px;
  background: var(--card-2);
  cursor: pointer;
  overflow: hidden;
  transition: border-color 0.2s var(--ease), background 0.2s var(--ease);
}
.upload-drop:hover { border-color: var(--brand-1); background: color-mix(in srgb, var(--brand-1) 6%, var(--card-2)); }
.upload-drop.round { min-height: 0; border-style: solid; border-radius: 50%; width: 84px; height: 84px; }
.upload-ph {
  display: flex; flex-direction: column; align-items: center; gap: 6px;
  color: color-mix(in srgb, var(--text) 55%, var(--bg)); font-size: 13px; text-align: center; padding: 10px;
}
.preview { width: 100%; height: 100%; object-fit: cover; display: block; }
.preview.round { border-radius: 50%; }
.upload-err { color: #e5484d; font-size: 12.5px; margin: 6px 2px 0; }
</style>
