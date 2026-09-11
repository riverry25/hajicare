# HajiCare — Project Context

## 1. Project Overview

**Project name:** HajiCare  
**Platform:** Flutter Android application  
**Main purpose:** Accessibility-first application for Hajj/Umrah pilgrims, especially elderly and disabled users.

HajiCare focuses on:
- Jamaah and Pendamping roles
- Navigation and important locations
- Companion tracking
- SOS / emergency assistance
- Facilities such as toilet and wudhu
- Hotel, restaurant, and oleh-oleh locations
- Prayer information
- Saudi Riyal money recognition
- Accessible communication
- Multi-language support
- Accessibility settings such as text size
- Light/dark theme

The current application was initially designed/prototyped using Google Stitch and is now being continued/refactored in Antigravity.

---

## 2. Current Development State

The UI/prototype already exists, but several parts need architectural and functional cleanup.

### Important current problems

1. Multi-language feature is not working consistently.
   - Language selection may appear on onboarding but does not reliably propagate to the entire application.
   - Language changes from Profile are not reliably applied.
   - Some pages still contain hardcoded strings.
   - The application must behave as **one globally localized application**, not as separate localized pages.

2. Dark mode is not global.
   - Dark mode must work from onboarding through every page.
   - Theme changes must be dynamic/reactive.
   - Default theme must follow the device system theme.
   - User should be able to change theme from Profile/Settings.
   - Theme choice should persist locally.

3. A `MaterialLocalizations` runtime error is currently visible:
   - `No MaterialLocalizations found`
   - A `TextField` cannot find a `MaterialLocalizations` ancestor.
   - The root application architecture must be fixed so Material localization is available globally.

4. State management is inconsistent.
   - The project should be refactored to use **GetX consistently**.
   - Avoid unnecessary `StatefulWidget`.
   - Prefer `StatelessWidget + GetX reactive state`.
   - Use `Obx` only where reactive rebuilding is actually needed.
   - Controllers should own state and business/UI logic.
   - Widgets should focus on presentation.

5. UI spacing and accessibility still need refinement.
   - Some components feel too tight/cluttered.
   - Text placement/padding is sometimes awkward.
   - Text scaling must not break layouts.
   - Animations should be subtle and calm because elderly/disabled users are a major target.

---

## 3. Required Global Application Architecture

The application must use a single global application root.

Preferred root:

```dart
GetMaterialApp(
  ...
)
```

Do not create separate `MaterialApp` instances inside individual pages.

There must be exactly one application-level Material/GetX root responsible for:
- Theme
- Dark mode
- Locale
- Translations
- Navigation
- Global defaults
- Material localization
- Global settings

Recommended conceptual structure:

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── routes/
│   ├── theme/
│   ├── localization/
│   └── bindings/
├── core/
│   ├── constants/
│   ├── helpers/
│   ├── services/
│   ├── utils/
│   └── widgets/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
├── features/
│   ├── onboarding/
│   ├── auth/
│   ├── home/
│   ├── navigation/
│   ├── companion/
│   ├── emergency/
│   ├── facilities/
│   ├── prayer/
│   ├── money_recognition/
│   ├── communication/
│   ├── profile/
│   └── settings/
└── ...
```

Adapt this structure to the existing project. Do not blindly recreate files or duplicate existing functionality.

---

## 4. GetX Architecture Rules

GetX is the primary state-management and navigation solution.

Use:

```dart
GetMaterialApp
```

for the application root.

Use:
- `GetxController`
- `Rx`
- `RxBool`
- `RxString`
- `RxInt`
- `RxDouble`
- `RxList`
- `Obx`
- `Get.to`
- `Get.back`
- `Get.off`
- `Get.offAll`
- `Get.snackbar`
- GetX bindings/dependency injection where useful

Avoid unnecessary:
- `setState`
- `StatefulWidget`
- `BuildContext` for navigation
- local duplicated state
- controller logic inside widgets

### Important

Do NOT blindly convert every widget into `Obx`.

Reactive widgets should only use `Obx` when they depend on Rx state.

Prefer:

```dart
class ExamplePage extends GetView<ExampleController> {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Text(controller.title.value));
  }
}
```

For pages without reactive state:

```dart
class ExamplePage extends StatelessWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    ...
  }
}
```

Use `GetView<T>` when it improves readability.

---

## 5. Global App Settings Controller

Create one focused global controller for settings that affect the entire application.

Example responsibility:

```text
AppSettingsController
├── locale
├── themeMode
└── textScale
```

Do not turn this into a giant controller containing unrelated application logic.

The controller should manage:

### Language

Supported languages:

1. Indonesian — `id`
2. Javanese — `jv`
3. Sundanese — `su`
4. English — `en`

Default:

```text
id
```

### Theme

Supported modes:

```text
System
Light
Dark
```

Default:

```text
System
```

### Text size

Suggested levels:

```text
Small
Normal
Large
Extra Large
```

Example scale factors:

```text
0.90
1.00
1.15
1.30
```

These values are examples and should be tested against the real UI.

All settings should be persisted locally.

If the project already uses SharedPreferences, reuse it instead of adding another persistence package.

---

## 6. Localization Architecture

Localization must be GLOBAL.

Do not localize individual pages independently.

Use GetX translations if GetX is already the chosen architecture.

Conceptually:

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'id_ID': {...},
    'jv_ID': {...},
    'su_ID': {...},
    'en_US': {...},
  };
}
```

The exact locale codes can be adapted to the implementation, but all four languages must exist.

### Rules

- Default language: Indonesian.
- Onboarding language selection changes the global application locale.
- Profile language setting changes the global application locale.
- Change should be reactive and immediate.
- Restarting the application should preserve the selected language.
- Every user-facing string must use translation keys.
- No hardcoded visible text should remain unless it is intentionally non-translatable.
- Do not use conditions such as:

```dart
locale == 'id' ? 'Beranda' : 'Home'
```

inside pages.

Use:

```dart
'home'.tr
```

or the project's established GetX translation helper.

### Required translation audit

Search the entire `lib/` directory for:
- `Text('...')`
- `Text("...")`
- `labelText`
- `hintText`
- `title`
- `tooltip`
- snackbar messages
- dialogs
- buttons
- empty states
- validation messages
- accessibility labels
- onboarding text
- profile/settings text
- bottom navigation labels
- error messages

Convert them into translation keys.

---

## 7. Fix MaterialLocalizations Error

The current error indicates that a `TextField` is being rendered without a valid Material localization ancestor.

The application must be checked for:
- nested `MaterialApp`
- custom root widgets that bypass `MaterialApp`
- incorrect GetMaterialApp placement
- widgets mounted outside the application root
- localization configuration that breaks Material localization

The expected architecture is:

```text
runApp()
   ↓
GetMaterialApp
   ├── translations
   ├── locale
   ├── fallbackLocale
   ├── theme
   ├── darkTheme
   └── initialRoute
        ↓
      Pages
        ↓
      TextField / Material widgets
```

Do not fix this by adding random `MaterialLocalizations` widgets around individual TextFields.

Fix the root architecture.

Verify the error disappears from all relevant flows.

---

## 8. Global Dark Mode

Dark mode must work across the ENTIRE app.

It must include:
- onboarding
- authentication
- home
- maps/navigation
- companion
- emergency/SOS
- facilities
- prayer
- money recognition
- communication
- profile
- settings
- dialogs
- bottom sheets
- cards
- forms
- buttons
- navigation bars
- empty/error states

Use:

```dart
theme: AppTheme.light
darkTheme: AppTheme.dark
themeMode: controller.themeMode.value
```

Do not manually check dark mode on every page unless absolutely necessary.

Use semantic theme colors from the centralized theme.

Avoid simply inverting colors.

Test:
- system light
- system dark
- explicit light
- explicit dark

Theme changes must update dynamically without restarting the app.

---

## 9. Onboarding Must Use Global Settings

Onboarding is part of the same application.

If the user chooses a language during onboarding:
- update the global locale
- save the selection
- all onboarding content should update
- after leaving onboarding, the rest of the application must use the same language

If dark mode is changed before leaving onboarding:
- the whole onboarding flow updates
- subsequent pages use the same theme

Do not implement onboarding as an isolated mini-application.

---

## 10. Profile / Settings

Profile should expose:

### Language

```text
Bahasa Indonesia
Basa Jawa
Basa Sunda
English
```

Use the currently selected language.

### Theme

Prefer:

```text
System
Light
Dark
```

If the existing design specifically requires a toggle, keep the toggle UI but ensure its implementation still uses the global GetX theme controller.

### Text Size

Provide:

```text
Small
Normal
Large
Extra Large
```

Changes should apply immediately.

---

## 11. Accessibility / Text Scaling

Text scaling is a core feature, not a page-specific feature.

Avoid:

```dart
fontSize: 14 * scale
```

being manually repeated across the application.

Centralize text sizing/theme behavior.

When text size increases:
- buttons should expand vertically if necessary
- cards should adapt
- rows should use Flexible/Expanded appropriately
- text should wrap
- bottom sheets should remain usable
- dialogs should remain usable
- navigation labels should not collide
- important text should not be hidden behind ellipsis
- scrolling should be used where appropriate

Do not solve overflow by simply reducing font size again.

Accessibility takes priority over maintaining a fixed compact layout.

---

## 12. UI Design Principles

The application should feel:

- clean
- spacious
- calm
- modern
- accessible
- professional
- easy to understand
- not crowded

### Spacing

Use a consistent spacing scale, for example:

```text
4
8
12
16
20
24
32
```

Do not make every component use maximum spacing.

Spacing must follow visual hierarchy.

Avoid:
- components touching each other
- excessive padding
- inconsistent gaps
- random margin values everywhere

### Text placement

Review:
- horizontal alignment
- vertical centering
- internal padding
- line height
- relationship between icon and text

Typical rule:
- page titles: left aligned
- list content: left aligned
- primary actions: centered where appropriate
- onboarding/hero content: centered when the design calls for it
- icons + labels: vertically centered

---

## 13. Animation

Animations should be subtle because elderly and disabled users are important target users.

Use:
- fade
- fade + small slide
- gentle scale
- AnimatedContainer
- AnimatedSwitcher
- subtle page transitions
- gentle button feedback

Prefer approximately:

```text
150–300 ms
```

for small interactions.

Avoid:
- aggressive bounce
- excessive scale
- rapid movement
- flashing
- unnecessary animation on every widget
- animation that delays important actions

If practical, respect reduced-motion preferences.

---

## 14. Firebase

Firebase is NOT the priority of this refactor phase unless required by existing code.

First stabilize:
1. architecture
2. GetX
3. theme
4. localization
5. accessibility
6. UI
7. navigation

After that, Firebase can be integrated through services/repositories without putting Firebase calls directly inside UI widgets.

Future architecture should allow:

```text
UI
 ↓
Controller
 ↓
Repository
 ↓
Firebase Service
```

---

## 15. Coding Standards

Prefer:
- small focused classes
- reusable widgets
- clear naming
- single responsibility
- readable code
- beginner-friendly structure
- centralized constants
- centralized theme
- centralized translations
- centralized settings

Avoid:
- giant controllers
- giant widgets
- duplicated UI code
- duplicated localization logic
- duplicated theme logic
- Firebase calls directly from widgets
- unnecessary abstraction layers
- unnecessary packages
- excessive `Get.find()` calls
- excessive `Obx`
- nested `MaterialApp`

---

## 16. Refactor Strategy

Do not blindly rewrite the entire project.

First:
1. Inspect the existing project.
2. Identify the current root application.
3. Identify all `MaterialApp`/`GetMaterialApp` instances.
4. Identify current GetX usage.
5. Identify current localization implementation.
6. Identify current theme implementation.
7. Identify current onboarding language implementation.
8. Identify all StatefulWidgets and `setState`.
9. Identify hardcoded strings.
10. Identify duplicated settings/state.
11. Identify UI overflow and spacing problems.

Then create a migration plan.

Implement in logical stages:
1. Root/GetMaterialApp
2. Global AppSettingsController
3. Localization
4. Theme
5. Text scaling
6. Onboarding integration
7. Profile integration
8. GetX controller cleanup
9. StatefulWidget reduction
10. UI/spacing/accessibility cleanup
11. Testing

After each major stage, run:

```bash
flutter analyze
```

and fix errors before continuing.

---

## 17. Definition of Done

The refactor is considered successful when:

### GetX
- [ ] GetMaterialApp is the single application root.
- [ ] Navigation uses GetX.
- [ ] Global settings use GetX.
- [ ] StatefulWidget is minimized where GetX can replace it.
- [ ] No unnecessary setState remains.
- [ ] Controllers are focused and readable.
- [ ] Obx is used only where reactive state is needed.

### Localization
- [ ] Indonesian works.
- [ ] Javanese works.
- [ ] Sundanese works.
- [ ] English works.
- [ ] Indonesian is the default.
- [ ] Onboarding language selection works.
- [ ] Profile language selection works.
- [ ] Language changes immediately.
- [ ] Language persists after restart.
- [ ] All pages use the selected language.
- [ ] No page behaves like an isolated localization system.

### Material
- [ ] `No MaterialLocalizations found` is fixed.
- [ ] TextField works normally.
- [ ] Dialogs, forms, date/time controls, and other Material widgets work normally.

### Theme
- [ ] System theme works.
- [ ] Light theme works.
- [ ] Dark theme works.
- [ ] Theme works on onboarding.
- [ ] Theme works on every page.
- [ ] Theme changes immediately.
- [ ] Theme persists.

### Accessibility
- [ ] Text size can be changed.
- [ ] Larger text does not create avoidable overflow.
- [ ] Buttons remain usable.
- [ ] Dialogs remain usable.
- [ ] Bottom sheets remain usable.
- [ ] Text remains readable.
- [ ] Touch targets are sufficiently large.

### UI
- [ ] Spacing feels breathable.
- [ ] No components feel unnecessarily cramped.
- [ ] Text alignment is intentional.
- [ ] Typography is consistent.
- [ ] Dark mode colors are coherent.
- [ ] Animations are subtle.

### Quality
- [ ] `flutter analyze` passes.
- [ ] Existing tests pass, if present.
- [ ] App runs on Android.
- [ ] Main flows have been manually tested.
- [ ] No duplicated MaterialApp.
- [ ] No major runtime exceptions during onboarding/navigation/profile flows.

---

## 18. Antigravity Working Rule

Before changing code, understand the existing implementation.

Do not invent files or APIs without checking the project.

Do not replace working features merely to make the architecture look different.

Preserve the current HajiCare visual identity and functionality while improving:
- architecture
- accessibility
- responsiveness
- localization
- theme
- state management
- maintainability

The final result should feel like **one coherent application**, not a collection of independent pages.

Priority order:

**Correctness → Accessibility → Consistency → Maintainability → Visual polish**
