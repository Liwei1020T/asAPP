# AGENTS 指南

本文件说明：在这个仓库里，**当你使用 AI 助手（例如 ChatGPT）协助开发时，应该怎么用、能做什么、不能做什么**。

---

## 1. 适用场景

每当你让 AI 帮你做下面这些事情时，请先快速看一眼本文件，确保风格一致：

- 设计新功能、改动现有逻辑、做重构或性能优化
- 规划较大的结构调整（例如路由、状态管理、数据层）
- 设计/修改 Supabase 表结构、RLS、SQL 脚本
- 编写/修改测试、文档、README
- 生成较多 Flutter 代码（页面、widget、repository、model 等）

---

## 2. 项目概览（给 AI 的最小必要背景）

- 前端：Flutter（支持 Web PWA）。
- 架构：**Clean Architecture**。
  - `lib/core/`：config、常量、router、theme、utils、通用 widgets。
  - `lib/data/`：models、repositories 等数据访问层。
  - `lib/features/`：按业务分模块，例如 `auth/`、`dashboard/`、`classes/`、`attendance/`、`salary/`、`timeline/` 等。
  - `lib/main.dart`：应用入口。
- 其他目录：
  - `assets/`：静态资源。
  - `local_storage/`：本地文件上传测试用。
  - `supabase/*.sql`：schema 与 RLS 脚本。
  - `documentation/`：说明文档。
  - `test/`：测试代码。
  - 编译输出：`android/`、`web/`、`windows/`、`build/` 等。

---

## 3. AI 协作工作流

AI 不会直接改代码，但可以帮你做 **计划 → 草稿 → 调整**，推荐这么用：

### 3.1 先告诉 AI 背景

在提问时建议包含：

- 你要改的是哪个 feature（例如 `features/classes`）。
- 这是 bugfix、重构还是新功能。
- 是否涉及 Supabase schema / SQL / RLS。
- 是否需要测试、文档一起调整。

> 示例：  
> “帮我在 `features/attendance` 里加一个请假功能，需要 UI + repository + Supabase SQL 设计，并给出测试建议。”

### 3.2 让 AI 先给**计划**再给代码

优先让 AI 输出：

1. 变更目标（要解决什么问题）。
2. 改动点列表（文件级别）。
3. 潜在风险点（例如 RLS、性能、兼容旧数据）。

确认方向之后，再让它给具体代码片段，而不是一上来就全文件。

---

## 4. 代码风格与约定（AI 必须遵守）

### 4.1 通用规则

- 严格遵守 `analysis_options.yaml` 中的规则。
- **组织 imports 顺序**：`dart:` → 第三方 package → 本项目。
- 行宽约 **100 字符** 左右。
- 只在逻辑不明显处写注释，避免注释废话。

### 4.2 命名规范

- 类/枚举：`PascalCase`  
  例如：`ClassDetailPage`, `AttendanceStatus`.
- 方法/变量：`camelCase`  
  例如：`loadClasses()`, `selectedDate`.
- 文件名：`snake_case.dart`  
  例如：`session_repository.dart`, `attendance_page.dart`.
- Widgets：文件或类名以 `*Widget` 结尾或使用合适的领域名。  
  例如：`ClassCardWidget`, `AttendanceFilterWidget`.

### 4.3 Flutter / UI 规范

- 在不影响可读性的前提下，**尽量使用 `const` widget**。
- Widgets 应该小而专一，避免巨型 `build`。
- 复杂布局建议拆分成多个私有 widget 或独立文件。
- 避免在 widget 中写太多业务逻辑，业务放到：
  - `features/.../application` 或
  - `data/repositories` / `core/utils` 等对应层。

---

## 5. 测试约定

- 测试文件放在 `test/feature_name/` 下，命名对应源文件：
  - 例如 `lib/features/classes/classes_page.dart`
  - 对应：`test/features/classes/classes_page_test.dart`
- 使用 `flutter_test`：
  - UI 组件/页面写 widget test。
  - 业务逻辑写 unit test。
- 带 Supabase 的逻辑要用 **fake / mock**，不要在测试中直接访问真实服务。
- 重要 widgets 暴露有意义的 `Key`，方便测试查找。

> 当 AI 生成代码时：
> - 如果修改到业务逻辑或数据层，请顺带建议/生成对应测试。
> - 给出可直接复制粘贴的 `test` 文件 skeleton。

---

## 6. 文档、SQL 与行为同步

当 AI 给出的方案 **会改变实际行为** 时，应同时考虑：

- 是否要更新：
  - `README.md`
  - `documentation/` 中相关文档
  - `supabase/*.sql`（schema/RLS 调整）
- AI 提供 SQL 时：
  - 用清晰的 **迁移脚本** 形式（而不是完整重建整个表）。
  - 标明：适用的环境/前置条件/影响范围。

---

## 7. 配置与安全

- **绝不向 AI 提供任何生产密钥、数据库密码等敏感信息。**
- 仓库中只允许存在本地/开发用的：
  - `SUPABASE_URL`
  - `SUPABASE_ANON_KEY`
- 如果改动涉及环境变量或存储方案：
  - AI 应给出需要新增的变量名称和用途说明，
  - 并提示你在 README 或 `documentation/` 中同步说明。

---

## 8. 推荐命令（AI 可引用，但不会直接执行）

在建议开发步骤时，AI 可以引用以下命令，但实际执行由你来：

- 安装依赖：`flutter pub get`
- 静态分析：`flutter analyze`
- 格式化：`dart format lib test`
- 运行测试：`flutter test` 或 `flutter test --coverage`
- 本地 PWA 运行：`flutter run -d chrome --web-port=8080`
- 构建 Web：`flutter build web`
- 本地文件服务器（for local_storage）：  
  `python3 -m http.server 9000 --directory local_storage`

---

## 9. 和 AI 沟通的小提示

- 多给一点上下文（路径、文件名、已有实现）→ 回答会更准。
- 希望它“改现有代码”时，最好贴出相关片段，而不是一句话描述。
- 如果回答不满意：
  - 可以让它“只输出 diff 风格片段”，或者
  - 明确要求“只修改某个函数/类，不要重写整个文件”。

---

## 10. 总结（给未来的你）

- AI 是**代码助手**，不是拍板的人。  
- 架构/数据库/安全相关的最终决定，仍然由你来做。
- 提问前想清楚三件事：
  1. 我想改哪个 feature？
  2. 我能接受多大范围的改动？
  3. 我希望 AI 先给的是“计划”还是“代码片段”？

只要遵守这些约定，就能比较安全、舒服地在这个仓库里使用 AI 帮忙开发。🚀
