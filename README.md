中文说明见 [README.zh-CN.md](README.zh-CN.md).

# Codex Chrome Plugin Windows Fix

Community repair scripts for a Windows-specific Codex Chrome plugin failure mode:

- `@chrome` is visible or partially connected.
- The Codex Chrome Extension and Native Messaging Host check out.
- Standard Chrome browser automation still hangs or cannot reliably screenshot.

This repository does **not** redistribute OpenAI/Codex proprietary plugin files. It only contains documentation and scripts that patch a plugin already installed on the user's own machine.

## What The Fix Does

The script creates a local fallback client:

```text
scripts/browser-client-net.mjs
```

inside the user's existing Codex Chrome plugin directory. The generated file is derived locally from the user's existing `browser-client.mjs`, then patched to use Node's Windows named-pipe connection path instead of the privileged native pipe bridge that can hang in this environment.

It also updates the local Chrome skill notes so future Codex sessions prefer `browser-client-net.mjs` when it exists.

## Short Fix Summary

1. First confirm the Chrome plugin stack itself is healthy:
   - Native Messaging Host manifest is present and valid.
   - Codex Chrome Extension is installed and enabled.
   - The low-level pipe can read the current Chrome tab list.
2. The real issue is not that the extension is unavailable. In this Windows environment, the standard `browser-client.mjs` can hang when it uses the privileged native pipe bridge.
3. Verify that the low-level named pipe can control Chrome directly:
   - create a Chrome tab
   - attach the CDP debugger
   - open `https://www.baidu.com/`
   - read the page title
   - call `Page.captureScreenshot`
4. Do not overwrite the original trusted client file. Add `browser-client-net.mjs` instead. It keeps the same API and only swaps the transport layer to the Windows named pipe path.
5. Update `SKILL.md` so future Codex sessions prefer importing `browser-client-net.mjs`.

Validation result: the standard API flow opened Baidu and captured a screenshot named `chrome-baidu-screenshot.jpg`.

## Requirements

- Windows
- Codex Desktop
- Chrome plugin already present at:

```text
%USERPROFILE%\.codex\plugins\cache\openai-bundled\chrome\0.1.7
```

- Codex Chrome Extension installed or installable in Chrome

If the plugin has never been installed at all, install or restore the official plugin first. These scripts are a repair patch, not a redistribution of OpenAI's plugin.

## Quick Start

For a double-click friendly flow on Windows, run these files from Explorer:

```text
scripts\apply-fix.cmd
scripts\verify.cmd
```

The `.cmd` wrappers keep the window open after success or failure so the output is readable.
Double-click the `.cmd` files, not the `.ps1` files.

Advanced PowerShell usage:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\scripts\apply-fix.ps1
.\scripts\verify.ps1
```

Then restart Codex and test:

```text
Use @chrome to open https://www.baidu.com/ and take a screenshot.
```

## Important Notes

- No OpenAI proprietary plugin source or binaries are included here.
- `browser-client-net.mjs` is generated on the user's machine from their own installed plugin files.
- This is an unofficial community workaround.
- Future Codex updates may replace the plugin cache under `chrome\0.1.7`; rerun `apply-fix.ps1` or restore `scripts/browser-client-net.mjs` and `skills/chrome/SKILL.md` if the issue returns.
