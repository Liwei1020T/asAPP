# 使用 Cloudflare Tunnel 自托管存储与前端（本机作为服务器）

本方案用于以下场景：

- Flutter Web 前端部署在 **Cloudflare Pages**。
- 所有图片/视频等媒体文件都统一存储在你本机的 `local_storage/` 目录。
- 通过 Cloudflare Tunnel 暴露一个 HTTPS 域名（如 `asp-media.your-domain.com`），供前端上传和读取。

应用侧使用 `StorageRepository`：

- 上传时：`StorageRepository.uploadFile` 会向 `StorageConfig.publicBaseUrl` 指定的域名发送 `POST /upload` 请求。
- 读取时：直接使用 `StorageConfig.publicBaseUrl + /相对路径` 通过 HTTP GET 访问。

## 前提

- 已有 Cloudflare 账户与域名，DNS 由 Cloudflare 托管。
- 已安装 `cloudflared`。
- 本机能运行 Python（用于示例上传 + 静态文件服务器）。

## 1. 启动本地存储服务（读写 `local_storage/`）

示例：使用一个简单的 Python 脚本同时：

- 接收 `POST /upload?folder=...&filename=...` 上传文件；
- 通过 `GET /...` 直接访问 `local_storage/` 里的文件。

```bash
cd <project-root>
python3 tools/local_storage_server.py
```

> 说明：你可以自定义实现，只要满足：
> - `POST /upload` 返回形如 `{"path":"timeline/.../image_0.png"}` 的 JSON；
> - `GET /timeline/.../image_0.png` 能返回对应文件内容。

默认监听 `9000` 端口，外网访问会通过 Cloudflare Tunnel 进入。

## 2. 通过 Cloudflare Tunnel 暴露存储域名

1) 登录 Cloudflare（首次）

```bash
cloudflared login
```

2) 创建隧道并绑定存储域名

```bash
cloudflared tunnel create asp-local
cloudflared tunnel route dns asp-local media.your-domain.com
```

3) 运行隧道指向本地 9000：

```bash
cloudflared tunnel run asp-local --url http://localhost:9000
```

## 3. （可选）同一隧道暴露前端

如果你本地也跑着 Flutter Web 进行调试，可以在同一个隧道中同时暴露前端：

```yaml
tunnel: asp-local
credentials-file: /home/<user>/.cloudflared/<tunnel-id>.json
ingress:
  - hostname: media.your-domain.com
    service: http://localhost:9000
  - hostname: app.your-domain.com
    service: http://localhost:8080
  - service: http_status:404
```

然后用配置启动：

```bash
cloudflared tunnel run asp-local
```

## 4. 更新应用配置

- 在 `lib/core/config/storage_config.dart` 设置：
  - `baseDirectory = 'local_storage'`（默认，用于说明目录结构）
  - `publicBaseUrl = 'https://media.your-domain.com'`
- 确保应用内上传/返回的文件 URL 使用上述域名，例如：
  - `https://media.your-domain.com/timeline/.../image_0.png`

## 5. 验证

- 本机访问 `http://localhost:9000` 可见文件列表或任意文件。
- 通过 `https://media.your-domain.com/...` 能访问上传文件。
- 若配置了前端，本地 `http://localhost:8080` 或 `https://app.your-domain.com` 正常访问。

## 6. 运行与维护

- 保持三个进程/服务在线：本地存储服务、cloudflared、（可选）本地前端。
- 如需后台运行，可用 `nohup`、systemd 或进程管理器（例如 pm2）托管 `cloudflared` 与存储服务。
- 定期备份 `local_storage/`（存放所有上传文件）。

## 8. 建议的文件命名与目录结构（Playbook / Timeline）

为了后期维护和手动排查更方便，应用已统一采用「按业务实体分文件夹」的命名方式。默认根目录仍是：

- `local_storage/`

之下主要有两类业务子目录：

### 8.1 训练手册 Playbook

每一条训练资料，都会拥有一个独立的 `materialKey`，所有相关文件放在同一个目录：

- 目录：`local_storage/playbook/<userId>/<materialKey>/`
  - 内容文件：`content.<ext>`（视频 / 文档 / 图片）
  - 封面：`thumb.<ext>`

其中：

- `userId`：Supabase `profiles.id`，方便按作者归档。
- `materialKey`：由标题 + 时间戳自动生成的 slug，例如：
  - 标题「高远球基础」→ `gao-yuan-qiu-ji-chu_1733630000000`

这样同一条资料的内容和封面始终在一起，便于迁移和备份。

### 8.2 训练动态 Timeline

每一条动态帖子，也会生成一个 `postKey` 目录：

- 目录：`local_storage/timeline/<userId>/<postKey>/`
  - 若为视频：
    - `video.<ext>`
  - 若为多张图片：
    - `image_0.<ext>`
    - `image_1.<ext>`
    - `image_2.<ext>` ...

`postKey` 同样由内容文本 + 时间戳生成的 slug 组成，便于根据帖子大致内容快速定位到对应目录。

> 说明：
> - 旧数据不会被重命名，仍然使用之前的时间戳目录；
> - 新增/编辑之后上传的内容会自动使用上述新结构。

## 7. 在一台电脑连接多个 Tunnel 的方法

你可以在同一台机器上创建多个隧道，常见场景：

- 为不同域名/子域名拆分隧道（便于独立启停或权限隔离）。
- 为不同服务或端口分开隧道（测试/生产、媒体/前端等）。

两种常见方式：

1) **多隧道多进程（独立运行）**

   - 分别创建隧道：

     ```bash
     cloudflared tunnel create media-tunnel
     cloudflared tunnel create app-tunnel
     ```

   - 为各自绑定域名：

     ```bash
     cloudflared tunnel route dns media-tunnel media.your-domain.com
     cloudflared tunnel route dns app-tunnel app.your-domain.com
     ```

   - 分别运行：

     ```bash
     # 运行媒体隧道指向 9000
     cloudflared tunnel run media-tunnel --url http://localhost:9000
     # 运行前端隧道指向 8080
     cloudflared tunnel run app-tunnel --url http://localhost:8080
     ```

2) **单隧道多路由（一个 config.yml 管理多个主机名）**

   - 只创建一个隧道（如 `asp-local`），在 `~/.cloudflared/config.yml` 中添加多条 ingress：

     ```yaml
     tunnel: asp-local
     credentials-file: /home/<user>/.cloudflared/<tunnel-id>.json
     ingress:
       - hostname: media.your-domain.com
         service: http://localhost:9000
       - hostname: app.your-domain.com
         service: http://localhost:8080
       - hostname: api.your-domain.com
         service: http://localhost:3000
       - service: http_status:404
     ```

   - DNS 绑定：

     ```bash
     cloudflared tunnel route dns asp-local media.your-domain.com
     cloudflared tunnel route dns asp-local app.your-domain.com
     cloudflared tunnel route dns asp-local api.your-domain.com
     ```

   - 运行时仅需：

     ```bash
     cloudflared tunnel run asp-local
     ```

注意事项：

- 端口冲突：本地服务端口需唯一，例如 9000/8080/3000。
- 证书文件：不同隧道会各自生成 `<tunnel-id>.json`；多隧道多进程时要确保使用对应的 credentials-file。
- 开机自启：多隧道多进程时需为每个隧道配置 systemd 服务；单隧道多路由只需一个服务。
