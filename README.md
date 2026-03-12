# Openclaw Docker Container Image

[![Build Status](https://github.com/wodby/openclaw/workflows/Build%20docker%20image/badge.svg)](https://github.com/wodby/openclaw/actions)
[![Docker Pulls](https://img.shields.io/docker/pulls/wodby/openclaw.svg)](https://hub.docker.com/r/wodby/openclaw)
[![Docker Stars](https://img.shields.io/docker/stars/wodby/openclaw.svg)](https://hub.docker.com/r/wodby/openclaw)

## Docker Images

❗For better reliability we release images with stability tags (
`wodby/openclaw:2026-X.X.X`) which correspond to [git tags](https://github.com/wodby/openclaw/releases). We strongly recommend using images only with stability tags.

Overview:

- All images are based on Debian Linux (some dependencies do not currently support Alpine)
- Base image: [node](https://hub.docker.com/_/node)
- [GitHub actions builds](https://github.com/wodby/openclaw/actions)
- [Docker Hub](https://hub.docker.com/r/wodby/openclaw)

[_(Dockerfile)_]: https://github.com/wodby/openclaw/tree/master/Dockerfile

Supported tags and respective `Dockerfile` links:

- `2026`, `latest` [_(Dockerfile)_]

All images built for `linux/amd64` and `linux/arm64`

## Environment Variables

| Variable                                         | Default Value                       | Description                                                                           |
|--------------------------------------------------|-------------------------------------|---------------------------------------------------------------------------------------|
| `OPENCLAW_GATEWAY_CONTROLUI_ALLOWED_ORIGIN_JSON` |                                     |                                                                                       |
| `OPENCLAW_AGENTS_WORKSPACE`                      | `~/.openclaw/workspace`             | Default workspace for agents                                                          |
| `OPENCLAW_OPENAI_MODEL`                          | `openai/gpt-5.1-codex`              | Primary model for the `openai` agent when `OPENAI_API_KEY` is set                     |
| `OPENCLAW_OPENAI_WORKSPACE`                      | `~/.openclaw/workspace-openai`      | Workspace override for the `openai` agent                                             |
| `OPENCLAW_OPENAI_CODE_MODEL`                     | `openai-codex/gpt-5.3-codex`        | Primary model for the `openai-code` agent when `OPENAI_API_KEY` is set                |
| `OPENCLAW_OPENAI_CODE_WORKSPACE`                 | `~/.openclaw/workspace-openai-code` | Workspace override for the `openai-code` agent                                        |
| `OPENCLAW_CLAUDE_MODEL`                          | `anthropic/claude-opus-4-6`         | Primary model for the `claude` agent when `ANTHROPIC_API_KEY` is set                  |
| `OPENCLAW_CLAUDE_WORKSPACE`                      | `~/.openclaw/workspace-claude`      | Workspace override for the `claude` agent                                             |
| `OPENCLAW_GEMINI_MODEL`                          | `google/gemini-3-pro-preview`       | Primary model for the `gemini` agent when `GEMINI_API_KEY` or `GOOGLE_API_KEY` is set |
| `OPENCLAW_GEMINI_WORKSPACE`                      | `~/.openclaw/workspace-gemini`      | Workspace override for the `gemini` agent                                             |
| `OPENCLAW_STATE_DIR`                             | `/data`                             |                                                                                       |
| `TELEGRAM_BOT_TOKEN`                             |                                     | Adds the `telegram` channel with `enabled: true`                                      |
| `DISCORD_BOT_TOKEN`                              |                                     | Adds the `discord` channel with `enabled: true`                                       |
| `OPENAI_API_KEY`                                 |                                     | Adds OpenAI and OpenAI Code agents                                                    |
| `ANTHROPIC_API_KEY`                              |                                     | Adds Anthropic's Claude agent                                                         |
| `GEMINI_API_KEY`                                 |                                     | Adds Google Gemini agent                                                              |

OpenClaw will now add agents automatically when the corresponding provider credentials are present:

- `OPENAI_API_KEY` adds the `openai` agent
- `OPENAI_API_KEY` also adds the `openai-code` agent
- `ANTHROPIC_API_KEY` adds the `claude` agent
- `GEMINI_API_KEY` or `GOOGLE_API_KEY` adds the `gemini` agent

The first available provider in that order becomes the default agent.

OpenClaw will also add channels automatically when the corresponding tokens are present:

- `TELEGRAM_BOT_TOKEN` adds the `telegram` channel
- `DISCORD_BOT_TOKEN` adds the `discord` channel

## Orchestration Actions

Usage:

```
make COMMAND [params ...]
 
commands:
    check-ready max_try wait_seconds delay_seconds
    check-live max_try wait_seconds delay_seconds
    
default params values:
    max_try 1
    wait_seconds 1
    delay_seconds 0
```

## Deployment

Deploy Openclaw to your server via [![Wodby](https://www.google.com/s2/favicons?domain=wodby.com) Wodby](https://wodby.com/).
