# Clipsy

> Every video, picked by a parent. When the time's up, it stops.

Clipsy lets parents build playlists of YouTube videos for their kids, lock the
device into one playlist, and cap how long it plays. Parents can publish
playlists to a community library, label them, and rate other parents' lists.

- **Parent mode**: behind a 4-digit PIN. Manage playlists, settings, community.
- **Kid mode**: big thumbnails, locked to one playlist, stops when time's up.

Flutter (Android first, then iOS) · Riverpod (codegen) · go_router · Supabase.

---

## Status

| Milestone | Scope | State |
|---|---|---|
| 1. Foundation | Project setup, theming, l10n (en, pt-PT), routing, Supabase auth, PIN, DB migrations + RLS + labels | ✅ |
| 2. Playlists | CRUD, add by URL + oEmbed validation, reorder, labels, age range | ✅ |
| 3. Kid mode | Player, Android screen pinning / iOS Guided Access detection, exit gesture + PIN, timers, time's-up, persistence | ⏳ |
| 4. Community | Publish, browse/filter/search, fork, ratings, reports + auto-hide, share-sheet intake, revalidation Edge Function | ⏳ |
| 5. Polish | Tests, accessibility, account deletion UI, privacy policy, Families checklist | ⏳ |

---

## Setup

### 1. Tooling

- Flutter stable (developed on 3.47.x, Dart 3.13). Run `flutter doctor` first.
- Android Studio / Android SDK for Android, Xcode for iOS.
- [Supabase CLI](https://supabase.com/docs/guides/cli) (`npx supabase …` works too).
- Docker, if you want a local Supabase stack.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Riverpod codegen
```

Localisations are generated automatically from `lib/l10n/*.arb` on
`flutter pub get` / `flutter run` (or run `flutter gen-l10n`).

### 2. Supabase project

1. Create a project at [supabase.com](https://supabase.com) (pick an EU region
   if most users are in the EU).
2. Link and push the migrations:
   ```bash
   supabase login
   supabase link --project-ref <your-project-ref>
   supabase db push
   ```
   This creates every table, trigger, RLS policy and RPC, and seeds the 16 labels.
3. **Auth → URL configuration**: add `app.clipsy://login-callback` to
   *Redirect URLs*.
4. **Auth → Providers**:
   - *Email*: enabled (magic link). Optionally customise the email template.
   - *Google*: create an OAuth client in Google Cloud (type *Web application*),
     set its redirect URI to `https://<project-ref>.supabase.co/auth/v1/callback`,
     paste the client ID and secret into Supabase.
5. Make yourself a moderator (SQL editor):
   ```sql
   insert into public.admins (user_id)
   select id from auth.users where email = 'you@example.com';
   ```
6. Optional: change the auto-hide threshold (default 3 reports):
   ```sql
   update public.app_settings set report_hide_threshold = 5;
   ```

#### Local Supabase instead

```bash
supabase start          # needs Docker; prints the local URL and anon key
supabase db reset       # applies migrations + seed
```

Use `http://10.0.2.2:54321` as `SUPABASE_URL` from the Android emulator.
Magic-link emails land in Inbucket/Mailpit at <http://127.0.0.1:54324>.

### 3. App configuration

Secrets never go in the repo. Copy the template and fill it in:

```bash
cp .env.example .env
```

| Key | Where to find it |
|---|---|
| `SUPABASE_URL` | Project Settings → API → Project URL |
| `SUPABASE_ANON_KEY` (or `SUPABASE_PUBLISHABLE_KEY`) | Project Settings → API → publishable/anon key |
| `PRIVACY_POLICY_URL` | Your hosted privacy policy (optional for now) |

The publishable key is designed to ship in apps: Row Level Security protects
the data. Never put the `service_role` key in the app or in `.env`.

### 4. Run

```bash
flutter run --dart-define-from-file=.env
```

On a physical Android device: enable Developer options → USB debugging,
connect, then `flutter devices` and `flutter run -d <id> --dart-define-from-file=.env`.

If you run without the defines the app shows a "missing configuration" screen
instead of crashing.

---

## Tests

```bash
flutter analyze
flutter test                 # unit + widget tests
tool/test_db.sh              # migrations + RLS + triggers (see below)
```

`tool/test_db.sh` spins up a throwaway Postgres (needs `initdb`/`pg_ctl`,
e.g. `apt install postgresql` or `brew install postgresql@16`), loads a small
Supabase stub, applies all migrations, and runs `supabase/tests/rls_test.sql`.
Point it at a local Supabase instead with
`DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres tool/test_db.sh`.
Everything runs in a rolled-back transaction.

CI (`.github/workflows/ci.yml`) runs format, analyze, Flutter tests and the
database tests on every push and PR.

---

## Project structure

```
lib/
  main.dart                  Supabase init, ProviderScope
  app.dart                   MaterialApp.router, themes, l10n, auto-relock
  core/
    config/                  Env (dart-define), AppConfig constants
    l10n/                    context.l10n helper
    router/                  go_router setup, AppGate state, pure redirect rules
    storage/                 SecureStore abstraction, secure Supabase session storage
    supabase/                SupabaseClient provider (the only global access)
    theme/                   Parent (M3 light/dark) and Kid themes
    widgets/                 PinPad, PinEntryView, ParentShell, shared UI
  features/
    auth/      data/ domain/ presentation/   sign-in, PIN, onboarding, unlock
    playlists/ data/ domain/ presentation/   library, editor, detail, add-video sheet
    kid_mode/  …                             (M3)
    community/ …                             (M4)
    settings/  …
  l10n/                      app_en.arb, app_pt.arb (+ generated/)
supabase/
  config.toml                local stack config
  migrations/                schema, RLS, triggers, RPCs, label seed
  tests/                     database tests (+ stub for plain Postgres)
tool/test_db.sh
```

Rules: widgets never call Supabase. Each feature exposes repositories
(`data/`) behind interfaces, plain models and pure logic (`domain/`), and
Riverpod providers and screens (`presentation/`).

---

## Design notes

### App gate and PIN
Startup goes through one gate, in order: signed in → PIN exists → onboarding
done → parent mode unlocked. `core/router/redirect.dart` holds the rule as a
pure function, and it is unit-tested.

- The PIN is hashed with salted PBKDF2-HMAC-SHA256 and stored with
  `flutter_secure_storage` (Android Keystore / iOS Keychain). A 4-digit PIN
  can't resist an offline attack, so the keystore and throttling are the
  real protection: 5 free tries, then 30 s, doubling up to 15 min.
- The PIN is per device. Signing out clears it, and "Forgot PIN?" signs out,
  so re-authenticating is the reset.
- Parent mode relocks after 1 minute in the background, and on every cold start.
- The Supabase session (refresh token) lives in secure storage, not
  SharedPreferences.

### Database
- Column-level grants mean clients can only write the columns they own. Counters,
  moderation flags, `owner_id` and `is_available` are written only by triggers,
  admin RPCs, or the service role.
- Triggers keep `rating_avg`/`rating_count`/`report_count` in sync and
  auto-hide at the threshold. Hiding is sticky until `admin_review_playlist`.
- Publishing requires 1–3 labels and at least one available video. This is a
  deferred constraint trigger, so `set_playlist_labels` can swap labels atomically.
- Covers and thumbnails must be YouTube image URLs, so nobody can put
  arbitrary images in front of children.
- `community_playlists` is a `security_invoker` view with author display
  name, counts, total duration and label slugs. It never includes an email.
- `delete_my_account()` removes the auth user and cascades everything they
  own. Other parents' forks survive with `forked_from = null`.

### Playlists
- `YouTubeUrlParser` accepts watch, short (`youtu.be`), Shorts, embed, live,
  mobile and music links, links inside shared text, and bare IDs. It rejects
  channels, playlist-only links and lookalike domains.
- Every video is validated with YouTube oEmbed before it is added. YouTube
  answers 401/403 when embedding is disabled and 400/404 when the video is
  gone; each gets its own friendly message. No API key is needed.
- Thumbnails are always built from the video ID on `i.ytimg.com`, never
  taken from the response.
- The cover is the first available video's thumbnail. A database trigger
  keeps it up to date (migration `20261018000000`).
- The parent's playlist order is `sort_index`. New playlists go to the top,
  and drag-and-drop saves through `reorder_my_playlists`.
- Video duration isn't available from oEmbed, so it stays empty for now (see
  Milestone 3).

### Compliance
- Video playback only through the official YouTube IFrame player (M3). No
  downloads, no audio-only background play. Ads and YouTube branding are
  never covered.
- No analytics or ads SDKs. No accounts or personal data for children.
- Parent profiles start with the display name "Parent". Google's real name
  is **not** copied into the public profile.
