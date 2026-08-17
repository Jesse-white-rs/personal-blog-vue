<template>
  <transition name="modal">
    <div class="modal-mask" v-if="open" @click.self="close">
      <div class="modal" role="dialog" aria-modal="true">
        <button class="modal-close" @click="close" aria-label="关闭">
          <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M18 6L6 18M6 6l12 12"/></svg>
        </button>

        <div class="modal-head">
          <span class="modal-badge">PROFILE</span>
          <h2 class="modal-title">个人资料</h2>
          <p class="modal-sub">展示在评论与博客中的公开信息。</p>
        </div>

        <div class="avatar-row">
          <div class="avatar avatar-lg">
            <img v-if="preview.avatar_url" :src="preview.avatar_url" :alt="preview.nickname || '头像'" referrerpolicy="no-referrer" />
            <span v-else>{{ initial }}</span>
          </div>
          <div>
            <button type="button" class="btn btn-sm" @click="pickAvatar">随机头像</button>
            <p class="hint">支持任意图片 URL</p>
          </div>
        </div>

        <form @submit.prevent="save" novalidate>
          <div class="field">
            <label for="p-nickname">昵称</label>
            <input id="p-nickname" type="text" v-model.trim="preview.nickname" maxlength="24"
                   placeholder="大家怎么称呼你" />
          </div>

          <div class="field">
            <label for="p-avatar">头像地址</label>
            <input id="p-avatar" type="url" v-model.trim="preview.avatar_url"
                   placeholder="https://…" />
          </div>

          <div class="field">
            <label for="p-bio">个人简介</label>
            <textarea id="p-bio" v-model.trim="preview.bio" rows="3" maxlength="160"
                      placeholder="用一句话介绍你自己"></textarea>
          </div>

          <transition name="fade">
            <p v-if="msg" class="form-alert" :class="msgType" role="status">{{ msg }}</p>
          </transition>

          <div class="modal-actions">
            <button type="button" class="btn btn-ghost" @click="close">取消</button>
            <button class="btn btn-primary" type="submit" :disabled="saving">
              <span v-if="saving" class="spinner" aria-hidden="true"></span>
              <span>{{ saving ? '保存中…' : '保存修改' }}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useAuth } from '../composables/useAuth'

const props = defineProps({ open: Boolean })
const emit = defineEmits(['close'])

const { profile, updateProfile } = useAuth()

const preview = ref({ nickname: '', avatar_url: '', bio: '' })
const msg = ref('')
const msgType = ref('error')
const saving = ref(false)

const initial = computed(() => {
  const n = preview.value.nickname || profile.value?.nickname || profile.value?.email || 'U'
  return n.charAt(0).toUpperCase()
})

const AVATARS = [
  'Rui', 'Mia', 'Leo', 'Nova', 'Iris', 'Aria'
].map((s) => 'https://api.dicebear.com/9.x/adventurer/svg?seed=' + s)
let ai = 0

function pickAvatar() {
  const url = AVATARS[ai % AVATARS.length]
  ai++
  preview.value.avatar_url = url
}

function sync() {
  preview.value = {
    nickname: profile.value?.nickname || '',
    avatar_url: profile.value?.avatar_url || '',
    bio: profile.value?.bio || ''
  }
  msg.value = ''
}

watch(() => props.open, (v) => { if (v) sync() }, { immediate: true })

function close() {
  emit('close')
}

async function save() {
  msg.value = ''
  if (!preview.value.nickname) {
    msgType.value = 'error'
    msg.value = '昵称不能为空'
    return
  }
  saving.value = true
  const { error } = await updateProfile({
    nickname: preview.value.nickname,
    avatar_url: preview.value.avatar_url || null,
    bio: preview.value.bio || null
  })
  saving.value = false
  if (error) {
    msgType.value = 'error'
    msg.value = error.message
    return
  }
  emit('close')
}
</script>
