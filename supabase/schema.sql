-- ============================================================
--  RWG 博客 —— Supabase 数据结构
--  在 Supabase 后台 SQL Editor 中执行本文件即可。
-- ============================================================

-- 个人资料（单行）
create table if not exists profile (
  id int primary key default 1,
  name text not null,
  tagline text,
  bio text,
  lead text,
  paragraphs jsonb default '[]'::jsonb,
  terminal_lines jsonb default '[]'::jsonb,
  updated_at timestamptz default now()
);

-- 兼容已存在旧表：补齐终端窗口内容字段（重复执行安全）
alter table profile add column if not exists terminal_lines jsonb default '[]'::jsonb;

-- 文章
create table if not exists posts (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  excerpt text,
  category text,
  date text,
  slug text,
  content text,
  status text not null default 'published',   -- published | draft
  cover_url text,
  tags text[] default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 兼容已存在旧表：补齐后台管理所需字段（重复执行安全）
alter table posts add column if not exists status text not null default 'published';
alter table posts add column if not exists cover_url text;
alter table posts add column if not exists tags text[] default '{}';
alter table posts add column if not exists updated_at timestamptz default now();
alter table posts add column if not exists views int not null default 0;
alter table posts add column if not exists likes int not null default 0;

-- 项目
create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text,
  langs text[] default '{}',
  link text,
  created_at timestamptz default now()
);

-- 技能
create table if not exists skills (
  id serial primary key,
  name text not null
);

-- 工具
create table if not exists tools (
  id serial primary key,
  name text not null
);

-- 现在
create table if not exists now_items (
  id uuid primary key default gen_random_uuid(),
  date text,
  text text,
  created_at timestamptz default now()
);

-- 行级安全：公开只读（博客内容对外可见，不允许匿名写入）
alter table profile   enable row level security;
alter table posts     enable row level security;
alter table projects  enable row level security;
alter table skills    enable row level security;
alter table tools     enable row level security;
alter table now_items enable row level security;

-- 认证用户档案（与 auth.users 一一对应）
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  nickname text,
  avatar_url text,
  bio text,
  is_admin boolean not null default false,
  created_at timestamptz default now()
);

-- 兼容旧表：补齐资料字段（重复执行安全）
alter table profiles add column if not exists nickname text;
alter table profiles add column if not exists avatar_url text;
alter table profiles add column if not exists bio text;

-- 公开资料视图：评论等场景需要展示作者昵称/头像，
-- 但 profiles 表受 RLS 保护（仅本人可读），故用视图暴露公开字段
drop view if exists public_profiles;
create view public_profiles as
  select id, nickname, avatar_url
  from profiles;
grant select on public_profiles to anon, authenticated;

-- 文章评论
create table if not exists comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null check (char_length(content) between 1 and 500),
  created_at timestamptz default now()
);

create index if not exists idx_comments_post_id on comments(post_id);

alter table comments enable row level security;

-- 管理员身份判断（SECURITY DEFINER 绕过 profiles 自身的 RLS，避免递归）
-- 注意：必须在 profiles 表创建之后再执行（SQL 语言函数创建时即校验表是否存在）
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (select 1 from profiles where id = auth.uid() and is_admin = true);
$$;

-- 新用户注册时自动建档案
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email) values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

alter table profiles enable row level security;

-- 公开可读：站点简介 / 已发布文章 / 项目 / 技能 / 工具 / 现在
drop policy if exists "public read profile" on profile;
drop policy if exists "public read published posts" on posts;
drop policy if exists "public read projects" on projects;
drop policy if exists "public read skills" on skills;
drop policy if exists "public read tools" on tools;
drop policy if exists "public read now_items" on now_items;
create policy "public read profile"   on profile   for select using (true);
create policy "public read published posts" on posts for select using (status = 'published' or status is null);
create policy "public read projects"  on projects  for select using (true);
create policy "public read skills"    on skills    for select using (true);
create policy "public read tools"     on tools     for select using (true);
create policy "public read now_items" on now_items for select using (true);

-- 登录用户可读自己的档案；管理员可读全部
drop policy if exists "self or admin read profiles" on profiles;
create policy "self or admin read profiles" on profiles
  for select using (auth.uid() = id or public.is_admin());

-- 登录用户可更新自己的资料（昵称 / 头像 / 简介）
drop policy if exists "self update own profile" on profiles;
create policy "self update own profile" on profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- 登录用户可写入自己的档案行（注册时自动创建，触发器缺失时兜底）
drop policy if exists "self insert own profile" on profiles;
create policy "self insert own profile" on profiles
  for insert with check (auth.uid() = id);

-- 评论：任何人可读，登录用户可发表，只能删除自己的评论
drop policy if exists "public read comments" on comments;
drop policy if exists "auth insert comments" on comments;
drop policy if exists "self delete comments" on comments;
create policy "public read comments" on comments
  for select using (true);
create policy "auth insert comments" on comments
  for insert with check (auth.uid() = user_id);
create policy "self delete comments" on comments
  for delete using (auth.uid() = user_id);

-- 点赞记录：复合主键保证同一用户对同一文章只能点一次
create table if not exists post_likes (
  user_id uuid not null references auth.users(id) on delete cascade,
  post_id uuid not null references posts(id) on delete cascade,
  created_at timestamptz default now(),
  primary key (user_id, post_id)
);

create index if not exists idx_post_likes_post_id on post_likes(post_id);

alter table post_likes enable row level security;

-- 公开可读（用于前端判断"我是否赞过"）
drop policy if exists "public read post_likes" on post_likes;
create policy "public read post_likes" on post_likes
  for select using (true);

-- 阅读数 +1：任何人可调用（打开文章详情时触发）
create or replace function public.increment_views(post_id uuid)
returns void
language sql
security definer
set search_path = public
set row_security = off
as $$
  update posts set views = views + 1 where id = post_id;
$$;

grant execute on function public.increment_views(uuid) to anon, authenticated;

-- 切换点赞：登录用户调用，返回 (liked 是否已赞, likes 最新点赞数)
create or replace function public.toggle_like(post_id uuid)
returns table (liked boolean, likes bigint)
language plpgsql
security definer
set search_path = public
set row_security = off
as $$
declare
  uid uuid := auth.uid();
  now_liked boolean;
begin
  if uid is null then
    return query select false::boolean, 0::bigint;
    return;
  end if;

  if exists (select 1 from post_likes where user_id = uid and post_id = toggle_like.post_id) then
    delete from post_likes where user_id = uid and post_id = toggle_like.post_id;
    update posts set likes = greatest(likes - 1, 0) where id = toggle_like.post_id;
    now_liked := false;
  else
    insert into post_likes (user_id, post_id) values (uid, toggle_like.post_id)
    on conflict do nothing;
    update posts set likes = likes + 1 where id = toggle_like.post_id;
    now_liked := true;
  end if;

  return query select now_liked, (select likes from posts where id = toggle_like.post_id);
end;
$$;

grant execute on function public.toggle_like(uuid) to authenticated;

-- 批量统计评论数：首页文章列表显示"评论数"用
create or replace function public.get_comment_counts(post_ids uuid[])
returns table (post_id uuid, total bigint)
language sql
security definer
set search_path = public
as $$
  select c.post_id, count(*)::bigint as total
  from comments c
  where c.post_id = any(post_ids)
  group by c.post_id;
$$;

grant execute on function public.get_comment_counts(uuid[]) to anon, authenticated;

-- 仅管理员可写文章与档案（插入/更新/删除）
drop policy if exists "admin manage posts" on posts;
drop policy if exists "admin manage profiles" on profiles;
drop policy if exists "admin manage profile" on profile;
drop policy if exists "admin manage projects" on projects;
drop policy if exists "admin manage skills" on skills;
drop policy if exists "admin manage tools" on tools;
drop policy if exists "admin manage now_items" on now_items;
create policy "admin manage posts"    on posts    for all
  using (public.is_admin()) with check (public.is_admin());
create policy "admin manage profiles" on profiles for all
  using (public.is_admin()) with check (public.is_admin());
-- 注意：profile 是"站点资料"表（单行），profiles 是"用户档案"表。
-- 站点资料必须单独授权管理员写权限，否则保存会被 RLS 静默拒绝。
create policy "admin manage profile" on profile for all
  using (public.is_admin()) with check (public.is_admin());
-- 项目 / 技能 / 工具 / 现在：后台「项目管理 / 关于 / 现在」需要管理员写权限
create policy "admin manage projects" on projects for all
  using (public.is_admin()) with check (public.is_admin());
create policy "admin manage skills" on skills for all
  using (public.is_admin()) with check (public.is_admin());
create policy "admin manage tools" on tools for all
  using (public.is_admin()) with check (public.is_admin());
create policy "admin manage now_items" on now_items for all
  using (public.is_admin()) with check (public.is_admin());

-- 设为管理员：注册账号后，把下面邮箱替换成你自己的，执行一次即可
-- update profiles set is_admin = true where email = 'you@example.com';

-- 种子数据（首次运行后可按需修改 / 删除）
insert into profile (id, name, tagline, bio, lead, paragraphs, terminal_lines)
values (
  1,
  'RWG',
  '写代码，也写生活。',
  '一个写代码的人，也记录生活里的琐碎与思考。',
  '我是一名后端工程师，平时主要和 Java、Spring Boot、数据库打交道，偶尔也写点前端。',
  '["过去几年，我参与过几个从零到一的系统建设，踩过不少坑，也攒下一些还算有用的经验。这个博客是我把这些东西整理出来的地方。","比起追求完美的架构，我更在意一件事能不能先跑起来，再慢慢变好。写作也是一样：先写，再改。"]'::jsonb,
  '["git commit -m \\"第 24 篇文章\\"","cd ~/ideas && vim new-post.md","npm run build && ship it"]'::jsonb
)
on conflict (id) do nothing;

insert into posts (title, excerpt, category, date) values
  ('从零搭一个 GitHub Pages 博客，比你想的简单','没有服务器，不用备案。一个仓库、一份工作流，静态博客就这样上线了。这篇把步骤拆开讲清楚。','前端','2026-08-10'),
  ('Java 8 到 17：值得换的新特性，我踩过的坑','升级不是换一行依赖版本号。record、switch 表达式、虚拟线程……哪些真的能用，哪些只是看起来美好。','后端','2026-07-28'),
  ('Vue 3 组合式 API：为什么我放弃了 Options','当业务逻辑长到几百行，分散在各处的问题会集中爆发。分享一次真实的迁移经历和我的取舍。','前端','2026-07-15'),
  ('一条慢查询引发的索引优化复盘','从慢查询日志到执行计划，再到最终的索引设计。一次生产事故的完整记录，希望你能少走这段路。','运维','2026-06-30'),
  ('写博客第三年，我换了三种工具','关于写作工具、内容组织和坚持更新的碎碎念。工具会变，记录的习惯值得保留。','随笔','2026-06-18'),
  ('Spring Boot 接口设计的几个小习惯','统一返回结构、参数校验、异常处理、文档自动化。这些习惯让接口在两年后依然好维护。','后端','2026-06-05');

insert into projects (name, description, langs, link) values
  ('ERP 管理系统','基于 Spring Boot + Vue 的外贸 ERP，覆盖采购、销售、财务、报表等核心业务域，支撑日常业务流转。',array['Java','Vue','MySQL','Redis'],'#projects'),
  ('数据可视化看板','轻量 BI 平台，拖拽配置图表、多数据源接入、实时大屏展示。目前是自己团队在用的内部工具。',array['TypeScript','ECharts','Node.js'],'#projects'),
  ('本站（personal-blog）','Vue 3 + Vite + Supabase 搭建的无服务器博客，推送到 GitHub 即自动部署。',array['Vue','Vite','Supabase'],'https://jesse-white-rs.github.io/personal-blog/'),
  ('自动化部署工具链','基于 GitHub Actions 的 CI/CD 工具，代码推送后自动构建、测试并发布到 Pages。',array['Shell','YAML','GitHub Actions'],'#projects');

insert into skills (name) values
  ('JavaScript'),('TypeScript'),('Vue 3'),('Java'),('Spring Boot'),('MySQL'),('Redis'),('Docker'),('Git'),('Nginx');

insert into tools (name) values
  ('VS Code'),('GitKraken'),('Navicat'),('Postman'),('DBeaver'),('Raycast'),('Warp'),('Figma');

insert into now_items (date, text) values
  ('进行中','参与公司 ERP 系统二期开发，负责报表模块的接口设计与性能优化。'),
  ('阅读','在读《设计数据密集型应用》，边读边把书里的思想落到现有项目的架构思考里。'),
  ('折腾','把博客从纯静态迁到 Vue 3 + Supabase，理由只有一个：写东西不该先配置框架。'),
  ('计划','准备整理一份《从零做 ERP》系列，把三年里踩过的坑按主题归档。');

-- ============================================================
-- 媒体存储桶（头像 / 文章图片 / 封面）
-- 说明：在 Supabase SQL Editor 中执行一次即可创建 bucket 与访问策略。
--       桶设为 public，任何人可读；仅登录用户可上传，且只能管理自己上传的文件。
-- ============================================================
insert into storage.buckets (id, name, public)
values ('media', 'media', true)
on conflict (id) do nothing;

-- 任何人可读媒体（公开访问）
drop policy if exists "media public read" on storage.objects;
create policy "media public read" on storage.objects
  for select using (bucket_id = 'media');

-- 登录用户可上传到 media 桶
drop policy if exists "media auth insert" on storage.objects;
create policy "media auth insert" on storage.objects
  for insert to authenticated with check (bucket_id = 'media');

-- 用户仅能更新 / 删除自己上传的对象（owner = 上传者的 auth.uid）
drop policy if exists "media owner update" on storage.objects;
create policy "media owner update" on storage.objects
  for update to authenticated
  using (bucket_id = 'media' and owner = auth.uid())
  with check (bucket_id = 'media' and owner = auth.uid());

drop policy if exists "media owner delete" on storage.objects;
create policy "media owner delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'media' and owner = auth.uid());
