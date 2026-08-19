import { createApp } from 'vue'
import App from './App.vue'
import './style.css'

const app = createApp(App)

// 滚动进入时淡入（替代原 script.js 的 IntersectionObserver）
app.directive('reveal', {
  mounted(el, binding) {
    // 支持 v-reveal / v-reveal="'left'|'right'|'scale'" / v-reveal="{ dir, delay }" / v-reveal="数字延迟(ms)"
    const v = binding.value
    let dir = 'up'
    let delay = 0
    if (typeof v === 'string') dir = v
    else if (typeof v === 'number') delay = v
    else if (v && typeof v === 'object') {
      dir = v.dir || 'up'
      delay = v.delay || 0
    }
    el.classList.add('reveal')
    if (dir !== 'up') el.classList.add('reveal-' + dir)
    if (delay) el.style.transitionDelay = delay + 'ms'
    const io = new IntersectionObserver(
      (entries) => {
        entries.forEach((e) => {
          if (e.isIntersecting) {
            el.classList.add('visible')
            io.unobserve(el)
          }
        })
      },
      { threshold: 0.12 }
    )
    io.observe(el)
  }
})

app.mount('#app')
