# HajiCare trusted operations

Deploy these callable functions before publishing the Flutter client or the
hardened Firestore Rules. The client uses region `asia-southeast2`.

Recommended rollout:

1. Deploy Functions and indexes.
2. Verify callable flows against a staging Firebase project.
3. Assign `role: admin` / `role: pendamping` custom claims only after manual
   identity approval. Do not bulk-copy the old writable profile role into a
   claim.
4. Deploy Firestore Rules.
5. Publish the client.
6. Enable and enforce App Check after registered production builds have been
   verified.

The `reviewPendampingAccess` callable is admin-only and updates both the custom
claim and the display profile. Users must receive a refreshed ID token before
new privileges appear; the app listens to `idTokenChanges()`.

Local verification uses the Firestore Emulator suite in `../firebase-tests`.
It requires Node 22 and Java 21.
