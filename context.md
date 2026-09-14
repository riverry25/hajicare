# HajiCare — Room & Role Architecture Context

## 1. Purpose

Implement a production-ready **Room/Pantau system** that connects Admin, Pendamping, and Jamaah into isolated monitoring groups.

Core principle:

> Auth menentukan siapa pengguna. Role menentukan hak akses. Room menentukan kelompok monitoring. Membership menentukan siapa yang dapat saling melihat/berinteraksi.

Do not rebuild the project. Audit and extend the existing HajiCare architecture.

---

## 2. Current Roles

There are exactly 3 application roles:

- `admin`
- `pendamping`
- `jamaah`

The existing Firebase/Firestore user data already contains role-related and profile/location fields such as `role`, `name`, `displayName`, `email`, `currentLocation`, `distance`, `sosActive`, `separatedMode`, `shortLabel`, etc. Reuse the current user model where possible.

---

## 3. Target User Flow

### Admin

```text
Download app
→ Login
→ Admin Dashboard
→ Kelola Room
→ Create / Read / Update / Delete / Activate / Deactivate Room
→ View Room Members
→ See member name + role
```

Admin account already exists by default. No admin self-registration is required.

### Pendamping

```text
Download app
→ Register sebagai Pendamping
→ Login
→ Check activeRoomId
→ If null: Join Room Screen
→ Enter Nama Room + Kode Room
→ Validate Room
→ Join Room
→ Save activeRoomId
→ Dashboard Pendamping
→ Access all Pendamping features
```

Pendamping may also have a **Tambah Jamaah** feature for the active room.

### Jamaah

```text
Download app
→ Register sebagai Jamaah
→ Login
→ Check activeRoomId
→ If null: Join Room Screen
→ Enter Nama Room + Kode Room
→ Validate Room
→ Join Room
→ Save activeRoomId
→ Dashboard Jamaah
→ Access all Jamaah features
```

A user without a valid active room must not reach the role dashboard.

---

## 4. Room Concept

A Room is the main boundary for monitoring and interaction.

Example:

```text
Room: Maktab 48
Code: M48X7K

Pendamping A ─┐
Jamaah B ─────┤
Jamaah C ─────┼──> Room Maktab 48
Jamaah D ─────┘
```

Important:

- One user has **one activeRoomId** in the first implementation.
- Different users can belong to the same room.
- A user cannot join the same room twice.
- Room code must be unique.
- Inactive rooms cannot receive new members.
- Room membership controls which users a Pendamping can monitor.
- Map/monitoring data must be scoped to the active room, not the global `users` collection.

---

## 5. Recommended Firestore Structure

### Users

```text
users/{uid}
{
  role: "admin" | "pendamping" | "jamaah",
  name: string,
  email: string,
  activeRoomId: string | null
}
```

Keep existing user fields in place. Add `activeRoomId` without removing existing application data.

### Rooms

```text
rooms/{roomId}
{
  name: string,
  code: string,
  createdBy: string,
  createdAt: timestamp,
  isActive: boolean
}
```

### Room Members

Use a subcollection instead of embedding all members into the room document:

```text
rooms/{roomId}/members/{uid}
{
  uid: string,
  name: string,
  role: "pendamping" | "jamaah",
  joinedAt: timestamp
}
```

Do not create a second independent user database. `members/{uid}` is a room membership index/snapshot, while the canonical profile remains `users/{uid}`.

---

## 6. Access Rules

### Admin

Can:

- Create room
- View rooms
- Edit room name/status
- Activate/deactivate room
- Delete room according to safe project policy
- View members
- See member role

### Pendamping

Can:

- Join a room
- View own active room
- View members of own active room
- Manage/add Jamaah in own active room, subject to final security rule design
- Access Pendamping dashboard only after valid room membership

Cannot:

- CRUD arbitrary rooms
- Access another Pendamping's room
- Change own role
- Move arbitrary users between rooms

### Jamaah

Can:

- Join a room
- View own active room
- Use Jamaah features

Cannot:

- CRUD rooms
- Manage room members
- Change own role
- Access other rooms' members

---

## 7. Authentication + Route Guard

Target navigation logic:

```text
Unauthenticated
    ↓
Login/Register
    ↓
Authenticated
    ├─ admin → Admin Dashboard
    ├─ pendamping + no valid activeRoomId → Join Room
    ├─ pendamping + valid activeRoomId → Pendamping Dashboard
    ├─ jamaah + no valid activeRoomId → Join Room
    └─ jamaah + valid activeRoomId → Jamaah Dashboard
```

Guard requirements:

- Do not rely only on UI visibility.
- Validate authentication state and role before entering protected routes.
- Validate that `activeRoomId` refers to a real, active room and that the user is actually a member.
- Prevent bypass through direct navigation/deep links.
- Logout clears local/reactive auth + room state but must not delete Firestore data.

Follow the project's existing GetX routing/guard architecture instead of introducing a second navigation system.

---

## 8. Join Room UX

Create/reuse a single Join Room flow where possible.

Fields:

- Nama Room
- Kode Room
- Button: `Gabung Room`

States:

- idle
- validating
- success
- invalid room name/code
- room inactive
- already a member
- network/Firestore error

After success:

```text
users/{uid}.activeRoomId = roomId
rooms/{roomId}/members/{uid} = membership
```

Use a Firestore transaction/batch where needed so these writes stay consistent.

Do not trust a room ID supplied by the client without validating the room code/name and membership rules.

---

## 9. Pendamping — Add Jamaah

Goal: allow a Pendamping to add an existing Jamaah account to the current active room.

Important design rule:

> Pendamping does not create a new Firebase account for the Jamaah.

The Jamaah already has an account.

Recommended flow:

```text
Pendamping Dashboard
→ Tambah Jamaah
→ Search/identify existing Jamaah
→ Validate target role == jamaah
→ Validate target is not already in another active room (for v1)
→ Add membership to current room
→ Set jamaah.activeRoomId
→ Refresh member list
```

The exact lookup mechanism should reuse existing user profile/search capabilities. Do not create a new data source unless necessary.

---

## 10. Monitoring / Map Integration

Existing HajiCare map and monitoring features must become room-aware.

Current map architecture already uses:

- `flutter_map`
- `latlong2`
- `MapController`
- Firebase-backed Jamaah data
- dynamic markers
- current user location
- SOS state

Room integration requirement:

```text
activeRoomId
    ↓
rooms/{roomId}/members
    ↓
resolve member UIDs
    ↓
load/observe corresponding users
    ↓
show only relevant Jamaah in map/monitoring
```

A Pendamping must NOT see all Jamaah in the global `users` collection.

Admin may have broader visibility depending on existing product rules, but do not expand scope unnecessarily.

---

## 11. Security Principles

Firestore rules must enforce authorization server-side.

Never rely on:

- hidden buttons
- route names
- client-side role checks only
- client-generated trusted role values

Rules must prevent:

- Jamaah changing role to admin/pendamping
- user changing another user's role
- non-admin creating/editing/deleting arbitrary rooms
- Pendamping reading another room's membership
- Jamaah reading unrelated room member lists
- joining inactive rooms
- duplicate memberships

If a required security constraint cannot be safely enforced with the current model, document it before implementing a workaround.

---

## 12. Data Consistency

Whenever membership is created:

1. Validate current authenticated user.
2. Validate role.
3. Validate room exists and is active.
4. Validate code/name.
5. Validate membership does not already exist.
6. Write membership.
7. Update `users/{uid}.activeRoomId`.
8. Confirm resulting state.

Use Firestore transaction/batch for multi-document updates whenever appropriate.

Do not silently leave a user in a half-joined state.

---

## 13. UI/UX Requirements

Keep the existing HajiCare design system.

Do not introduce a different visual language.

Required screens/features:

### Admin
- Room list
- Create room
- Edit room
- Activate/deactivate room
- Room detail
- Member list
- Member role labels

### Pendamping
- Join Room
- Active Room summary
- Member/Jamaah list
- Add Jamaah
- Existing dashboard/features remain accessible after joining

### Jamaah
- Join Room
- Active Room summary
- Existing dashboard/features remain accessible after joining

Use proper:

- loading state
- empty state
- error state
- success feedback
- confirmation for destructive actions
- accessible text sizes and touch targets

---

## 14. Existing Project Constraints

Before implementation:

1. Audit current project architecture.
2. Identify existing AuthService/AuthController/UserModel/Firestore repository.
3. Identify current GetX bindings/routes.
4. Identify existing role-based dashboards.
5. Identify all current uses of `users` and Jamaah data.
6. Integrate room state instead of duplicating existing state management.

Do not:

- rebuild authentication from scratch
- create duplicate user models
- create duplicate Firebase initialization
- replace GetX unnecessarily
- replace existing design system
- break existing map/SOS features
- use mock room data in production code
- hardcode user UID or room ID

---

## 15. Suggested Components

Names are suggestions only; reuse existing project naming conventions if equivalents already exist.

```text
RoomModel
RoomMemberModel
RoomRepository / RoomService
RoomController
JoinRoomScreen
AdminRoomScreen
RoomDetailScreen
AddJamaahDialog/Screen
RoomGuard / AuthGuard extension
```

Prefer a small number of well-defined services/controllers over excessive abstraction.

---

## 16. Tests / Acceptance Criteria

Minimum required behavior:

### Auth / Routing
- Admin login → Admin Dashboard
- Pendamping login with no room → Join Room
- Jamaah login with no room → Join Room
- Valid active room → role dashboard
- Invalid/deleted/inactive active room → Join Room
- Deep-link bypass is blocked

### Room
- Admin can create room
- Room code is generated and unique
- Admin can view room members
- Admin can update room
- Admin can deactivate room
- Inactive room rejects joining
- Duplicate join is rejected/handled safely

### Membership
- Pendamping can join valid room
- Jamaah can join valid room
- Two or more users can be in the same room
- Membership stored under room subcollection
- `activeRoomId` updated correctly
- Reload preserves valid room state
- Pendamping sees only members of active room
- Jamaah cannot manage members

### Existing Features
- Map still renders
- Room-scoped Jamaah appear on map
- SOS state remains functional
- Existing dashboards remain accessible after successful room join

Run:

```bash
flutter analyze
flutter test
```

Fix errors rather than ignoring them.

---

## 17. Implementation Order

Recommended order:

```text
1. Audit existing auth/user/role architecture
2. Define Room + RoomMember models
3. Add room repository/service
4. Add Firestore Security Rules
5. Implement admin Room CRUD
6. Implement Join Room
7. Add route/auth room guard
8. Implement Pendamping member management
9. Integrate room scope into map/monitoring
10. Update tests
11. Run analyzer + full tests
```

Do not start with UI-only changes. Establish the data/security foundation first.

---

## 18. Definition of Done

The feature is complete when:

- Admin can create/manage rooms.
- Pendamping can register/login, join a room, and then access Pendamping dashboard.
- Jamaah can register/login, join a room, and then access Jamaah dashboard.
- Users without a valid room cannot bypass the Join Room gate.
- Pendamping monitoring is isolated to the active room.
- Existing HajiCare features still work.
- Firestore Security Rules enforce role/room boundaries.
- Tests cover the critical room/auth flows.
- `flutter analyze` and `flutter test` pass.

---

## 19. Guiding Principle for Implementation

Keep v1 simple:

> **One user → one active room. One room → many members. Membership is the access boundary.**

Design the implementation so future multi-room support can be added later without rewriting the entire application.
