# Firebase Setup — Bananarator

Step-by-step to wire the existing Firebase project (`bananarator-cb0cc`) so the app's reads and writes actually work. The `GoogleService-Info.plist` is already in the repo at `Bananarator/GoogleService-Info.plist`; this doc covers everything you need to do **in the Firebase console** to unblock the app at runtime.

---

## 1. Authentication

The app calls `Auth.auth().signInAnonymously()` on first launch (see `AppState.swift:28`). Until Anonymous auth is enabled, every Firestore/Storage call fails with `PERMISSION_DENIED`.

**In Firebase Console** → Authentication → Sign-in method:
1. Enable **Anonymous** (required, Phase 1)
2. (Phase 2) Enable **Apple** for Sign in with Apple — needed before TestFlight if you want named accounts and persistent identities across reinstalls

That's it for Auth Phase 1.

---

## 2. Firestore Database

**Console** → Firestore Database → **Create database**:
1. Mode: **Production mode** (we'll paste rules below)
2. Region: **us-central1** (low latency for North America, cheap; cannot be changed later)
3. Click Enable

### Collections the app uses
| Collection | Used in | Purpose |
|---|---|---|
| `users/{uid}` | `FirebaseService.fetchUserProfile`, `createUserProfile`, `updateUsername` | profile doc per anonymous uid |
| `posts/{postId}` | `FirebaseService` showcase queries | published banana creations |
| `posts/{postId}/upvotes/{uid}` | `upvotePost` | one doc per user per post |
| `reports/{auto}` | `reportPost` | moderation queue (read by you offline) |

### Security rules — paste into Rules tab

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Profile docs — readable by anyone (Showcase shows usernames),
    // writable only by the owner.
    match /users/{userId} {
      allow read: if true;
      allow create, update: if request.auth != null && request.auth.uid == userId;
      allow delete: if false;
    }

    // Posts — readable by anyone, only the author may create / edit / delete,
    // and only well-formed payloads are accepted.
    match /posts/{postId} {
      allow read: if true;

      allow create: if request.auth != null
        && request.resource.data.authorId == request.auth.uid
        && request.resource.data.keys().hasAll(['authorId', 'imageURL', 'createdAt'])
        && request.resource.data.imageURL is string
        && request.resource.data.imageURL.size() < 1024;

      allow update: if request.auth != null
        && resource.data.authorId == request.auth.uid
        // upvote counter is the only field non-owners would modify;
        // owners can update anything else they own.
        ;

      allow delete: if request.auth != null
        && resource.data.authorId == request.auth.uid;

      // Upvotes: one doc per user. The doc id IS the voter's uid.
      match /upvotes/{uid} {
        allow read: if true;
        allow create, delete: if request.auth != null && request.auth.uid == uid;
        allow update: if false;
      }
    }

    // Reports — write-only from clients, read only via console / admin SDK.
    match /reports/{reportId} {
      allow create: if request.auth != null
        && request.resource.data.reporterId == request.auth.uid;
      allow read, update, delete: if false;
    }
  }
}
```

**Heads-up:** the `posts` update rule above is permissive — any authenticated user could increment the upvote counter on someone else's post (which is what we want — that's the upvote flow). If you ever add fields that only the author should edit, tighten this with a `request.resource.data.diff(resource.data).affectedKeys()` check that only allows `upvotes` to change for non-authors.

### Indexes

Likely needed once you start querying:
- `posts` composite: `createdAt DESC` (default) — auto-created on first query
- `posts` composite: `authorId ASC, createdAt DESC` — for "my posts" filter; Firebase will prompt with a one-click link the first time the query runs

Don't pre-create — let the console-provided links generate them on first 4xx.

---

## 3. Cloud Storage

**Console** → Storage → **Get started**:
1. Mode: Production
2. Region: us-central1 (same as Firestore)

### Path convention
`FirebaseService.uploadImage(_:path:)` takes an arbitrary path. Establish this convention in code (not yet enforced — flag for cleanup):

```
posts/{uid}/{postId}.jpg     // shared/published banana images
avatars/{uid}.jpg            // profile pictures (Phase 2)
```

### Security rules — paste into Storage Rules tab

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {

    // Public read for posts (Showcase + share links).
    // Writes scoped to the owner and limited to small JPEGs.
    match /posts/{uid}/{file=**} {
      allow read: if true;
      allow write: if request.auth != null
        && request.auth.uid == uid
        && request.resource.size < 8 * 1024 * 1024
        && request.resource.contentType.matches('image/(jpeg|png)');
    }

    match /avatars/{uid} {
      allow read: if true;
      allow write: if request.auth != null
        && request.auth.uid == uid
        && request.resource.size < 2 * 1024 * 1024
        && request.resource.contentType.matches('image/(jpeg|png)');
    }

    // Default deny.
    match /{path=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 4. Verification checklist

After pasting rules in both Firestore and Storage:

- [ ] Launch the app fresh on a simulator. First launch should silently sign in anonymously — no auth error in the Xcode console.
- [ ] Tap Showcase. If empty, that's normal — the collection is empty. Confirm no `PERMISSION_DENIED` log.
- [ ] If you've already wired a Create flow, take a photo, save/publish, then confirm a new `posts/{id}` doc appears in the Firestore console.
- [ ] If publish includes an image upload, confirm the file lands under `posts/<your-uid>/...` in Storage.
- [ ] Toggle Firestore → Rules → Rules Playground; simulate an unauthenticated read of `posts/anything` → should be **allowed**.
- [ ] Simulate unauthenticated write of `posts/abc` → should be **denied**.

---

## 5. What's next after this is wired

- **Sign in with Apple** (Phase 2) — needed for TestFlight, lets users keep posts across reinstalls.
- **Cloud Functions** — moderation: a function triggered on new `reports/*` docs that pages you in Slack/email. Out of scope for MVP.
- **Firestore Analytics** — Firebase Analytics is already pulled in by the Firebase SDK. No additional setup; just enable in the console if you want default event tracking.
- **App Check** — recommended before public launch. Blocks Firebase calls from non-app callers (e.g., someone running curl against your project). Easy to add later, easy to forget until you're being abused.
