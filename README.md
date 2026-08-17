# RWG 的个人博客（Vue 3 + Supabase）

无服务器个人博客技术栈：

```
Vue 3 + Vite  (前端，纯静态)
   ↓  GitHub Pages (托管 / 自动部署)
   ↓  Supabase (后端即服务)
   ↓  PostgreSQL (数据库)
```

## 本地开发

```bash
npm install
cp .env.example .env   # 填入你的 Supabase URL 与 anon key
npm run dev
```

未配置 Supabase 时，站点会使用 `src/data/fallback.js` 里的兜底数据，依然能正常显示。

## 数据库

在 Supabase 后台的 **SQL Editor** 中执行 `supabase/schema.sql`，会创建 6 张表
（`profile` / `posts` / `projects` / `skills` / `tools` / `now_items`）、开启公开只读的
行级安全策略（RLS），并写入种子数据。

前端通过 anon key 只读这些表；写操作请在 Supabase 后台完成。

## 部署

推送到 `main` 分支后，GitHub Actions 会自动 `npm run build` 并部署到 GitHub Pages。
构建所需的 `VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY` 取自仓库 Secrets。
