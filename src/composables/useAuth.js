import { ref } from 'vue'
import { supabase } from '../lib/supabase'

// 模块级单例：整个应用共享同一份登录状态
const user = ref(null)
const profile = ref(null)
const isAdmin = ref(false)
const ready = ref(false)
let unsub = null

async function refreshProfile() {
  if (!supabase || !user.value) {
    profile.value = null
    return
  }
  const { data } = await supabase
    .from('profiles')
    .select('id, email, nickname, avatar_url, bio, is_admin')
    .eq('id', user.value.id)
    .maybeSingle()
  profile.value = data || null
  isAdmin.value = !!data?.is_admin
}

async function refreshAdmin() {
  if (!supabase || !user.value) {
    isAdmin.value = false
    return
  }
  const { data } = await supabase
    .from('profiles')
    .select('is_admin')
    .eq('id', user.value.id)
    .maybeSingle()
  isAdmin.value = !!data?.is_admin
}

async function init() {
  if (!supabase) {
    ready.value = true
    return
  }
  const { data } = await supabase.auth.getUser()
  user.value = data.user || null
  await refreshProfile()
  ready.value = true

  const { data: sub } = supabase.auth.onAuthStateChange(async (_event, session) => {
    user.value = session?.user ?? null
    if (user.value) await refreshProfile()
    else {
      profile.value = null
      isAdmin.value = false
    }
  })
  unsub = sub
}

async function login(email, password) {
  if (!supabase) return { error: { message: '未配置 Supabase' } }
  const { error } = await supabase.auth.signInWithPassword({ email, password })
  if (!error) await refreshProfile()
  return { error }
}

// 注册：可选昵称，注册成功后自动初始化 profiles 资料行
async function signUp(email, password, nickname) {
  if (!supabase) return { error: { message: '未配置 Supabase' }, session: null }
  const { data, error } = await supabase.auth.signUp({ email, password })
  if (error) return { error, session: null }

  // 立即写入资料（触发器未配置时也能兜底）
  const uid = data.user?.id || user.value?.id
  if (uid) {
    await supabase
      .from('profiles')
      .upsert({ id: uid, email, nickname: nickname || null, is_admin: false })
  }
  await refreshProfile()
  return { error: null, session: data.session || null }
}

// 更新当前用户资料（昵称 / 头像 / 简介）
async function updateProfile(patch) {
  if (!supabase || !user.value) return { error: { message: '请先登录' } }
  const { error } = await supabase
    .from('profiles')
    .update(patch)
    .eq('id', user.value.id)
  if (!error) await refreshProfile()
  return { error }
}

async function logout() {
  if (!supabase) return
  await supabase.auth.signOut()
}

export function useAuth() {
  return {
    user, profile, isAdmin, ready,
    init, login, signUp, logout, updateProfile
  }
}
