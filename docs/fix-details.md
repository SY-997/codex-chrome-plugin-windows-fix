# Fix Details

## Background

In the observed Windows environment, the Codex Chrome plugin's Native Messaging Host and Chrome extension were both functional, but the standard browser runtime setup could hang.

Direct JSON-RPC over the Chrome extension named pipe worked. The failing path was the browser client's privileged native pipe bridge.

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

Run:

```powershell
.\scripts\verify.ps1
```

Then ask Codex:

```text
Use @chrome to open https://www.baidu.com/ and take a screenshot.
```

## Legal / Licensing Note

This repository's scripts and documentation are provided under the MIT License. The generated `browser-client-net.mjs` remains a local derivative of the user's installed Codex plugin and is not distributed here.

