#!/bin/bash
# ResolveKit Agent Skills Installer
# Installs ResolveKit integration instructions for all major AI coding agents.
#
# Supported agents:
#   Universal   - AGENTS.md (Hermes, OpenCode, Codex, and others)
#   Hermes      - .agents/skills/ (rich skill format with references)
#   OpenCode    - .agents/skills/ (rich skill format with references)
#   Claude Code - CLAUDE.md
#   Cursor      - .cursor/rules/
#   Copilot     - .github/copilot-instructions.md
#
# Usage:
#   ./install.sh                    # Install to current directory
#   ./install.sh /path/to/project   # Install to specified directory

set -e

TARGET_DIR="${1:-.}"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$TARGET_DIR' does not exist."
    exit 1
fi

# Resolve the absolute path for display
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "============================================"
echo " ResolveKit Agent Integration Installer"
echo "============================================"
echo ""
echo "Target: $TARGET_DIR"
echo ""

INSTALLED=0

# ============================================================
# 1. AGENTS.md (Universal -- read by most modern agents)
# ============================================================
if [ ! -f "$TARGET_DIR/AGENTS.md" ]; then
    cat > "$TARGET_DIR/AGENTS.md" << 'EOF'
# Project Agent Instructions

## ResolveKit Integration

This project uses [ResolveKit](https://resolvekit.app) for in-product AI support resolution.

When asked to integrate or work with ResolveKit, follow the steps below.

### Quick Install (One-Liner)
```bash
curl -sL https://raw.githubusercontent.com/resolve-kit/resolvekit-skills/main/install.sh | bash -s .
```

### Integration Steps

1. **Detect platform** -- Check if this is iOS (`.xcodeproj`/`Package.swift`), Android (`build.gradle.kts`), or backend (`docker-compose.yml` with agent/kb services).

2. **Add SDK dependency**
   - **iOS**: Add SPM package `https://github.com/resolve-kit/resolvekit-ios-sdk` (v1.4.2+). Link ONLY `ResolveKitUI`.
   - **Android**: Add `implementation("app.resolvekit:sdk:1.0.1")`. For function authoring also add `app.resolvekit:authoring:1.0.1` and `ksp("app.resolvekit:ksp:1.0.1")`.
   - **Backend**: Clone `https://github.com/resolve-kit/resolvekit-backend`, run `cp .env.example .env && docker compose up -d`.

3. **Create API key** -- Open the ResolveKit dashboard (port 3000 locally), create an app, generate an API key (format: `iaa_...`).

4. **Author tool functions** -- Define functions that give the agent access to app data:
   - **iOS**: `@ResolveKit(name: "do_something", description: "Plain English description for LLM")` macro on structs
   - **Android**: `@ResolveKit(name = "do_something", description = "...")` annotation + KSP

5. **Configure runtime** -- Create `ResolveKitRuntime` with `ResolveKitConfiguration` containing:
   - `baseUrl` / `baseURL` pointing to backend
   - `apiKeyProvider` returning the API key
   - `functions` list with registered tool functions
   - `llmContextProvider` passing user/app state

6. **Integrate UI**
   - **iOS/SwiftUI**: `ResolveKitChatView(runtime:)` inline or in sheet
   - **iOS/UIKit**: `ResolveKitChatViewController(runtime:)`
   - **Android/Compose**: `ResolveKitChatView(runtime = runtime)` wrapped in `MaterialTheme`
   - **Android/Views**: `ResolveKitChatActivity.createIntent()` or `ResolveKitChatFragment.newInstance()`

7. **Verify** -- Build succeeds, runtime connects (connectionState = active), functions registered, chat renders.

### Critical Notes
- iOS: Only link `ResolveKitUI` (includes Core transitively). Framework must be `Embed & Sign`.
- Android: Add `<uses-permission android:name="android.permission.INTERNET" />` to manifest. ProGuard rules REQUIRED for release builds.
- Function names: Always `snake_case`.
- API keys: Must start with `iaa_` prefix.
- Android `baseUrl`: Is `String`, not `java.net.URL`.

### Full Documentation
- Getting Started: https://docs.resolvekit.app/getting-started
- iOS SDK: https://docs.resolvekit.app/ios/
- Android SDK: https://docs.resolvekit.app/android/
- Backend: https://docs.resolvekit.app/backend/
- AI Agent Integration: https://docs.resolvekit.app/ai-agent-integration
EOF
    INSTALLED=$((INSTALLED + 1))
    echo "  [x] AGENTS.md (universal)"
else
    echo "  [-] AGENTS.md already exists (skipped)"
fi

# ============================================================
# 2. .agents/skills/ (Hermes, OpenCode)
# ============================================================
SKILLS_DIR="$TARGET_DIR/.agents/skills"

# Check if we have skill directories in the current repo (git clone case)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HAS_LOCAL_SKILLS=false

if [ -d "$SCRIPT_DIR/resolvekit-integration" ]; then
    HAS_LOCAL_SKILLS=true
fi

if [ "$HAS_LOCAL_SKILLS" = true ]; then
    # Copy from local repo (full skills with references)
    for skill in resolvekit-integration resolvekit-ios-integration resolvekit-android-integration resolvekit-backend-setup resolvekit-agent-instructions; do
        if [ -d "$SCRIPT_DIR/$skill" ]; then
            mkdir -p "$SKILLS_DIR/$skill"
            cp -r "$SCRIPT_DIR/$skill"/* "$SKILLS_DIR/$skill/"
            echo "  [x] .agents/skills/$skill/ (full)"
            INSTALLED=$((INSTALLED + 1))
        fi
    done
else
    # Standalone install -- create inline skill file
    mkdir -p "$SKILLS_DIR/resolvekit-integration"
    cat > "$SKILLS_DIR/resolvekit-integration/SKILL.md" << 'EOF'
---
name: resolvekit-integration
description: Master routing skill for ResolveKit SDK integration. Detects project type and routes to the correct integration path.
---

# ResolveKit Integration

## Project Detection
- iOS: `.xcodeproj`, `.xcworkspace`, `Package.swift`, `.swift` files
- Android: `build.gradle.kts`, `AndroidManifest.xml`, `src/main/`
- Backend: `docker-compose.yml` with agent/kb services, FastAPI Python files

## iOS Integration
1. SPM: `https://github.com/resolve-kit/resolvekit-ios-sdk` (v1.4.2+)
2. Link ONLY `ResolveKitUI` (Embed & Sign)
3. `@ResolveKit(name: "...", description: "...")` macro on structs
4. SwiftUI: `ResolveKitChatView(runtime:)`, UIKit: `ResolveKitChatViewController`

## Android Integration
1. Maven: `app.resolvekit:sdk:1.0.1`, KSP for authoring
2. `INTERNET` permission in manifest, ProGuard rules for release
3. `@ResolveKit(name = "...", description = "...")` + KSP
4. Compose: `ResolveKitChatView(runtime)`, Views: `ResolveKitChatActivity`

## Backend
1. `docker compose up -d` from resolvekit-backend
2. Create app + API key in dashboard (port 3000)
3. Configure `IAA_*`, `KBS_*` environment variables

## Full docs: https://docs.resolvekit.app
EOF
    echo "  [x] .agents/skills/resolvekit-integration/ (inline)"
    INSTALLED=$((INSTALLED + 1))
fi

# ============================================================
# 3. CLAUDE.md (Claude Code)
# ============================================================
if [ ! -f "$TARGET_DIR/CLAUDE.md" ]; then
    cat > "$TARGET_DIR/CLAUDE.md" << 'EOF'
# ResolveKit Integration Notes

This project uses ResolveKit for in-product AI support resolution.

## SDKs
- iOS: https://github.com/resolve-kit/resolvekit-ios-sdk (SPM, v1.4.2+, link only ResolveKitUI)
- Android: https://github.com/resolve-kit/resolvekit-android-sdk (Maven, app.resolvekit:sdk:1.0.1)
- Backend: https://github.com/resolve-kit/resolvekit-backend (Docker Compose)
- Docs: https://docs.resolvekit.app

## Key Integration Points
- Add SDK dependency (SPM for iOS, Gradle for Android)
- Create API key in dashboard (format: iaa_...)
- Author tool functions using @ResolveKit macro/annotation
- Configure ResolveKitRuntime with baseURL, apiKeyProvider, functions
- Integrate chat UI (SwiftUI: ResolveKitChatView, Compose: ResolveKitChatView)

## Gotchas
- iOS: Only link ResolveKitUI, framework must be Embed & Sign
- Android: INTERNET permission required, ProGuard rules required for release
- Function names must be snake_case
- Android baseUrl is String (not java.net.URL)
- API keys must start with iaa_ prefix
EOF
    echo "  [x] CLAUDE.md (Claude Code)"
    INSTALLED=$((INSTALLED + 1))
else
    echo "  [-] CLAUDE.md already exists (skipped)"
fi

# ============================================================
# 4. .cursor/rules/ (Cursor)
# ============================================================
CURSOR_RULES="$TARGET_DIR/.cursor/rules"
if [ ! -f "$CURSOR_RULES/resolvekit.mdc" ]; then
    mkdir -p "$CURSOR_RULES"
    cat > "$CURSOR_RULES/resolvekit.mdc" << 'EOF'
---
description: ResolveKit SDK integration patterns for iOS, Android, and backend
globs: **/*
alwaysApply: false
---

# ResolveKit Integration

## iOS
- SPM: `https://github.com/resolve-kit/resolvekit-ios-sdk`
- Link ONLY `ResolveKitUI` (includes Core transitively), set to Embed & Sign
- Tool functions: `@ResolveKit(name: "snake_case", description: "detailed for LLM")` macro on structs
- SwiftUI: `ResolveKitChatView(runtime:)` | UIKit: `ResolveKitChatViewController(runtime:)`
- Runtime config: `ResolveKitConfiguration(baseURL, apiKeyProvider, functions)`

## Android
- Maven: `app.resolvekit:sdk:1.0.1` + `authoring:1.0.1` + `ksp("ksp:1.0.1")`
- `<uses-permission android:name="android.permission.INTERNET" />` in manifest
- ProGuard rules REQUIRED in `proguard-rules.pro` (see docs)
- Tool functions: `@ResolveKit(name = "snake_case", description = "...")` + KSP
- Compose: `ResolveKitChatView(runtime)` in MaterialTheme
- Views: `ResolveKitChatActivity.createIntent()` or `ResolveKitChatFragment.newInstance()`
- `baseUrl` is `String`, NOT `java.net.URL`

## Backend
- Clone resolvekit-backend, `cp .env.example .env && docker compose up -d`
- Dashboard at port 3000, agent at 8000, KB at 8100
- Create app + API key in dashboard (iaa_...)

## Full docs: https://docs.resolvekit.app
EOF
    echo "  [x] .cursor/rules/resolvekit.mdc (Cursor)"
    INSTALLED=$((INSTALLED + 1))
else
    echo "  [-] .cursor/rules/resolvekit.mdc already exists (skipped)"
fi

# ============================================================
# 5. .github/copilot-instructions.md (GitHub Copilot)
# ============================================================
COPILOT_DIR="$TARGET_DIR/.github"
if [ ! -f "$COPILOT_DIR/copilot-instructions.md" ]; then
    mkdir -p "$COPILOT_DIR"
    cat > "$COPILOT_DIR/copilot-instructions.md" << 'EOF'
# ResolveKit Integration

This project uses ResolveKit for in-product AI support resolution.

## SDK Links
- iOS SDK: https://github.com/resolve-kit/resolvekit-ios-sdk
- Android SDK: https://github.com/resolve-kit/resolvekit-android-sdk
- Backend: https://github.com/resolve-kit/resolvekit-backend
- Documentation: https://docs.resolvekit.app

## Integration Checklist
1. Add SDK dependency (SPM for iOS, Gradle for Android)
2. Create API key in ResolveKit dashboard (format: iaa_...)
3. Author tool functions with @ResolveKit macro/annotation
4. Configure ResolveKitRuntime with backend URL, API key provider, functions
5. Integrate chat UI (ResolveKitChatView or platform-specific controller)
EOF
    echo "  [x] .github/copilot-instructions.md (Copilot)"
    INSTALLED=$((INSTALLED + 1))
else
    echo "  [-] .github/copilot-instructions.md already exists (skipped)"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "============================================"
echo " Installed $INSTALLED agent configuration(s)"
echo "============================================"
echo ""
echo "Supported agents:"
echo "  AGENTS.md           -- Universal (Hermes, OpenCode, Codex, etc.)"
echo "  .agents/skills/     -- Hermes, OpenCode (full skill format)"
echo "  CLAUDE.md           -- Claude Code"
echo "  .cursor/rules/      -- Cursor"
echo "  .github/copilot-*   -- GitHub Copilot"
echo ""
echo "Full documentation: https://docs.resolvekit.app"
echo "AI Agent guide:     https://docs.resolvekit.app/ai-agent-integration"
