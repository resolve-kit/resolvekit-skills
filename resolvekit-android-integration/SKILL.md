---
name: resolvekit-android-integration
description: Complete Android SDK integration guide for ResolveKit. Covers Maven installation, KSP function authoring, runtime configuration, Compose/Activity/Fragment UI integration, ProGuard rules, theming, and troubleshooting.
category: resolvekit
---

# ResolveKit Android SDK Integration

## Requirements
- Min SDK: 26
- Compile SDK: 36
- JDK target: 17
- Kotlin: 1.9.22+
- Compose BOM: 2024.02.00+
- Running ResolveKit backend with valid API key

## Published Packages
```
app.resolvekit:sdk:1.0.1          -- Umbrella facade (runtime + UI)
app.resolvekit:authoring:1.0.1    -- @ResolveKit annotation + ResolveKitFunction
app.resolvekit:ksp:1.0.1          -- KSP codegen processor
```

## Module Layout
| Module | Purpose |
|---|---|
| `sdk` | Umbrella facade for default runtime + UI |
| `core` | JSON/value types, function contracts, registry, errors |
| `networking` | REST + SSE clients (OkHttp + kotlinx.serialization) |
| `ui` | Runtime + Compose view + Activity/Fragment surfaces |
| `authoring` | `@ResolveKit` + `ResolveKitFunction` |
| `ksp` | Codegen processor for tool adapters |

## Step 1: Installation via Maven

### Basic (UI only, no function authoring)
```kotlin
dependencies {
    implementation("app.resolvekit:sdk:1.0.1")
}
```

### With KSP Function Authoring (Recommended)
```kotlin
plugins {
    id("com.google.devtools.ksp")
}

dependencies {
    implementation("app.resolvekit:sdk:1.0.1")
    implementation("app.resolvekit:authoring:1.0.1")
    ksp("app.resolvekit:ksp:1.0.1")
}
```

## Step 2: Define Tool Functions

### Recommended: @ResolveKit + KSP
```kotlin
import app.resolvekit.authoring.ResolveKit
import app.resolvekit.authoring.ResolveKitFunction

@ResolveKit(
    name = "get_subscription_status",
    description = "Returns the user's current subscription tier and renewal date",
    requiresApproval = false
)
class GetSubscriptionStatus : ResolveKitFunction {
    override suspend fun perform(): Any? {
        // Your app logic here
        return "Pro plan, renews 2026-06-15"
    }
}
```

KSP generates `{ClassName}ResolveKitAdapter` implementing `AnyResolveKitFunction`.

### Functions with Constructor Parameters
```kotlin
@ResolveKit(
    name = "send_feedback",
    description = "Send user feedback about a feature",
    requiresApproval = true
)
class SendFeedback(
    private val featureName: String,
    private val rating: Int,
    private val comment: String
) : ResolveKitFunction {
    override suspend fun perform(): Any? {
        // Call your app's feedback API
        return true
    }
}
```

### Supported Constructor Argument Types
- `String`, `Boolean`
- `Int`, `Long`, `Short`, `Byte`, `Double`, `Float`
- Nullable variants (`T?`)

### Register Generated Adapters
```kotlin
val config = ResolveKitConfiguration(
    apiKeyProvider = { "iaa_your_api_key" },
    functions = listOf(
        GetSubscriptionStatusResolveKitAdapter(),
        SendFeedbackResolveKitAdapter("settings", 4, "Great app!")
    )
)
```

### Manual AnyResolveKitFunction
```kotlin
object GetCurrentTime : AnyResolveKitFunction {
    override val resolveKitName = "get_current_time"
    override val resolveKitDescription = "Returns the current local time"
    override val resolveKitParametersSchema = mapOf(
        "type" to JSONValue.String("object"),
        "properties" to JSONValue.Object(emptyMap())
    )
    override val resolveKitTimeoutSeconds = 5
    override val resolveKitRequiresApproval = false

    override suspend fun invoke(
        arguments: JSONObject,
        context: ResolveKitFunctionContext
    ): JSONValue = JSONValue.String("12:00:00 UTC")
}
```

### Function Packs
```kotlin
object CommercePack : ResolveKitFunctionPack {
    override val packName = "commerce"
    override val supportedPlatforms = listOf(ResolveKitPlatform.ANDROID)
    override val functions = listOf(
        GetSubscriptionStatusResolveKitAdapter(),
        UpgradeSubscriptionResolveKitAdapter()
    )
}

// Usage
functionPacks = listOf(CommercePack)
```

## Step 3: Create and Configure Runtime

### Basic Configuration
```kotlin
val runtime = ResolveKitRuntime(
    configuration = ResolveKitConfiguration(
        baseUrl = "https://your-backend.example.com",
        apiKeyProvider = { "iaa_your_api_key" },
        functions = listOf(GetCurrentTime)
    ),
    context = applicationContext
)
```

### Full Configuration
```kotlin
val runtime = ResolveKitRuntime(
    configuration = ResolveKitConfiguration(
        baseUrl = "https://your-backend.example.com",
        apiKeyProvider = { SecureConfig.getApiKey() },
        deviceIdProvider = {
            val prefs = PreferenceManager.getDefaultSharedPreferences(context)
            prefs.getString("device_id", null) ?: run {
                val id = UUID.randomUUID().toString()
                prefs.edit().putString("device_id", id).apply()
                id
            }
        },
        llmContextProvider = {
            mapOf(
                "user_plan" to UserManager.current.plan,
                "app_version" to BuildConfig.VERSION_NAME,
                "is_onboarding_complete" to UserManager.current.isOnboardingComplete
            )
        },
        availableFunctionNamesProvider = {
            if (UserManager.current.isPro) allFunctionNames else basicFunctionNames
        },
        localeProvider = { UserManager.current.preferredLanguage },
        functions = listOf(GetCurrentTime),
        functionPacks = listOf(CommercePack)
    ),
    context = applicationContext
)
```

### Configuration Fields Reference
| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `baseUrl` | `String` | No | `https://agent.example.com` | Backend URL. String, NOT java.net.URL |
| `apiKeyProvider` | `() -> String?` | Yes | -- | Called per request. Return null to block |
| `deviceIdProvider` | `(() -> String?)?` | No | Auto UUID | Correlate sessions across launches |
| `llmContextProvider` | `() -> JSONObject` | No | `{}` | Custom context for routing |
| `availableFunctionNamesProvider` | `(() -> List<String>)?` | No | All registered | Allowlist by user plan |
| `localeProvider` | `(() -> String?)?` | No | System locale | BCP 47 tag |
| `preferredLocalesProvider` | `(() -> List<String>)?` | No | System locales | Ordered fallback list |
| `functions` | `List<AnyResolveKitFunction>` | No | `[]` | Tool function instances |
| `functionPacks` | `List<ResolveKitFunctionPack>` | No | `[]` | Function packs |

CRITICAL: Configuration is immutable after creation. To change settings, create a new configuration and runtime.

## Step 4: Integrate Chat UI

### Compose (Recommended)
```kotlin
setContent {
    MaterialTheme {
        ResolveKitChatView(runtime = runtime)
    }
}
```

`ResolveKitChatView` auto-starts runtime on first composition and stops on disposal.

### Activity Surface (View-based apps)
```kotlin
startActivity(
    ResolveKitChatActivity.createIntent(
        context = this,
        configuration = ResolveKitConfiguration(
            baseUrl = "https://your-backend.example.com",
            apiKeyProvider = { "iaa_your_api_key" },
            functions = listOf(GetCurrentTime)
        )
    )
)
```

### Fragment Surface
```kotlin
supportFragmentManager.beginTransaction()
    .replace(
        R.id.container,
        ResolveKitChatFragment.newInstance(
            ResolveKitConfiguration(
                baseUrl = "https://your-backend.example.com",
                apiKeyProvider = { "iaa_your_api_key" },
                functions = listOf(GetCurrentTime)
            )
        )
    )
    .commit()
```

## Step 5: Runtime Controls

```kotlin
runtime.start()                        // Start connection (suspend)
runtime.stop()                         // Stop connection
runtime.refreshSessionContext()        // Push updated context/locale/functions
runtime.setAppearance(ResolveKitAppearanceMode.DARK)  // Set appearance
```

## Step 6: Observe Runtime State

Runtime exposes `StateFlow` for all state:
```kotlin
lifecycleScope.launch {
    runtime.connectionState.collect { state ->
        when (state) {
            ResolveKitConnectionState.ACTIVE -> // Ready
            ResolveKitConnectionState.BLOCKED -> // Check API key
            ResolveKitConnectionState.FAILED -> // Check lastError
            else -> // In progress
        }
    }
}

lifecycleScope.launch { runtime.messages.collect { ... } }
lifecycleScope.launch { runtime.isTurnInProgress.collect { ... } }
lifecycleScope.launch { runtime.chatTheme.collect { ... } }
lifecycleScope.launch { runtime.chatTitle.collect { ... } }
lifecycleScope.launch { runtime.lastError.collect { ... } }
```

### Connection States
```
IDLE -> REGISTERING -> CONNECTING -> ACTIVE
                        -> RECONNECTING -> RECONNECTED -> ACTIVE
                        -> FAILED          (unrecoverable)
                        -> BLOCKED         (missing key / incompatible)
```

## Step 7: Theming

The SDK supports two approaches:

1. **Remote theme** -- Fetched from backend at `GET /v1/sdk/chat-theme`
2. **MaterialTheme integration** -- Wrap with your app's MaterialTheme for automatic color mapping

```kotlin
setContent {
    MaterialTheme {
        ResolveKitChatView(runtime = runtime)
    }
}
```

`ColorScheme.toResolveKitPaletteColors()` maps Material tokens to ResolveKit colors automatically.

Override appearance mode at runtime:
```kotlin
runtime.setAppearance(ResolveKitAppearanceMode.DARK)  // SYSTEM, LIGHT, DARK
```

## Step 8: ProGuard Rules (REQUIRED for Release Builds)

Add to `proguard-rules.pro`:
```proguard
# ResolveKit
-keep class app.resolvekit.** { *; }
-keep class app.resolvekit.core.** { *; }
-keep class app.resolvekit.ui.** { *; }
-keep class app.resolvekit.networking.** { *; }

# KSP-generated adapters
-keep class **ResolveKitAdapter { *; }

# JSON serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep function names for tool dispatch
-keepnames class app.resolvekit.authoring.** { *; }
```

Test with minification:
```bash
./gradlew :app:assembleRelease
```

## Step 9: Required Permissions

Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

For cleartext HTTP (non-HTTPS backends), configure network security config or enable cleartext traffic in the manifest.

## Pitfalls

1. **baseUrl type**: It is `String`, not `java.net.URL`. Property name is `baseUrl` (lowercase 'u').
2. **INTERNET permission**: Required in `AndroidManifest.xml`.
3. **KSP not running**: Verify `id("com.google.devtools.ksp")` plugin and `ksp(...)` dependency.
4. **Generated adapter naming**: `{ClassName}ResolveKitAdapter` -- no underscore prefix.
5. **ProGuard crash in release**: Rules are mandatory. Without them, release builds crash with missing class errors.
6. **Compose BOM version**: Requires BOM `2024.02.00` or later.
7. **Context requirement**: `ResolveKitRuntime` constructor requires a valid `Context` (use `applicationContext`).
8. **Configuration immutability**: Must create new `ResolveKitConfiguration` + `ResolveKitRuntime` to change settings. Use `refreshSessionContext()` for dynamic updates.
9. **API key format**: Must start with `iaa_` prefix.
10. **Function names**: Must be `snake_case` for LLM compatibility.
11. **MaterialTheme wrapping**: `ResolveKitChatView` must be inside `MaterialTheme`.
