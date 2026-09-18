# HajiCare — Project Context

## 1. Project Overview

**Project name:** HajiCare

**Platform:** Flutter Android application

**Main purpose:** Accessibility-first application for Hajj/Umrah pilgrims, especially elderly and disabled users.

HajiCare focuses on:

* Jamaah and Pendamping roles
* Admin management
* Room-based companion/group management
* Navigation and important locations
* Companion tracking
* SOS / emergency assistance
* Safe-radius monitoring
* Facilities such as toilet and wudhu
* Hotel, restaurant, and oleh-oleh locations
* Prayer information
* Saudi Riyal money recognition
* Text-to-speech
* Text-to-sign / accessible communication
* Multi-language support
* Accessibility settings such as text size
* Light/dark theme
* Real-time notifications

The application was initially designed/prototyped using Google Stitch and is now being continued/refactored in Antigravity.

---

# 2. Current Product Concept

HajiCare has three primary roles:

1. **Jamaah**
2. **Pendamping**
3. **Admin**

The application uses a **room-based relationship** between Jamaah and Pendamping.

A Room represents a managed group of pilgrims.

A Room may be created by:

* Admin
* Pendamping

A Room has:

* unique room code
* optional QR code
* one active Pendamping
* multiple Jamaah
* room configuration such as safe radius
* room-specific notifications
* room-specific monitoring
* room-specific SOS context

---

# 3. IMPORTANT USER FLOW — CURRENT VERSION

The old flow required users to join a Room before accessing most application features.

**This is NO LONGER the desired behavior.**

The current flow is:

```text
LOGIN
  ↓
Choose Role
  ├── Jamaah
  ├── Pendamping
  └── Admin
```

## Jamaah

```text
Jamaah
  ↓
Dashboard Basic
  ↓
room?
 ├── NO
 │    ├── Use basic features
 │    ├── Join Room manually
 │    └── Wait for Pendamping invitation
 │
 └── YES
      ↓
   Full Room Features
```

Jamaah does **NOT** need a Room to use basic application functionality.

Basic features may include:

* Dashboard
* Prayer schedule
* Basic map
* Profile
* Settings
* Language
* Theme
* Text size
* Saudi Riyal money recognition
* Manasik/guidance
* Other features that do not require a Room

Room-dependent features remain visible but locked.

Example:

```text
SOS Darurat 🔒

Fitur SOS aktif setelah Anda bergabung
dengan Room.

[ Gabung Room untuk Mengaktifkan ]
```

Do NOT hide room-dependent features completely.

---

# 4. JEMAAH ROOM ENTRY — TWO METHODS

A Jamaah can enter a Room through **two different mechanisms**.

## Method A — Join Manually

```text
Jamaah
  ↓
Gabung Room
  ↓
Input 6-character Room Code
OR
Scan QR Code
  ↓
Validate Room
  ↓
Join Room
  ↓
activeRoomId updated
  ↓
Room features unlocked
```

If the existing architecture uses direct joining, preserve it.

Do not introduce unnecessary approval steps unless required by the current implementation.

---

## Method B — Pendamping Invitation

```text
Pendamping
  ↓
Undang Jamaah
  ↓
Invitation created
  ↓
Notification sent
  ↓
Jamaah receives invitation
  ↓
Accept / Reject
```

If Jamaah accepts:

```text
Accept
  ↓
Validate invitation
  ↓
Add Jamaah to Room
  ↓
Update activeRoomId
  ↓
Update invitation status
  ↓
Room features unlocked
```

If Jamaah rejects:

```text
Reject
  ↓
Invitation status = rejected
  ↓
Jamaah remains outside Room
```

Jamaah must never be silently added to a Room through an invitation.

The invitation requires explicit user acceptance.

---

# 5. ROLE LOCKING

When a user first registers/logs in:

```text
Google Login
    ↓
Does Firestore user document already contain role?
    ├── NO → Show role selection
    └── YES → Use existing role
```

Available roles:

```text
jamaah
pendamping
admin
```

For normal users:

* Jamaah/Pendamping role is selected once.
* User cannot change role manually.
* Firestore is the source of truth.
* Local cache may be used for startup optimization.
* Local cache must not override Firestore authority.

Do not create logic that allows one account to simultaneously behave as Jamaah and Pendamping.

Admin role must be controlled through secure backend/database permissions and must not be freely selectable by normal users.

---

# 6. ROOM CONSTRAINTS

## One Room per User

A normal user may have only one active Room.

### Jamaah

```text
activeRoomId == null
    → Can join Room

activeRoomId != null
    → Cannot join another Room
```

### Pendamping

```text
activeRoomId == null
    → Can create/join Room

activeRoomId != null
    → Cannot create/join another active Room
```

Validate this both:

* client-side for UX
* server-side / Firestore Security Rules for security

---

# 7. ROOM CREATION

## Pendamping

Pendamping without a Room can:

```text
Buat Room
OR
Gabung Room
```

These must be presented as two explicit actions.

### Create Room

System automatically generates:

* unique 6-character alphanumeric code
* Room ID
* QR code

Example:

```text
HJC982
```

Pendamping becomes the Room's active Pendamping.

Do not require users to manually invent Room codes.

---

# 8. ONE PENDAMPING PER ROOM

A Room may have only one active Pendamping.

If a Room already has an active Pendamping:

* another Pendamping cannot simply overwrite the existing Pendamping
* existing Pendamping ownership must remain intact
* transfer/handover should be an administrative operation if required

Do not silently replace a Room's Pendamping.

---

# 9. ROOM MEMBER MANAGEMENT

## Pendamping Can Remove Jamaah

The current governance rule is:

* Jamaah cannot freely leave a Room by themselves.
* Pendamping can remove Jamaah from their own Room.
* Admin can remove Jamaah according to admin permissions.

Flow:

```text
Pendamping
  ↓
Room
  ↓
Daftar Jamaah
  ↓
Pilih Jamaah
  ↓
Detail / Action
  ↓
Keluarkan dari Room
  ↓
Confirmation Dialog
  ↓
Remove Member
```

When removed:

1. Remove Jamaah from Room membership.
2. Set Jamaah `activeRoomId = null`.
3. Update relevant reactive state.
4. Send notification to the Jamaah.
5. Record who performed the action.
6. Record timestamp.
7. Room-specific features become locked again.

Notification example:

```text
Title:
Anda dikeluarkan dari Room

Message:
Anda telah dikeluarkan dari Room "HJC982"
oleh Pendamping Ahmad.
```

Notification type:

```text
room_removed
```

Do not silently remove the Jamaah.

---

# 10. ROOM EXIT GOVERNANCE

Jamaah should not have a simple unrestricted:

```text
Keluar Room
```

button that immediately removes their monitoring relationship.

If a future requirement needs Jamaah to leave voluntarily, use a controlled process such as:

* leave request
* admin approval
* Pendamping approval

Do not bypass Room governance.

Pendamping should also not have an unrestricted destructive action to delete an active Room if doing so would orphan its Jamaah.

---

# 11. PENDAMPING INVITATION SYSTEM

Pendamping can invite Jamaah.

Current invitation mechanism:

```text
Pendamping
  ↓
Undang Jamaah
  ↓
Enter/search registered Jamaah
  ↓
Validate:
  - account exists
  - role == Jamaah
  - Jamaah is not already in another Room
  ↓
Create invitation
  ↓
Create notification
```

Invitation statuses:

```text
pending
accepted
rejected
expired
```

When accepted:

* Jamaah becomes Room member
* `users/{uid}.activeRoomId` is updated
* invitation becomes `accepted`
* UI updates immediately

No hot reload or application restart should be required.

---

# 12. NOTIFICATION SYSTEM

Notifications are a first-class HajiCare feature.

There are two categories:

## A. System/Event Notifications

Examples:

* Room invitation
* Jamaah removed from Room
* SOS
* system updates

## B. User-created Announcements

Admin and Pendamping can create notifications according to their permissions.

---

# 13. ADMIN NOTIFICATION PERMISSIONS

Admin can send notifications to:

### Global

All appropriate users.

```text
scope = global
```

### Maktab

Users belonging to a specific Maktab.

```text
scope = maktab
```

### Kloter

Users belonging to a specific Kloter.

```text
scope = kloter
```

### Room

Members of a specific Room.

```text
scope = room
```

### Specific User

One specific user.

```text
scope = user
```

Admin notification flow:

```text
Admin
  ↓
Buat Notifikasi
  ↓
Select Scope
  ├── Global
  ├── Maktab
  ├── Kloter
  ├── Room
  └── User
  ↓
Compose title/message
  ↓
Preview
  ↓
Send
```

Admin permissions must be enforced by Firestore Security Rules/backend logic.

---

# 14. PENDAMPING NOTIFICATION PERMISSIONS

Pendamping can only send notifications within their own Room.

Allowed:

```text
Semua Jamaah di Room
```

or:

```text
Jamaah tertentu di Room
```

Example:

```text
Pendamping
  ↓
Buat Notifikasi
  ↓
Target
  ├── Semua Jamaah Room
  └── Jamaah tertentu
  ↓
Judul + Pesan
  ↓
Send
```

Pendamping must NOT be able to:

* send global notifications
* send notifications to another Room
* send notifications to users outside their Room
* select another Pendamping's Room

Room ownership must be validated server-side.

The Pendamping's Room should be determined from authenticated user state, not manually trusted from arbitrary client input.

---

# 15. NOTIFICATION DATA MODEL

Reuse the existing notification infrastructure.

Conceptual structure:

```text
notifications
├── id
├── type
├── title
├── message
├── senderId
├── senderRole
├── senderName
├── scope
├── targetUserId
├── targetRoomId
├── targetMaktab
├── targetKloter
├── relatedId
├── isRead
└── createdAt
```

Possible notification types:

```text
room_invitation
room_removed
announcement
system
sos
```

Possible scopes:

```text
global
maktab
kloter
room
user
```

Adapt these fields to the existing Firestore architecture instead of blindly creating duplicate structures.

---

# 16. NOTIFICATION UI

Notification screen should support:

* unread/read state
* invitation cards
* system notifications
* room notifications
* removal notifications
* SOS notifications
* announcements

Invitation notifications must provide:

```text
Terima
Tolak
```

Normal informational notifications do not need Accept/Reject.

Notification creation UI should be available according to role.

### Admin

Can access notification management with all allowed scopes.

### Pendamping

Can access notification management limited to their own Room.

### Jamaah

Can receive notifications but cannot broadcast notifications.

---

# 17. SOS

SOS is a Room-dependent safety feature.

Without Room:

```text
SOS 🔒
```

The user receives an explanation that a Room is required because SOS must have a valid monitoring/response relationship.

With Room:

```text
Jamaah
  ↓
SOS
  ↓
Confirmation
  ↓
Create SOS Event
  ↓
Pendamping + Admin
```

SOS should automatically be recorded for Admin visibility.

SOS statuses:

```text
baru
direspons
selesai
eskalasi
```

Important:

Do not make SOS dependent exclusively on one Pendamping.

Admin should always be able to see active SOS events.

---

# 18. SAFE RADIUS

Safe radius belongs to the Room.

Conceptually:

```text
rooms/{roomId}
    safeRadius
```

Pendamping can configure the Room's safe radius.

Input must support manual numeric values.

Example:

```text
500 meter
```

Validation:

* numeric
* positive
* reasonable maximum
* cannot be empty

Changes must synchronize through Firestore realtime listeners.

When updated:

* Pendamping UI updates immediately.
* Jamaah UI updates immediately.
* No hot reload.
* No restart.
* No page reopening.

---

# 19. LOCATION STATE

Never display absurd distance values when GPS is unavailable.

Bad:

```text
7858931 meter
```

Expected:

```text
Menunggu lokasi...
```

or another clear unavailable-location state.

Location state must distinguish:

```text
loading
available
unavailable
permission denied
error
```

Do not interpret an invalid/default coordinate as a real location.

---

# 20. CURRENT IMPLEMENTATION STATUS

The latest room/access revamp has already implemented the following concepts:

### Role

* Permanent role selection
* Firestore user role
* Google authentication flow
* Role-aware navigation

### Room access

* Basic dashboard available without Room
* Locked room-specific features
* Pendamping Create Room
* Pendamping Join Room
* Jamaah Join Room
* 6-character Room code
* QR preview
* One Room per user
* One Pendamping per Room

### Invitation

* Pendamping can invite Jamaah
* Invitation stored in Firestore
* Notification generated
* Jamaah can Accept/Reject
* Accepted invitation updates Room membership
* Accepted invitation updates `activeRoomId`

### Room management

* Safe radius stored in Room
* Realtime safe radius synchronization
* GPS unavailable state displays friendly text
* Jamaah cannot freely leave Room
* Pendamping/Admin can remove Jamaah
* Removal generates notification

### Notifications

* In-app notification infrastructure
* Room invitation notification
* Room removal notification
* Admin notification management
* Pendamping room-scoped notification management
* Notification read/unread state

Do not recreate these systems if they already exist. Inspect and extend them.

---

# 21. GLOBAL APPLICATION ARCHITECTURE

The application must use exactly one application-level Material/GetX root.

Preferred:

```dart
GetMaterialApp(...)
```

Responsibilities:

* Theme
* Dark mode
* Locale
* Translations
* Navigation
* Material localization
* Global settings
* Global defaults

Do NOT create nested `MaterialApp` instances inside pages.

Expected structure:

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
   Material widgets
```

---

# 22. GETX ARCHITECTURE

GetX is the primary state-management and navigation solution.

Use:

```dart
GetMaterialApp
GetxController
Rx
RxBool
RxString
RxInt
RxDouble
RxList
Obx
Get.to
Get.back
Get.off
Get.offAll
Get.snackbar
```

Use Bindings/dependency injection where appropriate.

Avoid unnecessary:

```text
setState
StatefulWidget
BuildContext navigation
duplicated local state
controller logic inside widgets
```

Prefer:

```dart
class ExamplePage extends GetView<ExampleController> {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Text(controller.title.value),
    );
  }
}
```

But do NOT wrap every widget in `Obx`.

Only use reactive rebuilding when the widget actually depends on Rx state.

---

# 23. GLOBAL APP SETTINGS

Use one focused:

```text
AppSettingsController
```

Responsibilities:

```text
AppSettingsController
├── locale
├── themeMode
└── textScale
```

Do not turn this controller into a giant global controller.

Persist settings locally.

If SharedPreferences is already used, reuse it.

---

# 24. LANGUAGE

Supported:

```text
Indonesian → id
Javanese → jv
Sundanese → su
English → en
```

Default:

```text
id
```

Localization is GLOBAL.

Language selected in onboarding must affect the entire application.

Language selected from Profile/Settings must immediately affect the entire application.

Persist the selected language.

Every user-facing string should use translation keys.

Avoid:

```dart
locale == 'id'
    ? 'Beranda'
    : 'Home'
```

Prefer the project's GetX translation mechanism:

```dart
'home'.tr
```

Audit:

* buttons
* labels
* dialogs
* snackbars
* errors
* empty states
* tooltips
* accessibility labels
* onboarding
* profile
* settings
* bottom navigation
* room
* invitations
* notifications
* SOS
* dashboards

---

# 25. MATERIAL LOCALIZATION

The previous application encountered:

```text
No MaterialLocalizations found
```

This must be solved at the application root.

Check for:

* nested MaterialApp
* incorrect GetMaterialApp placement
* widgets mounted outside Material root
* broken localization configuration

Do NOT solve this by wrapping individual TextFields with random localization widgets.

The root application must correctly provide Material localization globally.

---

# 26. GLOBAL DARK MODE

Supported:

```text
System
Light
Dark
```

Default:

```text
System
```

Dark mode must work across:

* onboarding
* login/register
* dashboards
* maps
* room
* companion
* SOS
* facilities
* prayer
* money recognition
* communication
* notifications
* profile
* settings
* dialogs
* bottom sheets
* forms
* navigation
* empty states
* error states

Use:

```dart
theme: AppTheme.light,
darkTheme: AppTheme.dark,
themeMode: controller.themeMode.value,
```

Theme must update immediately.

Persist the choice.

Use semantic centralized theme colors rather than manually checking dark mode everywhere.

---

# 27. ACCESSIBILITY / TEXT SIZE

Text size is a global application setting.

Suggested levels:

```text
Small
Normal
Large
Extra Large
```

Suggested scale:

```text
0.90
1.00
1.15
1.30
```

These values are guidelines and must be tested against the actual UI.

When text becomes larger:

* buttons should expand
* text should wrap
* cards should adapt
* dialogs should remain usable
* bottom sheets should remain usable
* rows should use Flexible/Expanded appropriately
* important text should not be unnecessarily truncated
* scrolling should be used where appropriate

Do NOT solve accessibility overflow by simply reducing text size again.

---

# 28. UI DESIGN PRINCIPLES

HajiCare should feel:

* clean
* calm
* modern
* accessible
* professional
* spacious
* easy to understand
* not cluttered

Target users include elderly and disabled pilgrims.

Therefore prioritize:

* readable typography
* strong contrast
* large touch targets
* clear hierarchy
* predictable interaction
* consistent spacing
* minimal cognitive load

Avoid excessive decorative UI.

---

# 29. SPACING

Use a consistent spacing system.

Suggested:

```text
4
8
12
16
20
24
32
```

Spacing should follow hierarchy.

Avoid:

* random margins everywhere
* cramped components
* excessive empty space
* inconsistent card padding
* misaligned icons/text

---

# 30. ANIMATION

Animations should be subtle and calm.

Prefer:

* fade
* small slide
* gentle scale
* AnimatedContainer
* AnimatedSwitcher
* subtle transitions

Typical interaction duration:

```text
150–300 ms
```

Avoid:

* aggressive bounce
* excessive movement
* flashing
* rapid animations
* unnecessary animation on every component
* animations that delay important actions

If practical, respect reduced-motion preferences.

---

# 31. FIREBASE ARCHITECTURE

Prefer:

```text
UI
 ↓
GetX Controller
 ↓
Repository / Service
 ↓
Firebase
```

Do not put complex Firebase operations directly inside widgets.

Firebase Security Rules are part of the security boundary.

Client-side checks are for UX only and must not be treated as sufficient security.

Important security-sensitive operations:

* role permissions
* Room membership
* Room ownership
* Pendamping assignment
* invitation acceptance
* member removal
* notifications
* SOS
* safe radius

must be validated server-side through appropriate Firestore Rules/backend mechanisms.

---

# 32. CODING STANDARDS

Prefer:

* small focused classes
* reusable widgets
* single responsibility
* readable code
* clear naming
* centralized constants
* centralized theme
* centralized translations
* focused controllers
* repository/service separation
* reusable notification infrastructure

Avoid:

* giant controllers
* giant widgets
* duplicate services
* duplicate notification systems
* duplicate Room state
* Firebase calls directly from UI
* unnecessary packages
* unnecessary abstraction
* excessive `Get.find()`
* excessive `Obx`
* nested MaterialApp

---

# 33. REACTIVE STATE REQUIREMENT

This is especially important for Room and notification features.

After any successful mutation:

* add Jamaah
* remove Jamaah
* accept invitation
* reject invitation
* change safe radius
* create Room
* join Room
* send notification
* mark notification read

the UI must update without:

* hot reload
* application restart
* leaving/re-entering the page
* manually reopening the screen

Use GetX reactive state and Firestore realtime listeners where appropriate.

Maintain one clear source of truth for Room state.

---

# 34. CURRENT FIRESTORE CONCEPT

Existing architecture may contain collections such as:

```text
users
rooms
invitations
notifications
sos_events
```

Conceptual Room:

```text
rooms/{roomId}

id
uniqueCode
createdBy
createdByRole
pendampingId
maktab
kloter
safeRadius
status
createdAt
```

Room members may use:

```text
rooms/{roomId}/members/{userId}
```

User:

```text
users/{uid}

id
role
displayName
email
activeRoomId
createdAt
```

Invitation:

```text
invitations/{invitationId}

id
roomId
fromUserId
toUserId
status
createdAt
respondedAt
```

Notification:

```text
notifications/{notificationId}

id
type
title
message
senderId
senderRole
senderName
scope
targetUserId
targetRoomId
targetMaktab
targetKloter
relatedId
isRead
createdAt
```

SOS:

```text
sos_events/{sosId}

id
jamaahId
roomId
location
status
createdAt
respondedBy
respondedAt
resolvedAt
```

These are conceptual models. Always inspect the actual project before modifying schemas.

---

# 35. ADMIN ROLE

Admin has the highest operational scope.

Admin may manage:

* Rooms
* Room members
* SOS monitoring
* Room history
* Notifications
* Global announcements
* Maktab announcements
* Kloter announcements
* Room announcements
* User-specific announcements
* Other administrative features already present

Admin UI should not be constrained by normal Room membership.

Admin permissions must be enforced securely.

---

# 36. ADMIN NOTIFICATION FLOW

Admin notification composer:

```text
Buat Notifikasi

Target:
○ Global
○ Maktab
○ Kloter
○ Room
○ User tertentu

Judul
[________________]

Pesan
[________________]

[ Preview ] [ Kirim ]
```

The target selector should change dynamically based on selected scope.

Example:

```text
Room
→ select/search Room
```

```text
User
→ search/select User
```

Do not expose unauthorized target choices to Pendamping.

---

# 37. PENDAMPING NOTIFICATION FLOW

Pendamping notification composer:

```text
Buat Notifikasi

Target:
○ Semua Jamaah di Room
○ Jamaah tertentu

Judul
[________________]

Pesan
[________________]

[ Preview ] [ Kirim ]
```

The Room should automatically come from the Pendamping's active Room.

Do not allow manual arbitrary Room IDs.

---

# 38. REFACTOR STRATEGY

Do not blindly rewrite the entire project.

Before changing code:

1. Inspect existing project structure.
2. Identify application root.
3. Find all MaterialApp/GetMaterialApp instances.
4. Find existing GetX controllers.
5. Find current localization implementation.
6. Find current theme implementation.
7. Find onboarding language implementation.
8. Find current Room architecture.
9. Find invitation architecture.
10. Find notification architecture.
11. Find SOS architecture.
12. Find Firebase repositories/services.
13. Find Firestore Security Rules.
14. Find all relevant StatefulWidgets/setState.
15. Find hardcoded strings.
16. Find duplicated state.

Then create a migration plan.

Reuse existing functionality whenever possible.

Do not recreate working services merely to match a new folder structure.

---

# 39. TESTING PRIORITIES

Test these flows manually:

## Authentication

```text
New user
→ Google login
→ Role selection
→ Role persisted
```

## Jamaah without Room

```text
Login
→ Dashboard
→ Basic features accessible
→ Room-specific features locked
```

## Jamaah manual Join

```text
Join Room
→ Code/QR
→ Join
→ Room features unlock
```

## Jamaah invitation

```text
Pendamping invites
→ Jamaah notification
→ Accept
→ Member added
→ Room features unlock
```

## Reject invitation

```text
Invitation
→ Reject
→ Remains outside Room
```

## Remove Jamaah

```text
Pendamping
→ Member
→ Remove
→ Confirm
→ Jamaah removed
→ activeRoomId null
→ Notification sent
→ Jamaah features locked
```

## Notifications

Admin:

```text
Global
Maktab
Kloter
Room
User
```

Pendamping:

```text
Room
Specific Jamaah
```

## Safe Radius

```text
Change radius
→ Firebase
→ realtime update
→ no hot reload
```

## SOS

```text
No Room
→ SOS locked

Room exists
→ SOS active
→ Pendamping + Admin receive event
```

---

# 40. DEFINITION OF DONE

## Authentication

* [ ] Role is permanently assigned.
* [ ] Role cannot be changed by normal user.
* [ ] Firestore is source of truth.

## Room

* [ ] Users can access basic features without Room.
* [ ] Room-specific features are locked when no Room exists.
* [ ] Jamaah can manually join.
* [ ] Jamaah can accept Pendamping invitation.
* [ ] Pendamping can create Room.
* [ ] Pendamping can join Room.
* [ ] One active Room per user.
* [ ] One active Pendamping per Room.
* [ ] QR code available where appropriate.
* [ ] Pendamping can remove Jamaah.
* [ ] Admin can manage members according to permissions.
* [ ] Removal generates notification.
* [ ] Jamaah cannot freely leave Room.

## Notifications

* [ ] Invitation notifications work.
* [ ] Removal notifications work.
* [ ] System notifications work.
* [ ] Admin can send Global notifications.
* [ ] Admin can target Maktab.
* [ ] Admin can target Kloter.
* [ ] Admin can target Room.
* [ ] Admin can target specific User.
* [ ] Pendamping can notify their Room.
* [ ] Pendamping can notify specific Jamaah in their Room.
* [ ] Pendamping cannot target users outside their Room.
* [ ] Read/unread state works.
* [ ] Notifications update realtime where appropriate.

## SOS

* [ ] SOS locked without Room.
* [ ] SOS active with Room.
* [ ] Admin always receives/has visibility of SOS events.
* [ ] Status tracking works.

## Safe Radius

* [ ] Manual radius input works.
* [ ] Firebase persistence works.
* [ ] Realtime synchronization works.
* [ ] No invalid distance shown when GPS unavailable.

## Localization

* [ ] Indonesian
* [ ] Javanese
* [ ] Sundanese
* [ ] English
* [ ] Default Indonesian
* [ ] Onboarding changes global locale
* [ ] Profile changes global locale
* [ ] Locale persists
* [ ] No unnecessary hardcoded user-facing text

## Theme

* [ ] System
* [ ] Light
* [ ] Dark
* [ ] Onboarding
* [ ] Authentication
* [ ] All application pages
* [ ] Immediate switching
* [ ] Persistence

## Accessibility

* [ ] Text scaling works globally.
* [ ] Larger text does not cause avoidable overflow.
* [ ] Touch targets are accessible.
* [ ] Contrast remains clear in dark mode.
* [ ] Dialogs remain usable.
* [ ] Bottom sheets remain usable.
* [ ] Important information is not unnecessarily truncated.

## Architecture

* [ ] Exactly one GetMaterialApp root.
* [ ] No nested MaterialApp.
* [ ] MaterialLocalizations works globally.
* [ ] GetX is the primary state-management solution.
* [ ] No unnecessary StatefulWidget.
* [ ] No unnecessary setState.
* [ ] Controllers remain focused.
* [ ] UI does not contain complex business logic.
* [ ] Firebase logic is separated from presentation.

## Quality

* [ ] `flutter analyze` passes.
* [ ] Existing tests pass if present.
* [ ] Android build succeeds.
* [ ] Main flows manually tested.
* [ ] No major runtime exceptions.
* [ ] No feature requires hot reload/restart to update normal state changes.

---

# 41. ANTIGRAVITY WORKING RULE

Before modifying code:

**Inspect first. Implement second.**

Do not guess the existing architecture.

Do not invent duplicate:

* controllers
* services
* repositories
* notification systems
* Room state
* Firebase collections

Reuse existing implementation whenever possible.

When requirements conflict with old code, follow this Project Context as the current source of product requirements.

When an implementation decision is unclear:

1. Prefer the existing architecture.
2. Prefer the simplest maintainable solution.
3. Preserve existing functionality.
4. Prioritize accessibility.
5. Prioritize data/security integrity.
6. Avoid unnecessary refactoring.

Priority:

```text
Correctness
    ↓
Security
    ↓
Accessibility
    ↓
Consistency
    ↓
Maintainability
    ↓
Visual polish
```

The final HajiCare application should feel like **one coherent application**, not a collection of unrelated screens or independently implemented features.
