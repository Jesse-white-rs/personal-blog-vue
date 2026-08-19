import { supabase } from './supabase'

export const MEDIA_BUCKET = 'media'

// 校验图片：类型 + 大小
export function validateImage(file, { maxMB = 5 } = {}) {
  if (!file) return '未选择文件'
  if (!file.type || !file.type.startsWith('image/')) return '仅支持图片文件'
  if (file.size > maxMB * 1024 * 1024) return `图片不能超过 ${maxMB}MB`
  return null
}

// 上传到 media 桶，返回 { url, error }
export async function uploadImage(file, folder = 'post-images', { maxMB = 5 } = {}) {
  if (!supabase) return { url: null, error: '未配置 Supabase，无法上传' }
  const err = validateImage(file, { maxMB })
  if (err) return { url: null, error: err }
  const ext = (file.name.split('.').pop() || 'png').toLowerCase().replace(/[^a-z0-9]/g, '')
  const path = `${folder}/${crypto.randomUUID()}.${ext}`
  const { error } = await supabase.storage.from(MEDIA_BUCKET).upload(path, file, {
    cacheControl: '3600',
    upsert: false,
    contentType: file.type
  })
  if (error) return { url: null, error: error.message || '上传失败' }
  const { data } = supabase.storage.from(MEDIA_BUCKET).getPublicUrl(path)
  return { url: data.publicUrl, error: null }
}
