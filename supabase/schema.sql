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
  updated_at timestamptz default now()
);

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

-- 项目
create table if not exists projects (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  desc text,
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

-- 管理员身份判断（SECURITY DEFINER 绕过 profiles 自身的 RLS，避免递归）
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (select 1 from profiles where id = auth.uid() and is_admin = true);
$$;

-- 认证用户档案（与 auth.users 一一对应）
create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  is_admin boolean not null default false,
  created_at timestamptz default now()
);

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
create policy "public read profile"   on profile   for select using (true);
create policy "public read published posts" on posts for select using (status = 'published' or status is null);
create policy "public read projects"  on projects  for select using (true);
create policy "public read skills"    on skills    for select using (true);
create policy "public read tools"     on tools     for select using (true);
create policy "public read now_items" on now_items for select using (true);

-- 登录用户可读自己的档案；管理员可读全部
create policy "self or admin read profiles" on profiles
  for select using (auth.uid() = id or public.is_admin());

-- 仅管理员可写文章与档案（插入/更新/删除）
create policy "admin manage posts"    on posts    for all
  using (public.is_admin()) with check (public.is_admin());
create policy "admin manage profiles" on profiles for all
  using (public.is_admin()) with check (public.is_admin());

-- 设为管理员：注册账号后，把下面邮箱替换成你自己的，执行一次即可
-- update profiles set is_admin = true where email = 'you@example.com';

-- 种子数据（首次运行后可按需修改 / 删除）
insert into profile (id, name, tagline, bio, lead, paragraphs)
values (
  1,
  'RWG',
  '写代码，也写生活。',
  '一个写代码的人，也记录生活里的琐碎与思考。',
  '我是一名后端工程师，平时主要和 Java、Spring Boot、数据库打交道，偶尔也写点前端。',
  '["过去几年，我参与过几个从零到一的系统建设，踩过不少坑，也攒下一些还算有用的经验。这个博客是我把这些东西整理出来的地方。","比起追求完美的架构，我更在意一件事能不能先跑起来，再慢慢变好。写作也是一样：先写，再改。"]'::jsonb
)
on conflict (id) do nothing;

insert into posts (title, excerpt, category, date) values
  ('从零搭一个 GitHub Pages 博客，比你想的简单','没有服务器，不用备案。一个仓库、一份工作流，静态博客就这样上线了。这篇把步骤拆开讲清楚。','前端','2026-08-10'),
  ('Java 8 到 17：值得换的新特性，我踩过的坑','升级不是换一行依赖版本号。record、switch 表达式、虚拟线程……哪些真的能用，哪些只是看起来美好。','后端','2026-07-28'),
  ('Vue 3 组合式 API：为什么我放弃了 Options','当业务逻辑长到几百行，分散在各处的问题会集中爆发。分享一次真实的迁移经历和我的取舍。','前端','2026-07-15'),
  ('一条慢查询引发的索引优化复盘','从慢查询日志到执行计划，再到最终的索引设计。一次生产事故的完整记录，希望你能少走这段路。','运维','2026-06-30'),
  ('写博客第三年，我换了三种工具','关于写作工具、内容组织和坚持更新的碎碎念。工具会变，记录的习惯值得保留。','随笔','2026-06-18'),
  ('Spring Boot 接口设计的几个小习惯','统一返回结构、参数校验、异常处理、文档自动化。这些习惯让接口在两年后依然好维护。','后端','2026-06-05');

insert into projects (name, desc, langs, link) values
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
