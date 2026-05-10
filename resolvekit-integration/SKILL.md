---
name: resolvekit-integration
description: Master routing skill for ResolveKit SDK integration. Detects project type and routes to the correct integration path (iOS, Android, Backend). Use this first when integrating ResolveKit into any project.
category: resolvekit
---

# ResolveKit Integration Router

ResolveKit adds AI-powered in-product support resolution to mobile apps. It has three layers:

1. **Backend** (`resolvekit-backend`) -- Python/FastAPI runtime, KB service, dashboard
2. **iOS SDK** (`resolvekit-ios-sdk`) -- Swift 5.9+, iOS 16+, macOS 12+
3. **Android SDK** (`resolvekit-android-sdk`) -- Kotlin, minSdk 26, JDK 17

## When to Load This Skill

Load this skill whenever the user asks to integrate ResolveKit into a project, or when you detect a project that could benefit from embedded AI support resolution.

## Step 1: Detect Project Type

Inspect the project to determine what you're working with:

### iOS / Apple Platform
- Presence of `.xcodeproj`, `.xcworkspace`, or `Package.swift`
- `.swift` source files
- `Info.plist` with iOS/macOS bundle identifiers
- SwiftUI or UIKit/AppKit patterns

### Android
- `build.gradle.kts` or `build.gradle` with `com.android.application` plugin
- `src/main/AndroidManifest.xml`
- Kotlin (`.kt`) or Java (`.java`) source files
- `compose` dependencies or XML layouts

### Backend / Server
- `resolvekit-backend` repo itself, or a project that needs self-hosted backend
- FastAPI / Python backend that could integrate as a custom agent
- Docker Compose setups needing ResolveKit services

### Mixed / Multi-Platform
- Mono-repo with both iOS and Android directories
- React Native / Flutter / KMP projects (need platform-specific bridging)
- Backend + mobile app in same repo

## Step 2: Route to Correct Integration Skill

Based on detected project type, load the appropriate skill:

| Project Type | Skill to Load |
|---|---|
| iOS app (SwiftUI/UIKit) | `resolvekit-ios-integration` |
| Android app (Compose/Views) | `resolvekit-android-integration` |
| Backend deployment | `resolvekit-backend-setup` |
| Both iOS + Android | Load BOTH SDK skills |
| Agent integration | `resolvekit-agent-instructions` |

## Step 3: Integration Phases

Every ResolveKit integration follows this pattern:

### Phase 1: Backend Connection
- Determine backend URL (local dev vs production)
- Obtain API key from dashboard
- Configure `apiKeyProvider` in the SDK

### Phase 2: SDK Installation
- iOS: Add SPM dependency (`resolvekit-ios-sdk`, version `1.4.2+`)
- Android: Add Maven dependencies (`app.resolvekit:sdk:1.0.1`)

### Phase 3: Function Authoring
- Define tool functions the agent can call (the core value add)
- iOS: `@ResolveKit` macro on structs
- Android: `@ResolveKit` annotation + KSP, or manual `AnyResolveKitFunction`

### Phase 4: UI Integration
- iOS: `ResolveKitChatView(runtime:)` in SwiftUI, or `ResolveKitChatViewController` for UIKit/AppKit
- Android: `ResolveKitChatView(runtime)` in Compose, or `ResolveKitChatActivity`/`ResolveKitChatFragment` for View-based apps

### Phase 5: Context & Personalization
- Configure `llmContextProvider` to pass user/app state to the agent
- Configure `deviceIdProvider` for session correlation
- Set up `localeProvider` for localization

## Critical Integration Notes

- SDKs use **Server-Sent Events (SSE)** for real-time event streaming
- Session-scoped requests require `X-Resolvekit-Chat-Capability` token
- Functions are synced via `PUT /v1/functions/bulk` at startup
- Sessions auto-reuse: `POST /v1/sessions` returns existing active session if one exists
- Chat theme is fetched from backend at `GET /v1/sdk/chat-theme`
- Compatibility is checked at `GET /v1/sdk/compat`

## Licensing
- Backend: AGPL-3.0-only
- iOS SDK: MIT
- Android SDK: MIT

## Pitfalls

1. **iOS**: Only link `ResolveKitUI` in app targets -- it transitively includes `ResolveKitCore`. Linking both causes build conflicts.
2. **iOS**: Framework must be set to `Embed & Sign`, not just linked.
3. **Android**: `baseUrl` is `String`, not `java.net.URL`. The property name is `baseUrl` (lowercase 'u').
4. **Android**: Requires `INTERNET` permission in `AndroidManifest.xml`.
5. **Android**: ProGuard rules are REQUIRED for release builds -- see `resolvekit-android-integration` skill.
6. **Both**: API keys must start with `iaa_` prefix.
7. **Both**: `@ResolveKit` functions must have `snake_case` names for LLM compatibility.
