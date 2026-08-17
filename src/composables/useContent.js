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
        articles.value = posts.data
          .filter((p) => p.status === 'published' || p.status == null)
          .map((p) => ({
            id: p.id,
            title: p.title,
            excerpt: p.excerpt,
            category: p.category,
            date: p.date,
            slug: p.slug,
            content: p.content,
            tags: p.tags || [],
            cover_url: p.cover_url
          }))
      }
      if (proj.data?.length) {
        projects.value = proj.data.map((p) => ({
          name: p.name, description: p.description, langs: p.langs || [], link: p.link
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

  // ---------- 评论 ----------

  // 获取某篇文章的评论（带作者昵称/头像）
  async function getComments(postId) {
    if (!supabase || !postId) return []
    const { data, error } = await supabase
      .from('comments')
      .select('id, content, created_at, user_id')
      .eq('post_id', postId)
      .order('created_at', { ascending: true })
    if (error) {
      console.warn('[comments] 读取失败', error)
      return []
    }
    // 批量取作者公开资料（public_profiles 视图不受 profiles 的 RLS 限制）
    const uids = [...new Set((data || []).map((c) => c.user_id))]
    const authors = {}
    if (uids.length) {
      const { data: pf } = await supabase
        .from('public_profiles')
        .select('id, nickname, avatar_url')
        .in('id', uids)
      ;(pf || []).forEach((p) => { authors[p.id] = p })
    }
    return (data || []).map((c) => ({
      id: c.id,
      content: c.content,
      created_at: c.created_at,
      user_id: c.user_id,
      nickname: authors[c.user_id]?.nickname,
      avatar_url: authors[c.user_id]?.avatar_url
    }))
  }

  // 发表评论
  async function addComment(postId, content, userId) {
    if (!supabase) return { error: { message: '未配置 Supabase' } }
    const { error } = await supabase
      .from('comments')
      .insert({ post_id: postId, content, user_id: userId })
    return { error }
  }

  // 删除评论（仅自己可删）
  async function deleteComment(id) {
    if (!supabase) return { error: { message: '未配置 Supabase' } }
    const { error } = await supabase
      .from('comments')
      .delete()
      .eq('id', id)
    return { error }
  }

  return {
    articles, projects, skills, tools, nowItems, profile, loading, source, load,
    getComments, addComment, deleteComment
  }
}
