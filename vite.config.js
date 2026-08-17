import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// GitHub Pages 部署在子路径 /personal-blog-vue/ 下，base 必须与之对应
export default defineConfig({
  plugins: [vue()],
  base: '/personal-blog-vue/'
})
