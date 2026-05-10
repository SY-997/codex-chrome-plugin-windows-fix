# Fix Details

## Background

In the observed Windows environment, the Codex Chrome plugin's Native Messaging Host and Chrome extension were both functional, but the standard browser runtime setup could hang.

Direct JSON-RPC over the Chrome extension named pipe worked. The failing path was the browser client's privileged native pipe bridge.

## Search Keywords

Codex Chrome plugin fix, Codex Google Chrome plugin fix, Codex `@chrome` fix, Chrome Native Messaging Host fix, Codex browser automation Windows fix, browser-client-net.mjs, Windows named pipe, 谷歌浏览器插件修复, codex谷歌插件修复, codex chrome插件修复。

## Simplified Recovery Logic

1. Confirm that the Chrome plugin stack is not broken:
   - the Native Messaging Host manifest exists and points to the expected host
   - the Codex Chrome Extension is installed and enabled
   - the low-level pipe can read the current Chrome tab list
2. Identify the actual failure: the extension is reachable, but the standard `browser-client.mjs` can hang on the privileged native pipe bridge in this Windows environment.
3. Prove the direct named-pipe path works by using it to:
   - create a Chrome tab
   - attach the CDP debugger
   - navigate to `https://www.baidu.com/`
   - read the page title
   - call `Page.captureScreenshot`
4. Avoid modifying the original trusted file. Create `scripts/browser-client-net.mjs`, keep the original public API, and change only the underlying transport to the Windows named pipe.
5. Update `skills/chrome/SKILL.md` so future Codex sessions prefer `browser-client-net.mjs` when it exists.

The validation run succeeded through the normal API flow by opening Baidu and capturing `chrome-baidu-screenshot.jpg`.

If a future Codex update or plugin cache rebuild overwrites the local patch under `chrome\0.1.7`, restore or regenerate these two local files:

- `scripts/browser-client-net.mjs`
- `skills/chrome/SKILL.md`

## Local Patch Strategy

The public repository does not include the original `browser-client.mjs`.

Instead, `scripts/apply-fix.ps1`:

1. Locates the installed Codex Chrome plugin.
2. Copies the user's local `scripts/browser-client.mjs` to `scripts/browser-client-net.mjs`.
3. Applies small targeted regex patches to the copied file:
   - replaces transport creation with Node `net.createConnection()`
   - removes the startup guard that requires the privileged bridge
   - disables nonessential ambient telemetry startup calls in the patched copy
4. Updates `skills/chrome/SKILL.md` with a local note telling future Codex runs to prefer `browser-client-net.mjs`.
5. Ensures `config.toml` has the Chrome plugin enabled unless `-SkipConfig` is passed.

## Config Entries

The relevant TOML entries are:

```toml
[features]
plugins = true
apps = true

[plugins."chrome@openai-bundled"]
enabled = true
```

The in-app browser plugin is separate and can coexist:

```toml
[plugins."browser-use@openai-bundled"]
enabled = true
```

## Verification

For double-click use on Windows, run:

```text
scripts\apply-fix.cmd
scripts\verify.cmd
```

The `.cmd` wrappers call PowerShell with `-ExecutionPolicy Bypass` and pause before closing. Double-click the `.cmd` files, not the `.ps1` files. For automation, set `CODEX_NO_PAUSE=1`.

PowerShell equivalent:

```powershell
.\scripts\verify.ps1
```

Then ask Codex:

```text
Use @chrome to open https://www.baidu.com/ and take a screenshot.
```

## Legal / Licensing Note

This repository's scripts and documentation are provided under the MIT License. The generated `browser-client-net.mjs` remains a local derivative of the user's installed Codex plugin and is not distributed here.
