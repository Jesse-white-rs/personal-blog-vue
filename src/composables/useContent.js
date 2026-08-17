import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import * as fallback from '../data/fallback'

// 统一内容入口：优先从 Supabase 读取，失败则用本地兜底数据。
export function useContent() {
  const articles = ref(fallback.articles)
  const projects = ref(fallback.projects)
  const skills = ref(fallback.skills)
  const tools = ref(fallback.tools)
  const nowItems = ref(fallback.nowItems)
  const profile = ref(fallback.profile)
  const loading = ref(true)
  const source = ref('fallback') // 'supabase' | 'fallback'

  async function load() {
    if (!supabase) {
      loading.value = false
      return
    }
    try {
      const [posts, proj, sk, tl, ni, prof] = await Promise.all([
        supabase.from('posts').select('*').order('date', { ascending: false }),
        supabase.from('projects').select('*').order('created_at', { ascending: false }),
        supabase.from('skills').select('*').order('id'),
        supabase.from('tools').select('*').order('id'),
        supabase.from('now_items').select('*').order('created_at', { ascending: false }),
        supabase.from('profile').select('*').limit(1).maybeSingle()
      ])

      if (posts.data?.length) {
        articles.value = posts.data.map((p) => ({
          title: p.title, excerpt: p.excerpt, category: p.category, date: p.date
        }))
      }
      if (proj.data?.length) {
        projects.value = proj.data.map((p) => ({
          name: p.name, desc: p.desc, langs: p.langs || [], link: p.link
        }))
      }
      if (sk.data?.length) skills.value = sk.data.map((s) => ({ name: s.name }))
      if (tl.data?.length) tools.value = tl.data.map((t) => ({ name: t.name }))
      if (ni.data?.length) {
        nowItems.value = ni.data.map((n) => ({ date: n.date, text: n.text }))
      }
      if (prof.data) profile.value = prof.data

      source.value = 'supabase'
    } catch (e) {
      console.warn('[content] Supabase 读取失败，使用本地兜底数据', e)
    } finally {
      loading.value = false
    }
  }

  return { articles, projects, skills, tools, nowItems, profile, loading, source, load }
}
