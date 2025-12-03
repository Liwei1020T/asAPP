# ArtSport Management System (ASP-MS)

ASP-MS 是一个专为 Art Sport Penang 羽毛球学院打造的综合管理系统。该系统基于 Flutter Web (PWA) 构建，采用现代化的 Clean Architecture 架构，旨在为管理员、教练、家长和学员提供高效、流畅的管理与交互体验。

## 🌟 核心功能

系统围绕四大核心角色（管理员、教练、家长、学员）设计，涵盖以下主要模块：

*   **🔐 身份认证与权限管理**
    *   支持多角色登录（Admin, Coach, Parent, Student）。
    *   基于 Supabase Auth 的安全认证。
    *   基于角色的访问控制（RBAC）。

*   **📊 仪表板 (Dashboard)**
    *   **管理员**：全局数据概览、快捷操作入口。
    *   **教练**：今日课程、待办事项、收入概览。
    *   **家长/学员**：课程表、出勤记录、最新动态。

*   **📅 课程与出勤管理**
    *   **班级管理**：创建不同等级的班级（基础/进阶），设置时间、场地和默认教练。
    *   **排课系统**：自动生成课程 Session，支持临时调整。
    *   **实时点名**：教练端快速点名（出席/缺席/迟到/请假），支持添加评价与 AI 反馈。

*   **� 人员管理**
    *   **学员档案**：管理学员基本信息、剩余课时、家长关联。
    *   **教练档案**：管理教练信息、课时费率。

*   **💰 薪资与财务**
    *   **自动计算**：根据教练完成的课时和费率自动计算月度薪资。
    *   **薪资报表**：按月查看收入明细。

*   **📢 沟通与互动**
    *   **训练动态 (Timeline)**：类似社交媒体的动态流，教练发布训练照片/视频，家长点赞互动。
    *   **公告系统 (Notices)**：发布重要通知（放假安排、比赛信息），支持置顶和紧急标记。
    *   **训练手册 (Playbook)**：共享教学资料（视频/文档），支持分类管理。

## 🛠 技术栈

本项目采用 Flutter 生态中最前沿的技术组合：

*   **前端框架**: [Flutter](https://flutter.dev/) (Web / PWA)
*   **语言**: Dart 3.x
*   **状态管理**: [Riverpod 2.x/3.x](https://riverpod.dev/) (Generator语法)
*   **路由管理**: [GoRouter](https://pub.dev/packages/go_router)
*   **后端服务**: [Supabase](https://supabase.com/) (PostgreSQL + Auth + Storage + Realtime)
*   **UI 组件库**: Material 3 Design
*   **动画效果**: [flutter_animate](https://pub.dev/packages/flutter_animate)
*   **骨架屏**: [shimmer](https://pub.dev/packages/shimmer)
*   **工具库**:
    *   `intl`: 日期格式化与国际化
    *   `shared_preferences`: 本地配置存储
    *   `file_picker`: 文件上传

## 📂 项目结构

项目遵循 **Clean Architecture** 分层架构，确保代码的可维护性与可扩展性：

```
lib/
├── core/                   # 核心共享模块
│   ├── config/             # 全局配置 (Supabase等)
│   ├── constants/          # 常量 (颜色、间距、动画参数)
│   ├── router/             # 路由配置 (AppRouter)
│   ├── theme/              # 主题定义 (Light/Dark Mode)
│   ├── utils/              # 工具类 (日期处理、响应式工具)
│   └── widgets/            # 通用 UI 组件 (ASCard, ASButton等)
├── data/                   # 数据层
│   ├── models/             # 数据模型 (Dart Data Classes)
│   └── repositories/       # 数据仓库 (Supabase API 调用)
├── features/               # 业务功能模块
│   ├── auth/               # 认证 (登录/注册)
│   ├── dashboard/          # 各角色仪表板
│   ├── classes/            # 班级与课程
│   ├── attendance/         # 出勤点名
│   ├── students/           # 学员管理
│   ├── coaches/            # 教练管理
│   ├── salary/             # 薪资管理
│   ├── timeline/           # 训练动态
│   ├── playbook/           # 训练手册
│   └── notices/            # 公告通知
└── main.dart               # 应用入口
```

## 🚀 快速开始

### 1. 环境准备

*   Flutter SDK (推荐 3.10+)
*   Git

### 2. 获取代码

```bash
git clone <repository_url>
cd asp_ms
```

### 3. 安装依赖

```bash
flutter pub get
```

### 4. Supabase 配置

1.  创建一个新的 [Supabase](https://supabase.com/) 项目。
2.  在 Supabase SQL Editor 中运行项目根目录下的 `populate_data.sql` 脚本。该脚本会：
    *   创建所有必要的数据表 (Profiles, Sessions, Attendance 等)。
    *   设置 Row Level Security (RLS) 策略。
    *   创建测试用户和初始数据。
3.  配置 Storage Buckets：
    *   创建名为 `timeline` 的公开 bucket。
    *   创建名为 `playbook` 的公开 bucket。
4.  在 `lib/core/config/supabase_config.dart` (或相应配置文件) 中填入你的 `SUPABASE_URL` 和 `SUPABASE_ANON_KEY`。

### 5. 运行项目

```bash
# 运行在 Chrome
flutter run -d chrome --web-port=8080
```

访问 [http://localhost:8080](http://localhost:8080) 即可看到应用。

## 🧪 测试账号

`populate_data.sql` 脚本默认创建了以下测试账号（密码均为 `password123`）：

| 角色 | 邮箱 | 说明 |
|------|------|------|
| **教练** | `mike@example.com` | 资深教练，已有排课数据 |
| **教练** | `sarah@example.com` | 中级教练 |
| **学员** | `alice@example.com` | 基础班学员 |
| **学员** | `bob@example.com` | 进阶班学员 |

> **注意**: 管理员账号需要在 Supabase Auth 中手动创建用户，并在 `profiles` 表中将其 `role` 设置为 `admin`。

## 🎨 UI/UX 特性

*   **响应式设计**: 完美适配 Desktop, Tablet 和 Mobile 设备。
*   **深色模式**: 支持系统自动切换或手动切换深色/浅色主题。
*   **交互动画**: 列表项错落入场、按钮点击反馈、卡片悬停效果，提升用户体验。

## 📝 数据库设计 (Schema)

核心数据表关系如下：

*   **profiles**: 用户档案 (关联 auth.users)
*   **class_groups**: 班级定义
*   **sessions**: 具体课次 (关联 class_groups, coaches, venues)
*   **attendance**: 出勤记录 (关联 sessions, students)
*   **coach_shifts**: 教练排班记录
*   **timeline_posts**: 动态帖子
*   **notices**: 系统公告

详细 SQL 定义请参考 `populate_data.sql`。
