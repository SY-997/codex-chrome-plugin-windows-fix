# 修复细节

## 背景

在这次观察到的 Windows 环境里，Codex Chrome 插件的 Native Messaging Host 和 Chrome 扩展本身都能工作，但标准浏览器运行时初始化会卡住。

直接通过 Chrome 扩展暴露的 named pipe 做 JSON-RPC 是可以工作的。容易卡住的是 `browser-client.mjs` 里的 privileged native pipe bridge 路径。

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

运行：

```powershell
.\scripts\verify.ps1
```

然后让 Codex 测试：

```text
用 @chrome 打开 https://www.baidu.com/ 并截图
```

## 许可说明

本仓库里的脚本和文档使用 MIT License。生成的 `browser-client-net.mjs` 是用户本机已安装 Codex 插件的本地派生文件，本仓库不分发它。

