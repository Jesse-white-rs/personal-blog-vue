<template>
  <transition name="modal">
    <div class="modal-mask" v-if="open" @click.self="$emit('close')">
      <div class="modal" role="dialog" aria-modal="true">
        <button class="modal-close" @click="$emit('close')" aria-label="关闭">
          <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M18 6L6 18M6 6l12 12"/></svg>
        </button>

        <div class="modal-head">
          <span class="modal-badge">{{ tab === 'login' ? 'WELCOME BACK' : 'JOIN NOW' }}</span>
          <h2 class="modal-title">{{ tab === 'login' ? '欢迎回来' : '创建账号' }}</h2>
          <p class="modal-sub">{{ tab === 'login' ? '登录后即可参与评论、写博客。' : '注册一个账号，开启博客之旅。' }}</p>
        </div>

        <div class="seg" role="tablist">
          <button type="button" :class="{ active: tab === 'login' }" @click="switchTab('login')">登录</button>
          <button type="button" :class="{ active: tab === 'signup' }" @click="switchTab('signup')">注册</button>
        </div>

        <form @submit.prevent="submit" novalidate>
          <div class="field" v-if="tab === 'signup'">
            <label for="nickname">昵称</label>
            <input id="nickname" type="text" v-model.trim="nickname" maxlength="24"
                   placeholder="大家怎么称呼你" autocomplete="nickname" />
          </div>

          <div class="field">
            <label for="auth-email">邮箱</label>
            <input id="auth-email" type="email" v-model.trim="email" required
                   placeholder="you@example.com" autocomplete="email" />
          </div>

          <div class="field">
            <label for="auth-pass">密码</label>
            <div class="pass-wrap">
              <input id="auth-pass" :type="showPass ? 'text' : 'password'" v-model="password"
                     required :minlength="tab === 'signup' ? 6 : 1"
                     placeholder="至少 6 位" autocomplete="current-password" />
              <button type="button" class="pass-toggle" @click="showPass = !showPass"
                      :aria-label="showPass ? '隐藏密码' : '显示密码'">
                <svg v-if="!showPass" viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                <svg v-else viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M17.94 17.94A10.07 10.07 0 0112 20c-7 0-11-8-11-8a18.45 18.45 0 015.06-5.94M9.9 4.24A9.12 9.12 0 0112 4c7 0 11 8 11 8a18.5 18.5 0 01-2.16 3.19m-6.72-1.07a3 3 0 11-4.24-4.24M1 1l22 22"/></svg>
              </button>
            </div>
          </div>

          <transition name="fade">
            <p v-if="msg" class="form-alert" :class="msgType" role="status">
              {{ msg }}
            </p>
          </transition>

          <button class="btn btn-primary btn-block" type="submit" :disabled="loading">
            <span v-if="loading" class="spinner" aria-hidden="true"></span>
            <span>{{ loading ? '请稍候…' : (tab === 'login' ? '登 录' : '创 建') }}</span>
          </button>
        </form>

        <p class="modal-foot" v-if="tab === 'signup'">
          注册即表示你同意本站的使用条款与隐私政策。
        </p>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref } from 'vue'
import { useAuth } from '../composables/useAuth'

defineProps({ open: Boolean })
const emit = defineEmits(['close'])

const { login, signUp } = useAuth()

const tab = ref('login')
const nickname = ref('')
const email = ref('')
const password = ref('')
const showPass = ref(false)
const msg = ref('')
const msgType = ref('error')
const loading = ref(false)

function switchTab(t) {
  tab.value = t
  msg.value = ''
}

async function submit() {
  msg.value = ''
  loading.value = true
  let res
  if (tab.value === 'login') {
    res = await login(email.value, password.value)
    if (!res.error) {
      email.value = ''
      password.value = ''
      window.dispatchEvent(new Event('auth:logged-in'))
      emit('close')
    }
  } else {
    res = await signUp(email.value, password.value, nickname.value)
    if (!res.error) {
      // 未开启邮箱验证时 Supabase 会直接返回 session（自动登录）
      if (res.session) {
        email.value = ''
        password.value = ''
        nickname.value = ''
        window.dispatchEvent(new Event('auth:logged-in'))
        emit('close')
      } else {
        msgType.value = 'success'
        msg.value = '注册成功！请前往邮箱完成验证后登录。'
        tab.value = 'login'
        email.value = ''
        password.value = ''
      }
    }
  }
  loading.value = false
  if (res.error) {
    msgType.value = 'error'
    msg.value = res.error.message
  }
}
</script>
