# Codex remote control without TUN mode

[中文](README.md)

On Windows, Codex cross-device remote control initially worked only with the proxy application's TUN mode enabled. After configuring an explicit proxy for Codex and fully restarting the application, remote access from another device was verified with TUN disabled.

This guide documents that troubleshooting result for environments where a local proxy can already reach the required services.

## What the comparison revealed

A working browser does not establish that every Codex background connection uses the system proxy. Applications must adopt system proxy settings; environment variables also depend on networking-library support. TUN can intercept additional connections at the network layer.

The computer that worked without TUN already had Codex-specific proxy environment settings. The computer that depended on TUN did not. After adding those settings and restarting, Codex background processes connected to the local proxy, which identified the traffic as HTTP CONNECT. A subsequent test confirmed actual remote access from another device with TUN disabled.

This supports checking explicit proxy routing first. How each component loads environment variables may change across versions; verify actual connections and remote operation.

## Configure the proxy

1. Keep the proxy application running, enable its system proxy option, and confirm its HTTP or mixed port. `7890` below is an example.
2. In rule mode, route `chatgpt.com`, `openai.com`, and their subdomains through a working proxy.
3. Add the following settings to `%USERPROFILE%\.codex\.env`:

```dotenv
HTTP_PROXY=http://127.0.0.1:7890
HTTPS_PROXY=http://127.0.0.1:7890
ALL_PROXY=http://127.0.0.1:7890
NO_PROXY=localhost,127.0.0.1,::1
```

Alternatively, read [configure-proxy.ps1](configure-proxy.ps1), then run it in PowerShell:

```powershell
.\configure-proxy.ps1 -ProxyPort 7890
```

The script checks the port, backs up an existing `.env`, preserves unrelated settings, and updates these four variables. It does not change the system proxy, TUN, DNS, firewall, or permanent Windows environment variables. If you already use a custom proxy bypass list, review it first: the script replaces `NO_PROXY` with the local-address list shown above.

4. Save your work and fully quit Codex, including any remaining tray instance. Keep the proxy running, disable TUN, and reopen Codex.
5. Test normal conversations, actual access from another device, and sustained use separately.

The `.codex/.env` method worked in this environment. If another version does not adopt the settings after restarting, check its supported environment-loading mechanism rather than assuming that an existing file proves success.

## Verify at the right level

- **Saved settings:** prove that configuration exists.
- **Actual proxy connections:** Codex background and desktop network processes connect to the local proxy; the proxy shows the relevant target domains and routing rules.
- **Reachable service endpoint:** TLS certificate verification succeeds and an HTTP response arrives. A plain GET returning `426 Upgrade Required` indicates an endpoint that requires a WebSocket upgrade.
- **Working remote control:** another device connects and executes a task with TUN disabled. This is the final check.

A `426` response is not a successful WebSocket handshake. A working conversation is not a remote-control test. Logs showing a local executor connected to the relay are useful evidence, but should be paired with an actual cross-device test.

## If it still fails

- Check the port and protocol: the URLs above require an HTTP proxy or a mixed port supporting HTTP CONNECT.
- Confirm a full restart and inspect the background processes' actual proxy connections.
- Check domain routing and `NO_PROXY` for unintended direct connections.
- Correlate remote WebSocket errors by time, distinguishing local-executor relay logs from other remote connections.
- Compare under the same network and node. The lowest short-test latency does not necessarily mean the best persistent connections or real-world experience.

Keep TUN available as a fallback when needed. Relay-based remote control generally does not require opening public inbound ports.

## Rollback and privacy

Restore the script's backup if `.env` already existed. If it did not, remove only the four added variables, preserving any settings added later. Fully restart Codex and verify again.

Before sharing diagnostics, remove usernames, concrete local paths, network addresses, device and account identifiers, tokens, cookies, proxy passwords, subscription URLs, and raw connection logs. This repository contains generic examples only.

## Reference

- [Official OpenAI remote connections documentation](https://learn.chatgpt.com/docs/remote-connections): describes secure relay and cross-device access. The `.env` procedure here comes from the observed troubleshooting result.
