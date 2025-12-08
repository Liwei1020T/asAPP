# 使用 Cloudflare Tunnel 自托管存储与前端（本机作为服务器）

本方案假设你的文件已写入本机 `local_storage/`，并且 Flutter Web 前端运行在本机 8080 端口。

## 前提
- 已有 Cloudflare 账户与域名，DNS 由 Cloudflare 托管。
- 已安装 `cloudflared`。
- 本机能运行 Python（用于示例静态服务器）。

## 步骤

1) 启动本地静态文件服务（指向 `local_storage/`）
```bash
cd <project-root>
python3 -m http.server 9000 --directory local_storage
```
说明：9000 端口仅本机监听，外网访问将通过 Cloudflare Tunnel。

2) 启动应用（示例为 Flutter Web）
```bash
flutter run -d chrome --web-port=8080
```
如果是桌面/移动原生，只需确保访问的 API/存储指向本机即可。

3) 登录 Cloudflare（首次）
```bash
cloudflared login
```
浏览器完成授权。

4) 创建隧道并绑定存储域名
```bash
cloudflared tunnel create asp-local
cloudflared tunnel route dns asp-local media.your-domain.com
```
运行隧道指向本地 9000：
```bash
cloudflared tunnel run asp-local --url http://localhost:9000
```

5) （可选）同一隧道暴露前端
创建/编辑 `~/.cloudflared/config.yml`：
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

6) 更新应用配置
- 在 `lib/core/config/storage_config.dart` 设置：
  - `baseDirectory = 'local_storage'`（默认）
  - `publicBaseUrl = 'https://media.your-domain.com'`
- 确保应用内返回的文件 URL 使用上述域名。

7) 验证
- 本机访问 `http://localhost:9000` 可见文件列表。
- 通过 `https://media.your-domain.com/...` 能访问上传文件。
- 若配置了前端，`https://app.your-domain.com` 正常访问。

## 运行与维护
- 保持三个进程/服务在线：静态文件服务、应用、cloudflared。
- 如需后台运行，可用 `nohup`、systemd 或进程管理器（例如 pm2）托管 `cloudflared` 与静态服务器。
- 定期备份 `local_storage/`（存放所有上传文件）。

## 在一台电脑连接多个 Tunnel 的方法

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
   - 这种方式每个隧道单独进程，互不影响。

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
   - 这种方式一个进程管理多个主机名。

注意事项：
- 端口冲突：本地服务端口需唯一，例如 9000/8080/3000。
- 证书文件：不同隧道会各自生成 `<tunnel-id>.json`；多隧道多进程时要确保使用对应的 credentials-file。
- 开机自启：多隧道多进程时需为每个隧道配置 systemd 服务；单隧道多路由只需一个服务。
