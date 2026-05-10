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

Run PowerShell:

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
- Future Codex updates may replace the plugin cache; rerun `apply-fix.ps1` after updates if the issue returns.
