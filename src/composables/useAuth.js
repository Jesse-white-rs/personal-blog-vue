import { ref } from 'vue'
import { supabase } from '../lib/supabase'

// 模块级单例：整个应用共享同一份登录状态
const user = ref(null)
const isAdmin = ref(false)
const ready = ref(false)
let unsub = null

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
  await refreshAdmin()
  ready.value = true

  const { data: sub } = supabase.auth.onAuthStateChange(async (_event, session) => {
    user.value = session?.user ?? null
    if (user.value) await refreshAdmin()
    else isAdmin.value = false
  })
  unsub = sub
}

async function login(email, password) {
  if (!supabase) return { error: { message: '未配置 Supabase' } }
  const { error } = await supabase.auth.signInWithPassword({ email, password })
  return { error }
}

async function signUp(email, password) {
  if (!supabase) return { error: { message: '未配置 Supabase' } }
  const { error } = await supabase.auth.signUp({ email, password })
  return { error }
}

async function logout() {
  if (!supabase) return
  await supabase.auth.signOut()
}

export function useAuth() {
  return { user, isAdmin, ready, init, login, signUp, logout }
}
