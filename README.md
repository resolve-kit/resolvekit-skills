# ResolveKit Agent Skills

AI agent skills for integrating ResolveKit into any project. Drop these into your project's `.agents/skills/` directory and tell your AI agent to integrate ResolveKit.

## Quick Install

```bash
# Option 1: Run the install script
curl -sL https://raw.githubusercontent.com/resolve-kit/resolvekit-skills/main/install.sh | bash -s /path/to/your/project

# Option 2: Clone and copy
git clone https://github.com/resolve-kit/resolvekit-skills.git
cd resolvekit-skills
./install.sh /path/to/your/project

# Option 3: Manual copy
cp -r resolvekit-skills/resolvekit-* /path/to/your/project/.agents/skills/
```

## Available Skills

| Skill | Purpose |
|---|---|
| `resolvekit-integration` | Master router. Detects your project type (iOS, Android, Backend, Mixed) and routes to the correct integration guide. |
| `resolvekit-ios-integration` | Complete iOS SDK integration: SPM installation, `@ResolveKit` macro, SwiftUI/UIKit UI, troubleshooting. |
| `resolvekit-android-integration` | Complete Android SDK integration: Maven, KSP function authoring, Compose/Views UI, ProGuard rules, theming. |
| `resolvekit-backend-setup` | Backend deployment: Docker Compose, environment configuration, production setup, knowledge bases. |
| `resolvekit-agent-instructions` | How AI agents should approach ResolveKit integration: project detection, function design patterns, integration order, verification. |

## How It Works

1. **Skills are placed in `.agents/skills/`** in your project directory
2. **AI agents discover them automatically** when opened in an agent-enabled environment (Hermes, Codex, Claude Code, Cursor, etc.)
3. **Tell your agent**: "Integrate ResolveKit into this project"
4. **The agent follows the skill**: Detects your project type, adds dependencies, authors tool functions, integrates the UI

## What Gets Integrated

ResolveKit adds AI-powered in-product support resolution:

- **Chat UI** embedded directly in your app (SwiftUI, UIKit, Compose, or Views)
- **Tool functions** the AI agent can call to access your app's data and features
- **Session management** with persistence, reconnection, and streaming
- **Remote theming** fetched from your backend to match your brand

## Documentation

- Full documentation: https://docs.thingsarestaging.tech
- Getting started: https://docs.thingsarestaging.tech/getting-started
- iOS SDK: https://github.com/resolve-kit/resolvekit-ios-sdk
- Android SDK: https://github.com/resolve-kit/resolvekit-android-sdk
- Backend: https://github.com/resolve-kit/resolvekit-backend

## License

- Backend: AGPL-3.0-only
- iOS SDK: MIT
- Android SDK: MIT
