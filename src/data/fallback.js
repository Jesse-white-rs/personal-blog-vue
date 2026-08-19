// 本地兜底数据：未配置 Supabase 或读取失败时，站点照常显示这些内容。
// 字段与 supabase/schema.sql 中的表结构保持一致。

export const profile = {
  name: 'Jesse.se',
  tagline: '写代码，也写生活。',
  bio: '一个写代码的人，也记录生活里的琐碎与思考。',
  lead: '我是一名后端工程师，平时主要和 Java、Spring Boot、数据库打交道，偶尔也写点前端。',
  paragraphs: [
    '过去几年，我参与过几个从零到一的系统建设，踩过不少坑，也攒下一些还算有用的经验。这个博客是我把这些东西整理出来的地方。',
    '比起追求完美的架构，我更在意一件事能不能先跑起来，再慢慢变好。写作也是一样：先写，再改。'
  ],
  // 首页终端窗口逐行显示的命令（后台「站点设置」可修改，保存在 Supabase profile 表）
  terminal_lines: [
    'git commit -m "第 24 篇文章"',
    'cd ~/ideas && vim new-post.md',
    'npm run build && ship it'
  ]
}

export const articles = [
  {
    id: 'fb-01',
    title: '从零搭一个 GitHub Pages 博客，比你想的简单',
    category: '前端',
    date: '2026-08-10',
    excerpt: '没有服务器，不用备案。一个仓库、一份工作流，静态博客就这样上线了。这篇把步骤拆开讲清楚。',
    content: '没有服务器，不用备案。一个仓库、一份工作流，静态博客就这样上线了。\n\n这篇把步骤拆开讲清楚：\n\n- 创建仓库并开启 Pages\n- 配置构建工作流\n- 绑定自己的域名\n\n写东西不该先配置框架。'
  },
  {
    id: 'fb-02',
    title: 'Java 8 到 17：值得换的新特性，我踩过的坑',
    category: '后端',
    date: '2026-07-28',
    excerpt: '升级不是换一行依赖版本号。record、switch 表达式、虚拟线程……哪些真的能用，哪些只是看起来美好。',
    content: '升级不是换一行依赖版本号。\n\nrecord、switch 表达式、虚拟线程……哪些真的能用，哪些只是看起来美好。\n\n建议先从小模块试点，再逐步推进。'
  },
  {
    id: 'fb-03',
    title: 'Vue 3 组合式 API：为什么我放弃了 Options',
    category: '前端',
    date: '2026-07-15',
    excerpt: '当业务逻辑长到几百行，分散在各处的问题会集中爆发。分享一次真实的迁移经历和我的取舍。',
    content: '当业务逻辑长到几百行，分散在各处的问题会集中爆发。\n\n分享一次真实的迁移经历和我的取舍：组合式 API 更适合逻辑复用与组织，配合 hooks 可以让代码更清爽。'
  },
  {
    id: 'fb-04',
    title: '一条慢查询引发的索引优化复盘',
    category: '运维',
    date: '2026-06-30',
    excerpt: '从慢查询日志到执行计划，再到最终的索引设计。一次生产事故的完整记录，希望你能少走这段路。',
    content: '从慢查询日志到执行计划，再到最终的索引设计。\n\n一次生产事故的完整记录，希望你能少走这段路。'
  },
  {
    id: 'fb-05',
    title: '写博客第三年，我换了三种工具',
    category: '随笔',
    date: '2026-06-18',
    excerpt: '关于写作工具、内容组织和坚持更新的碎碎念。工具会变，记录的习惯值得保留。',
    content: '关于写作工具、内容组织和坚持更新的碎碎念。\n\n工具会变，记录的习惯值得保留。'
  },
  {
    id: 'fb-06',
    title: 'Spring Boot 接口设计的几个小习惯',
    category: '后端',
    date: '2026-06-05',
    excerpt: '统一返回结构、参数校验、异常处理、文档自动化。这些习惯让接口在两年后依然好维护。',
    content: '统一返回结构、参数校验、异常处理、文档自动化。\n\n这些习惯让接口在两年后依然好维护。'
  }
]

export const projects = [
  {
    name: 'ERP 管理系统',
    description: '基于 Spring Boot + Vue 的外贸 ERP，覆盖采购、销售、财务、报表等核心业务域，支撑日常业务流转。',
    langs: ['Java', 'Vue', 'MySQL', 'Redis'],
    link: '#projects'
  },
  {
    name: '数据可视化看板',
    description: '轻量 BI 平台，拖拽配置图表、多数据源接入、实时大屏展示。目前是自己团队在用的内部工具。',
    langs: ['TypeScript', 'ECharts', 'Node.js'],
    link: '#projects'
  },
  {
    name: '本站（personal-blog）',
    description: 'Vue 3 + Vite + Supabase 搭建的无服务器博客，推送到 GitHub 即自动部署。',
    langs: ['Vue', 'Vite', 'Supabase'],
    link: 'https://jesse-white-rs.github.io/personal-blog/'
  },
  {
    name: '自动化部署工具链',
    description: '基于 GitHub Actions 的 CI/CD 工具，代码推送后自动构建、测试并发布到 Pages。',
    langs: ['Shell', 'YAML', 'GitHub Actions'],
    link: '#projects'
  }
]

export const skills = [
  'JavaScript', 'TypeScript', 'Vue 3', 'Java', 'Spring Boot',
  'MySQL', 'Redis', 'Docker', 'Git', 'Nginx'
]

export const tools = ['VS Code', 'GitKraken', 'Navicat', 'Postman', 'DBeaver', 'Raycast', 'Warp', 'Figma']

export const nowItems = [
  { date: '进行中', text: '参与公司 ERP 系统二期开发，负责报表模块的接口设计与性能优化。' },
  { date: '阅读', text: '在读《设计数据密集型应用》，边读边把书里的思想落到现有项目的架构思考里。' },
  { date: '折腾', text: '把博客从纯静态迁到 Vue 3 + Supabase，理由只有一个：写东西不该先配置框架。' },
  { date: '计划', text: '准备整理一份《从零做 ERP》系列，把三年里踩过的坑按主题归档。' }
]
