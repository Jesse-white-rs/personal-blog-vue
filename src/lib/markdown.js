import { marked } from 'marked'
import DOMPurify from 'dompurify'

marked.setOptions({ gfm: true, breaks: true })

// 将 Markdown 转为经过消毒的安全 HTML，杜绝 XSS
export function renderMarkdown(md = '') {
  if (!md) return ''
  return DOMPurify.sanitize(marked.parse(md), {
    ADD_ATTR: ['target', 'rel']
  })
}
