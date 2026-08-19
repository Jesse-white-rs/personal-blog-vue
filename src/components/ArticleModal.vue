<template>
  <transition name="modal">
    <div class="modal-mask" v-if="open" @click.self="close">
      <div class="modal modal-article" role="dialog" aria-modal="true">
        <button class="modal-close" @click="close" aria-label="关闭">
          <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M18 6L6 18M6 6l12 12"/></svg>
        </button>

        <article class="article">
          <div class="article-cover-lg" v-if="article.cover_url">
            <img :src="article.cover_url" :alt="article.title" referrerpolicy="no-referrer" />
          </div>
          <div class="article-head">
            <div class="article-meta">
              <span class="chip" v-if="article.category">{{ article.category }}</span>
              <time v-if="article.date">{{ article.date }}</time>
              <span class="stat-inline" v-if="viewCount !== null" title="阅读数">
                <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7z"/><circle cx="12" cy="12" r="3"/></svg>
                {{ fmt(viewCount) }}
              </span>
              <span class="stat-inline" title="评论数">
                <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
                {{ fmt(comments.length) }}
              </span>
            </div>
            <button class="like-btn" :class="{ liked }" :disabled="liking"
                    :title="user ? (liked ? '取消点赞' : '点赞') : '登录后点赞'"
                    @click="toggleLike">
              <svg v-if="liked" viewBox="0 0 24 24" width="15" height="15" fill="currentColor" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8z"/></svg>
              <svg v-else viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 0 0-7.8 7.8l1 1L12 21l7.8-7.6 1-1a5.5 5.5 0 0 0 0-7.8z"/></svg>
              <span>{{ fmt(likesCount) }}</span>
            </button>
          </div>
          <h2 class="article-title">{{ article.title }}</h2>
          <p class="article-excerpt" v-if="article.excerpt">{{ article.excerpt }}</p>
          <div class="article-body" v-if="article.content">
        <MarkdownView :source="article.content" />
      </div>
        </article>

        <!-- 评论区 -->
        <section class="comments">
          <div class="comments-head">
            <h3>评论 <span class="count" v-if="comments.length">{{ comments.length }}</span></h3>
          </div>

          <div v-if="!user" class="comments-login">
            <p>登录后即可参与评论。</p>
            <button class="btn btn-sm" @click="$emit('login')">去登录</button>
          </div>

          <form v-else class="comment-form" @submit.prevent="submitComment" novalidate>
            <div class="avatar avatar-sm">
              <img v-if="myAvatar" :src="myAvatar" :alt="myName" referrerpolicy="no-referrer" />
              <span v-else>{{ myInitial }}</span>
            </div>
            <div class="comment-input-wrap">
              <textarea v-model.trim="draft" rows="2" maxlength="500"
                        placeholder="写下你的想法…" @keydown.ctrl.enter="submitComment"></textarea>
              <div class="comment-actions">
                <span class="hint">{{ draft.length }}/500</span>
                <button class="btn btn-sm btn-primary" type="submit" :disabled="!draft || submitting">
                  <span v-if="submitting" class="spinner" aria-hidden="true"></span>
                  <span>{{ submitting ? '发送中…' : '发表评论' }}</span>
                </button>
              </div>
            </div>
          </form>

          <div v-if="loadingComments" class="comments-loading">
            <span class="spinner" aria-hidden="true"></span> 加载中…
          </div>

          <ul v-else-if="comments.length" class="comment-list">
            <li v-for="c in comments" :key="c.id" class="comment-item">
              <div class="avatar avatar-sm">
                <img v-if="c.avatar_url" :src="c.avatar_url" :alt="c.nickname || '访客'" referrerpolicy="no-referrer" />
                <span v-else>{{ (c.nickname || '客').charAt(0).toUpperCase() }}</span>
              </div>
              <div class="comment-body">
                <div class="comment-meta">
                  <span class="comment-author">{{ c.nickname || '匿名用户' }}</span>
                  <time>{{ formatTime(c.created_at) }}</time>
                  <button v-if="c.user_id === user?.id" class="comment-del" @click="removeComment(c)" aria-label="删除评论">
                    <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 6h18M8 6V4a2 2 0 012-2h4a2 2 0 012 2v2m3 0v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6h14z"/></svg>
                  </button>
                </div>
                <p class="comment-content">{{ c.content }}</p>
              </div>
            </li>
          </ul>

          <p v-else class="comments-empty">还没有评论，来说两句吧～</p>
        </section>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useAuth } from '../composables/useAuth'
import { useContent } from '../composables/useContent'
import MarkdownView from './MarkdownView.vue'

const props = defineProps({ open: Boolean, article: { type: Object, default: () => ({}) } })
const emit = defineEmits(['close', 'login', 'viewed', 'like-changed'])

const { user, profile } = useAuth()
const { getComments, addComment, deleteComment, incrementViews, toggleLike: toggleLikeApi, getLikedPostIds } = useContent()

const comments = ref([])
const draft = ref('')
const submitting = ref(false)
const loadingComments = ref(false)
const viewCount = ref(null)
const likesCount = ref(0)
const liked = ref(false)
const liking = ref(false)

const myName = computed(() => profile.value?.nickname || profile.value?.email || '我')
const myInitial = computed(() => (myName.value || '我').charAt(0).toUpperCase())
const myAvatar = computed(() => profile.value?.avatar_url)

// 同一篇文章在同一会话内只记一次阅读数，防止反复开关刷数
let lastViewedId = null

async function load() {
  if (!props.open || !props.article?.id) return
  comments.value = []
  loadingComments.value = true
  comments.value = await getComments(props.article.id)
  loadingComments.value = false

  // 阅读数：首次打开 +1
  if (lastViewedId !== props.article.id) {
    lastViewedId = props.article.id
    incrementViews(props.article.id)
    emit('viewed')
    viewCount.value = (props.article.views || 0) + 1
  } else {
    viewCount.value = props.article.views || 0
  }

  // 点赞状态
  likesCount.value = props.article.likes || 0
  liked.value = false
  if (user.value?.id) {
    const ids = await getLikedPostIds([props.article.id])
    liked.value = ids.includes(props.article.id)
  }
}

watch(() => [props.open, props.article?.id], load, { immediate: true })

function formatTime(iso) {
  if (!iso) return ''
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return iso
  const p = (n) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`
}

// 数字美化：1200 -> 1.2k，23000 -> 2.3w
function fmt(n) {
  n = Number(n) || 0
  if (n >= 10000) return (n / 10000).toFixed(1).replace(/\.0$/, '') + 'w'
  if (n >= 1000) return (n / 1000).toFixed(1).replace(/\.0$/, '') + 'k'
  return String(n)
}

async function submitComment() {
  if (!draft.value || submitting.value) return
  submitting.value = true
  const { error } = await addComment(props.article.id, draft.value, user.value.id)
  submitting.value = false
  if (error) return
  draft.value = ''
  comments.value = await getComments(props.article.id)
}

async function removeComment(c) {
  const { error } = await deleteComment(c.id)
  if (error) return
  comments.value = await getComments(props.article.id)
}

async function toggleLike() {
  if (!user.value) {
    emit('login')
    return
  }
  if (liking.value) return
  liking.value = true
  const res = await toggleLikeApi(props.article.id)
  liking.value = false
  if (res.error) return
  liked.value = res.liked
  likesCount.value = res.likes
  emit('like-changed', res.likes)
}

function close() {
  emit('close')
}
</script>
