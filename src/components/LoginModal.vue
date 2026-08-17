<template>
  <transition name="fade">
    <div class="modal-mask" v-if="open" @click.self="$emit('close')">
      <div class="modal" role="dialog" aria-modal="true">
        <button class="modal-close" @click="$emit('close')" aria-label="关闭">×</button>
        <h2 class="modal-title">{{ tab === 'login' ? '登录' : '注册' }}</h2>

        <div class="seg">
          <button :class="{ active: tab === 'login' }" @click="tab = 'login'">登录</button>
          <button :class="{ active: tab === 'signup' }" @click="tab = 'signup'">注册</button>
        </div>

        <form @submit.prevent="submit">
          <label>邮箱
            <input type="email" v-model.trim="email" required placeholder="you@example.com" />
          </label>
          <label>密码
            <input type="password" v-model="password" required minlength="6" placeholder="至少 6 位" />
          </label>

          <p class="form-error" v-if="error">{{ error }}</p>

          <button class="btn btn-primary" type="submit" :disabled="loading">
            {{ loading ? '处理中…' : (tab === 'login' ? '登录' : '注册') }}
          </button>
        </form>

        <p class="hint" v-if="tab === 'signup'">
          注册后需到邮箱确认（或在 Supabase 后台关闭邮件确认）。<br />
          管理员权限需在 Supabase 执行：<code>update profiles set is_admin = true where email = '你的邮箱';</code>
        </p>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref } from 'vue'
import { useAuth } from '../composables/useAuth'

defineProps({ open: Boolean })
defineEmits(['close'])

const { login, signUp } = useAuth()
const tab = ref('login')
const email = ref('')
const password = ref('')
const error = ref('')
const loading = ref(false)

async function submit() {
  error.value = ''
  loading.value = true
  const { error: e } = tab.value === 'login'
    ? await login(email.value, password.value)
    : await signUp(email.value, password.value)
  loading.value = false

  if (e) {
    error.value = e.message
    return
  }
  if (tab.value === 'signup') {
    error.value = '注册成功，请查收确认邮件后登录。'
    tab.value = 'login'
    return
  }
  // 登录成功
  email.value = ''
  password.value = ''
  // 关闭交给父组件在状态变化后处理
  window.dispatchEvent(new CustomEvent('auth:logged-in'))
}
</script>
