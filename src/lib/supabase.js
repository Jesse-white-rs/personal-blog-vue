import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

// 仅在提供了 URL + anon key 时才初始化；否则前端退回本地兜底数据
export const supabase = url && anonKey ? createClient(url, anonKey) : null
