# 修复细节

## 背景

在这次观察到的 Windows 环境里，Codex Chrome 插件的 Native Messaging Host 和 Chrome 扩展本身都能工作，但标准浏览器运行时初始化会卡住。

直接通过 Chrome 扩展暴露的 named pipe 做 JSON-RPC 是可以工作的。容易卡住的是 `browser-client.mjs` 里的 privileged native pipe bridge 路径。

## 修复思路简版

1. 先确认 Chrome 插件链路本身没有坏：
   - Native Messaging Host manifest 存在，并指向预期 host
   - Codex Chrome Extension 已安装并启用
   - 低层 pipe 能读到当前 Chrome tab 列表
2. 定位真正问题：扩展可达，但标准 `browser-client.mjs` 在当前 Windows 环境里走 privileged native pipe bridge 时会卡住。
3. 用低层 named pipe 验证可以直接控制 Chrome：
   - 创建 Chrome tab
   - attach CDP debugger
   - 打开 `https://www.baidu.com/`
   - 读取页面标题
   - 调用 `Page.captureScreenshot`
4. 不修改原始可信文件，而是新增 `scripts/browser-client-net.mjs`，保留原 API，只把底层传输改成 Windows named pipe。
5. 更新 `skills/chrome/SKILL.md`，让后续 Codex 会话在文件存在时优先使用 `browser-client-net.mjs`。

验证结果：已通过标准 API 流程打开百度并截图，截图文件名为 `chrome-baidu-screenshot.jpg`。

如果以后 Codex 更新或插件缓存重建覆盖了 `chrome\0.1.7` 里的本地补丁，恢复或重新生成这两处文件即可：

- `scripts/browser-client-net.mjs`
- `skills/chrome/SKILL.md`

## 本地 patch 策略

这个公开仓库不包含原始 `browser-client.mjs`。

`scripts/apply-fix.ps1` 会：

1. 找到本机已安装的 Codex Chrome 插件目录。
2. 把用户本机的 `scripts/browser-client.mjs` 复制成 `scripts/browser-client-net.mjs`。
3. 对复制出来的文件做少量定向 regex patch：
   - 把传输层改成 Node `net.createConnection()`
   - 移除必须使用 privileged bridge 的启动检查
   - 在 patched copy 里关闭非必要 ambient telemetry 启动调用
4. 更新 `skills/chrome/SKILL.md`，提示未来 Codex 会话优先使用 `browser-client-net.mjs`。
5. 除非传入 `-SkipConfig`，否则确保 `config.toml` 中启用 Chrome 插件。

## 配置项

Chrome 插件相关的 TOML 配置是：

```toml
[features]
plugins = true
apps = true

[plugins."chrome@openai-bundled"]
enabled = true
```

in-app browser 是另一个插件，可以共存：

```toml
[plugins."browser-use@openai-bundled"]
enabled = true
```

## 验证

Windows 下双击运行：

```text
scripts\apply-fix.cmd
scripts\verify.cmd
```

`.cmd` 包装器会用 `-ExecutionPolicy Bypass` 调用 PowerShell，并在退出前暂停。请双击 `.cmd` 文件，不要直接双击 `.ps1` 文件。自动化环境可以设置 `CODEX_NO_PAUSE=1` 跳过暂停。

等价的 PowerShell 命令：

```powershell
.\scripts\verify.ps1
```

然后让 Codex 测试：

```text
用 @chrome 打开 https://www.baidu.com/ 并截图
```

## 许可说明

本仓库里的脚本和文档使用 MIT License。生成的 `browser-client-net.mjs` 是用户本机已安装 Codex 插件的本地派生文件，本仓库不分发它。
