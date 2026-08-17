import { createApp } from 'vue'
import App from './App.vue'
import './style.css'

const app = createApp(App)

// 滚动进入时淡入（替代原 script.js 的 IntersectionObserver）
app.directive('reveal', {
  mounted(el) {
    el.classList.add('reveal')
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
