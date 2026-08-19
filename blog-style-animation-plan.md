# 个人博客 动效与样式增强 · 交付说明

> 2026-08-19 ｜ `f:/Desktop/personal-blog-vue` ｜ Vue 3 + Vite + Supabase

## 一、诊断结论（已更正）

首轮分析曾误判为"类名系统性错配"。复核全部组件后确认：`style.css` 的类名与组件**基本匹配**，样式系统（Vercel Geist 风格）本身是完整的。**真正的问题**：

1. **CSS 变量缺失**：`MarkdownEditor` / `ImageUploader` / `markdown-body` 引用了 `--brand-1`、`--brand-2`、`--card`、`--card-2`、`--mono`，但 `:root` 从未定义 → 编辑器、图片上传、文章正文的边框/配色/链接色全部失效。
2. **字体未引入**：`--font-sans: 'Geist'` 但 `index.html` 无 Google Fonts 链接 → 回退到系统字体，观感平庸。
3. **动效偏基础**：只有 `v-reveal` 滚动入场 + terminal 打字机，缺少首屏入场、氛围层、导航反馈、滚动进度、回到顶部等现代博客常见的动效体验。

## 二、已执行改动

| 文件 | 改动 |
|---|---|
| `index.html` | 引入 Geist / Geist Mono 字体（preconnect + stylesheet） |
| `src/style.css` | ① `:root` 与暗色主题补齐 `--brand-1/--brand-2/--card/--card-2/--mono` 别名；② 追加 v3 动效增强块（见下） |
| `src/main.js` | `v-reveal` 指令升级：支持 `v-reveal="'left'|'right'|'scale'"`、`v-reveal="{dir, delay}"`、数字延迟 |
| `src/components/SiteNav.vue` | 顶部滚动进度条（`scroll-progress`，随滚动更新 `--progress`） |
| `src/components/HeroSection.vue` | 移除首屏 `v-reveal`（改用 CSS 入场动画，消除首屏被 `opacity:0` 卡住的隐患） |
| `src/components/ArticlesSection.vue` | 文章项错峰入场 `{ dir:'up', delay:(i%3)*60 }` |
| `src/components/AboutSection.vue` | 左栏 `'left'` / 右栏 `'right'` 双向入场 |
| `src/components/ProjectsSection.vue` | 项目卡片错峰入场 `{ dir:'up', delay:(i%2)*90 }` |
| `src/App.vue` | 新增回到顶部按钮（滚动 >480px 浮现，平滑回顶），滚动监听挂载/卸载 |

## 三、v3 动效增强清单（style.css 追加块）

- **顶部滚动进度条**：渐变细条随阅读进度缩放（`scaleX(--progress)`）。
- **导航毛玻璃**：`backdrop-filter: blur(14px)` 半透明背景，滚动时内容透出；链接 hover 下划线从左滑入。
- **Hero 背景氛围**：双层径向渐变光晕缓慢漂移（`bgDrift` 16s 循环）。
- **首屏入场**：标题/副标题/简介/按钮/统计逐条上浮+模糊消散（`heroUp`，0.05~0.38s 错峰，不依赖 JS）。
- **名字光泽**：`<span class="accent">` 渐变流动文字（`sheen`），`@supports` 保护降级。
- **统计数字**：hover 轻微上浮。
- **reveal 变体**：`reveal-left/right/scale` 新增，配合升级后的指令实现左右/缩放入场。
- **项目卡片**：hover 顶部光晕渐显（`radial-gradient` 过渡）。
- **文章卡片**：hover 标题右移 4px 微反馈。
- **回到顶部**：圆形按钮悬浮右下角，hover 变 accent 色。
- **eyebrow 装饰**：区块小标题前加 accent 短线。
- **可访问性**：`prefers-reduced-motion` 下全部动画/过渡关闭，内容立即可见，防止 `reveal` 卡死。

## 四、验证

- `npm run build` ✅ 构建通过（77 modules，1.82s）
- `npm run dev -- --port 5173` ✅ dev server 运行中
- IDE 内置浏览器预览已打开：http://localhost:5173
- Lint 检查 0 错误

## 五、建议的后续打磨（本次未做，供参考）

- 文章正文图片懒加载 + 淡入
- 文章区切换分类时列表过渡动画（`<TransitionGroup>`）
- 更多自定义 CSS 变量命名收敛（`--brand-*` 别名后续可合并回 `--accent` 体系）
