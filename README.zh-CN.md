# Codex Chrome 插件 Windows 修复脚本

这是一个面向 Windows 上 Codex Chrome 插件异常的社区修复脚本仓库。

典型现象：

- `@chrome` 已经可见，或者能部分连接。
- Codex Chrome Extension 和 Native Messaging Host 检查正常。
- 但实际使用时，标准 Chrome 自动化入口会卡住，截图或控制不稳定。

这个仓库**不再分发 OpenAI/Codex 的专有插件文件**。这里只放文档和修复脚本。脚本会在用户自己机器上已有的插件目录里，现场生成修复文件。

## 修复做了什么

脚本会在本机已有的 Codex Chrome 插件目录里生成：

```text
scripts/browser-client-net.mjs
```

这个文件由用户本机已有的 `browser-client.mjs` 复制并现场 patch 得到。修复点是：把可能卡住的 privileged native pipe bridge 连接路径，换成 Windows 上可工作的 Node named-pipe 连接路径。

脚本还会更新本机 Chrome skill 说明，让后续 Codex 会话优先使用 `browser-client-net.mjs`。

## 修复思路简版

1. 先确认 Chrome 插件、扩展、Native Messaging Host 都没坏：
   - Native Messaging Host manifest 存在且有效。
   - Codex Chrome Extension 已安装并启用。
   - 低层 pipe 能读到当前 Chrome tab 列表。
2. 真正的问题不是扩展不可用，而是标准 `browser-client.mjs` 在当前 Windows 环境里走 privileged native pipe bridge 时会卡住。
3. 验证低层 named pipe 可以直接控制 Chrome：
   - 创建 Chrome tab
   - attach CDP debugger
   - 打开 `https://www.baidu.com/`
   - 读取页面标题
   - 调用 `Page.captureScreenshot`
4. 最终不改坏原始可信文件，而是新增 `browser-client-net.mjs`。它保留原 API，只把底层传输改成 Windows named pipe。
5. 然后更新 `SKILL.md`，让后续 Codex 会话优先导入 `browser-client-net.mjs`。

验证结果：已通过标准 API 流程打开百度并截图，截图文件名为 `chrome-baidu-screenshot.jpg`。

## 适用条件

- Windows
- Codex Desktop
- 本机已经存在 Chrome 插件目录：

```text
%USERPROFILE%\.codex\plugins\cache\openai-bundled\chrome\0.1.7
```

- Chrome 中已安装或可以安装 Codex Chrome Extension

如果目标机器从未安装过官方 Chrome 插件，需要先通过官方方式安装或恢复官方插件。本仓库提供的是修复补丁，不是 OpenAI 插件再分发包。

## 快速使用

Windows 下建议直接双击运行：

```text
scripts\apply-fix.cmd
scripts\verify.cmd
```

这两个 `.cmd` 包装器会在成功或失败后停住窗口，方便看到输出和错误信息，不会一闪而过。
请双击 `.cmd` 文件，不要直接双击 `.ps1` 文件。

高级 PowerShell 用法：

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\apply-fix.ps1
.\scripts\verify.ps1
```

然后重启 Codex，测试：

```text
用 @chrome 打开 https://www.baidu.com/ 并截图
```

## 注意事项

- 这里不包含 OpenAI 专有插件源码或二进制文件。
- `browser-client-net.mjs` 会在用户本机根据已安装插件生成。
- 这是非官方社区 workaround。
- Codex 更新后可能覆盖 `chrome\0.1.7` 里的本地补丁；如果问题复现，重新运行 `apply-fix.ps1`，或者恢复 `scripts/browser-client-net.mjs` 和 `skills/chrome/SKILL.md` 这两处文件。

## 更多文档

- [英文技术说明](docs/fix-details.md)
- [中文技术说明](docs/fix-details.zh-CN.md)
